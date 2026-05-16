class StageLeaderboardEntry {
  const StageLeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.campaignId,
    required this.stageId,
    required this.score,
    required this.stars,
    required this.money,
    required this.correctAnswers,
    required this.timeMs,
    required this.usedLifelines,
    required this.assisted,
    this.photoUrl,
    this.updatedAt,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;
  final String campaignId;
  final String stageId;
  final int score;
  final int stars;
  final int money;
  final int correctAnswers;
  final int timeMs;
  final int usedLifelines;
  final bool assisted;
  final DateTime? updatedAt;

  factory StageLeaderboardEntry.empty() => const StageLeaderboardEntry(
        uid: '',
        displayName: '',
        campaignId: '',
        stageId: '',
        score: 0,
        stars: 0,
        money: 0,
        correctAnswers: 0,
        timeMs: 0,
        usedLifelines: 0,
        assisted: false,
      );

  factory StageLeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return StageLeaderboardEntry(
      uid: _readString(map['uid']),
      displayName: _readString(map['displayName']),
      photoUrl: _readNullableString(map['photoUrl']),
      campaignId: _readString(map['campaignId']),
      stageId: _readString(map['stageId']),
      score: _readInt(map['score']),
      stars: _readInt(map['stars']),
      money: _readInt(map['money']),
      correctAnswers: _readInt(map['correctAnswers']),
      timeMs: _readInt(map['timeMs']),
      usedLifelines: _readInt(map['usedLifelines']),
      assisted: _readBool(map['assisted']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'uid': uid,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'campaignId': campaignId,
        'stageId': stageId,
        'score': score,
        'stars': stars,
        'money': money,
        'correctAnswers': correctAnswers,
        'timeMs': timeMs,
        'usedLifelines': usedLifelines,
        'assisted': assisted,
        'updatedAt': updatedAt,
      };

  StageLeaderboardEntry copyWith({
    String? uid,
    String? displayName,
    String? photoUrl,
    String? campaignId,
    String? stageId,
    int? score,
    int? stars,
    int? money,
    int? correctAnswers,
    int? timeMs,
    int? usedLifelines,
    bool? assisted,
    DateTime? updatedAt,
  }) {
    return StageLeaderboardEntry(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      campaignId: campaignId ?? this.campaignId,
      stageId: stageId ?? this.stageId,
      score: score ?? this.score,
      stars: stars ?? this.stars,
      money: money ?? this.money,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      timeMs: timeMs ?? this.timeMs,
      usedLifelines: usedLifelines ?? this.usedLifelines,
      assisted: assisted ?? this.assisted,
      updatedAt: updatedAt ?? this.updatedAt,
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

String? _readNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}
