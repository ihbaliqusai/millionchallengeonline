class StageAttempt {
  const StageAttempt({
    required this.attemptId,
    required this.uid,
    required this.campaignId,
    required this.stageId,
    required this.stageType,
    required this.score,
    required this.money,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.timeMs,
    required this.used5050,
    required this.usedAudience,
    required this.usedCall,
    required this.completed,
    required this.stars,
    this.bossDefeated = false,
    this.bossName,
    this.bossCorrectAnswers = 0,
    this.bossWrongAnswers = 0,
    this.bossScore = 0,
    this.playerScore = 0,
    this.createdAt,
  });

  final String attemptId;
  final String uid;
  final String campaignId;
  final String stageId;
  final String stageType;
  final int score;
  final int money;
  final int correctAnswers;
  final int wrongAnswers;
  final int timeMs;
  final int used5050;
  final int usedAudience;
  final int usedCall;
  final bool completed;
  final int stars;
  final bool bossDefeated;
  final String? bossName;
  final int bossCorrectAnswers;
  final int bossWrongAnswers;
  final int bossScore;
  final int playerScore;
  final DateTime? createdAt;

  factory StageAttempt.empty() => const StageAttempt(
        attemptId: '',
        uid: '',
        campaignId: '',
        stageId: '',
        stageType: '',
        score: 0,
        money: 0,
        correctAnswers: 0,
        wrongAnswers: 0,
        timeMs: 0,
        used5050: 0,
        usedAudience: 0,
        usedCall: 0,
        completed: false,
        stars: 0,
        bossDefeated: false,
      );

  factory StageAttempt.fromMap(Map<String, dynamic> map) => StageAttempt(
        attemptId: _readString(map['attemptId']),
        uid: _readString(map['uid']),
        campaignId: _readString(map['campaignId']),
        stageId: _readString(map['stageId']),
        stageType: _readString(map['stageType']),
        score: _readInt(map['score']),
        money: _readInt(map['money']),
        correctAnswers: _readInt(map['correctAnswers']),
        wrongAnswers: _readInt(map['wrongAnswers']),
        timeMs: _readInt(map['timeMs']),
        used5050: _readInt(map['used5050']),
        usedAudience: _readInt(map['usedAudience']),
        usedCall: _readInt(map['usedCall']),
        completed: _readBool(map['completed']),
        stars: _readInt(map['stars']),
        bossDefeated: _readBool(map['bossDefeated']),
        bossName: _readNullableString(map['bossName']),
        bossCorrectAnswers: _readInt(map['bossCorrectAnswers']),
        bossWrongAnswers: _readInt(map['bossWrongAnswers']),
        bossScore: _readInt(map['bossScore']),
        playerScore: _readInt(map['playerScore']),
        createdAt: _readDate(map['createdAt']),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'attemptId': attemptId,
        'uid': uid,
        'campaignId': campaignId,
        'stageId': stageId,
        'stageType': stageType,
        'score': score,
        'money': money,
        'correctAnswers': correctAnswers,
        'wrongAnswers': wrongAnswers,
        'timeMs': timeMs,
        'used5050': used5050,
        'usedAudience': usedAudience,
        'usedCall': usedCall,
        'completed': completed,
        'stars': stars,
        'bossDefeated': bossDefeated,
        if (bossName != null) 'bossName': bossName,
        'bossCorrectAnswers': bossCorrectAnswers,
        'bossWrongAnswers': bossWrongAnswers,
        'bossScore': bossScore,
        'playerScore': playerScore,
        'createdAt': createdAt,
      };

  StageAttempt copyWith({
    String? attemptId,
    String? uid,
    String? campaignId,
    String? stageId,
    String? stageType,
    int? score,
    int? money,
    int? correctAnswers,
    int? wrongAnswers,
    int? timeMs,
    int? used5050,
    int? usedAudience,
    int? usedCall,
    bool? completed,
    int? stars,
    bool? bossDefeated,
    String? bossName,
    int? bossCorrectAnswers,
    int? bossWrongAnswers,
    int? bossScore,
    int? playerScore,
    DateTime? createdAt,
  }) {
    return StageAttempt(
      attemptId: attemptId ?? this.attemptId,
      uid: uid ?? this.uid,
      campaignId: campaignId ?? this.campaignId,
      stageId: stageId ?? this.stageId,
      stageType: stageType ?? this.stageType,
      score: score ?? this.score,
      money: money ?? this.money,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      timeMs: timeMs ?? this.timeMs,
      used5050: used5050 ?? this.used5050,
      usedAudience: usedAudience ?? this.usedAudience,
      usedCall: usedCall ?? this.usedCall,
      completed: completed ?? this.completed,
      stars: stars ?? this.stars,
      bossDefeated: bossDefeated ?? this.bossDefeated,
      bossName: bossName ?? this.bossName,
      bossCorrectAnswers: bossCorrectAnswers ?? this.bossCorrectAnswers,
      bossWrongAnswers: bossWrongAnswers ?? this.bossWrongAnswers,
      bossScore: bossScore ?? this.bossScore,
      playerScore: playerScore ?? this.playerScore,
      createdAt: createdAt ?? this.createdAt,
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
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}
