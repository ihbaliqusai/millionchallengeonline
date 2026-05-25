import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/campaign_stage.dart';
import '../../models/stage_attempt.dart';
import '../../services/campaign_mode_engine.dart';
import '../../services/campaign_question_selector.dart';
import '../../services/campaign_result_handler.dart';
import '../../services/campaign_service.dart';
import '../../services/native_bridge_service.dart';
import 'campaign_map_screen.dart';
import 'stage_leaderboard_screen.dart';
import 'widgets/animated_result_stars.dart';
import 'widgets/level_complete_background.dart';
import 'widgets/result_bottom_actions.dart';
import 'widgets/result_reward_panel.dart';
import 'widgets/result_ribbon_header.dart';
import 'widgets/result_score_counter.dart';

class StageResultScreen extends StatefulWidget {
  const StageResultScreen({
    super.key,
    required this.stage,
    required this.submissionResult,
    this.rawNativeResult,
    this.currencyRewardApplied = false,
  });

  final CampaignStage stage;
  final StageSubmissionResult submissionResult;
  final Map<String, dynamic>? rawNativeResult;
  final bool currencyRewardApplied;

  @override
  State<StageResultScreen> createState() => _StageResultScreenState();
}

class _StageResultScreenState extends State<StageResultScreen>
    with WidgetsBindingObserver {
  static const Duration _pendingResultRetryDelay = Duration(milliseconds: 350);
  static const Duration _missingResultTimeout = Duration(seconds: 8);

  final CampaignQuestionSelector _questionSelector = CampaignQuestionSelector();
  bool _launchingStage = false;
  bool _waitingForResult = false;
  bool _returnedFromNative = false;
  bool _pendingResultRetryScheduled = false;
  DateTime? _missingResultSince;

  CampaignStage get stage => widget.stage;
  StageSubmissionResult get submissionResult => widget.submissionResult;
  Map<String, dynamic>? get rawNativeResult => widget.rawNativeResult;
  bool get currencyRewardApplied => widget.currencyRewardApplied;
  bool get _isUnsavedPreview {
    return submissionResult.attempt.uid.isEmpty && rawNativeResult != null;
  }

  bool get _isBossStage =>
      stage.campaignMode == CampaignMode.bossBattle ||
      stage.type == CampaignStageType.boss;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_launchingStage) {
        _returnedFromNative = true;
        if (!_waitingForResult && mounted) {
          setState(() => _waitingForResult = true);
        }
      }
      _consumePendingCampaignResult();
    }
  }

  Future<void> _consumePendingCampaignResult() async {
    if (!mounted) return;
    final handled =
        await CampaignResultHandler.consumeAndHandlePendingCampaignResult(
      context: context,
    );
    if (!mounted) return;
    if (handled && _launchingStage) {
      _resetPendingResultWait();
      setState(() {
        _launchingStage = false;
        _waitingForResult = false;
      });
      return;
    }
    if (!handled && _launchingStage) {
      if (_shouldStopWaitingForMissingResult()) {
        _stopWaitingForMissingResult();
        return;
      }
      _retryPendingResultSoon();
    }
  }

  void _retryPendingResultSoon() {
    if (_pendingResultRetryScheduled) return;
    _pendingResultRetryScheduled = true;
    Future<void>.delayed(_pendingResultRetryDelay, () {
      _pendingResultRetryScheduled = false;
      if (!mounted || !_launchingStage) return;
      _consumePendingCampaignResult();
    });
  }

  bool _shouldStopWaitingForMissingResult() {
    if (!_returnedFromNative) return false;
    final now = DateTime.now();
    _missingResultSince ??= now;
    return now.difference(_missingResultSince!) >= _missingResultTimeout;
  }

  void _stopWaitingForMissingResult() {
    _resetPendingResultWait();
    if (!mounted) return;
    setState(() {
      _launchingStage = false;
      _waitingForResult = false;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'لم تصل نتيجة المرحلة. حاول بدء المرحلة مرة أخرى.',
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
  }

  void _resetPendingResultWait() {
    _returnedFromNative = false;
    _pendingResultRetryScheduled = false;
    _missingResultSince = null;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final attempt = submissionResult.attempt;
    final completed = attempt.completed;
    final bossDefeated = _isBossStage && attempt.bossDefeated;
    final usedLifelines =
        attempt.used5050 + attempt.usedAudience + attempt.usedCall;
    final hasCoins = appState.currentUser != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: LevelCompleteBackground()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final contentWidth = constraints.maxWidth - 32;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      children: [
                        _TopHud(
                          coins: hasCoins ? appState.coins : null,
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Center(
                              child: SizedBox(
                                width: contentWidth,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ResultRibbonHeader(
                                      child: AnimatedResultStars(
                                        stars: submissionResult.newStars,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _ResultMessage(
                                      completed: completed,
                                      stage: stage,
                                      attempt: attempt,
                                      bossDefeated: bossDefeated,
                                      message: _cleanMessage(
                                        submissionResult.motivationalMessage,
                                        completed: completed,
                                        attempt: attempt,
                                        bossStage: _isBossStage,
                                        bossDefeated: bossDefeated,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ResultScoreCounter(score: attempt.score),
                                    if (_isUnsavedPreview) ...[
                                      const SizedBox(height: 10),
                                      const _WarningPill(),
                                    ],
                                    const SizedBox(height: 12),
                                    _StatsPanel(
                                      correctAnswers: attempt.correctAnswers,
                                      wrongAnswers: attempt.wrongAnswers,
                                      timeMs: attempt.timeMs,
                                      usedLifelines: usedLifelines,
                                    ),
                                    if (_hasModeDetails(attempt)) ...[
                                      const SizedBox(height: 10),
                                      _ModeDetailsPanel(
                                        stage: stage,
                                        attempt: attempt,
                                      ),
                                    ],
                                    if (_isBossStage) ...[
                                      const SizedBox(height: 10),
                                      _BossBattleResultPanel(
                                        bossName: attempt.bossName,
                                        playerCorrectAnswers:
                                            attempt.correctAnswers,
                                        bossCorrectAnswers:
                                            attempt.bossCorrectAnswers,
                                        playerScore: attempt.playerScore,
                                        bossScore: attempt.bossScore,
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    ResultRewardPanel(
                                      result: submissionResult,
                                      currencyRewardApplied:
                                          currencyRewardApplied,
                                    ),
                                    const SizedBox(height: 6),
                                    TextButton.icon(
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              StageLeaderboardScreen(
                                            stage: stage,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.leaderboard_rounded,
                                      ),
                                      label: const Text('عرض الترتيب'),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFFBDEBFF),
                                        textStyle: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    if (_isUnsavedPreview) ...[
                                      const SizedBox(height: 4),
                                      _RetrySaveButton(
                                        onPressed: () => _retrySave(context),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ResultBottomActions(
                          launching: _launchingStage,
                          onMap: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => const CampaignMapScreen(),
                            ),
                          ),
                          onRetry: () => _launchStageAgain(context),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_launchingStage)
              const Positioned.fill(
                child: _BlockingLoadingOverlay(message: 'جاري بدء المرحلة...'),
              ),
          ],
        ),
      ),
    );
  }

  String _cleanMessage(
    String message, {
    required bool completed,
    required StageAttempt attempt,
    bool bossStage = false,
    bool bossDefeated = false,
  }) {
    final mode = _modeForAttempt(attempt, stage);
    if (bossStage || mode == CampaignMode.bossBattle) {
      return bossDefeated
          ? 'مواجهة رائعة، لقد فتحت الطريق التالي.'
          : 'لم تهزم الزعيم بعد. حاول مرة أخرى.';
    }
    switch (mode) {
      case CampaignMode.blitz:
        if (!completed && attempt.failureReason == 'timeExpired') {
          return 'انتهى الوقت قبل إكمال المرحلة.';
        }
        break;
      case CampaignMode.elimination:
        if (!completed) return 'تجاوزت حد الأخطاء المسموح.';
        break;
      case CampaignMode.survival:
        if (!completed) return 'انتهت الأرواح قبل نهاية الأسئلة.';
        break;
      case CampaignMode.battle:
        return completed
            ? 'تفوقت على الخصم بالنقاط.'
            : 'الخصم أنهى المواجهة متقدمًا.';
      case CampaignMode.rival:
        return completed
            ? 'تجاوزت نتيجة الهدف.'
            : 'اقتربت، لكن الهدف لم يتحقق.';
      case CampaignMode.series:
        return completed
            ? 'حسمت السلسلة لصالحك.'
            : 'السلسلة لم تكن لصالحك هذه المرة.';
      case CampaignMode.teamBattle:
        return completed
            ? 'فريقك أنهى المواجهة متقدمًا.'
            : 'فريق الخصم تفوق بالنقاط.';
      case CampaignMode.classic:
      case CampaignMode.noLifeline:
      case CampaignMode.bossBattle:
        break;
    }
    final trimmed = message.trim();
    if (trimmed.isNotEmpty && !trimmed.contains('\u00D8')) return trimmed;
    return completed
        ? 'تم حفظ النتيجة واحتساب النجوم حسب قواعد المرحلة.'
        : 'حاول مرة أخرى وأكمل شرط المرحلة لفتح الطريق التالي.';
  }

  bool _hasModeDetails(StageAttempt attempt) {
    final mode = _modeForAttempt(attempt, stage);
    return mode != CampaignMode.classic && mode != CampaignMode.noLifeline;
  }

  Future<void> _retrySave(BuildContext context) async {
    final user = context.read<AppState>().currentUser;
    final uid = user?.uid.trim() ?? '';
    final payload = rawNativeResult;
    final messenger = ScaffoldMessenger.of(context);
    if (user == null || uid.isEmpty || payload == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('سجّل الدخول لحفظ تقدمك في رحلة المليون.'),
          ),
        );
      return;
    }
    try {
      final result = await CampaignService().submitStageResult(
        uid: uid,
        stage: stage,
        nativeResult: payload,
        displayName:
            (user.displayName ?? user.email?.split('@').first ?? '').trim(),
        photoUrl: user.photoURL,
      );
      if (!context.mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => StageResultScreen(
            stage: stage,
            submissionResult: result,
            rawNativeResult: payload,
          ),
        ),
      );
    } catch (error, stackTrace) {
      _debugRetrySaveFailure(
        error: error,
        stackTrace: stackTrace,
        uid: uid,
        payload: payload,
      );
      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _saveFailureMessage(error),
              textAlign: TextAlign.right,
            ),
          ),
        );
    }
  }

  Future<void> _launchStageAgain(BuildContext context) async {
    if (_launchingStage) return;
    _resetPendingResultWait();
    setState(() {
      _launchingStage = true;
      _waitingForResult = false;
    });
    final nativeBridge = context.read<NativeBridgeService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final questionIds = await _questionSelector.selectQuestionIds(stage);
      final levelSummary =
          await _questionSelector.levelSummaryForQuestionIds(questionIds);
      final effectiveAllowedLevels = <String>{
        ...stage.allowedLevels,
        ...levelSummary.keys,
      }.where((level) => level.trim().isNotEmpty).toList(growable: false);
      if (kDebugMode) {
        debugPrint(
          'Retry campaign stage=${stage.id} order=${stage.order} '
          'allowed=${stage.allowedLevels} questionIds=$questionIds '
          'levels=$levelSummary nativeAllowed=$effectiveAllowedLevels',
        );
      }
      if (questionIds.length < stage.questionCount) {
        throw StateError('Not enough campaign questions selected');
      }
      final launchConfig = const CampaignModeEngine().buildLaunchConfig(stage);
      await nativeBridge.launchCampaignStage(
        campaignId: launchConfig['campaignId'] as String? ?? stage.campaignId,
        stageId: launchConfig['stageId'] as String? ?? stage.id,
        stageType: launchConfig['stageType'] as String? ?? stage.type.value,
        campaignMode:
            launchConfig['campaignMode'] as String? ?? stage.campaignMode.value,
        winCondition:
            launchConfig['winCondition'] as String? ?? stage.winCondition.value,
        questionIds: questionIds,
        allowedLevels: effectiveAllowedLevels,
        questionCount:
            launchConfig['questionCount'] as int? ?? stage.questionCount,
        timeLimitSeconds:
            launchConfig['timeLimitSeconds'] as int? ?? stage.timeLimitSeconds,
        allow5050: launchConfig['allow5050'] as bool? ?? stage.allow5050,
        allowAudience:
            launchConfig['allowAudience'] as bool? ?? stage.allowAudience,
        allowCall: launchConfig['allowCall'] as bool? ?? stage.allowCall,
        bossBotName: launchConfig['bossBotName'] as String? ?? '',
        bossBotIntelligence: launchConfig['bossBotIntelligence'] as int? ?? 0,
        lives: launchConfig['lives'] as int? ?? 0,
        maxWrongAnswers: launchConfig['maxWrongAnswers'] as int? ?? 0,
        targetScore: launchConfig['targetScore'] as int? ?? 0,
        opponentName: launchConfig['opponentName'] as String? ?? '',
        opponentAccuracy: launchConfig['opponentAccuracy'] as int? ?? 0,
        opponentStartScore: launchConfig['opponentStartScore'] as int? ?? 0,
        seriesRounds: launchConfig['seriesRounds'] as int? ?? 0,
        seriesWinsRequired: launchConfig['seriesWinsRequired'] as int? ?? 0,
        teamAllyName: launchConfig['teamAllyName'] as String? ?? '',
        teamEnemyName: launchConfig['teamEnemyName'] as String? ?? '',
      );
      if (mounted) setState(() => _waitingForResult = true);
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر تحميل أسئلة مناسبة لهذه المرحلة.',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        );
      if (mounted) {
        _resetPendingResultWait();
        setState(() {
          _launchingStage = false;
          _waitingForResult = false;
        });
      }
    }
  }

  String _saveFailureMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'تعذر الحفظ بسبب صلاحيات قاعدة البيانات. تأكد من نشر قواعد Firestore.';
        case 'unavailable':
        case 'deadline-exceeded':
          return 'تعذر الاتصال. سيتم عرض نتيجتك الحالية فقط.';
      }
    }
    if (error is ArgumentError) {
      return 'سجّل الدخول لحفظ تقدمك في رحلة المليون.';
    }
    return 'تعذر حفظ النتيجة الآن. سيتم عرض نتيجتك الحالية فقط.';
  }

  void _debugRetrySaveFailure({
    required Object error,
    required StackTrace stackTrace,
    required String uid,
    required Map<String, dynamic> payload,
  }) {
    final firebaseDetails = error is FirebaseException
        ? ' firebaseCode=${error.code} firebaseMessage=${error.message} '
            'firebasePlugin=${error.plugin}'
        : '';
    debugPrint(
      'CAMPAIGN_SAVE_FAILED\n'
      'exceptionType=${error.runtimeType}$firebaseDetails\n'
      'message=$error\n'
      'uid=$uid\n'
      'campaignId=${payload['campaignId']}\n'
      'stageId=${payload['stageId']}\n'
      'completed=${payload['completed']}\n'
      'correctAnswers=${payload['correctAnswers']}\n'
      'wrongAnswers=${payload['wrongAnswers']}\n'
      'timeMs=${payload['timeMs']}\n'
      'nativeResultKeys=${payload.keys.toList()}\n'
      'nativeResult=$payload',
    );
    if (kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

class _TopHud extends StatelessWidget {
  const _TopHud({
    required this.coins,
    required this.onBack,
  });

  final int? coins;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HudButton(icon: Icons.arrow_forward_rounded, onPressed: onBack),
        const Spacer(),
        if (coins != null)
          _CurrencyChip(
            icon: Icons.monetization_on_rounded,
            value: '$coins',
          ),
      ],
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF06143D).withValues(alpha: 0.56),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF06143D).withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFFD84A), size: 19),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMessage extends StatelessWidget {
  const _ResultMessage({
    required this.completed,
    required this.stage,
    required this.attempt,
    required this.bossDefeated,
    required this.message,
  });

  final bool completed;
  final CampaignStage stage;
  final StageAttempt attempt;
  final bool bossDefeated;
  final String message;

  @override
  Widget build(BuildContext context) {
    final mode = _modeForAttempt(attempt, stage);
    return Column(
      children: [
        Text(
          _resultTitle(
            mode: mode,
            completed: completed,
            failureReason: attempt.failureReason,
            bossDefeated: bossDefeated,
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.05,
            shadows: [
              Shadow(
                color: Color(0xAA000000),
                blurRadius: 9,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'مرحلة ${stage.order} • ${stage.title}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFBDEBFF),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 15,
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ModeDetailsPanel extends StatelessWidget {
  const _ModeDetailsPanel({
    required this.stage,
    required this.attempt,
  });

  final CampaignStage stage;
  final StageAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final mode = _modeForAttempt(attempt, stage);
    final chips = _chipsForMode(mode);
    if (chips.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF061642).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: GridView.count(
        crossAxisCount: chips.length > 2 ? 3 : 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.28,
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
        children: chips,
      ),
    );
  }

  List<Widget> _chipsForMode(CampaignMode mode) {
    switch (mode) {
      case CampaignMode.blitz:
        return <Widget>[
          _StatChip(
            icon: Icons.timer_rounded,
            label: 'الوقت',
            value: _formatTime(attempt.timeMs),
            color: const Color(0xFF7DD3FC),
          ),
          _StatChip(
            icon: Icons.flag_rounded,
            label: 'الحالة',
            value: attempt.failureReason == 'timeExpired' ? 'انتهى' : 'مكتمل',
            color: const Color(0xFFFFD95A),
          ),
        ];
      case CampaignMode.elimination:
        return <Widget>[
          _StatChip(
            icon: Icons.close_rounded,
            label: 'الأخطاء',
            value: '${attempt.wrongAnswers}/$_effectiveMaxWrongAnswers',
            color: const Color(0xFFFF6B7C),
          ),
          _StatChip(
            icon: Icons.quiz_rounded,
            label: 'المجاب',
            value: '${attempt.correctAnswers + attempt.wrongAnswers}',
            color: const Color(0xFF54F088),
          ),
        ];
      case CampaignMode.survival:
        return <Widget>[
          _StatChip(
            icon: Icons.favorite_rounded,
            label: 'الأرواح',
            value: '${attempt.livesRemaining}/$_effectiveLives',
            color: const Color(0xFFFF6B7C),
          ),
        ];
      case CampaignMode.battle:
        return _scoreChips(
          opponentName: attempt.opponentName ?? 'الخصم',
          opponentScore: attempt.opponentScore,
        );
      case CampaignMode.rival:
        return <Widget>[
          _StatChip(
            icon: Icons.person_rounded,
            label: 'نقاطك',
            value: '${attempt.playerScore}',
            color: const Color(0xFF54F088),
          ),
          _StatChip(
            icon: Icons.flag_rounded,
            label: 'الهدف',
            value: '$_effectiveTargetScore',
            color: const Color(0xFFFFD95A),
          ),
        ];
      case CampaignMode.bossBattle:
        return _scoreChips(
          opponentName: attempt.bossName ?? stage.bossBotName ?? 'الزعيم',
          opponentScore: attempt.bossScore,
        );
      case CampaignMode.series:
        return <Widget>[
          _StatChip(
            icon: Icons.emoji_events_rounded,
            label: 'جولاتك',
            value: '${attempt.playerSeriesWins}',
            color: const Color(0xFF54F088),
          ),
          _StatChip(
            icon: Icons.shield_rounded,
            label: 'الخصم',
            value: '${attempt.opponentSeriesWins}',
            color: const Color(0xFFFFD95A),
          ),
          _StatChip(
            icon: Icons.flag_rounded,
            label: 'المطلوب',
            value: '$_effectiveSeriesWinsRequired',
            color: const Color(0xFF7DD3FC),
          ),
        ];
      case CampaignMode.teamBattle:
        return <Widget>[
          _StatChip(
            icon: Icons.groups_rounded,
            label: 'فريقك',
            value: '${attempt.teamScore}',
            color: const Color(0xFF54F088),
          ),
          _StatChip(
            icon: Icons.shield_rounded,
            label: attempt.teamEnemyName ?? 'الخصم',
            value: '${attempt.enemyTeamScore}',
            color: const Color(0xFFFFD95A),
          ),
          _StatChip(
            icon: Icons.person_add_rounded,
            label: attempt.teamAllyName ?? 'الحليف',
            value: '${attempt.allyScore}',
            color: const Color(0xFF7DD3FC),
          ),
        ];
      case CampaignMode.classic:
      case CampaignMode.noLifeline:
        return const <Widget>[];
    }
  }

  List<Widget> _scoreChips({
    required String opponentName,
    required int opponentScore,
  }) {
    return <Widget>[
      _StatChip(
        icon: Icons.person_rounded,
        label: 'نقاطك',
        value: '${attempt.playerScore}',
        color: const Color(0xFF54F088),
      ),
      _StatChip(
        icon: Icons.shield_rounded,
        label: opponentName,
        value: '$opponentScore',
        color: const Color(0xFFFFD95A),
      ),
    ];
  }

  int get _effectiveLives {
    if (attempt.lives > 0) return attempt.lives;
    return stage.lives ?? 3;
  }

  int get _effectiveMaxWrongAnswers {
    if (attempt.maxWrongAnswers > 0) return attempt.maxWrongAnswers;
    return stage.maxWrongAnswers ?? 1;
  }

  int get _effectiveTargetScore {
    if (attempt.targetScore > 0) return attempt.targetScore;
    return stage.targetScore ?? 700;
  }

  int get _effectiveSeriesWinsRequired {
    if (attempt.seriesWinsRequired > 0) return attempt.seriesWinsRequired;
    return stage.seriesWinsRequired ?? 2;
  }
}

class _BossBattleResultPanel extends StatelessWidget {
  const _BossBattleResultPanel({
    required this.bossName,
    required this.playerCorrectAnswers,
    required this.bossCorrectAnswers,
    required this.playerScore,
    required this.bossScore,
  });

  final String? bossName;
  final int playerCorrectAnswers;
  final int bossCorrectAnswers;
  final int playerScore;
  final int bossScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF061642).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: const Color(0xFFFFD95A).withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BossScoreSide(
              name: 'أنت',
              correctAnswers: playerCorrectAnswers,
              score: playerScore,
              color: const Color(0xFF54F088),
            ),
          ),
          Container(
            width: 1,
            height: 46,
            color: Colors.white.withValues(alpha: 0.16),
          ),
          Expanded(
            child: _BossScoreSide(
              name: bossName?.trim().isNotEmpty == true
                  ? bossName!.trim()
                  : 'الزعيم',
              correctAnswers: bossCorrectAnswers,
              score: bossScore,
              color: const Color(0xFFFFD95A),
            ),
          ),
        ],
      ),
    );
  }
}

class _BossScoreSide extends StatelessWidget {
  const _BossScoreSide({
    required this.name,
    required this.correctAnswers,
    required this.score,
    required this.color,
  });

  final String name;
  final int correctAnswers;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$correctAnswers صحيح | $score نقطة',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _WarningPill extends StatelessWidget {
  const _WarningPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB84A).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFD36A)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFFD36A), size: 18),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'تعذر حفظ المرحلة، لكن هذه نتيجتك الحالية.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.timeMs,
    required this.usedLifelines,
  });

  final int correctAnswers;
  final int wrongAnswers;
  final int timeMs;
  final int usedLifelines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF061642).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.98,
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
        children: [
          _StatChip(
            icon: Icons.check_rounded,
            label: 'صحيحة',
            value: '$correctAnswers',
            color: const Color(0xFF40F783),
          ),
          _StatChip(
            icon: Icons.close_rounded,
            label: 'خاطئة',
            value: '$wrongAnswers',
            color: const Color(0xFFFF6B7C),
          ),
          _StatChip(
            icon: Icons.timer_rounded,
            label: 'الوقت',
            value: _formatTime(timeMs),
            color: const Color(0xFF7DD3FC),
          ),
          _StatChip(
            icon: Icons.auto_awesome_rounded,
            label: 'مساعدات',
            value: '$usedLifelines',
            color: const Color(0xFFFFC857),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _RetrySaveButton extends StatelessWidget {
  const _RetrySaveButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.cloud_upload_rounded, size: 18),
      label: const Text('إعادة محاولة الحفظ'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFFFC857),
        foregroundColor: const Color(0xFF311300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _BlockingLoadingOverlay extends StatelessWidget {
  const _BlockingLoadingOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF020B2A).withValues(alpha: 0.82),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF061642).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFFD95A)),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatTime(int timeMs) {
  final seconds = (timeMs / 1000).round().clamp(0, 24 * 60 * 60);
  final minutesPart = (seconds ~/ 60).toString().padLeft(2, '0');
  final secondsPart = (seconds % 60).toString().padLeft(2, '0');
  return '$minutesPart:$secondsPart';
}

CampaignMode _modeForAttempt(StageAttempt attempt, CampaignStage stage) {
  return campaignModeFromString(
    attempt.campaignMode.isNotEmpty ? attempt.campaignMode : null,
    fallbackType: stage.type,
  );
}

String _resultTitle({
  required CampaignMode mode,
  required bool completed,
  required String failureReason,
  required bool bossDefeated,
}) {
  switch (mode) {
    case CampaignMode.classic:
    case CampaignMode.noLifeline:
      return completed ? 'تم إنهاء المرحلة' : 'لم تكتمل المرحلة';
    case CampaignMode.blitz:
      if (!completed && failureReason == 'timeExpired') return 'انتهى الوقت';
      return completed ? 'تم إنهاء المرحلة' : 'لم تكتمل المرحلة';
    case CampaignMode.elimination:
      return completed ? 'تم إنهاء المرحلة' : 'تم إقصاؤك';
    case CampaignMode.survival:
      return completed ? 'تم إنهاء المرحلة' : 'انتهت الأرواح';
    case CampaignMode.battle:
      return completed ? 'فزت بالمواجهة' : 'خسرت المواجهة';
    case CampaignMode.rival:
      return completed ? 'تجاوزت الهدف' : 'لم تصل إلى الهدف';
    case CampaignMode.bossBattle:
      return bossDefeated ? 'هزمت الزعيم' : 'خسرت أمام الزعيم';
    case CampaignMode.series:
      return completed ? 'فزت بالسلسلة' : 'خسرت السلسلة';
    case CampaignMode.teamBattle:
      return completed ? 'فاز فريقك' : 'خسر فريقك';
  }
}
