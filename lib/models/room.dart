import 'package:cloud_firestore/cloud_firestore.dart';

class RoomBotProfile {
  const RoomBotProfile({
    required this.displayName,
    required this.intelligence,
    required this.avatarSeed,
    required this.nativePhoto,
  });

  final String displayName;
  final int intelligence;
  final int avatarSeed;
  final String nativePhoto;
}

class RoomPlayer {
  const RoomPlayer({
    required this.score,
    required this.ready,
    this.answeredCount = 0,
    this.completedAt,
    this.eliminated = false,
    this.currentAnswer,
    this.lives = 0,
    this.roundWins = 0,
    this.teamId,
  });

  final int score;
  final bool ready;
  final int answeredCount;
  final DateTime? completedAt;
  final bool eliminated;
  final String? currentAnswer;

  /// survival: remaining lives (starts at 3, eliminated when 0).
  final int lives;

  /// series: rounds won so far in this series.
  final int roundWins;

  /// team_battle: 'A' or 'B'.
  final String? teamId;

  factory RoomPlayer.fromMap(
    Map<String, dynamic> map, {
    int defaultLives = 0,
  }) =>
      RoomPlayer(
        score: (map['score'] as num?)?.toInt() ?? 0,
        ready: map['ready'] == true,
        answeredCount: (map['answeredCount'] as num?)?.toInt() ?? 0,
        completedAt: _readDate(map['completedAt']),
        eliminated: map['eliminated'] == true,
        currentAnswer: map['currentAnswer'] as String?,
        lives: _readLives(map, defaultLives: defaultLives),
        roundWins: (map['roundWins'] as num?)?.toInt() ?? 0,
        teamId: Room.normalizeTeamId(map['teamId'] as String?),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'score': score,
        'ready': ready,
        'answeredCount': answeredCount,
        if (completedAt != null)
          'completedAt': Timestamp.fromDate(completedAt!),
        if (eliminated) 'eliminated': eliminated,
        if (currentAnswer != null) 'currentAnswer': currentAnswer,
        if (lives > 0 || eliminated) 'lives': lives,
        if (roundWins > 0) 'roundWins': roundWins,
        if (teamId != null) 'teamId': Room.normalizeTeamId(teamId),
      };

  RoomPlayer copyWith({
    int? score,
    bool? ready,
    int? answeredCount,
    DateTime? completedAt,
    bool? eliminated,
    String? currentAnswer,
    int? lives,
    int? roundWins,
    String? teamId,
  }) {
    return RoomPlayer(
      score: score ?? this.score,
      ready: ready ?? this.ready,
      answeredCount: answeredCount ?? this.answeredCount,
      completedAt: completedAt ?? this.completedAt,
      eliminated: eliminated ?? this.eliminated,
      currentAnswer: currentAnswer ?? this.currentAnswer,
      lives: lives ?? this.lives,
      roundWins: roundWins ?? this.roundWins,
      teamId: Room.normalizeTeamId(teamId ?? this.teamId),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static int _readLives(
    Map<String, dynamic> map, {
    required int defaultLives,
  }) {
    final rawLives = map['lives'];
    if (rawLives is num) {
      return rawLives.toInt();
    }
    if (map['eliminated'] == true) {
      return 0;
    }
    return defaultLives;
  }
}

class Room {
  static const String modeBattle = 'battle';
  static const String modeElimination = 'elimination';
  static const String modeBlitz = 'blitz';
  static const String modeSurvival = 'survival';
  static const String modeSeries = 'series';
  static const String modeTeamBattle = 'team_battle';
  static const String teamA = 'A';
  static const String teamB = 'B';
  static const List<String> teamIds = <String>[teamA, teamB];

  static const String phaseLobby = 'lobby';
  static const String phasePlaying = 'playing';
  static const String phasePlayingRound = 'playing_round';
  static const String phaseRoundOver = 'round_over';
  static const String phaseFinished = 'finished';

  static const int initialSurvivalLives = 3;
  static const String botIdPrefix = 'bot_room_';
  static const List<RoomBotProfile> _botProfiles = <RoomBotProfile>[
    // 1 — ذكر — العبقري الهادئ
    RoomBotProfile(
      displayName: 'طارق',
      intelligence: 95,
      avatarSeed: 0,
      nativePhoto: 'drawable:avatar1',
    ),
    // 2 — أنثى — المغامرة
    RoomBotProfile(
      displayName: 'ليلى',
      intelligence: 70,
      avatarSeed: 1,
      nativePhoto: 'drawable:avatar2',
    ),
    // 3 — أنثى — المترددة
    RoomBotProfile(
      displayName: 'هدى',
      intelligence: 65,
      avatarSeed: 2,
      nativePhoto: 'drawable:avatar3',
    ),
    // 4 — ذكر — الخبير
    RoomBotProfile(
      displayName: 'عمر',
      intelligence: 85,
      avatarSeed: 3,
      nativePhoto: 'drawable:avatar4',
    ),
    // 5 — أنثى — المحظوظة
    RoomBotProfile(
      displayName: 'منى',
      intelligence: 50,
      avatarSeed: 4,
      nativePhoto: 'drawable:avatar5',
    ),
    // 6 — أنثى — المفكرة البطيئة
    RoomBotProfile(
      displayName: 'سارة',
      intelligence: 80,
      avatarSeed: 5,
      nativePhoto: 'drawable:avatar6',
    ),
    // 7 — ذكر — المتسرع
    RoomBotProfile(
      displayName: 'علي',
      intelligence: 60,
      avatarSeed: 6,
      nativePhoto: 'drawable:avatar7',
    ),
    // 8 — ذكر — العبقري الاجتماعي
    RoomBotProfile(
      displayName: 'فيصل',
      intelligence: 90,
      avatarSeed: 7,
      nativePhoto: 'drawable:avatar8',
    ),
    // 9 — ذكر — المبتدئ
    RoomBotProfile(
      displayName: 'يوسف',
      intelligence: 40,
      avatarSeed: 8,
      nativePhoto: 'drawable:avatar9',
    ),
    // 10 — أنثى — المخادعة
    RoomBotProfile(
      displayName: 'رنا',
      intelligence: 75,
      avatarSeed: 9,
      nativePhoto: 'drawable:avatar10',
    ),
    // 11 — ذكر — الموسوعي
    RoomBotProfile(
      displayName: 'خالد',
      intelligence: 92,
      avatarSeed: 10,
      nativePhoto: 'drawable:avatar11',
    ),
    // 12 — ذكر — الكلاسيكي
    RoomBotProfile(
      displayName: 'سالم',
      intelligence: 78,
      avatarSeed: 11,
      nativePhoto: 'drawable:avatar12',
    ),
  ];

  const Room({
    required this.id,
    required this.hostId,
    required this.maxPlayers,
    required this.started,
    required this.players,
    this.createdAt,
    this.startedAt,
    this.mode = 'battle',
    this.phase = 'lobby',
    this.currentQuestionIndex = 0,
    this.questionStartedAt,
    this.questionIds = const [],
    this.winnerId,
    this.winnerTeamId,
    this.roundDurationSeconds = 0,
    this.seriesTarget = 2,
    this.roundNumber = 1,
  });

  final String id;
  final String hostId;
  final int maxPlayers;
  final bool started;
  final Map<String, RoomPlayer> players;
  final DateTime? createdAt;
  final DateTime? startedAt;

  /// 'battle' | 'elimination' | 'blitz' | 'survival' | 'series' | 'team_battle'
  final String mode;

  /// battle/blitz/team_battle: 'lobby' | 'playing' | 'finished'
  /// elimination/survival/series: 'lobby' | 'playing_round' | 'round_over' | 'finished'
  final String phase;

  final int currentQuestionIndex;
  final DateTime? questionStartedAt;

  /// Shuffled list of indices into questions.json, set when game starts (elimination/survival).
  final List<int> questionIds;

  /// UID of the winning player when phase == 'finished'. Null = draw / no winner.
  final String? winnerId;

  /// team_battle: 'A' or 'B' — winning team.
  final String? winnerTeamId;

  /// blitz: game duration in seconds (60 or 90). 0 = not applicable.
  final int roundDurationSeconds;

  /// series: number of round wins needed to win the series.
  final int seriesTarget;

  /// series/survival: current round number (1-indexed).
  final int roundNumber;

  static const List<int> allowedBlitzDurations = [60, 90, 120];

  /// The UTC moment when the blitz game ends (startedAt + roundDurationSeconds).
  DateTime? get blitzEndTime {
    if (mode != modeBlitz) return null;
    final start = startedAt;
    if (start == null || roundDurationSeconds <= 0) return null;
    return start.add(Duration(seconds: roundDurationSeconds));
  }

  /// Client-side estimate: true when the blitz timer has elapsed.
  bool get isBlitzExpired {
    final end = blitzEndTime;
    if (end == null) return false;
    return DateTime.now().isAfter(end);
  }

  /// Seconds remaining in the blitz game; 0 when expired or not applicable.
  int get blitzSecondsRemaining {
    final end = blitzEndTime;
    if (end == null) return 0;
    final secs = end.difference(DateTime.now()).inSeconds;
    return secs < 0 ? 0 : secs;
  }

  factory Room.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final mode = (data['mode'] ?? modeBattle).toString();
    final started = data['started'] == true;
    final playersRaw = data['players'];
    final parsedPlayers = <String, RoomPlayer>{};

    if (playersRaw is Map<String, dynamic>) {
      for (final entry in playersRaw.entries) {
        final rawPlayer = entry.value;
        if (rawPlayer is Map<String, dynamic>) {
          parsedPlayers[entry.key] = RoomPlayer.fromMap(
            rawPlayer,
            defaultLives: _defaultLivesForPlayer(
              rawPlayer,
              mode: mode,
              started: started,
            ),
          );
        } else if (rawPlayer is Map) {
          final normalizedPlayer = rawPlayer.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          parsedPlayers[entry.key] = RoomPlayer.fromMap(
            normalizedPlayer,
            defaultLives: _defaultLivesForPlayer(
              normalizedPlayer,
              mode: mode,
              started: started,
            ),
          );
        }
      }
    }

    return Room(
      id: snapshot.id,
      hostId: (data['hostId'] ?? '').toString(),
      maxPlayers: (data['maxPlayers'] as num?)?.toInt() ?? 4,
      started: started,
      players: parsedPlayers,
      createdAt: _readDate(data['createdAt']),
      startedAt: _readDate(data['startedAt']),
      mode: mode,
      phase: (data['phase'] ?? phaseLobby).toString(),
      currentQuestionIndex:
          (data['currentQuestionIndex'] as num?)?.toInt() ?? 0,
      questionStartedAt: _readDate(data['questionStartedAt']),
      questionIds: _readIntList(data['questionIds']),
      winnerId: data['winnerId'] as String?,
      winnerTeamId: data['winnerTeamId'] as String?,
      roundDurationSeconds:
          (data['roundDurationSeconds'] as num?)?.toInt() ?? 0,
      seriesTarget: (data['seriesTarget'] as num?)?.toInt() ?? 2,
      roundNumber: (data['roundNumber'] as num?)?.toInt() ?? 1,
    );
  }

  int get playerCount => players.length;

  bool get isFull => playerCount >= maxPlayers;

  bool containsPlayer(String userId) => players.containsKey(userId);

  List<String> get playerIds => players.keys.toList(growable: false);

  bool get isRoundBasedMode =>
      mode == modeElimination || mode == modeSurvival || mode == modeSeries;

  bool get isDirectScoreMode =>
      mode == modeBattle || mode == modeBlitz || mode == modeTeamBattle;

  bool get isTeamBattle => mode == modeTeamBattle;

  int get aliveCount => players.values.where((p) => !p.eliminated).length;

  int get survivalAliveCount =>
      players.values.where((p) => !p.eliminated && p.lives > 0).length;

  static bool isBotUserId(String userId) => userId.startsWith(botIdPrefix);

  int get teamBattleTeamCapacity =>
      maxPlayers >= 2 && maxPlayers.isEven ? maxPlayers ~/ 2 : 0;

  int teamSize(String teamId) => players.values
      .where((player) => player.teamId == normalizeTeamId(teamId))
      .length;

  int teamScore(String teamId) => players.values
      .where((player) => player.teamId == normalizeTeamId(teamId))
      .fold(0, (totalScore, player) => totalScore + player.score);

  Map<String, int> get teamSizes => <String, int>{
        teamA: teamSize(teamA),
        teamB: teamSize(teamB),
      };

  Map<String, int> get teamScores => <String, int>{
        teamA: teamScore(teamA),
        teamB: teamScore(teamB),
      };

  List<MapEntry<String, RoomPlayer>> teamEntries(String teamId) =>
      players.entries
          .where((entry) => entry.value.teamId == normalizeTeamId(teamId))
          .toList(growable: false);

  String? get teamBattleBalanceIssue {
    if (!isTeamBattle) return null;
    if (maxPlayers < 2) {
      return 'تتطلب مواجهة الفرق مقعدين على الأقل.';
    }
    if (maxPlayers.isOdd) {
      return 'تتطلب مواجهة الفرق عددًا زوجيًا من المقاعد.';
    }
    if (playerCount > maxPlayers) {
      return 'عدد اللاعبين أكبر من المقاعد المتاحة في الغرفة.';
    }
    final capacity = teamBattleTeamCapacity;
    for (final player in players.values) {
      if (!teamIds.contains(player.teamId)) {
        return 'يجب تعيين كل لاعب إلى الفريق أ أو الفريق ب.';
      }
    }
    if (teamSize(teamA) > capacity || teamSize(teamB) > capacity) {
      return 'أحد الفريقين يضم لاعبين أكثر من المسموح لهذه الغرفة.';
    }
    return null;
  }

  bool get canStartTeamBattleFromLobby => teamBattleBalanceIssue == null;

  bool get isTeamBattleDraw =>
      isTeamBattle &&
      phase == phaseFinished &&
      winnerTeamId == null &&
      teamScore(teamA) == teamScore(teamB);

  static RoomBotProfile botProfile(String userId) {
    final seed = _stableHash(userId);
    return _botProfiles[seed % _botProfiles.length];
  }

  static String? normalizeTeamId(String? value) {
    final normalized = value?.trim().toUpperCase();
    if (normalized == teamA || normalized == teamB) {
      return normalized;
    }
    return null;
  }

  static String botDisplayName(String userId) {
    if (!isBotUserId(userId)) return userId;
    return botProfile(userId).displayName;
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static List<int> _readIntList(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value.map((e) => (e as num).toInt()).toList();
    }
    return const [];
  }

  static int _stableHash(String value) {
    var hash = 5381;
    for (final unit in value.codeUnits) {
      hash = ((hash << 5) + hash) ^ unit;
    }
    return hash & 0x7fffffff;
  }

  static int _defaultLivesForPlayer(
    Map<String, dynamic> playerMap, {
    required String mode,
    required bool started,
  }) {
    if (mode != modeSurvival || !started) {
      return 0;
    }
    if (playerMap.containsKey('lives') || playerMap['eliminated'] == true) {
      return 0;
    }
    return initialSurvivalLives;
  }
}
