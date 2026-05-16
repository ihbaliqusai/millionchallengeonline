enum StageProgressStatus {
  locked,
  unlocked,
  completed,
}

extension StageProgressStatusX on StageProgressStatus {
  String get value {
    switch (this) {
      case StageProgressStatus.locked:
        return 'locked';
      case StageProgressStatus.unlocked:
        return 'unlocked';
      case StageProgressStatus.completed:
        return 'completed';
    }
  }
}

StageProgressStatus stageProgressStatusFromString(dynamic value) {
  final normalized = _readString(value).trim().toLowerCase();
  switch (normalized) {
    case 'unlocked':
      return StageProgressStatus.unlocked;
    case 'completed':
      return StageProgressStatus.completed;
    case 'locked':
    default:
      return StageProgressStatus.locked;
  }
}

class StageProgress {
  const StageProgress({
    required this.campaignId,
    required this.stageId,
    required this.status,
    required this.stars,
    required this.bestScore,
    required this.bestMoney,
    required this.bestCorrectAnswers,
    required this.bestTimeMs,
    required this.attempts,
    this.firstCompletedAt,
    this.lastPlayedAt,
  });

  final String campaignId;
  final String stageId;
  final StageProgressStatus status;
  final int stars;
  final int bestScore;
  final int bestMoney;
  final int bestCorrectAnswers;
  final int bestTimeMs;
  final int attempts;
  final DateTime? firstCompletedAt;
  final DateTime? lastPlayedAt;

  factory StageProgress.empty() => const StageProgress(
        campaignId: '',
        stageId: '',
        status: StageProgressStatus.locked,
        stars: 0,
        bestScore: 0,
        bestMoney: 0,
        bestCorrectAnswers: 0,
        bestTimeMs: 0,
        attempts: 0,
      );

  factory StageProgress.fromMap(Map<String, dynamic> map) => StageProgress(
        campaignId: _readString(map['campaignId']),
        stageId: _readString(map['stageId']),
        status: stageProgressStatusFromString(map['status']),
        stars: _readInt(map['stars']),
        bestScore: _readInt(map['bestScore']),
        bestMoney: _readInt(map['bestMoney']),
        bestCorrectAnswers: _readInt(map['bestCorrectAnswers']),
        bestTimeMs: _readInt(map['bestTimeMs']),
        attempts: _readInt(map['attempts']),
        firstCompletedAt: _readDate(map['firstCompletedAt']),
        lastPlayedAt: _readDate(map['lastPlayedAt']),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'campaignId': campaignId,
        'stageId': stageId,
        'status': status.value,
        'stars': stars,
        'bestScore': bestScore,
        'bestMoney': bestMoney,
        'bestCorrectAnswers': bestCorrectAnswers,
        'bestTimeMs': bestTimeMs,
        'attempts': attempts,
        'firstCompletedAt': firstCompletedAt,
        'lastPlayedAt': lastPlayedAt,
      };

  StageProgress copyWith({
    String? campaignId,
    String? stageId,
    StageProgressStatus? status,
    int? stars,
    int? bestScore,
    int? bestMoney,
    int? bestCorrectAnswers,
    int? bestTimeMs,
    int? attempts,
    DateTime? firstCompletedAt,
    DateTime? lastPlayedAt,
  }) {
    return StageProgress(
      campaignId: campaignId ?? this.campaignId,
      stageId: stageId ?? this.stageId,
      status: status ?? this.status,
      stars: stars ?? this.stars,
      bestScore: bestScore ?? this.bestScore,
      bestMoney: bestMoney ?? this.bestMoney,
      bestCorrectAnswers: bestCorrectAnswers ?? this.bestCorrectAnswers,
      bestTimeMs: bestTimeMs ?? this.bestTimeMs,
      attempts: attempts ?? this.attempts,
      firstCompletedAt: firstCompletedAt ?? this.firstCompletedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  if (value is String) return DateTime.tryParse(value);
  try {
    final dynamic date = value.toDate();
    if (date is DateTime) return date;
  } on Object {
    return null;
  }
  return null;
}

int _readInt(dynamic value, {int defaultValue = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? defaultValue;
  return defaultValue;
}

String _readString(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  return value.toString();
}
