import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../models/campaign_stage.dart';
import '../models/stage_attempt.dart';
import '../models/stage_progress.dart';
import '../screens/campaign/stage_result_screen.dart';
import 'campaign_service.dart';
import 'native_bridge_service.dart';

class CampaignResultHandler {
  CampaignResultHandler._();

  static bool _processing = false;

  static Future<bool> consumeAndHandlePendingCampaignResult({
    required BuildContext context,
  }) async {
    if (_processing) return false;
    _processing = true;
    try {
      final nativeBridge = context.read<NativeBridgeService>();
      final campaignService = CampaignService();
      final appState = context.read<AppState>();
      await _retryPendingRewardClaims(
        appState: appState,
        campaignService: campaignService,
      );

      final payload = await nativeBridge.consumePendingCampaignStageResult();
      if (payload == null) return false;
      if (payload['mode'] != null && payload['mode'].toString() != 'campaign') {
        return false;
      }
      if (!_hasCompleteCampaignResult(payload)) {
        if (context.mounted) {
          _showSnack(context, 'نتيجة المرحلة غير مكتملة. حاول مرة أخرى.');
        }
        return true;
      }

      final campaignId =
          (payload['campaignId'] ?? 'main_campaign').toString().trim();
      final stageId = (payload['stageId'] ?? '').toString().trim();
      if (campaignId.isEmpty || stageId.isEmpty) {
        if (context.mounted) {
          _showSnack(context, 'تعذر العثور على بيانات المرحلة.');
        }
        return true;
      }

      final stages = await campaignService.loadStages(campaignId: campaignId);
      final stage = _findStage(stages, stageId);
      if (stage == null) {
        if (context.mounted) {
          _showSnack(context, 'تعذر العثور على بيانات المرحلة.');
        }
        return true;
      }

      final user = appState.currentUser;
      final uid = user?.uid.trim() ?? '';
      if (user == null || uid.isEmpty) {
        if (!context.mounted) return true;
        _showSnack(context, _loggedOutSaveMessage);
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => StageResultScreen(
              stage: stage,
              submissionResult: _buildLocalPreview(
                campaignService: campaignService,
                stage: stage,
                payload: payload,
              ),
              rawNativeResult: payload,
            ),
          ),
        );
        return true;
      }

      late final StageSubmissionResult result;
      try {
        result = await campaignService.submitStageResult(
          uid: uid,
          stage: stage,
          nativeResult: payload,
          displayName:
              (user.displayName ?? user.email?.split('@').first ?? '').trim(),
          photoUrl: user.photoURL,
        );
      } catch (error, stackTrace) {
        _debugSaveFailure(
          error: error,
          stackTrace: stackTrace,
          campaignId: campaignId,
          stageId: stageId,
          uid: uid,
          payload: payload,
        );
        if (!context.mounted) return true;
        _showSnack(context, _saveFailureMessage(error));
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => StageResultScreen(
              stage: stage,
              submissionResult: _buildLocalPreview(
                campaignService: campaignService,
                stage: stage,
                payload: payload,
                saveFailed: true,
              ),
              rawNativeResult: payload,
            ),
          ),
        );
        return true;
      }

      var rewardApplied = false;
      if (result.rewardClaimId != null) {
        rewardApplied = await _applyRewardClaim(
          appState: appState,
          campaignService: campaignService,
          uid: uid,
          claimId: result.rewardClaimId!,
          fallbackCoins: result.rewardCoinsGranted,
          fallbackGems: result.rewardGemsGranted,
          fallbackXp: result.rewardXpGranted,
        );
      }

      if (!context.mounted) return true;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => StageResultScreen(
            stage: stage,
            submissionResult: result,
            rawNativeResult: payload,
            currencyRewardApplied: rewardApplied,
          ),
        ),
      );
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'CAMPAIGN_RESULT_HANDLER_FAILED type=${error.runtimeType} '
          'message=$error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      if (context.mounted) {
        _showSnack(
          context,
          'تعذر حفظ نتيجة المرحلة. تحقق من الاتصال وحاول مرة أخرى.',
        );
      }
      return true;
    } finally {
      _processing = false;
    }
  }

  static const String _loggedOutSaveMessage =
      'سجّل الدخول لحفظ تقدمك في رحلة المليون.';

  static String saveFailureMessage(Object error) => _saveFailureMessage(error);

  static String _saveFailureMessage(Object error) {
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
      return _loggedOutSaveMessage;
    }
    return 'تعذر حفظ النتيجة الآن. سيتم عرض نتيجتك الحالية فقط.';
  }

  static CampaignStage? _findStage(List<CampaignStage> stages, String stageId) {
    for (final stage in stages) {
      if (stage.id == stageId) return stage;
    }
    return null;
  }

  static bool _hasCompleteCampaignResult(Map<String, dynamic> payload) {
    final stageId = (payload['stageId'] ?? '').toString().trim();
    return stageId.isNotEmpty &&
        payload.containsKey('completed') &&
        payload.containsKey('correctAnswers') &&
        payload.containsKey('wrongAnswers') &&
        payload.containsKey('timeMs');
  }

  static void _debugSaveFailure({
    required Object error,
    required StackTrace stackTrace,
    required String campaignId,
    required String stageId,
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
      'campaignId=$campaignId\n'
      'stageId=$stageId\n'
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

  static Future<void> _retryPendingRewardClaims({
    required AppState appState,
    required CampaignService campaignService,
  }) async {
    final uid = appState.currentUser?.uid.trim();
    if (uid == null) return;
    final claims = await campaignService.loadPendingRewardClaims(uid: uid);
    for (final claim in claims) {
      await _applyRewardClaim(
        appState: appState,
        campaignService: campaignService,
        uid: uid,
        claimId: claim.claimId,
        claim: claim,
      );
    }
  }

  static Future<bool> _applyRewardClaim({
    required AppState appState,
    required CampaignService campaignService,
    required String uid,
    required String claimId,
    CampaignRewardClaim? claim,
    int fallbackCoins = 0,
    int fallbackGems = 0,
    int fallbackXp = 0,
  }) async {
    final loadedClaim = claim ??
        await campaignService.loadRewardClaim(uid: uid, claimId: claimId);
    final effectiveClaim = loadedClaim;
    if (effectiveClaim == null || effectiveClaim.isClaimed) {
      return effectiveClaim?.isClaimed ?? false;
    }

    var currencyClaimed = effectiveClaim.currencyClaimed;
    var xpClaimed = effectiveClaim.xpClaimed;
    final coins =
        effectiveClaim.coins > 0 ? effectiveClaim.coins : fallbackCoins;
    final gems = effectiveClaim.gems > 0 ? effectiveClaim.gems : fallbackGems;
    final xp = effectiveClaim.xp > 0 ? effectiveClaim.xp : fallbackXp;

    try {
      if (!currencyClaimed) {
        final granted = await appState.grantCampaignCurrency(
          coinsReward: coins,
          gemsReward: gems,
        );
        if (!granted) {
          await _markRewardFailedQuietly(
            campaignService: campaignService,
            uid: uid,
            claimId: claimId,
          );
          return false;
        }
        await campaignService.markRewardCurrencyClaimed(
          uid: uid,
          claimId: claimId,
        );
        currencyClaimed = true;
      }

      if (!xpClaimed) {
        final granted = await appState.grantCampaignXp(xpReward: xp);
        if (!granted) {
          await _markRewardFailedQuietly(
            campaignService: campaignService,
            uid: uid,
            claimId: claimId,
          );
          return false;
        }
        await campaignService.markRewardXpClaimed(
          uid: uid,
          claimId: claimId,
        );
        xpClaimed = true;
      }
      return currencyClaimed && xpClaimed;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'CAMPAIGN_REWARD_GRANT_FAILED type=${error.runtimeType} '
          'message=$error uid=$uid claimId=$claimId',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      await _markRewardFailedQuietly(
        campaignService: campaignService,
        uid: uid,
        claimId: claimId,
      );
      return false;
    }
  }

  static Future<void> _markRewardFailedQuietly({
    required CampaignService campaignService,
    required String uid,
    required String claimId,
  }) async {
    try {
      await campaignService.markRewardFailed(uid: uid, claimId: claimId);
    } catch (markError, markStackTrace) {
      if (kDebugMode) {
        debugPrint(
          'CAMPAIGN_REWARD_MARK_FAILED type=${markError.runtimeType} '
          'message=$markError uid=$uid claimId=$claimId',
        );
        debugPrintStack(stackTrace: markStackTrace);
      }
    }
  }

  static StageSubmissionResult _buildLocalPreview({
    required CampaignService campaignService,
    required CampaignStage stage,
    required Map<String, dynamic> payload,
    bool saveFailed = false,
  }) {
    final campaignMode = campaignModeFromString(
      payload['campaignMode'],
      fallbackType: stage.type,
    );
    final isBossStage = campaignMode == CampaignMode.bossBattle ||
        stage.type == CampaignStageType.boss ||
        (payload['stageType']?.toString() == 'boss');
    final bossDefeated = _readBool(payload['bossDefeated']) ||
        _readBool(payload['bossBattleWon']);
    final completed = campaignService.normalizeStageCompleted(
      stage: stage,
      nativeResult: payload,
      correctAnswers: _readInt(payload['correctAnswers']),
      wrongAnswers: _readInt(payload['wrongAnswers']),
    );
    final money = _readInt(payload['money']);
    final correctAnswers = _readInt(payload['correctAnswers']);
    final wrongAnswers = _readInt(payload['wrongAnswers']);
    final timeMs = _readInt(payload['timeMs']);
    final used5050 = _readInt(payload['used5050']);
    final usedAudience = _readInt(payload['usedAudience']);
    final usedCall = _readInt(payload['usedCall']);
    final usedLifelines = used5050 + usedAudience + usedCall;
    final calculatedScore = campaignService.calculateScore(
      money: money,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
      timeMs: timeMs,
      used5050: used5050,
      usedAudience: usedAudience,
      usedCall: usedCall,
    );
    final playerScore = _readInt(payload['playerScore']);
    final score = playerScore > 0 ? playerScore : calculatedScore;
    final lives = _readInt(payload['lives']);
    final livesRemaining = _readInt(payload['livesRemaining']);
    final maxWrongAnswers = _readInt(payload['maxWrongAnswers']);
    final targetScore = _readInt(payload['targetScore']);
    final opponentScore = _readInt(payload['opponentScore']);
    final bossScore = _readInt(payload['bossScore']);
    final playerSeriesWins = _readInt(payload['playerSeriesWins']);
    final opponentSeriesWins = _readInt(payload['opponentSeriesWins']);
    final seriesWinsRequired = _readInt(payload['seriesWinsRequired']);
    final teamScore = _readInt(payload['teamScore']);
    final enemyTeamScore = _readInt(payload['enemyTeamScore']);
    final stars = campaignService.calculateStars(
      stage: stage,
      completed: completed,
      score: score,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
      timeMs: timeMs,
      usedLifelines: usedLifelines,
      failureReason: payload['failureReason']?.toString() ?? '',
      answeredQuestions: correctAnswers + wrongAnswers,
      lives: lives,
      livesRemaining: livesRemaining,
      maxWrongAnswers: maxWrongAnswers,
      targetScore: targetScore,
      playerScore: score,
      opponentScore: opponentScore,
      bossScore: bossScore,
      bossDefeated: bossDefeated,
      playerSeriesWins: playerSeriesWins,
      opponentSeriesWins: opponentSeriesWins,
      seriesWinsRequired: seriesWinsRequired,
      teamScore: teamScore,
      enemyTeamScore: enemyTeamScore,
    );
    final now = DateTime.now();
    final attempt = StageAttempt(
      attemptId: 'local_preview_${now.millisecondsSinceEpoch}',
      uid: '',
      campaignId: stage.campaignId,
      stageId: stage.id,
      stageType: stage.type.value,
      campaignMode: campaignMode.value,
      winCondition:
          payload['winCondition']?.toString() ?? stage.winCondition.value,
      failureReason: payload['failureReason']?.toString() ?? '',
      score: score,
      money: money,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
      timeMs: timeMs,
      used5050: used5050,
      usedAudience: usedAudience,
      usedCall: usedCall,
      completed: completed,
      stars: stars,
      lives: lives,
      livesRemaining: livesRemaining,
      maxWrongAnswers: maxWrongAnswers,
      targetScore: targetScore,
      opponentName: _cleanString(payload['opponentName']?.toString()),
      opponentScore: opponentScore,
      opponentCorrectAnswers: _readInt(payload['opponentCorrectAnswers']),
      opponentWrongAnswers: _readInt(payload['opponentWrongAnswers']),
      bossDefeated: isBossStage && bossDefeated,
      bossName: _cleanString(payload['bossName']?.toString()),
      bossCorrectAnswers: _readInt(payload['bossCorrectAnswers']),
      bossWrongAnswers: _readInt(payload['bossWrongAnswers']),
      bossScore: bossScore,
      playerScore: score,
      seriesRounds: _readInt(payload['seriesRounds']),
      seriesWinsRequired: seriesWinsRequired,
      playerSeriesWins: playerSeriesWins,
      opponentSeriesWins: opponentSeriesWins,
      teamAllyName: _cleanString(payload['teamAllyName']?.toString()),
      teamEnemyName: _cleanString(payload['teamEnemyName']?.toString()),
      allyScore: _readInt(payload['allyScore']),
      teamScore: teamScore,
      enemyTeamScore: enemyTeamScore,
      createdAt: now,
    );
    final progress = StageProgress(
      campaignId: stage.campaignId,
      stageId: stage.id,
      status: completed
          ? StageProgressStatus.completed
          : StageProgressStatus.unlocked,
      stars: stars,
      bestScore: score,
      bestMoney: money,
      bestCorrectAnswers: correctAnswers,
      bestTimeMs: timeMs,
      attempts: 1,
      firstCompletedAt: completed ? now : null,
      lastPlayedAt: now,
    );
    return StageSubmissionResult(
      attempt: attempt,
      updatedProgress: progress,
      previousStars: 0,
      newStars: stars,
      isFirstCompletion: completed,
      improvedBestScore: false,
      improvedStars: false,
      leaderboardUpdated: false,
      rewardGranted: false,
      rewardCoinsGranted: 0,
      rewardGemsGranted: 0,
      rewardXpGranted: 0,
      motivationalMessage: saveFailed
          ? 'تعذر حفظ النتيجة، لكن هذه نتيجتك الحالية.'
          : completed
              ? 'أحسنت! سجّل الدخول لحفظ هذا التقدم.'
              : 'كنت قريبًا جدًا، حاول مرة أخرى.',
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  static String? _cleanString(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
  }
}
