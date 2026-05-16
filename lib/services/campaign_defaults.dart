import '../models/campaign_stage.dart';

class CampaignDefaults {
  static const String mainCampaignId = 'main_campaign';

  static List<CampaignStage> stages({
    String campaignId = mainCampaignId,
  }) {
    return List<CampaignStage>.generate(30, (index) {
      final order = index + 1;
      final type = _typeFor(order);
      final allowedLevels = allowedLevelsForOrder(order);
      final world = order <= 10
          ? 'غابة البداية'
          : order <= 20
              ? 'تلال المعرفة'
              : 'طريق المليون';
      return _stage(
        id: 'stage_${order.toString().padLeft(3, '0')}',
        campaignId: campaignId,
        order: order,
        title: _titleFor(order, type),
        subtitle: '$world - أجب عن 10 أسئلة واجمع أكبر عدد من النجوم.',
        type: type,
        timeLimitSeconds: _timeLimitFor(type, order),
        categories: const <String>['general'],
        allowedLevels: allowedLevels,
        minDifficulty: _minDifficultyFor(allowedLevels),
        maxDifficulty: _maxDifficultyFor(allowedLevels),
        unlockRequirementStars: order == 1 ? 0 : (order - 1) * 2,
        rewardCoins: 100 + order * 22,
        rewardGems: order % 5 == 0 ? 2 : (order % 3 == 0 ? 1 : 0),
        rewardXp: 70 + order * 18,
        bossBotName:
            type == CampaignStageType.boss ? _bossNameFor(order) : null,
        bossBotIntelligence:
            type == CampaignStageType.boss ? _bossIntelligenceFor(order) : null,
        starRules: _starRulesFor(type, order),
      );
    });
  }

  static List<String> allowedLevelsForOrder(int order) {
    const levelPlan = <int, List<String>>{
      1: ['0'],
      2: ['0', '1'],
      3: ['1'],
      4: ['1'],
      5: ['1', '2'],
      6: ['1', '2'],
      7: ['2'],
      8: ['2'],
      9: ['2', '3'],
      10: ['2', '3'],
      11: ['2', '3'],
      12: ['3'],
      13: ['3'],
      14: ['3'],
      15: ['3', '4'],
      16: ['4'],
      17: ['4'],
      18: ['4'],
      19: ['4', '5'],
      20: ['4', '5'],
      21: ['5'],
      22: ['5'],
      23: ['5'],
      24: ['5', '6'],
      25: ['6'],
      26: ['6'],
      27: ['6', '7'],
      28: ['7'],
      29: ['7'],
      30: ['7', '8'],
    };
    return levelPlan[order] ?? const <String>['0'];
  }

  static CampaignStage _stage({
    required String id,
    required String campaignId,
    required int order,
    required String title,
    required String subtitle,
    required CampaignStageType type,
    required int timeLimitSeconds,
    required List<String> categories,
    required List<String> allowedLevels,
    required int minDifficulty,
    required int maxDifficulty,
    required int unlockRequirementStars,
    required int rewardCoins,
    required int rewardGems,
    required int rewardXp,
    required StageStarRules starRules,
    String? bossBotName,
    int? bossBotIntelligence,
  }) {
    final noLifeline = type == CampaignStageType.noLifeline;
    return CampaignStage(
      id: id,
      campaignId: campaignId,
      order: order,
      title: title,
      subtitle: subtitle,
      type: type,
      questionCount: 10,
      timeLimitSeconds: timeLimitSeconds,
      categories: categories,
      allowedLevels: allowedLevels,
      minDifficulty: minDifficulty,
      maxDifficulty: maxDifficulty,
      unlockRequirementStars: unlockRequirementStars,
      allow5050: !noLifeline,
      allowAudience: !noLifeline,
      allowCall: !noLifeline,
      rewardCoins: rewardCoins,
      rewardGems: rewardGems,
      rewardXp: rewardXp,
      bossBotName: bossBotName,
      bossBotIntelligence: bossBotIntelligence,
      starRules: starRules,
    );
  }

  static CampaignStageType _typeFor(int order) {
    if (order == 10 || order == 20 || order == 30) {
      return CampaignStageType.boss;
    }
    if (order == 6 ||
        order == 12 ||
        order == 17 ||
        order == 23 ||
        order == 27) {
      return CampaignStageType.speed;
    }
    if (order == 7 || order == 14 || order == 22 || order == 28) {
      return CampaignStageType.noLifeline;
    }
    if (order == 9 || order == 25) return CampaignStageType.survival;
    if (order == 18) return CampaignStageType.rival;
    return CampaignStageType.classic;
  }

  static StageStarRules _starRulesFor(CampaignStageType type, int order) {
    return StageStarRules(
      oneStarMinScore: 0,
      twoStarsMinScore: 0,
      threeStarsMinScore: 0,
      oneStarMinCorrectAnswers: 5,
      twoStarsMinCorrectAnswers: 7,
      threeStarsMinCorrectAnswers: order == 20 || order == 30 ? 10 : 9,
      maxWrongAnswersForThreeStars: order == 20 || order == 30 ? 0 : null,
      twoStarsMaxTimeMs: type == CampaignStageType.speed ? 165000 : null,
      threeStarsMaxTimeMs: type == CampaignStageType.speed ? 125000 : null,
      threeStarsMaxLifelinesUsed: type == CampaignStageType.noLifeline
          ? 0
          : type == CampaignStageType.boss
              ? 1
              : null,
      completedRequired: true,
    );
  }

  static int _timeLimitFor(CampaignStageType type, int order) {
    if (type == CampaignStageType.speed) return order >= 20 ? 130 : 150;
    if (type == CampaignStageType.boss) return order == 30 ? 180 : 210;
    return 0;
  }

  static String _titleFor(int order, CampaignStageType type) {
    switch (type) {
      case CampaignStageType.speed:
        return 'سباق المعرفة $order';
      case CampaignStageType.survival:
        return 'تحدي الصمود $order';
      case CampaignStageType.noLifeline:
        return 'بدون مساعدات $order';
      case CampaignStageType.boss:
        return order == 30 ? 'زعيم طريق المليون' : 'مواجهة الزعيم $order';
      case CampaignStageType.rival:
        return 'منافسة المعرفة';
      case CampaignStageType.classic:
        return 'مرحلة $order';
    }
  }

  static String _bossNameFor(int order) {
    if (order == 10) return 'طارق';
    if (order == 20) return 'ليلى';
    return 'حارس المليون';
  }

  static int _bossIntelligenceFor(int order) {
    if (order >= 30) return 88;
    if (order >= 20) return 76;
    return 64;
  }

  static int _minDifficultyFor(List<String> levels) {
    return levels
        .map((level) => int.tryParse(level) ?? 0)
        .reduce((a, b) => a < b ? a : b);
  }

  static int _maxDifficultyFor(List<String> levels) {
    return levels
        .map((level) => int.tryParse(level) ?? 0)
        .reduce((a, b) => a > b ? a : b);
  }
}
