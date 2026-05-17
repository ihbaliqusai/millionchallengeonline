import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/campaign_stage.dart';
import '../models/stage_attempt.dart';
import '../models/stage_leaderboard_entry.dart';
import '../models/stage_progress.dart';
import 'campaign_defaults.dart';

class StageSubmissionResult {
  const StageSubmissionResult({
    required this.attempt,
    required this.updatedProgress,
    required this.previousStars,
    required this.newStars,
    required this.isFirstCompletion,
    required this.improvedBestScore,
    required this.improvedStars,
    required this.leaderboardUpdated,
    required this.rewardGranted,
    required this.rewardCoinsGranted,
    required this.rewardGemsGranted,
    required this.rewardXpGranted,
    required this.motivationalMessage,
    this.previousProgress,
    this.rewardClaimId,
    this.rewardClaimStatus,
    this.rewardGrantSucceeded = false,
  });

  final StageAttempt attempt;
  final StageProgress? previousProgress;
  final StageProgress updatedProgress;
  final int previousStars;
  final int newStars;
  final bool isFirstCompletion;
  final bool improvedBestScore;
  final bool improvedStars;
  final bool leaderboardUpdated;
  final bool rewardGranted;
  final int rewardCoinsGranted;
  final int rewardGemsGranted;
  final int rewardXpGranted;
  final String motivationalMessage;
  final String? rewardClaimId;
  final String? rewardClaimStatus;
  final bool rewardGrantSucceeded;

  StageSubmissionResult copyWith({
    bool? leaderboardUpdated,
    bool? rewardGranted,
    int? rewardCoinsGranted,
    int? rewardGemsGranted,
    int? rewardXpGranted,
    String? rewardClaimId,
    String? rewardClaimStatus,
    bool? rewardGrantSucceeded,
  }) {
    return StageSubmissionResult(
      attempt: attempt,
      previousProgress: previousProgress,
      updatedProgress: updatedProgress,
      previousStars: previousStars,
      newStars: newStars,
      isFirstCompletion: isFirstCompletion,
      improvedBestScore: improvedBestScore,
      improvedStars: improvedStars,
      leaderboardUpdated: leaderboardUpdated ?? this.leaderboardUpdated,
      rewardGranted: rewardGranted ?? this.rewardGranted,
      rewardCoinsGranted: rewardCoinsGranted ?? this.rewardCoinsGranted,
      rewardGemsGranted: rewardGemsGranted ?? this.rewardGemsGranted,
      rewardXpGranted: rewardXpGranted ?? this.rewardXpGranted,
      motivationalMessage: motivationalMessage,
      rewardClaimId: rewardClaimId ?? this.rewardClaimId,
      rewardClaimStatus: rewardClaimStatus ?? this.rewardClaimStatus,
      rewardGrantSucceeded: rewardGrantSucceeded ?? this.rewardGrantSucceeded,
    );
  }
}

class CampaignRewardClaim {
  const CampaignRewardClaim({
    required this.claimId,
    required this.uid,
    required this.campaignId,
    required this.stageId,
    required this.previousStars,
    required this.newStars,
    required this.coins,
    required this.gems,
    required this.xp,
    required this.status,
    required this.attemptId,
    required this.currencyClaimed,
    required this.xpClaimed,
    required this.retryCount,
  });

  final String claimId;
  final String uid;
  final String campaignId;
  final String stageId;
  final int previousStars;
  final int newStars;
  final int coins;
  final int gems;
  final int xp;
  final String status;
  final String attemptId;
  final bool currencyClaimed;
  final bool xpClaimed;
  final int retryCount;

  bool get isClaimed => status == CampaignRewardClaimStatus.claimed.value;
  bool get hasCurrencyReward => coins > 0 || gems > 0;
  bool get hasXpReward => xp > 0;

  factory CampaignRewardClaim.fromMap(
    Map<String, dynamic> map, {
    required String claimId,
  }) {
    return CampaignRewardClaim(
      claimId: claimId,
      uid: _readString(map['uid']),
      campaignId: _readString(map['campaignId']),
      stageId: _readString(map['stageId']),
      previousStars: _readInt(map['previousStars']),
      newStars: _readInt(map['newStars']),
      coins: _readInt(map['coins']),
      gems: _readInt(map['gems']),
      xp: _readInt(map['xp']),
      status: campaignRewardClaimStatusFromString(
        _readString(map['status']),
      ).value,
      attemptId: _readString(map['attemptId']),
      currencyClaimed: _readBool(map['currencyClaimed']),
      xpClaimed: _readBool(map['xpClaimed']),
      retryCount: _readInt(map['retryCount']),
    );
  }
}

enum CampaignRewardClaimStatus {
  pending,
  claimed,
  failed,
}

extension CampaignRewardClaimStatusX on CampaignRewardClaimStatus {
  String get value {
    switch (this) {
      case CampaignRewardClaimStatus.pending:
        return 'pending';
      case CampaignRewardClaimStatus.claimed:
        return 'claimed';
      case CampaignRewardClaimStatus.failed:
        return 'failed';
    }
  }
}

CampaignRewardClaimStatus campaignRewardClaimStatusFromString(String value) {
  switch (value.trim()) {
    case 'claimed':
      return CampaignRewardClaimStatus.claimed;
    case 'failed':
      return CampaignRewardClaimStatus.failed;
    case 'pending':
    default:
      return CampaignRewardClaimStatus.pending;
  }
}

class CampaignService {
  CampaignService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<CampaignStage>> loadStages({
    String campaignId = CampaignDefaults.mainCampaignId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('campaigns')
          .doc(campaignId)
          .collection('stages')
          .get();
      final stages = snapshot.docs.map((doc) {
        final data = doc.data();
        return _withDefaultAllowedLevels(
            CampaignStage.fromMap(<String, dynamic>{
          ...data,
          'id': _readString(data['id'], defaultValue: doc.id),
          'campaignId': _readString(
            data['campaignId'],
            defaultValue: campaignId,
          ),
        }));
      }).toList(growable: false)
        ..sort((left, right) => left.order.compareTo(right.order));
      if (stages.isNotEmpty) return stages;
    } catch (_) {
      // Offline or permission failures should not block the campaign map.
    }
    return CampaignDefaults.stages(campaignId: campaignId);
  }

  CampaignStage _withDefaultAllowedLevels(CampaignStage stage) {
    if (stage.allowedLevels.isNotEmpty) return stage;
    return stage.copyWith(
      allowedLevels: CampaignDefaults.allowedLevelsForOrder(stage.order),
    );
  }

  Future<Map<String, StageProgress>> loadUserProgress({
    required String uid,
    String campaignId = CampaignDefaults.mainCampaignId,
  }) async {
    if (uid.trim().isEmpty) return const <String, StageProgress>{};
    try {
      final snapshot = await _userProgress(uid).get();
      return <String, StageProgress>{
        for (final doc in snapshot.docs)
          doc.id: StageProgress.fromMap(<String, dynamic>{
            ...doc.data(),
            'campaignId': _readString(
              doc.data()['campaignId'],
              defaultValue: campaignId,
            ),
            'stageId': _readString(doc.data()['stageId'], defaultValue: doc.id),
          }),
      };
    } catch (_) {
      return const <String, StageProgress>{};
    }
  }

  List<StageProgress> resolveProgressForStages({
    required List<CampaignStage> stages,
    required Map<String, StageProgress> savedProgress,
  }) {
    final sortedStages = List<CampaignStage>.from(stages)
      ..sort((left, right) => left.order.compareTo(right.order));
    final resolved = <StageProgress>[];
    final completedStageIds = <String>{};
    var earnedStars = 0;

    for (var index = 0; index < sortedStages.length; index += 1) {
      final stage = sortedStages[index];
      final saved =
          savedProgress[stage.id] ?? savedProgress[_legacyStageId(stage.id)];
      final previousStageCompleted =
          index > 0 && completedStageIds.contains(sortedStages[index - 1].id);
      final previousStageIsBoss =
          index > 0 && sortedStages[index - 1].type == CampaignStageType.boss;
      final completed = saved != null && isStageCompleted(saved);
      final unlocked = previousStageIsBoss && !previousStageCompleted
          ? false
          : isStageUnlocked(
              stage: stage,
              isFirstStage: stage.order == 1 || index == 0,
              previousStageCompleted: previousStageCompleted,
              earnedStars: earnedStars,
            );
      final status = completed
          ? StageProgressStatus.completed
          : unlocked
              ? StageProgressStatus.unlocked
              : StageProgressStatus.locked;
      final progress = StageProgress(
        campaignId: saved?.campaignId.isNotEmpty == true
            ? saved!.campaignId
            : stage.campaignId,
        stageId: saved?.stageId.isNotEmpty == true ? saved!.stageId : stage.id,
        status: status,
        stars: saved?.stars ?? 0,
        bestScore: saved?.bestScore ?? 0,
        bestMoney: saved?.bestMoney ?? 0,
        bestCorrectAnswers: saved?.bestCorrectAnswers ?? 0,
        bestTimeMs: saved?.bestTimeMs ?? 0,
        attempts: saved?.attempts ?? 0,
        firstCompletedAt: saved?.firstCompletedAt,
        lastPlayedAt: saved?.lastPlayedAt,
      );
      resolved.add(progress);
      earnedStars += progress.stars;
      if (isStageCompleted(progress)) completedStageIds.add(stage.id);
    }

    return resolved;
  }

  String _legacyStageId(String stageId) {
    final match = RegExp(r'^stage_0(\d{2})$').firstMatch(stageId);
    if (match == null) return stageId;
    return 'stage_${match.group(1)}';
  }

  int calculateScore({
    required int money,
    required int correctAnswers,
    required int wrongAnswers,
    required int timeMs,
    required int used5050,
    required int usedAudience,
    required int usedCall,
  }) {
    final timeBonus = math.max(0, 300000 - timeMs) ~/ 1000;
    final streakBonus = correctAnswers >= 10
        ? 500
        : correctAnswers >= 5
            ? 200
            : 0;
    final lifelinePenalty = used5050 * 80 + usedAudience * 60 + usedCall * 60;
    final wrongAnswerPenalty = wrongAnswers * 120;
    final score = money +
        correctAnswers * 100 +
        timeBonus +
        streakBonus -
        lifelinePenalty -
        wrongAnswerPenalty;
    return math.max(0, score);
  }

  int calculateStars({
    required CampaignStage stage,
    required bool completed,
    required int score,
    required int correctAnswers,
    required int wrongAnswers,
    required int timeMs,
    required int usedLifelines,
  }) {
    final rules = stage.starRules;
    if (rules.completedRequired && !completed) return 0;

    if (stage.type == CampaignStageType.boss) {
      if (correctAnswers >= 9) return 3;
      if (correctAnswers >= 7) return 2;
      if (correctAnswers >= 5) return 1;
      return 0;
    }

    var stars = 0;
    if (correctAnswers >= rules.oneStarMinCorrectAnswers ||
        (rules.oneStarMinScore > 0 && score >= rules.oneStarMinScore)) {
      stars = 1;
    }
    if ((correctAnswers >= rules.twoStarsMinCorrectAnswers ||
            (rules.twoStarsMinScore > 0 && score >= rules.twoStarsMinScore)) &&
        _passesMax(timeMs, rules.twoStarsMaxTimeMs)) {
      stars = 2;
    }
    if ((correctAnswers >= rules.threeStarsMinCorrectAnswers ||
            (rules.threeStarsMinScore > 0 &&
                score >= rules.threeStarsMinScore)) &&
        _passesMax(timeMs, rules.threeStarsMaxTimeMs) &&
        _passesMax(wrongAnswers, rules.maxWrongAnswersForThreeStars) &&
        _passesMax(usedLifelines, rules.threeStarsMaxLifelinesUsed)) {
      stars = 3;
    }
    return stars.clamp(0, 3);
  }

  Future<StageSubmissionResult> submitStageResult({
    required String uid,
    required CampaignStage stage,
    required Map<String, dynamic> nativeResult,
    String displayName = '',
    String? photoUrl,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'uid must not be empty');
    }

    final campaignId = _readString(
      nativeResult['campaignId'],
      defaultValue: stage.campaignId,
    );
    final stageId =
        _readString(nativeResult['stageId'], defaultValue: stage.id);
    final stageType = _readString(
      nativeResult['stageType'],
      defaultValue: stage.type.value,
    );
    final isBossStage =
        stage.type == CampaignStageType.boss || stageType == 'boss';
    final bossDefeated = _readBool(nativeResult['bossDefeated'],
        defaultValue: _readBool(nativeResult['bossBattleWon']));
    final completed =
        isBossStage ? bossDefeated : _readBool(nativeResult['completed']);
    final money = _readInt(nativeResult['money']);
    final correctAnswers = _readInt(nativeResult['correctAnswers']);
    final wrongAnswers = _readInt(nativeResult['wrongAnswers']);
    final timeMs = _readInt(nativeResult['timeMs']);
    final used5050 = _readInt(nativeResult['used5050']);
    final usedAudience = _readInt(nativeResult['usedAudience']);
    final usedCall = _readInt(nativeResult['usedCall']);
    final usedLifelines = used5050 + usedAudience + usedCall;
    final playerScore = _readInt(nativeResult['playerScore']);
    final bossScore = _readInt(nativeResult['bossScore']);
    final bossCorrectAnswers = _readInt(nativeResult['bossCorrectAnswers']);
    final bossWrongAnswers = _readInt(nativeResult['bossWrongAnswers']);
    final score = isBossStage
        ? (playerScore > 0 ? playerScore : correctAnswers * 100)
        : calculateScore(
            money: money,
            correctAnswers: correctAnswers,
            wrongAnswers: wrongAnswers,
            timeMs: timeMs,
            used5050: used5050,
            usedAudience: usedAudience,
            usedCall: usedCall,
          );
    final stars = calculateStars(
      stage: stage,
      completed: completed,
      score: score,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
      timeMs: timeMs,
      usedLifelines: usedLifelines,
    );

    final attemptRef = _userAttempts(normalizedUid).doc();
    final progressRef = _userProgress(normalizedUid).doc(stageId);
    final attempt = StageAttempt(
      attemptId: attemptRef.id,
      uid: normalizedUid,
      campaignId: campaignId,
      stageId: stageId,
      stageType: stageType,
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
      bossDefeated: isBossStage && bossDefeated,
      bossName: _cleanString(_readString(nativeResult['bossName'])),
      bossCorrectAnswers: bossCorrectAnswers,
      bossWrongAnswers: bossWrongAnswers,
      bossScore: bossScore,
      playerScore: score,
      createdAt: DateTime.now(),
    );
    final leaderboardEntry = StageLeaderboardEntry(
      uid: normalizedUid,
      displayName: displayName.trim(),
      photoUrl: _cleanString(photoUrl),
      campaignId: campaignId,
      stageId: stageId,
      score: score,
      stars: stars,
      money: money,
      correctAnswers: correctAnswers,
      timeMs: timeMs,
      usedLifelines: usedLifelines,
      assisted: usedLifelines > 0,
      updatedAt: DateTime.now(),
    );

    final pendingReward = _PendingReward.empty();
    final result = await _firestore
        .runTransaction<StageSubmissionResult>((transaction) async {
      final progressSnapshot = await transaction.get(progressRef);
      final previousProgress = progressSnapshot.exists
          ? StageProgress.fromMap(<String, dynamic>{
              ...?progressSnapshot.data(),
              'campaignId': _readString(
                progressSnapshot.data()?['campaignId'],
                defaultValue: campaignId,
              ),
              'stageId': _readString(
                progressSnapshot.data()?['stageId'],
                defaultValue: stageId,
              ),
            })
          : null;
      final previousStars = previousProgress?.stars ?? 0;
      final previousCompleted =
          previousProgress != null && isStageCompleted(previousProgress);
      final completedNow =
          completed || (!isBossStage && stars > 0) || previousCompleted;
      final newStars = math.max(previousStars, stars);
      final improvedBestScore = score > (previousProgress?.bestScore ?? 0);
      final improvedStars = newStars > previousStars;
      final isFirstCompletion = !previousCompleted && completedNow;
      final updatedProgress = StageProgress(
        campaignId: campaignId,
        stageId: stageId,
        status: completedNow
            ? StageProgressStatus.completed
            : StageProgressStatus.unlocked,
        stars: newStars,
        bestScore: math.max(previousProgress?.bestScore ?? 0, score),
        bestMoney: math.max(previousProgress?.bestMoney ?? 0, money),
        bestCorrectAnswers: math.max(
          previousProgress?.bestCorrectAnswers ?? 0,
          correctAnswers,
        ),
        bestTimeMs: _bestTime(previousProgress?.bestTimeMs ?? 0, timeMs),
        attempts: (previousProgress?.attempts ?? 0) + 1,
        firstCompletedAt: previousProgress?.firstCompletedAt ??
            (completedNow ? DateTime.now() : null),
        lastPlayedAt: DateTime.now(),
      );

      final reward = _calculateReward(
        stage: stage,
        isFirstCompletion: isFirstCompletion,
        previousStars: previousStars,
        newStars: newStars,
      );
      final rewardClaimId = reward.granted
          ? _rewardClaimId(
              campaignId: campaignId,
              stageId: stageId,
              previousStars: previousStars,
              newStars: newStars,
              isFirstCompletion: isFirstCompletion,
            )
          : null;
      pendingReward
        ..claimId = rewardClaimId
        ..previousStars = previousStars
        ..newStars = newStars
        ..coins = reward.coins
        ..gems = reward.gems
        ..xp = reward.xp;

      transaction.set(attemptRef, <String, dynamic>{
        ...attempt.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(
          progressRef,
          <String, dynamic>{
            ...updatedProgress.toMap(),
            'firstCompletedAt': updatedProgress.firstCompletedAt == null
                ? null
                : Timestamp.fromDate(updatedProgress.firstCompletedAt!),
            'lastPlayedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      return StageSubmissionResult(
        attempt: attempt,
        previousProgress: previousProgress,
        updatedProgress: updatedProgress,
        previousStars: previousStars,
        newStars: newStars,
        isFirstCompletion: isFirstCompletion,
        improvedBestScore: improvedBestScore,
        improvedStars: improvedStars,
        leaderboardUpdated: false,
        rewardGranted: false,
        rewardCoinsGranted: 0,
        rewardGemsGranted: 0,
        rewardXpGranted: 0,
        motivationalMessage: _motivationalMessage(
          isFirstCompletion: isFirstCompletion,
          improvedStars: improvedStars,
          improvedBestScore: improvedBestScore,
          completed: completed,
          stars: stars,
        ),
      );
    });
    final leaderboardUpdated = isBossStage && !completed
        ? false
        : await _tryUpdateStageLeaderboard(
            campaignId: campaignId,
            stageId: stageId,
            uid: normalizedUid,
            entry: leaderboardEntry,
          );
    final rewardResult = await _tryCreateRewardClaim(
      uid: normalizedUid,
      campaignId: campaignId,
      stageId: stageId,
      attemptId: attemptRef.id,
      pendingReward: pendingReward,
    );
    return result.copyWith(
      leaderboardUpdated: leaderboardUpdated,
      rewardGranted: rewardResult.created,
      rewardCoinsGranted: rewardResult.created ? pendingReward.coins : 0,
      rewardGemsGranted: rewardResult.created ? pendingReward.gems : 0,
      rewardXpGranted: rewardResult.created ? pendingReward.xp : 0,
      rewardClaimId: rewardResult.created ? pendingReward.claimId : null,
      rewardClaimStatus: rewardResult.status,
    );
  }

  bool isStageCompleted(StageProgress progress) {
    return progress.status == StageProgressStatus.completed ||
        progress.stars > 0;
  }

  bool isStageUnlocked({
    required CampaignStage stage,
    required bool isFirstStage,
    required bool previousStageCompleted,
    required int earnedStars,
  }) {
    return isFirstStage ||
        previousStageCompleted ||
        earnedStars >= stage.unlockRequirementStars;
  }

  int totalStars(Iterable<StageProgress> progress) {
    return progress.fold<int>(0, (total, item) => total + item.stars);
  }

  int usedLifelinesFromResult(Map<String, dynamic> result) {
    return _readInt(result['used5050']) +
        _readInt(result['usedAudience']) +
        _readInt(result['usedCall']);
  }

  Future<List<StageLeaderboardEntry>> loadStageLeaderboard({
    required String campaignId,
    required String stageId,
    bool pureOnly = false,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('stageLeaderboards')
          .doc(leaderboardId(campaignId, stageId))
          .collection('scores');
      if (pureOnly) {
        query = query.where('assisted', isEqualTo: false);
      }
      final snapshot = await query
          .orderBy('score', descending: true)
          .orderBy('stars', descending: true)
          .orderBy('timeMs')
          .limit(limit.clamp(1, 100))
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return StageLeaderboardEntry.fromMap(<String, dynamic>{
          ...data,
          'uid': _readString(data['uid'], defaultValue: doc.id),
          'campaignId': _readString(
            data['campaignId'],
            defaultValue: campaignId,
          ),
          'stageId': _readString(data['stageId'], defaultValue: stageId),
        });
      }).toList(growable: false);
    } catch (_) {
      return const <StageLeaderboardEntry>[];
    }
  }

  Future<int?> getPlayerStageRank({
    required String campaignId,
    required String stageId,
    required String uid,
    bool pureOnly = false,
  }) async {
    // TODO: Compute exact rank server-side with Cloud Functions or a bounded
    // aggregate strategy. Avoid full client-side leaderboard scans here.
    return null;
  }

  String leaderboardId(String campaignId, String stageId) {
    return '${campaignId}_$stageId';
  }

  Future<CampaignRewardClaim?> loadRewardClaim({
    required String uid,
    required String claimId,
  }) async {
    try {
      final doc = await _userRewardClaims(uid.trim()).doc(claimId).get();
      if (!doc.exists) return null;
      return CampaignRewardClaim.fromMap(
        doc.data() ?? const <String, dynamic>{},
        claimId: doc.id,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<CampaignRewardClaim>> loadPendingRewardClaims({
    required String uid,
    int limit = 10,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return const <CampaignRewardClaim>[];
    try {
      final snapshot = await _userRewardClaims(normalizedUid)
          .where(
            'status',
            whereIn: <String>[
              CampaignRewardClaimStatus.pending.value,
              CampaignRewardClaimStatus.failed.value,
            ],
          )
          .limit(limit.clamp(1, 25))
          .get();
      return snapshot.docs
          .map(
            (doc) => CampaignRewardClaim.fromMap(
              doc.data(),
              claimId: doc.id,
            ),
          )
          .where((claim) => !claim.isClaimed)
          .toList(growable: false);
    } catch (_) {
      return const <CampaignRewardClaim>[];
    }
  }

  Future<void> markRewardCurrencyClaimed({
    required String uid,
    required String claimId,
  }) async {
    await _updateRewardClaimPart(
      uid: uid,
      claimId: claimId,
      currencyClaimed: true,
    );
  }

  Future<void> markRewardXpClaimed({
    required String uid,
    required String claimId,
  }) async {
    await _updateRewardClaimPart(
      uid: uid,
      claimId: claimId,
      xpClaimed: true,
    );
  }

  Future<void> markRewardFailed({
    required String uid,
    required String claimId,
  }) async {
    final ref = _userRewardClaims(uid.trim()).doc(claimId);
    await ref.set(
      <String, dynamic>{
        'status': CampaignRewardClaimStatus.failed.value,
        'retryCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<_RewardClaimCreateResult> _tryCreateRewardClaim({
    required String uid,
    required String campaignId,
    required String stageId,
    required String attemptId,
    required _PendingReward pendingReward,
  }) async {
    final claimId = pendingReward.claimId;
    if (claimId == null || !pendingReward.granted) {
      return const _RewardClaimCreateResult(
        created: false,
        status: null,
      );
    }
    final ref = _userRewardClaims(uid).doc(claimId);
    try {
      return await _firestore.runTransaction<_RewardClaimCreateResult>(
        (transaction) async {
          final snapshot = await transaction.get(ref);
          final status = snapshot.exists
              ? campaignRewardClaimStatusFromString(
                  _readString(snapshot.data()?['status']),
                )
              : null;
          if (status == CampaignRewardClaimStatus.claimed) {
            return _RewardClaimCreateResult(
              created: false,
              status: CampaignRewardClaimStatus.claimed.value,
            );
          }
          if (!snapshot.exists) {
            transaction.set(ref, <String, dynamic>{
              'uid': uid,
              'campaignId': campaignId,
              'stageId': stageId,
              'previousStars': pendingReward.previousStars,
              'newStars': pendingReward.newStars,
              'coins': pendingReward.coins,
              'gems': pendingReward.gems,
              'xp': pendingReward.xp,
              'status': CampaignRewardClaimStatus.pending.value,
              'attemptId': attemptId,
              'currencyClaimed':
                  pendingReward.coins <= 0 && pendingReward.gems <= 0,
              'xpClaimed': pendingReward.xp <= 0,
              'retryCount': 0,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'claimedAt': null,
            });
          } else if (status == CampaignRewardClaimStatus.failed) {
            transaction.update(ref, <String, dynamic>{
              'status': CampaignRewardClaimStatus.pending.value,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          return const _RewardClaimCreateResult(
            created: true,
            status: 'pending',
          );
        },
      );
    } catch (error, stackTrace) {
      _logCampaignFailure(
        marker: 'CAMPAIGN_REWARD_CLAIM_SAVE_FAILED',
        error: error,
        stackTrace: stackTrace,
        campaignId: campaignId,
        stageId: stageId,
        uid: uid,
      );
      return const _RewardClaimCreateResult(
        created: false,
        status: null,
      );
    }
  }

  Future<bool> _tryUpdateStageLeaderboard({
    required String campaignId,
    required String stageId,
    required String uid,
    required StageLeaderboardEntry entry,
  }) async {
    final ref = _firestore
        .collection('stageLeaderboards')
        .doc(leaderboardId(campaignId, stageId))
        .collection('scores')
        .doc(uid);
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(ref);
        final shouldUpdate = _shouldUpdateLeaderboard(
          currentData: snapshot.data(),
          candidate: entry,
        );
        if (shouldUpdate) {
          transaction.set(
            ref,
            <String, dynamic>{
              ...entry.toMap(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
        return shouldUpdate;
      });
    } catch (error, stackTrace) {
      _logCampaignFailure(
        marker: 'CAMPAIGN_LEADERBOARD_SAVE_FAILED',
        error: error,
        stackTrace: stackTrace,
        campaignId: campaignId,
        stageId: stageId,
        uid: uid,
      );
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>> _userProgress(String uid) {
    return _firestore.collection('users').doc(uid).collection(
          'campaignProgress',
        );
  }

  CollectionReference<Map<String, dynamic>> _userAttempts(String uid) {
    return _firestore.collection('users').doc(uid).collection(
          'campaignAttempts',
        );
  }

  CollectionReference<Map<String, dynamic>> _userRewardClaims(String uid) {
    return _firestore.collection('users').doc(uid).collection(
          'campaignRewardClaims',
        );
  }

  Future<void> _updateRewardClaimPart({
    required String uid,
    required String claimId,
    bool? currencyClaimed,
    bool? xpClaimed,
  }) async {
    final ref = _userRewardClaims(uid.trim()).doc(claimId);
    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? const <String, dynamic>{};
      final nextCurrencyClaimed =
          currencyClaimed ?? _readBool(data['currencyClaimed']);
      final nextXpClaimed = xpClaimed ?? _readBool(data['xpClaimed']);
      final claimed = nextCurrencyClaimed && nextXpClaimed;
      transaction.update(ref, <String, dynamic>{
        if (currencyClaimed != null) 'currencyClaimed': currencyClaimed,
        if (xpClaimed != null) 'xpClaimed': xpClaimed,
        'status': claimed
            ? CampaignRewardClaimStatus.claimed.value
            : CampaignRewardClaimStatus.pending.value,
        'updatedAt': FieldValue.serverTimestamp(),
        if (claimed) 'claimedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  bool _passesMax(int value, int? maxValue) {
    return maxValue == null || value <= maxValue;
  }

  int _bestTime(int previousBestTimeMs, int timeMs) {
    if (timeMs <= 0) return previousBestTimeMs;
    if (previousBestTimeMs <= 0) return timeMs;
    return math.min(previousBestTimeMs, timeMs);
  }

  bool _shouldUpdateLeaderboard({
    required Map<String, dynamic>? currentData,
    required StageLeaderboardEntry candidate,
  }) {
    if (currentData == null) return true;
    final currentScore = _readInt(currentData['score']);
    if (candidate.score > currentScore) return true;
    if (candidate.score < currentScore) return false;

    final currentStars = _readInt(currentData['stars']);
    if (candidate.stars > currentStars) return true;
    if (candidate.stars < currentStars) return false;

    final currentTimeMs = _readInt(currentData['timeMs']);
    if (currentTimeMs <= 0) return candidate.timeMs > 0;
    return candidate.timeMs > 0 && candidate.timeMs < currentTimeMs;
  }

  _RewardGrant _calculateReward({
    required CampaignStage stage,
    required bool isFirstCompletion,
    required int previousStars,
    required int newStars,
  }) {
    if (isFirstCompletion) {
      return _RewardGrant(
        coins: stage.rewardCoins,
        gems: stage.rewardGems,
        xp: stage.rewardXp,
      );
    }
    if (newStars <= previousStars) return const _RewardGrant.none();

    final gainedStars = newStars - previousStars;
    return _RewardGrant(
      coins: stage.rewardCoins * gainedStars ~/ 3,
      gems: stage.rewardGems * gainedStars ~/ 3,
      xp: stage.rewardXp * gainedStars ~/ 3,
    );
  }

  String _rewardClaimId({
    required String campaignId,
    required String stageId,
    required int previousStars,
    required int newStars,
    required bool isFirstCompletion,
  }) {
    final phase = isFirstCompletion
        ? 'first_completion'
        : '${previousStars}_to_$newStars';
    return '${_safeClaimSegment(campaignId)}_${_safeClaimSegment(stageId)}_$phase';
  }

  String _safeClaimSegment(String value) {
    return value.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  }

  void _logCampaignFailure({
    required String marker,
    required Object error,
    required StackTrace stackTrace,
    required String campaignId,
    required String stageId,
    required String uid,
  }) {
    final firebaseDetails = error is FirebaseException
        ? ' firebaseCode=${error.code} firebaseMessage=${error.message} '
            'firebasePlugin=${error.plugin}'
        : '';
    debugPrint(
      '$marker type=${error.runtimeType}$firebaseDetails '
      'message=$error campaignId=$campaignId stageId=$stageId uid=$uid',
    );
    if (kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  String _motivationalMessage({
    required bool isFirstCompletion,
    required bool improvedStars,
    required bool improvedBestScore,
    required bool completed,
    required int stars,
  }) {
    if (isFirstCompletion) return 'أحسنت! أنهيت المرحلة لأول مرة.';
    if (improvedStars) return 'رائع! حسّنت عدد النجوم.';
    if (improvedBestScore) return 'نتيجة ممتازة! لقد تجاوزت رقمك السابق.';
    if (!completed && stars == 0) return 'كنت قريبًا جدًا، حاول مرة أخرى.';
    return 'استمر، المرحلة التالية تنتظرك.';
  }
}

class _RewardGrant {
  const _RewardGrant({
    required this.coins,
    required this.gems,
    required this.xp,
  });

  const _RewardGrant.none()
      : coins = 0,
        gems = 0,
        xp = 0;

  final int coins;
  final int gems;
  final int xp;

  bool get granted => coins > 0 || gems > 0 || xp > 0;
}

class _PendingReward {
  _PendingReward.empty();

  String? claimId;
  int previousStars = 0;
  int newStars = 0;
  int coins = 0;
  int gems = 0;
  int xp = 0;

  bool get granted => claimId != null && (coins > 0 || gems > 0 || xp > 0);
}

class _RewardClaimCreateResult {
  const _RewardClaimCreateResult({
    required this.created,
    required this.status,
  });

  final bool created;
  final String? status;
}

bool _readBool(dynamic value, {bool defaultValue = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return defaultValue;
}

int _readInt(dynamic value, {int defaultValue = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? defaultValue;
  return defaultValue;
}

String _readString(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  final text = value.toString();
  return text.isEmpty ? defaultValue : text;
}

String? _cleanString(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  return text;
}
