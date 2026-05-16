enum CampaignStageType {
  classic,
  speed,
  survival,
  noLifeline,
  boss,
  rival,
}

extension CampaignStageTypeX on CampaignStageType {
  String get value {
    switch (this) {
      case CampaignStageType.classic:
        return 'classic';
      case CampaignStageType.speed:
        return 'speed';
      case CampaignStageType.survival:
        return 'survival';
      case CampaignStageType.noLifeline:
        return 'noLifeline';
      case CampaignStageType.boss:
        return 'boss';
      case CampaignStageType.rival:
        return 'rival';
    }
  }
}

CampaignStageType campaignStageTypeFromString(dynamic value) {
  final normalized = _readString(value).trim().toLowerCase();
  switch (normalized) {
    case 'speed':
      return CampaignStageType.speed;
    case 'survival':
      return CampaignStageType.survival;
    case 'nolifeline':
    case 'no_lifeline':
    case 'no-lifeline':
      return CampaignStageType.noLifeline;
    case 'boss':
      return CampaignStageType.boss;
    case 'rival':
      return CampaignStageType.rival;
    case 'classic':
    default:
      return CampaignStageType.classic;
  }
}

class StageStarRules {
  const StageStarRules({
    required this.oneStarMinScore,
    required this.twoStarsMinScore,
    required this.threeStarsMinScore,
    required this.completedRequired,
    this.oneStarMinCorrectAnswers = 5,
    this.twoStarsMinCorrectAnswers = 7,
    this.threeStarsMinCorrectAnswers = 9,
    this.maxWrongAnswersForThreeStars,
    this.twoStarsMaxTimeMs,
    this.threeStarsMaxTimeMs,
    this.threeStarsMaxLifelinesUsed,
  });

  final int oneStarMinScore;
  final int twoStarsMinScore;
  final int threeStarsMinScore;
  final int oneStarMinCorrectAnswers;
  final int twoStarsMinCorrectAnswers;
  final int threeStarsMinCorrectAnswers;
  final int? maxWrongAnswersForThreeStars;
  final int? twoStarsMaxTimeMs;
  final int? threeStarsMaxTimeMs;
  final int? threeStarsMaxLifelinesUsed;
  final bool completedRequired;

  factory StageStarRules.empty() => const StageStarRules(
        oneStarMinScore: 0,
        twoStarsMinScore: 0,
        threeStarsMinScore: 0,
        oneStarMinCorrectAnswers: 5,
        twoStarsMinCorrectAnswers: 7,
        threeStarsMinCorrectAnswers: 9,
        completedRequired: true,
      );

  factory StageStarRules.fromMap(Map<String, dynamic>? map) {
    if (map == null) return StageStarRules.empty();
    return StageStarRules(
      oneStarMinScore: _readInt(map['oneStarMinScore']),
      twoStarsMinScore: _readInt(map['twoStarsMinScore']),
      threeStarsMinScore: _readInt(map['threeStarsMinScore']),
      oneStarMinCorrectAnswers:
          _readInt(map['oneStarMinCorrectAnswers'], defaultValue: 5),
      twoStarsMinCorrectAnswers:
          _readInt(map['twoStarsMinCorrectAnswers'], defaultValue: 7),
      threeStarsMinCorrectAnswers:
          _readInt(map['threeStarsMinCorrectAnswers'], defaultValue: 9),
      maxWrongAnswersForThreeStars:
          _readNullableInt(map['maxWrongAnswersForThreeStars']),
      twoStarsMaxTimeMs: _readNullableInt(map['twoStarsMaxTimeMs']),
      threeStarsMaxTimeMs: _readNullableInt(map['threeStarsMaxTimeMs']),
      threeStarsMaxLifelinesUsed:
          _readNullableInt(map['threeStarsMaxLifelinesUsed']),
      completedRequired:
          _readBool(map['completedRequired'], defaultValue: true),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'oneStarMinScore': oneStarMinScore,
        'twoStarsMinScore': twoStarsMinScore,
        'threeStarsMinScore': threeStarsMinScore,
        'oneStarMinCorrectAnswers': oneStarMinCorrectAnswers,
        'twoStarsMinCorrectAnswers': twoStarsMinCorrectAnswers,
        'threeStarsMinCorrectAnswers': threeStarsMinCorrectAnswers,
        'maxWrongAnswersForThreeStars': maxWrongAnswersForThreeStars,
        'twoStarsMaxTimeMs': twoStarsMaxTimeMs,
        'threeStarsMaxTimeMs': threeStarsMaxTimeMs,
        'threeStarsMaxLifelinesUsed': threeStarsMaxLifelinesUsed,
        'completedRequired': completedRequired,
      };

  StageStarRules copyWith({
    int? oneStarMinScore,
    int? twoStarsMinScore,
    int? threeStarsMinScore,
    int? oneStarMinCorrectAnswers,
    int? twoStarsMinCorrectAnswers,
    int? threeStarsMinCorrectAnswers,
    int? maxWrongAnswersForThreeStars,
    int? twoStarsMaxTimeMs,
    int? threeStarsMaxTimeMs,
    int? threeStarsMaxLifelinesUsed,
    bool? completedRequired,
  }) {
    return StageStarRules(
      oneStarMinScore: oneStarMinScore ?? this.oneStarMinScore,
      twoStarsMinScore: twoStarsMinScore ?? this.twoStarsMinScore,
      threeStarsMinScore: threeStarsMinScore ?? this.threeStarsMinScore,
      oneStarMinCorrectAnswers:
          oneStarMinCorrectAnswers ?? this.oneStarMinCorrectAnswers,
      twoStarsMinCorrectAnswers:
          twoStarsMinCorrectAnswers ?? this.twoStarsMinCorrectAnswers,
      threeStarsMinCorrectAnswers:
          threeStarsMinCorrectAnswers ?? this.threeStarsMinCorrectAnswers,
      maxWrongAnswersForThreeStars:
          maxWrongAnswersForThreeStars ?? this.maxWrongAnswersForThreeStars,
      twoStarsMaxTimeMs: twoStarsMaxTimeMs ?? this.twoStarsMaxTimeMs,
      threeStarsMaxTimeMs: threeStarsMaxTimeMs ?? this.threeStarsMaxTimeMs,
      threeStarsMaxLifelinesUsed:
          threeStarsMaxLifelinesUsed ?? this.threeStarsMaxLifelinesUsed,
      completedRequired: completedRequired ?? this.completedRequired,
    );
  }
}

class CampaignStage {
  const CampaignStage({
    required this.id,
    required this.campaignId,
    required this.order,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.questionCount,
    required this.timeLimitSeconds,
    required this.categories,
    required this.allowedLevels,
    required this.minDifficulty,
    required this.maxDifficulty,
    required this.unlockRequirementStars,
    required this.allow5050,
    required this.allowAudience,
    required this.allowCall,
    required this.rewardCoins,
    required this.rewardGems,
    required this.rewardXp,
    required this.starRules,
    this.bossBotName,
    this.bossBotIntelligence,
  });

  final String id;
  final String campaignId;
  final int order;
  final String title;
  final String subtitle;
  final CampaignStageType type;
  final int questionCount;
  final int timeLimitSeconds;
  final List<String> categories;
  final List<String> allowedLevels;
  final int minDifficulty;
  final int maxDifficulty;
  final int unlockRequirementStars;
  final bool allow5050;
  final bool allowAudience;
  final bool allowCall;
  final int rewardCoins;
  final int rewardGems;
  final int rewardXp;
  final String? bossBotName;
  final int? bossBotIntelligence;
  final StageStarRules starRules;

  factory CampaignStage.empty() => CampaignStage(
        id: '',
        campaignId: '',
        order: 0,
        title: '',
        subtitle: '',
        type: CampaignStageType.classic,
        questionCount: 0,
        timeLimitSeconds: 0,
        categories: const <String>[],
        allowedLevels: const <String>[],
        minDifficulty: 0,
        maxDifficulty: 0,
        unlockRequirementStars: 0,
        allow5050: true,
        allowAudience: true,
        allowCall: true,
        rewardCoins: 0,
        rewardGems: 0,
        rewardXp: 0,
        starRules: StageStarRules.empty(),
      );

  factory CampaignStage.fromMap(Map<String, dynamic> map) => CampaignStage(
        id: _readString(map['id']),
        campaignId: _readString(map['campaignId']),
        order: _readInt(map['order']),
        title: _readString(map['title']),
        subtitle: _readString(map['subtitle']),
        type: campaignStageTypeFromString(map['type']),
        questionCount: _readInt(map['questionCount']),
        timeLimitSeconds: _readInt(map['timeLimitSeconds']),
        categories: _readStringList(map['categories']),
        allowedLevels: _readStringList(map['allowedLevels']),
        minDifficulty: _readInt(map['minDifficulty']),
        maxDifficulty: _readInt(map['maxDifficulty']),
        unlockRequirementStars: _readInt(map['unlockRequirementStars']),
        allow5050: _readBool(map['allow5050'], defaultValue: true),
        allowAudience: _readBool(map['allowAudience'], defaultValue: true),
        allowCall: _readBool(map['allowCall'], defaultValue: true),
        rewardCoins: _readInt(map['rewardCoins']),
        rewardGems: _readInt(map['rewardGems']),
        rewardXp: _readInt(map['rewardXp']),
        bossBotName: _readNullableString(map['bossBotName']),
        bossBotIntelligence: _readNullableInt(map['bossBotIntelligence']),
        starRules: StageStarRules.fromMap(_readMap(map['starRules'])),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'campaignId': campaignId,
        'order': order,
        'title': title,
        'subtitle': subtitle,
        'type': type.value,
        'questionCount': questionCount,
        'timeLimitSeconds': timeLimitSeconds,
        'categories': categories,
        'allowedLevels': allowedLevels,
        'minDifficulty': minDifficulty,
        'maxDifficulty': maxDifficulty,
        'unlockRequirementStars': unlockRequirementStars,
        'allow5050': allow5050,
        'allowAudience': allowAudience,
        'allowCall': allowCall,
        'rewardCoins': rewardCoins,
        'rewardGems': rewardGems,
        'rewardXp': rewardXp,
        'bossBotName': bossBotName,
        'bossBotIntelligence': bossBotIntelligence,
        'starRules': starRules.toMap(),
      };

  CampaignStage copyWith({
    String? id,
    String? campaignId,
    int? order,
    String? title,
    String? subtitle,
    CampaignStageType? type,
    int? questionCount,
    int? timeLimitSeconds,
    List<String>? categories,
    List<String>? allowedLevels,
    int? minDifficulty,
    int? maxDifficulty,
    int? unlockRequirementStars,
    bool? allow5050,
    bool? allowAudience,
    bool? allowCall,
    int? rewardCoins,
    int? rewardGems,
    int? rewardXp,
    String? bossBotName,
    int? bossBotIntelligence,
    StageStarRules? starRules,
  }) {
    return CampaignStage(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      order: order ?? this.order,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      questionCount: questionCount ?? this.questionCount,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      categories: categories ?? this.categories,
      allowedLevels: allowedLevels ?? this.allowedLevels,
      minDifficulty: minDifficulty ?? this.minDifficulty,
      maxDifficulty: maxDifficulty ?? this.maxDifficulty,
      unlockRequirementStars:
          unlockRequirementStars ?? this.unlockRequirementStars,
      allow5050: allow5050 ?? this.allow5050,
      allowAudience: allowAudience ?? this.allowAudience,
      allowCall: allowCall ?? this.allowCall,
      rewardCoins: rewardCoins ?? this.rewardCoins,
      rewardGems: rewardGems ?? this.rewardGems,
      rewardXp: rewardXp ?? this.rewardXp,
      bossBotName: bossBotName ?? this.bossBotName,
      bossBotIntelligence: bossBotIntelligence ?? this.bossBotIntelligence,
      starRules: starRules ?? this.starRules,
    );
  }
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

int? _readNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

Map<String, dynamic>? _readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _readString(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  return value.toString();
}

String? _readNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

List<String> _readStringList(dynamic value) {
  if (value is Iterable) {
    return value
        .map((dynamic item) => item?.toString().trim() ?? '')
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }
  if (value is String && value.trim().isNotEmpty) {
    return <String>[value.trim()];
  }
  return const <String>[];
}
