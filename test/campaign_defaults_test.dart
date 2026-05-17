import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:millionaire_flutter_exact/models/campaign_stage.dart';
import 'package:millionaire_flutter_exact/models/stage_progress.dart';
import 'package:millionaire_flutter_exact/services/campaign_defaults.dart';
import 'package:millionaire_flutter_exact/services/campaign_question_selector.dart';
import 'package:millionaire_flutter_exact/services/campaign_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CampaignDefaults', () {
    test('built-in stages cover stable stage_001 through stage_100', () {
      final stages = CampaignDefaults.stages();
      final ids = stages.map((stage) => stage.id).toList(growable: false);
      final orders = stages.map((stage) => stage.order).toList(growable: false);

      expect(stages, hasLength(100));
      expect(ids.toSet(), hasLength(100));
      expect(orders.toSet(), hasLength(100));

      for (var order = 1; order <= 100; order += 1) {
        expect(ids, contains('stage_${order.toString().padLeft(3, '0')}'));
        expect(orders, contains(order));
      }
      expect(orders, List<int>.generate(100, (index) => index + 1));
    });

    test('all stages have valid required campaign data', () {
      for (final stage in CampaignDefaults.stages()) {
        expect(stage.questionCount, 10, reason: stage.id);
        expect(stage.allowedLevels, isNotEmpty, reason: stage.id);
        expect(stage.rewardCoins, greaterThanOrEqualTo(0), reason: stage.id);
        expect(stage.rewardGems, greaterThanOrEqualTo(0), reason: stage.id);
        expect(stage.rewardXp, greaterThanOrEqualTo(0), reason: stage.id);
        expect(stage.title, isNot(contains('Ø')), reason: stage.id);
        expect(stage.title, isNot(contains('Ù')), reason: stage.id);
        expect(stage.title, isNot(contains('â')), reason: stage.id);
      }
    });

    test('competitive stages include required fields', () {
      final stages = {
        for (final stage in CampaignDefaults.stages()) stage.order: stage,
      };

      for (final order in <int>[35, 43, 48, 55, 65, 76, 85, 96]) {
        final stage = stages[order]!;
        expect(stage.campaignMode, CampaignMode.battle);
        expect(stage.opponentName, isNotEmpty);
        expect(stage.opponentAccuracy, greaterThan(0));
      }

      for (final order in <int>[38, 67, 88, 99]) {
        final stage = stages[order]!;
        expect(stage.campaignMode, CampaignMode.rival);
        expect(stage.targetScore, greaterThan(0));
      }
      expect(stages[38]!.targetScore, 800);
      expect(stages[99]!.targetScore, 950);

      for (final order in <int>[37, 57, 77, 87, 97]) {
        final stage = stages[order]!;
        expect(stage.campaignMode, CampaignMode.series);
        expect(stage.seriesRounds, greaterThan(0));
        expect(stage.seriesWinsRequired, greaterThan(0));
        expect(
            stage.seriesWinsRequired, lessThanOrEqualTo(stage.seriesRounds!));
        expect(stage.opponentName, isNotEmpty);
        expect(stage.opponentAccuracy, greaterThan(0));
      }
      expect(stages[97]!.seriesRounds, 5);
      expect(stages[97]!.seriesWinsRequired, 3);

      for (final order in <int>[47, 58, 78, 98]) {
        final stage = stages[order]!;
        expect(stage.campaignMode, CampaignMode.teamBattle);
        expect(stage.teamAllyName, isNotEmpty);
        expect(stage.teamEnemyName, isNotEmpty);
        expect(stage.opponentAccuracy, greaterThan(0));
      }

      for (final order in <int>[40, 50, 60, 70, 80, 90, 100]) {
        final stage = stages[order]!;
        expect(stage.campaignMode, CampaignMode.bossBattle);
        expect(stage.bossBotName, isNotEmpty);
        expect(stage.bossBotIntelligence, greaterThan(0));
      }
      expect(stages[100]!.bossBotName, 'سيد المليون الأخير');
    });

    test('new mode distribution matches the 20-stage plan', () {
      final counts = <CampaignMode, int>{};
      for (final stage in CampaignDefaults.stages().where(
        (stage) => stage.order >= 31 && stage.order <= 50,
      )) {
        counts[stage.campaignMode] = (counts[stage.campaignMode] ?? 0) + 1;
      }

      expect(counts[CampaignMode.classic], 2);
      expect(counts[CampaignMode.blitz], 4);
      expect(counts[CampaignMode.survival], 2);
      expect(counts[CampaignMode.elimination], 2);
      expect(counts[CampaignMode.noLifeline], 2);
      expect(counts[CampaignMode.battle], 3);
      expect(counts[CampaignMode.rival], 1);
      expect(counts[CampaignMode.series], 1);
      expect(counts[CampaignMode.teamBattle], 1);
      expect(counts[CampaignMode.bossBattle], 2);
    });

    test('stages 51 through 100 use valid high-level levels', () {
      final stages = {
        for (final stage in CampaignDefaults.stages()) stage.order: stage,
      };

      for (var order = 51; order <= 100; order += 1) {
        final stage = stages[order]!;
        expect(
          stage.allowedLevels.every(
            (level) => const <String>{'6', '7', '8'}.contains(level),
          ),
          isTrue,
          reason: stage.id,
        );
      }
    });
  });

  group('CampaignService stage loading', () {
    test('remote stages override defaults without hiding missing defaults',
        () async {
      final firestore = FakeFirebaseFirestore();
      const campaignId = CampaignDefaults.mainCampaignId;
      final defaultStages = CampaignDefaults.stages(campaignId: campaignId);

      for (final stage in defaultStages.take(50)) {
        await firestore
            .collection('campaigns')
            .doc(campaignId)
            .collection('stages')
            .doc(stage.id)
            .set(stage.toMap());
      }
      await firestore
          .collection('campaigns')
          .doc(campaignId)
          .collection('stages')
          .doc('stage_040')
          .set(<String, dynamic>{
        ...defaultStages.firstWhere((stage) => stage.id == 'stage_040').toMap(),
        'title': 'حارس مخصص',
      });
      await firestore
          .collection('campaigns')
          .doc(campaignId)
          .collection('stages')
          .doc('stage_001')
          .set(<String, dynamic>{
        ...defaultStages.first.toMap(),
        'title': 'عنوان مخصص',
      });

      final stages = await CampaignService(firestore: firestore).loadStages();
      final byId = {for (final stage in stages) stage.id: stage};

      expect(stages, hasLength(100));
      expect(byId['stage_001']!.title, 'عنوان مخصص');
      expect(byId['stage_040']!.title, 'حارس مخصص');
      expect(byId['stage_041']!.title, 'بوابة المدينة');
      expect(byId, contains('stage_031'));
      expect(byId, contains('stage_050'));
      expect(byId, contains('stage_051'));
      expect(byId, contains('stage_100'));
      expect(
        stages.map((stage) => stage.order).toList(growable: false),
        List<int>.generate(100, (index) => index + 1),
      );
    });
  });

  group('Campaign progression and mode QA', () {
    late List<CampaignStage> stages;
    late Map<int, CampaignStage> byOrder;
    late CampaignService service;

    setUp(() {
      stages = CampaignDefaults.stages();
      byOrder = {for (final stage in stages) stage.order: stage};
      service = CampaignService(firestore: FakeFirebaseFirestore());
    });

    test('key new stages have the requested allowed levels', () {
      expect(byOrder[31]!.allowedLevels, <String>['5', '6']);
      expect(byOrder[32]!.allowedLevels, <String>['6']);
      expect(byOrder[36]!.allowedLevels, <String>['7']);
      expect(byOrder[39]!.allowedLevels, <String>['7', '8']);
      expect(byOrder[47]!.allowedLevels, <String>['8']);
      expect(byOrder[50]!.allowedLevels, <String>['8']);
      expect(byOrder[51]!.allowedLevels, <String>['6', '7']);
      expect(byOrder[60]!.allowedLevels, <String>['8']);
      expect(byOrder[70]!.allowedLevels, <String>['8']);
      expect(byOrder[80]!.allowedLevels, <String>['8']);
      expect(byOrder[90]!.allowedLevels, <String>['8']);
      expect(byOrder[100]!.allowedLevels, <String>['8']);
    });

    test('debug unlock exposes stages without granting progress', () {
      final saved = <String, StageProgress>{
        byOrder[10]!.id: _completedProgress(byOrder[10]!, stars: 2),
      };
      final progress = service.resolveProgressForStages(
        stages: stages,
        savedProgress: saved,
      );

      expect(progress, hasLength(100));
      expect(
        progress.every(
          (item) => item.status != StageProgressStatus.locked,
        ),
        isTrue,
      );
      expect(progress[9].stageId, 'stage_010');
      expect(progress[9].status, StageProgressStatus.completed);
      expect(progress[9].stars, 2);
      expect(progress[99].stageId, 'stage_100');
      expect(progress[99].status, StageProgressStatus.unlocked);
      expect(progress[99].stars, 0);
      expect(progress[99].firstCompletedAt, isNull);
    });

    test('normal locking is restored when debug unlock is off', () {
      final progress = service.resolveProgressForStages(
        stages: stages,
        savedProgress: const <String, StageProgress>{},
        debugUnlockAllCampaignStagesOverride: false,
      );

      expect(progress.first.stageId, 'stage_001');
      expect(progress.first.status, StageProgressStatus.unlocked);
      expect(progress[1].stageId, 'stage_002');
      expect(progress[1].status, StageProgressStatus.locked);
      expect(progress[49].stageId, 'stage_050');
      expect(progress[49].status, StageProgressStatus.locked);
      expect(progress[99].stageId, 'stage_100');
      expect(progress[99].status, StageProgressStatus.locked);
    });

    test('new-stage unlock chain stays reachable by previous completion', () {
      final saved = <String, StageProgress>{
        for (final stage in stages.take(30))
          stage.id: _completedProgress(stage, stars: 1),
      };
      var progress = service.resolveProgressForStages(
        stages: stages,
        savedProgress: saved,
        debugUnlockAllCampaignStagesOverride: false,
      );
      expect(progress[30].stageId, 'stage_031');
      expect(progress[30].status, StageProgressStatus.unlocked);

      for (final stage in stages.take(39)) {
        saved[stage.id] = _completedProgress(stage, stars: 1);
      }
      progress = service.resolveProgressForStages(
        stages: stages,
        savedProgress: saved,
        debugUnlockAllCampaignStagesOverride: false,
      );
      expect(progress[39].stageId, 'stage_040');
      expect(progress[39].status, StageProgressStatus.unlocked);

      saved[byOrder[40]!.id] = _completedProgress(byOrder[40]!, stars: 1);
      progress = service.resolveProgressForStages(
        stages: stages,
        savedProgress: saved,
        debugUnlockAllCampaignStagesOverride: false,
      );
      expect(progress[40].stageId, 'stage_041');
      expect(progress[40].status, StageProgressStatus.unlocked);

      for (final stage in stages.take(49)) {
        saved[stage.id] = _completedProgress(stage, stars: 1);
      }
      progress = service.resolveProgressForStages(
        stages: stages,
        savedProgress: saved,
        debugUnlockAllCampaignStagesOverride: false,
      );
      expect(progress[49].stageId, 'stage_050');
      expect(progress[49].status, StageProgressStatus.unlocked);

      for (final stage in stages.take(99)) {
        saved[stage.id] = _completedProgress(stage, stars: 1);
      }
      progress = service.resolveProgressForStages(
        stages: stages,
        savedProgress: saved,
        debugUnlockAllCampaignStagesOverride: false,
      );
      expect(progress[99].stageId, 'stage_100');
      expect(progress[99].status, StageProgressStatus.unlocked);
    });

    test('representative stage completion rules normalize correctly', () {
      expect(_completed(service, byOrder[31]!, correct: 10), isTrue);
      expect(_stars(service, byOrder[31]!, correct: 10), 3);

      expect(
        _completed(
          service,
          byOrder[32]!,
          completed: false,
          failureReason: 'timeExpired',
          correct: 8,
        ),
        isFalse,
      );
      expect(_completed(service, byOrder[32]!, correct: 10), isTrue);

      expect(
        _completed(
          service,
          byOrder[33]!,
          completed: false,
          failureReason: 'outOfLives',
          correct: 3,
          wrong: 2,
          livesRemaining: 0,
        ),
        isFalse,
      );
      expect(
        _completed(
          service,
          byOrder[36]!,
          completed: false,
          failureReason: 'eliminated',
          correct: 4,
          wrong: 1,
        ),
        isFalse,
      );

      expect(
        _completed(service, byOrder[38]!, correct: 7, playerScore: 700),
        isFalse,
      );
      expect(
        _completed(service, byOrder[38]!, correct: 8, playerScore: 800),
        isTrue,
      );

      expect(
        _completed(service, byOrder[40]!, bossDefeated: false),
        isFalse,
      );
      expect(
        _completed(service, byOrder[40]!, bossDefeated: true),
        isTrue,
      );
      expect(
        _completed(
          service,
          byOrder[47]!,
          teamScore: 900,
          enemyTeamScore: 1000,
        ),
        isFalse,
      );
      expect(
        _completed(
          service,
          byOrder[47]!,
          teamScore: 1100,
          enemyTeamScore: 1000,
        ),
        isTrue,
      );
      expect(
        _completed(service, byOrder[50]!, bossDefeated: true),
        isTrue,
      );
      expect(
        _completed(service, byOrder[100]!, bossDefeated: false),
        isFalse,
      );
      expect(
        _completed(service, byOrder[100]!, bossDefeated: true),
        isTrue,
      );
    });

    test('failed and repeated attempts do not duplicate rewards', () async {
      final firestore = FakeFirebaseFirestore();
      final campaignService = CampaignService(firestore: firestore);
      final stage = byOrder[31]!;

      final failed = await campaignService.submitStageResult(
        uid: 'qa_user',
        stage: stage,
        nativeResult: _nativeResult(stage, completed: false, correct: 4),
      );
      expect(failed.rewardGranted, isFalse);
      expect(failed.attempt.stars, 0);
      expect(failed.updatedProgress.status, StageProgressStatus.unlocked);

      final oneStar = await campaignService.submitStageResult(
        uid: 'qa_user',
        stage: stage,
        nativeResult: _nativeResult(stage, completed: true, correct: 5),
      );
      expect(oneStar.rewardGranted, isTrue);
      expect(oneStar.newStars, 1);

      final repeatedOneStar = await campaignService.submitStageResult(
        uid: 'qa_user',
        stage: stage,
        nativeResult: _nativeResult(stage, completed: true, correct: 5),
      );
      expect(repeatedOneStar.rewardGranted, isFalse);
      expect(repeatedOneStar.newStars, 1);

      final improved = await campaignService.submitStageResult(
        uid: 'qa_user',
        stage: stage,
        nativeResult: _nativeResult(stage, completed: true, correct: 10),
      );
      expect(improved.rewardGranted, isTrue);
      expect(improved.previousStars, 1);
      expect(improved.newStars, 3);
      expect(improved.rewardCoinsGranted, stage.rewardCoins * 2 ~/ 3);
    });
  });

  group('CampaignQuestionSelector fallback', () {
    test('real bundled question asset supports campaign stage levels',
        () async {
      final decoded =
          jsonDecode(await rootBundle.loadString('assets/questions.json'));
      expect(decoded, isA<List<dynamic>>());
      final counts = <String, int>{};
      for (final item in decoded as List<dynamic>) {
        if (item is! Map) continue;
        final level = item['Level']?.toString().trim() ?? '';
        counts[level] = (counts[level] ?? 0) + 1;
      }

      for (final level in <String>[
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8'
      ]) {
        expect(counts[level], greaterThanOrEqualTo(10), reason: 'Level $level');
      }

      final selector = CampaignQuestionSelector();
      final stages = CampaignDefaults.stages();
      for (final stage in stages) {
        expect(
          stage.allowedLevels.every(counts.containsKey),
          isTrue,
          reason: stage.id,
        );
        final selected = await selector.selectQuestionIds(stage);
        final summary = await selector.levelSummaryForQuestionIds(selected);
        expect(selected, hasLength(stage.questionCount), reason: stage.id);
        expect(
          summary.keys.toSet().difference(stage.allowedLevels.toSet()),
          isEmpty,
          reason: stage.id,
        );
      }

      expect(
        await selector.levelSummaryForQuestionIds(
          await selector.selectQuestionIds(
            stages.firstWhere((stage) => stage.order == 1),
          ),
        ),
        <String, int>{'0': 10},
      );
      expect(
        (await selector.levelSummaryForQuestionIds(
          await selector.selectQuestionIds(
            stages.firstWhere((stage) => stage.order == 2),
          ),
        ))
            .keys
            .toSet()
            .difference(<String>{'0', '1'}),
        isEmpty,
      );
      expect(
        await selector.levelSummaryForQuestionIds(
          await selector.selectQuestionIds(
            stages.firstWhere((stage) => stage.order == 3),
          ),
        ),
        <String, int>{'1': 10},
      );
      expect(
        await selector.selectQuestionIds(
          stages.firstWhere((stage) => stage.order == 40),
        ),
        hasLength(10),
      );
      expect(
        await selector.selectQuestionIds(
          stages.firstWhere((stage) => stage.order == 50),
        ),
        hasLength(10),
      );
      expect(
        await selector.selectQuestionIds(
          stages.firstWhere((stage) => stage.order == 100),
        ),
        hasLength(10),
      );
    });

    test('level 8 stages fall back to highest available level, not beginners',
        () async {
      final questions = <Map<String, dynamic>>[
        for (var i = 0; i < 12; i += 1) {'Level': '0'},
        for (var i = 0; i < 12; i += 1) {'Level': '1'},
        for (var i = 0; i < 12; i += 1) {'Level': '2'},
        for (var i = 0; i < 12; i += 1) {'Level': '3'},
      ];
      final selector = CampaignQuestionSelector(
        bundle: _JsonAssetBundle(jsonEncode(questions)),
      );

      final ids = await selector.selectQuestionIds(
        CampaignDefaults.stages().firstWhere((stage) => stage.order == 50),
      );
      final selectedLevels = ids.map((id) => questions[id]['Level']).toSet();

      expect(ids, hasLength(10));
      expect(selectedLevels, <String>{'3'});
    });
  });
}

StageProgress _completedProgress(CampaignStage stage, {required int stars}) {
  return StageProgress(
    campaignId: stage.campaignId,
    stageId: stage.id,
    status: StageProgressStatus.completed,
    stars: stars,
    bestScore: 1000,
    bestMoney: 0,
    bestCorrectAnswers: 10,
    bestTimeMs: 60000,
    attempts: 1,
    firstCompletedAt: DateTime(2026),
    lastPlayedAt: DateTime(2026),
  );
}

bool _completed(
  CampaignService service,
  CampaignStage stage, {
  bool completed = true,
  String failureReason = '',
  int correct = 10,
  int wrong = 0,
  int livesRemaining = 1,
  int playerScore = 1000,
  int opponentScore = 700,
  bool bossDefeated = false,
  int teamScore = 0,
  int enemyTeamScore = 0,
}) {
  return service.normalizeStageCompleted(
    stage: stage,
    nativeResult: _nativeResult(
      stage,
      completed: completed,
      failureReason: failureReason,
      correct: correct,
      wrong: wrong,
      livesRemaining: livesRemaining,
      playerScore: playerScore,
      opponentScore: opponentScore,
      bossDefeated: bossDefeated,
      teamScore: teamScore,
      enemyTeamScore: enemyTeamScore,
    ),
    correctAnswers: correct,
    wrongAnswers: wrong,
  );
}

int _stars(
  CampaignService service,
  CampaignStage stage, {
  required int correct,
}) {
  return service.calculateStars(
    stage: stage,
    completed: true,
    score: correct * 100,
    correctAnswers: correct,
    wrongAnswers: 10 - correct,
    timeMs: 60000,
    usedLifelines: 0,
  );
}

Map<String, dynamic> _nativeResult(
  CampaignStage stage, {
  required bool completed,
  String failureReason = '',
  int correct = 10,
  int wrong = 0,
  int livesRemaining = 1,
  int playerScore = 1000,
  int opponentScore = 700,
  bool bossDefeated = false,
  int teamScore = 0,
  int enemyTeamScore = 0,
}) {
  return <String, dynamic>{
    'campaignId': stage.campaignId,
    'stageId': stage.id,
    'stageType': stage.type.value,
    'campaignMode': stage.campaignMode.value,
    'winCondition': stage.winCondition.value,
    'completed': completed,
    'failureReason': failureReason,
    'money': 0,
    'correctAnswers': correct,
    'wrongAnswers': wrong,
    'timeMs': 60000,
    'used5050': 0,
    'usedAudience': 0,
    'usedCall': 0,
    'lives': stage.lives ?? 0,
    'livesRemaining': livesRemaining,
    'maxWrongAnswers': stage.maxWrongAnswers ?? 0,
    'targetScore': stage.targetScore ?? 0,
    'playerScore': playerScore,
    'opponentScore': opponentScore,
    'opponentCorrectAnswers': opponentScore ~/ 100,
    'bossDefeated': bossDefeated,
    'bossBattleWon': bossDefeated,
    'bossScore': bossDefeated ? 700 : 1100,
    'teamScore': teamScore,
    'enemyTeamScore': enemyTeamScore,
  };
}

class _JsonAssetBundle extends CachingAssetBundle {
  _JsonAssetBundle(this.value);

  final String value;

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(utf8.encode(value));
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => value;
}
