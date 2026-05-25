import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign_stage.dart';
import '../../models/stage_progress.dart';
import '../../services/campaign_mode_engine.dart';
import '../../services/campaign_question_selector.dart';
import '../../services/campaign_result_handler.dart';
import '../../services/native_bridge_service.dart';
import 'stage_leaderboard_screen.dart';
import 'widgets/level_complete_background.dart';
import 'widgets/lifeline_rules_row.dart';
import 'widgets/stage_reward_chip.dart';
import 'widgets/star_rating_view.dart';

class StageIntroScreen extends StatefulWidget {
  const StageIntroScreen({
    super.key,
    required this.stage,
    required this.progress,
  });

  final CampaignStage stage;
  final StageProgress progress;

  @override
  State<StageIntroScreen> createState() => _StageIntroScreenState();
}

class _StageIntroScreenState extends State<StageIntroScreen>
    with WidgetsBindingObserver {
  static const Duration _pendingResultRetryDelay = Duration(milliseconds: 350);
  static const Duration _missingResultTimeout = Duration(seconds: 8);

  final CampaignQuestionSelector _questionSelector = CampaignQuestionSelector();
  final CampaignModeEngine _modeEngine = const CampaignModeEngine();
  bool _launching = false;
  bool _waitingForResult = false;
  bool _returnedFromNative = false;
  bool _pendingResultRetryScheduled = false;
  DateTime? _missingResultSince;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingCampaignResult();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_launching) {
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
    if (handled && _launching) {
      _resetPendingResultWait();
      setState(() {
        _launching = false;
        _waitingForResult = false;
      });
      return;
    }
    if (!handled && _launching) {
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
      if (!mounted || !_launching) return;
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
      _launching = false;
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

  Future<void> _launchStage() async {
    if (_launching) return;
    _resetPendingResultWait();
    setState(() {
      _launching = true;
      _waitingForResult = false;
    });

    final nativeBridge = context.read<NativeBridgeService>();
    final messenger = ScaffoldMessenger.of(context);
    final stage = widget.stage;

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
          'Launch campaign stage=${stage.id} order=${stage.order} '
          'allowed=${stage.allowedLevels} questionIds=$questionIds '
          'levels=$levelSummary nativeAllowed=$effectiveAllowedLevels',
        );
      }
      if (questionIds.length < stage.questionCount) {
        throw StateError('Not enough campaign questions selected');
      }
      final launchConfig = _modeEngine.buildLaunchConfig(stage);
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
          _launching = false;
          _waitingForResult = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage;
    final progress = widget.progress;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: LevelCompleteBackground()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final contentWidth = constraints.maxWidth - 28;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                    child: Column(
                      children: [
                        _TopBar(
                          onBack: () => Navigator.of(context).maybePop(),
                          onLeaderboard: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => StageLeaderboardScreen(
                                stage: stage,
                              ),
                            ),
                          ),
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
                                    StageIntroHeader(
                                      stage: stage,
                                      progress: progress,
                                    ),
                                    const SizedBox(height: 12),
                                    StageRequirementsPanel(stage: stage),
                                    const SizedBox(height: 10),
                                    StageRewardsPanel(stage: stage),
                                    const SizedBox(height: 10),
                                    _RulesPanel(stage: stage),
                                    const SizedBox(height: 10),
                                    _BestProgressPanel(progress: progress),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        StageStartButton(
                          launching: _launching,
                          onStart: _launchStage,
                          onMap: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_launching)
              const Positioned.fill(
                child: _BlockingLoadingOverlay(
                  message: 'جاري تجهيز المرحلة...',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.onLeaderboard,
  });

  final VoidCallback onBack;
  final VoidCallback onLeaderboard;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleHudButton(
          icon: Icons.arrow_forward_rounded,
          onPressed: onBack,
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Text(
            'تفاصيل المرحلة',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Color(0x99000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onLeaderboard,
          icon: const Icon(Icons.leaderboard_rounded, size: 18),
          label: const Text('عرض الترتيب'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFBDEBFF),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class StageIntroHeader extends StatelessWidget {
  const StageIntroHeader({
    super.key,
    required this.stage,
    required this.progress,
  });

  final CampaignStage stage;
  final StageProgress progress;

  @override
  Widget build(BuildContext context) {
    const modeEngine = CampaignModeEngine();
    final boss = stage.campaignMode == CampaignMode.bossBattle ||
        stage.type == CampaignStageType.boss;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: boss
              ? const [Color(0xFFFF4E5F), Color(0xFFC51531), Color(0xFF67163D)]
              : const [Color(0xFFFF626F), Color(0xFFE12039), Color(0xFF8D1230)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.26),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          _StageNumberBadge(order: stage.order, boss: boss),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stage.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Color(0x99000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MiniPill(
                      icon: Icons.sports_esports_rounded,
                      label: modeEngine.modeLabelArabic(stage.campaignMode),
                      color: const Color(0xFFFFF0A7),
                    ),
                    if (boss)
                      _MiniPill(
                        icon: Icons.shield_rounded,
                        label: stage.bossBotName?.trim().isNotEmpty == true
                            ? stage.bossBotName!
                            : 'زعيم المرحلة',
                        color: const Color(0xFFFFD66B),
                      ),
                    if (boss)
                      _MiniPill(
                        icon: Icons.local_fire_department_rounded,
                        label: _bossDifficultyLabel(stage.order),
                        color: const Color(0xFFFFF0A7),
                      ),
                    StarRatingView(stars: progress.stars, size: 19),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StageNumberBadge extends StatelessWidget {
  const _StageNumberBadge({
    required this.order,
    required this.boss,
  });

  final int order;
  final bool boss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: boss ? 76 : 68,
      height: boss ? 76 : 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: boss
              ? const [Color(0xFFFFF5C4), Color(0xFFFFC43F), Color(0xFFFF7C1E)]
              : const [Color(0xFFFFFFFF), Color(0xFFFFE56E), Color(0xFFFF9E2C)],
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFDA64).withValues(alpha: 0.38),
            blurRadius: 20,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (boss)
            const Positioned(
              top: 5,
              child: Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFF8A2F00),
                size: 18,
              ),
            ),
          Text(
            '$order',
            style: TextStyle(
              color: const Color(0xFF5B2100),
              fontSize: boss ? 27 : 25,
              fontWeight: FontWeight.w900,
              height: boss ? 1.25 : 1,
            ),
          ),
        ],
      ),
    );
  }
}

class StageRequirementsPanel extends StatelessWidget {
  const StageRequirementsPanel({
    super.key,
    required this.stage,
  });

  final CampaignStage stage;

  @override
  Widget build(BuildContext context) {
    final rules = stage.starRules;
    final specialRule = _specialRuleText(stage);
    return _GlassPanel(
      title: 'شروط النجوم',
      icon: Icons.star_rounded,
      color: const Color(0xFFFFD95A),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StarRequirement(
                  stars: 1,
                  text:
                      '${_requiredCorrect(rules.oneStarMinCorrectAnswers, 5)} صحيحة',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _StarRequirement(
                  stars: 2,
                  text:
                      '${_requiredCorrect(rules.twoStarsMinCorrectAnswers, 7)} صحيحة',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _StarRequirement(
                  stars: 3,
                  text:
                      '${_requiredCorrect(rules.threeStarsMinCorrectAnswers, 9)} صحيحة',
                ),
              ),
            ],
          ),
          if (specialRule != null) ...[
            const SizedBox(height: 8),
            _SpecialRulePill(text: specialRule),
          ],
        ],
      ),
    );
  }

  String? _specialRuleText(CampaignStage stage) {
    final rules = stage.starRules;
    if (stage.type == CampaignStageType.noLifeline ||
        rules.threeStarsMaxLifelinesUsed == 0) {
      return 'لـ 3 نجوم: بدون مساعدات';
    }
    if (rules.threeStarsMaxTimeMs != null) {
      return 'لـ 3 نجوم: قبل ${_formatTime(rules.threeStarsMaxTimeMs!)}';
    }
    return null;
  }

  int _requiredCorrect(int value, int fallback) {
    return value > 0 ? value : fallback;
  }
}

class _StarRequirement extends StatelessWidget {
  const _StarRequirement({
    required this.stars,
    required this.text,
  });

  final int stars;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD95A).withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFFD95A).withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StarRatingView(stars: stars, size: 17),
          const SizedBox(height: 5),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'من 10',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialRulePill extends StatelessWidget {
  const _SpecialRulePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF7DD3FC).withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: const Color(0xFF7DD3FC).withValues(alpha: 0.28)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class StageRewardsPanel extends StatelessWidget {
  const StageRewardsPanel({
    super.key,
    required this.stage,
  });

  final CampaignStage stage;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      title: 'مكافأة المرحلة',
      icon: Icons.card_giftcard_rounded,
      color: const Color(0xFFFFD95A),
      compact: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 7,
        children: [
          StageRewardChip(
            icon: Icons.monetization_on_rounded,
            label: '${stage.rewardCoins} عملة',
            color: const Color(0xFFFFD95A),
          ),
          StageRewardChip(
            icon: Icons.diamond_rounded,
            label: '${stage.rewardGems} جوهرة',
            color: const Color(0xFF6FE7FF),
          ),
          StageRewardChip(
            icon: Icons.bolt_rounded,
            label: '${stage.rewardXp} خبرة',
            color: const Color(0xFF54F088),
          ),
        ],
      ),
    );
  }
}

class _RulesPanel extends StatelessWidget {
  const _RulesPanel({required this.stage});

  final CampaignStage stage;

  @override
  Widget build(BuildContext context) {
    const modeEngine = CampaignModeEngine();
    final objective = modeEngine.objectiveText(stage);
    return _GlassPanel(
      title: 'المساعدات',
      icon: Icons.auto_awesome_rounded,
      color: const Color(0xFF7DD3FC),
      compact: true,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  icon: Icons.quiz_rounded,
                  label: objective,
                  color: const Color(0xFF54F088),
                ),
              ),
              if (stage.timeLimitSeconds > 0) ...[
                const SizedBox(width: 7),
                Expanded(
                  child: _InfoChip(
                    icon: Icons.timer_rounded,
                    label: _formatSeconds(stage.timeLimitSeconds),
                    color: const Color(0xFFFFD95A),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (stage.type == CampaignStageType.boss) ...[
            const _InfoChip(
              icon: Icons.shield_rounded,
              label: 'اهزم الزعيم لفتح الطريق التالي',
              color: Color(0xFFFFD95A),
            ),
            const SizedBox(height: 8),
          ],
          LifelineRulesRow(
            allow5050: stage.allow5050,
            allowAudience: stage.allowAudience,
            allowCall: stage.allowCall,
          ),
        ],
      ),
    );
  }
}

class _BestProgressPanel extends StatelessWidget {
  const _BestProgressPanel({required this.progress});

  final StageProgress progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF061642).withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ProgressMetric(
              icon: Icons.star_rounded,
              label: 'أفضل نجوم',
              value: '${progress.stars}/3',
              color: const Color(0xFFFFD95A),
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          Expanded(
            child: _ProgressMetric(
              icon: Icons.leaderboard_rounded,
              label: 'أفضل نتيجة',
              value: '${progress.bestScore}',
              color: const Color(0xFF7DD3FC),
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          Expanded(
            child: _ProgressMetric(
              icon: Icons.replay_rounded,
              label: 'المحاولات',
              value: '${progress.attempts}',
              color: const Color(0xFF54F088),
            ),
          ),
        ],
      ),
    );
  }
}

class StageStartButton extends StatelessWidget {
  const StageStartButton({
    super.key,
    required this.launching,
    required this.onStart,
    required this.onMap,
  });

  final bool launching;
  final VoidCallback onStart;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 58,
            child: FilledButton.icon(
              onPressed: launching ? null : onStart,
              icon: launching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 30),
              label: Text(launching ? 'جارٍ البدء...' : 'ابدأ المرحلة'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFB22E),
                disabledBackgroundColor: const Color(0xFF826646),
                foregroundColor: const Color(0xFF321600),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
                elevation: 10,
                shadowColor: const Color(0xFFFFB22E).withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 58,
          child: OutlinedButton.icon(
            onPressed: launching ? null : onMap,
            icon: const Icon(Icons.map_rounded),
            label: const Text('الخريطة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.36)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
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
        color: const Color(0xFF020B2A).withValues(alpha: 0.86),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF061642).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
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
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'سيتم عرض نتيجة المرحلة خلال لحظات.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(11, compact ? 9 : 11, 11, compact ? 9 : 11),
      decoration: BoxDecoration(
        color: const Color(0xFF061642).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
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

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleHudButton extends StatelessWidget {
  const _CircleHudButton({
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

String _bossDifficultyLabel(int order) {
  if (order >= 30) return 'أسطوري';
  if (order >= 20) return 'صعب';
  return 'متوسط';
}

String stageTypeLabel(CampaignStageType type) {
  switch (type) {
    case CampaignStageType.classic:
      return 'كلاسيكي';
    case CampaignStageType.speed:
      return 'تحدي السرعة';
    case CampaignStageType.survival:
      return 'البقاء';
    case CampaignStageType.noLifeline:
      return 'بدون مساعدات';
    case CampaignStageType.boss:
      return 'الزعيم';
    case CampaignStageType.rival:
      return 'منافسة';
  }
}

String _formatTime(int milliseconds) {
  final totalSeconds = (milliseconds / 1000).ceil();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String _formatSeconds(int seconds) {
  if (seconds <= 0) return 'وقت مفتوح';
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  if (minutes <= 0) return '$seconds ثانية';
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}
