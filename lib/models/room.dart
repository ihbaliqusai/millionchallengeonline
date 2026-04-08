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
  });

  final int score;
  final bool ready;
  final int answeredCount;
  final DateTime? completedAt;

  factory RoomPlayer.fromMap(Map<String, dynamic> map) => RoomPlayer(
        score: (map['score'] as num?)?.toInt() ?? 0,
        ready: map['ready'] == true,
        answeredCount: (map['answeredCount'] as num?)?.toInt() ?? 0,
        completedAt: _readDate(map['completedAt']),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'score': score,
        'ready': ready,
        'answeredCount': answeredCount,
        if (completedAt != null)
          'completedAt': Timestamp.fromDate(completedAt!),
      };

  RoomPlayer copyWith({
    int? score,
    bool? ready,
    int? answeredCount,
    DateTime? completedAt,
  }) {
    return RoomPlayer(
      score: score ?? this.score,
      ready: ready ?? this.ready,
      answeredCount: answeredCount ?? this.answeredCount,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }
}

class Room {
  static const String botIdPrefix = 'bot_room_';
  static const List<RoomBotProfile> _botProfiles = <RoomBotProfile>[
    RoomBotProfile(
      displayName: 'Nova AI',
      intelligence: 96,
      avatarSeed: 0,
      nativePhoto: 'drawable:avatar21',
    ),
    RoomBotProfile(
      displayName: 'Falcon AI',
      intelligence: 89,
      avatarSeed: 1,
      nativePhoto: 'drawable:avatar32',
    ),
    RoomBotProfile(
      displayName: 'Atlas AI',
      intelligence: 84,
      avatarSeed: 2,
      nativePhoto: 'drawable:avatar43',
    ),
    RoomBotProfile(
      displayName: 'Blaze AI',
      intelligence: 77,
      avatarSeed: 3,
      nativePhoto: 'drawable:avatar54',
    ),
    RoomBotProfile(
      displayName: 'Pixel AI',
      intelligence: 71,
      avatarSeed: 4,
      nativePhoto: 'drawable:avatar65',
    ),
    RoomBotProfile(
      displayName: 'Oracle AI',
      intelligence: 66,
      avatarSeed: 5,
      nativePhoto: 'drawable:avatar76',
    ),
    RoomBotProfile(
      displayName: 'Turbo AI',
      intelligence: 59,
      avatarSeed: 6,
      nativePhoto: 'drawable:avatar87',
    ),
    RoomBotProfile(
      displayName: 'Titan AI',
      intelligence: 53,
      avatarSeed: 7,
      nativePhoto: 'drawable:avatar98',
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
  });

  final String id;
  final String hostId;
  final int maxPlayers;
  final bool started;
  final Map<String, RoomPlayer> players;
  final DateTime? createdAt;
  final DateTime? startedAt;

  factory Room.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final playersRaw = data['players'];
    final parsedPlayers = <String, RoomPlayer>{};

    if (playersRaw is Map<String, dynamic>) {
      for (final entry in playersRaw.entries) {
        final rawPlayer = entry.value;
        if (rawPlayer is Map<String, dynamic>) {
          parsedPlayers[entry.key] = RoomPlayer.fromMap(rawPlayer);
        } else if (rawPlayer is Map) {
          parsedPlayers[entry.key] = RoomPlayer.fromMap(
            rawPlayer.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          );
        }
      }
    }

    return Room(
      id: snapshot.id,
      hostId: (data['hostId'] ?? '').toString(),
      maxPlayers: (data['maxPlayers'] as num?)?.toInt() ?? 4,
      started: data['started'] == true,
      players: parsedPlayers,
      createdAt: _readDate(data['createdAt']),
      startedAt: _readDate(data['startedAt']),
    );
  }

  int get playerCount => players.length;

  bool get isFull => playerCount >= maxPlayers;

  bool containsPlayer(String userId) => players.containsKey(userId);

  List<String> get playerIds => players.keys.toList(growable: false);

  static bool isBotUserId(String userId) => userId.startsWith(botIdPrefix);

  static RoomBotProfile botProfile(String userId) {
    final seed = _stableHash(userId);
    return _botProfiles[seed % _botProfiles.length];
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

  static int _stableHash(String value) {
    var hash = 5381;
    for (final unit in value.codeUnits) {
      hash = ((hash << 5) + hash) ^ unit;
    }
    return hash & 0x7fffffff;
  }
}
