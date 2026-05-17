import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/campaign_stage.dart';
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
  final CampaignQuestionSelector _questionSelector = CampaignQuestionSelector();
  bool _launchingStage = false;
  bool _waitingForResult = false;

  CampaignStage get stage => widget.stage;
  StageSubmissionResult get submissionResult => widget.submissionResult;
  Map<String, dynamic>? get rawNativeResult => widget.rawNativeResult;
  bool get currencyRewardApplied => widget.currencyRewardApplied;
  bool get _isBossStage => stage.type == CampaignStageType.boss;

  bool get _isUnsavedPreview {
    return submissionResult.attempt.uid.isEmpty && rawNativeResult != null;
  }

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
      if (_launchingStage && !_waitingForResult && mounted) {
        setState(() => _waitingForResult = true);
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
      setState(() {
        _launchingStage = false;
        _waitingForResult = false;
      });
      return;
    }
    if (!handled && _launchingStage) {
      _retryPendingResultSoon();
    }
  }

  void _retryPendingResultSoon() {
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || !_launchingStage) return;
      _consumePendingCampaignResult();
    });
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
                                      bossDefeated: bossDefeated,
                                      message: _cleanMessage(
                                        submissionResult.motivationalMessage,
                                        completed: completed,
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
    bool bossStage = false,
    bool bossDefeated = false,
  }) {
    if (bossStage) {
      return bossDefeated
          ? 'مواجهة رائعة، لقد فتحت الطريق التالي.'
          : 'لم تهزم الزعيم بعد. حاول مرة أخرى.';
    }
    final trimmed = message.trim();
    if (trimmed.isNotEmpty && !trimmed.contains('\u00D8')) return trimmed;
    return completed
        ? 'الأخطاء لا تنهي المرحلة، لكنها تقلل عدد النجوم.'
        : 'حاول مرة أخرى واجمع المزيد من النجوم.';
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
      await nativeBridge.launchCampaignStage(
        campaignId: stage.campaignId,
        stageId: stage.id,
        stageType: stage.type.value,
        questionIds: questionIds,
        allowedLevels: effectiveAllowedLevels,
        questionCount: stage.questionCount,
        timeLimitSeconds: stage.timeLimitSeconds,
        allow5050: stage.allow5050,
        allowAudience: stage.allowAudience,
        allowCall: stage.allowCall,
        bossBotName: stage.bossBotName ?? '',
        bossBotIntelligence: stage.bossBotIntelligence ?? 0,
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
    required this.bossDefeated,
    required this.message,
  });

  final bool completed;
  final CampaignStage stage;
  final bool bossDefeated;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isBoss = stage.type == CampaignStageType.boss;
    return Column(
      children: [
        Text(
          isBoss
              ? (bossDefeated ? 'هزمت الزعيم!' : 'خسرت المواجهة')
              : (completed ? 'تم إنهاء المرحلة!' : 'انتهت المرحلة'),
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
