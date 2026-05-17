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
    this.campaignMode = '',
    this.winCondition = '',
    this.failureReason = '',
    this.lives = 0,
    this.livesRemaining = 0,
    this.maxWrongAnswers = 0,
    this.targetScore = 0,
    this.playerScore = 0,
    this.opponentName,
    this.opponentScore = 0,
    this.opponentCorrectAnswers = 0,
    this.opponentWrongAnswers = 0,
    this.bossDefeated = false,
    this.bossName,
    this.bossCorrectAnswers = 0,
    this.bossWrongAnswers = 0,
    this.bossScore = 0,
    this.seriesRounds = 0,
    this.seriesWinsRequired = 0,
    this.playerSeriesWins = 0,
    this.opponentSeriesWins = 0,
    this.teamAllyName,
    this.teamEnemyName,
    this.allyScore = 0,
    this.teamScore = 0,
    this.enemyTeamScore = 0,
    this.createdAt,
  });

  final String attemptId;
  final String uid;
  final String campaignId;
  final String stageId;
  final String stageType;
  final String campaignMode;
  final String winCondition;
  final String failureReason;
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
  final int lives;
  final int livesRemaining;
  final int maxWrongAnswers;
  final int targetScore;
  final int playerScore;
  final String? opponentName;
  final int opponentScore;
  final int opponentCorrectAnswers;
  final int opponentWrongAnswers;
  final bool bossDefeated;
  final String? bossName;
  final int bossCorrectAnswers;
  final int bossWrongAnswers;
  final int bossScore;
  final int seriesRounds;
  final int seriesWinsRequired;
  final int playerSeriesWins;
  final int opponentSeriesWins;
  final String? teamAllyName;
  final String? teamEnemyName;
  final int allyScore;
  final int teamScore;
  final int enemyTeamScore;
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
      );

  factory StageAttempt.fromMap(Map<String, dynamic> map) => StageAttempt(
        attemptId: _readString(map['attemptId']),
        uid: _readString(map['uid']),
        campaignId: _readString(map['campaignId']),
        stageId: _readString(map['stageId']),
        stageType: _readString(map['stageType']),
        campaignMode: _readString(map['campaignMode']),
        winCondition: _readString(map['winCondition']),
        failureReason: _readString(map['failureReason']),
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
        lives: _readInt(map['lives']),
        livesRemaining: _readInt(map['livesRemaining']),
        maxWrongAnswers: _readInt(map['maxWrongAnswers']),
        targetScore: _readInt(map['targetScore']),
        playerScore: _readInt(map['playerScore']),
        opponentName: _readNullableString(map['opponentName']),
        opponentScore: _readInt(map['opponentScore']),
        opponentCorrectAnswers: _readInt(map['opponentCorrectAnswers']),
        opponentWrongAnswers: _readInt(map['opponentWrongAnswers']),
        bossDefeated: _readBool(map['bossDefeated']),
        bossName: _readNullableString(map['bossName']),
        bossCorrectAnswers: _readInt(map['bossCorrectAnswers']),
        bossWrongAnswers: _readInt(map['bossWrongAnswers']),
        bossScore: _readInt(map['bossScore']),
        seriesRounds: _readInt(map['seriesRounds']),
        seriesWinsRequired: _readInt(map['seriesWinsRequired']),
        playerSeriesWins: _readInt(map['playerSeriesWins']),
        opponentSeriesWins: _readInt(map['opponentSeriesWins']),
        teamAllyName: _readNullableString(map['teamAllyName']),
        teamEnemyName: _readNullableString(map['teamEnemyName']),
        allyScore: _readInt(map['allyScore']),
        teamScore: _readInt(map['teamScore']),
        enemyTeamScore: _readInt(map['enemyTeamScore']),
        createdAt: _readDate(map['createdAt']),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'attemptId': attemptId,
        'uid': uid,
        'campaignId': campaignId,
        'stageId': stageId,
        'stageType': stageType,
        'campaignMode': campaignMode,
        'winCondition': winCondition,
        'failureReason': failureReason,
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
        'lives': lives,
        'livesRemaining': livesRemaining,
        'maxWrongAnswers': maxWrongAnswers,
        'targetScore': targetScore,
        'playerScore': playerScore,
        if (opponentName != null) 'opponentName': opponentName,
        'opponentScore': opponentScore,
        'opponentCorrectAnswers': opponentCorrectAnswers,
        'opponentWrongAnswers': opponentWrongAnswers,
        'bossDefeated': bossDefeated,
        if (bossName != null) 'bossName': bossName,
        'bossCorrectAnswers': bossCorrectAnswers,
        'bossWrongAnswers': bossWrongAnswers,
        'bossScore': bossScore,
        'seriesRounds': seriesRounds,
        'seriesWinsRequired': seriesWinsRequired,
        'playerSeriesWins': playerSeriesWins,
        'opponentSeriesWins': opponentSeriesWins,
        if (teamAllyName != null) 'teamAllyName': teamAllyName,
        if (teamEnemyName != null) 'teamEnemyName': teamEnemyName,
        'allyScore': allyScore,
        'teamScore': teamScore,
        'enemyTeamScore': enemyTeamScore,
        'createdAt': createdAt,
      };
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
