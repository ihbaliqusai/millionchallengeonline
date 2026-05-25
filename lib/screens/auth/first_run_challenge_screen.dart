import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign_stage.dart';
import '../../services/campaign_defaults.dart';
import '../../services/campaign_mode_engine.dart';
import '../../services/campaign_question_selector.dart';
import '../../services/campaign_result_handler.dart';
import '../../services/native_bridge_service.dart';

class FirstRunChallengeScreen extends StatefulWidget {
  const FirstRunChallengeScreen({super.key});

  @override
  State<FirstRunChallengeScreen> createState() =>
      _FirstRunChallengeScreenState();
}

class _FirstRunChallengeScreenState extends State<FirstRunChallengeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final CampaignQuestionSelector _questionSelector = CampaignQuestionSelector();
  final CampaignModeEngine _modeEngine = const CampaignModeEngine();
  late final AnimationController _pulseCtrl;
  bool _launching = false;
  bool _waitingForResult = false;
  String? _error;

  CampaignStage get _firstStage => CampaignDefaults.stages().first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _launchStage());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_launching && !_waitingForResult && mounted) {
        setState(() => _waitingForResult = true);
      }
      _consumePendingResult();
    }
  }

  Future<void> _consumePendingResult() async {
    if (!mounted) return;
    final handled =
        await CampaignResultHandler.consumeAndHandlePendingCampaignResult(
      context: context,
    );
    if (!mounted) return;
    if (handled) {
      setState(() {
        _launching = false;
        _waitingForResult = false;
      });
      return;
    }
    if (_launching) {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted && _launching) _consumePendingResult();
      });
    }
  }

  Future<void> _launchStage() async {
    if (_launching) return;
    setState(() {
      _launching = true;
      _waitingForResult = false;
      _error = null;
    });

    final stage = _firstStage;
    final nativeBridge = context.read<NativeBridgeService>();

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
          'First run campaign stage=${stage.id} questionIds=$questionIds '
          'levels=$levelSummary nativeAllowed=$effectiveAllowedLevels',
        );
      }

      if (questionIds.length < stage.questionCount) {
        throw StateError('Not enough first-run questions selected');
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
      if (!mounted) return;
      setState(() {
        _launching = false;
        _waitingForResult = false;
        _error = 'تعذر تجهيز التحدي السريع. حاول مرة أخرى.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/ui/bg_login.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF08112F).withValues(alpha: 0.78),
                        const Color(0xFF020617).withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, child) => Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFACC15)
                                  .withValues(alpha: 0.12),
                              border: Border.all(
                                color: const Color(0xFFFACC15).withValues(
                                  alpha: 0.35 + _pulseCtrl.value * 0.4,
                                ),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(
                                    alpha: 0.28 + _pulseCtrl.value * 0.22,
                                  ),
                                  blurRadius: 28,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: child,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Color(0xFFFACC15),
                            size: 56,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'تحدي البداية',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _waitingForResult
                              ? 'ارجع إلى اللعبة بعد إنهاء الأسئلة لعرض الصندوق والنجوم.'
                              : 'سنبدأ أول مرحلة مباشرة. العب الآن، واحفظ تقدمك بعد أن تشعر بالحماس.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.74),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (_launching)
                          const CircularProgressIndicator(
                            color: Color(0xFFFACC15),
                          )
                        else
                          _StartAgainButton(onPressed: _launchStage),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFCA5A5),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Text(
                            'العودة لتسجيل الدخول',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartAgainButton extends StatelessWidget {
  const _StartAgainButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('ابدأ التحدي'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFACC15),
          foregroundColor: const Color(0xFF1F2937),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
