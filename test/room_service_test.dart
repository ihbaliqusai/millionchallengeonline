import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millionaire_flutter_exact/models/room.dart';
import 'package:millionaire_flutter_exact/services/room_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RoomService survival mode', () {
    late FakeFirebaseFirestore firestore;
    late RoomService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = RoomService(firestore: firestore);
    });

    test('backward-compatible survival docs default missing lives', () async {
      await firestore.collection('rooms').doc('legacy').set({
        'hostId': 'host',
        'maxPlayers': 2,
        'mode': Room.modeSurvival,
        'phase': Room.phasePlayingRound,
        'started': true,
        'players': {
          'host': {
            'score': 0,
            'ready': false,
          },
          'p2': {
            'score': 1,
            'ready': false,
            'eliminated': true,
          },
        },
      });

      final room = await _loadRoom(firestore, 'legacy');
      expect(room.players['host']!.lives, Room.initialSurvivalLives);
      expect(room.players['p2']!.lives, 0);
    });

    test('start survival room initializes lives correctly', () async {
      final roomId = await service.createRoom(
        hostId: 'host',
        maxPlayers: 4,
        mode: Room.modeSurvival,
      );
      await service.joinRoom(roomId: roomId, userId: 'p2');

      await service.startRoom(roomId: roomId, userId: 'host');

      final room = await _loadRoom(firestore, roomId);
      expect(room.started, isTrue);
      expect(room.phase, Room.phasePlayingRound);
      expect(room.roundNumber, 1);
      expect(room.playerCount, 4);
      for (final player in room.players.values) {
        expect(player.lives, Room.initialSurvivalLives);
        expect(player.eliminated, isFalse);
        expect(player.answeredCount, 0);
        expect(player.currentAnswer, isNull);
      }
    });

    test('wrong answer decrements life', () async {
      final roomId = await _createStartedSurvivalRoom(
        service,
        maxPlayers: 2,
        extraPlayers: const ['p2'],
      );

      await service.submitSurvivalAnswer(
        roomId: roomId,
        userId: 'p2',
        answer: 'A',
        isCorrect: false,
      );

      final room = await _loadRoom(firestore, roomId);
      final player = room.players['p2']!;
      expect(player.lives, 2);
      expect(player.eliminated, isFalse);
      expect(player.score, 0);
      expect(player.answeredCount, 1);
      expect(player.currentAnswer, 'A');
      expect(room.phase, Room.phasePlayingRound);
    });

    test('life reaching zero eliminates player', () async {
      final roomId = await _createStartedSurvivalRoom(
        service,
        maxPlayers: 3,
        extraPlayers: const ['p2', 'p3'],
      );

      await _playSurvivalRound(service, roomId, {
        'host': true,
        'p2': false,
        'p3': true,
      });
      await service.startNextSurvivalRound(roomId: roomId, userId: 'host');

      await _playSurvivalRound(service, roomId, {
        'host': true,
        'p2': false,
        'p3': true,
      });
      await service.startNextSurvivalRound(roomId: roomId, userId: 'host');

      await _playSurvivalRound(service, roomId, {
        'host': true,
        'p2': false,
        'p3': true,
      });

      final room = await _loadRoom(firestore, roomId);
      expect(room.phase, Room.phaseRoundOver);
      expect(room.players['p2']!.lives, 0);
      expect(room.players['p2']!.eliminated, isTrue);
      expect(room.winnerId, isNull);
    });

    test('eliminated player cannot answer', () async {
      final roomId = await _createStartedSurvivalRoom(
        service,
        maxPlayers: 3,
        extraPlayers: const ['p2', 'p3'],
      );

      for (var round = 0; round < 3; round++) {
        await _playSurvivalRound(service, roomId, {
          'host': true,
          'p2': false,
          'p3': true,
        });
        if (round < 2) {
          await service.startNextSurvivalRound(roomId: roomId, userId: 'host');
        }
      }

      await service.startNextSurvivalRound(roomId: roomId, userId: 'host');
      final before = await _loadRoom(firestore, roomId);

      await service.submitSurvivalAnswer(
        roomId: roomId,
        userId: 'p2',
        answer: 'B',
        isCorrect: true,
      );

      final after = await _loadRoom(firestore, roomId);
      expect(after.players['p2']!.lives, before.players['p2']!.lives);
      expect(after.players['p2']!.score, before.players['p2']!.score);
      expect(after.players['p2']!.answeredCount,
          before.players['p2']!.answeredCount);
      expect(after.players['p2']!.currentAnswer,
          before.players['p2']!.currentAnswer);
    });

    test('round moves to round_over when multiple players survive', () async {
      final roomId = await _createStartedSurvivalRoom(
        service,
        maxPlayers: 2,
        extraPlayers: const ['p2'],
      );

      await _playSurvivalRound(service, roomId, {
        'p2': false,
        'host': true,
      });

      final room = await _loadRoom(firestore, roomId);
      expect(room.phase, Room.phaseRoundOver);
      expect(room.winnerId, isNull);
      expect(room.survivalAliveCount, 2);
    });

    test('round moves to finished when one survivor remains', () async {
      final roomId = await _createStartedSurvivalRoom(
        service,
        maxPlayers: 2,
        extraPlayers: const ['p2'],
      );

      for (var round = 0; round < 3; round++) {
        await _playSurvivalRound(service, roomId, {
          'p2': false,
          'host': true,
        });
        if (round < 2) {
          await service.startNextSurvivalRound(roomId: roomId, userId: 'host');
        }
      }

      final room = await _loadRoom(firestore, roomId);
      expect(room.phase, Room.phaseFinished);
      expect(room.winnerId, 'host');
      expect(room.players['p2']!.lives, 0);
      expect(room.players['p2']!.eliminated, isTrue);
    });

    test('next round resets only per-round fields for alive players', () async {
      final roomId = await _createStartedSurvivalRoom(
        service,
        maxPlayers: 3,
        extraPlayers: const ['p2', 'p3'],
      );

      await _playSurvivalRound(service, roomId, {
        'host': true,
        'p2': false,
        'p3': true,
      });

      final roundOver = await _loadRoom(firestore, roomId);
      expect(roundOver.phase, Room.phaseRoundOver);
      expect(roundOver.players['host']!.score, 1);
      expect(roundOver.players['p2']!.lives, 2);
      expect(roundOver.players['p3']!.score, 1);

      await service.startNextSurvivalRound(roomId: roomId, userId: 'host');

      final nextRound = await _loadRoom(firestore, roomId);
      expect(nextRound.phase, Room.phasePlayingRound);
      expect(nextRound.roundNumber, 2);

      for (final id in const ['host', 'p2', 'p3']) {
        final player = nextRound.players[id]!;
        expect(player.answeredCount, 0);
        expect(player.currentAnswer, isNull);
        expect(player.completedAt, isNull);
      }
      expect(nextRound.players['host']!.score, 1);
      expect(nextRound.players['p2']!.score, 0);
      expect(nextRound.players['p2']!.lives, 2);
      expect(nextRound.players['p3']!.score, 1);
    });

    test('survival bots answer through the same room rules', () async {
      final roomId = await service.createRoom(
        hostId: 'host',
        maxPlayers: 3,
        mode: Room.modeSurvival,
      );
      await service.startRoom(roomId: roomId, userId: 'host');

      await service.submitSurvivalAnswer(
        roomId: roomId,
        userId: 'host',
        answer: 'A',
        isCorrect: true,
      );

      final room = await _loadRoom(firestore, roomId);
      expect(room.phase, Room.phaseRoundOver);
      final botPlayers = room.players.entries
          .where((entry) => Room.isBotUserId(entry.key))
          .map((entry) => entry.value)
          .toList();
      expect(botPlayers, isNotEmpty);
      expect(
          botPlayers.every((player) => player.currentAnswer != null), isTrue);
      expect(botPlayers.every((player) => player.answeredCount == 1), isTrue);
      expect(botPlayers.every((player) => player.lives >= 2), isTrue);
    });
  });

  group('RoomService team battle', () {
    late FakeFirebaseFirestore firestore;
    late RoomService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = RoomService(firestore: firestore);
    });

    test('creating a Team Battle room seeds the host on Team A', () async {
      final roomId = await service.createRoom(
        hostId: 'host',
        maxPlayers: 4,
        mode: Room.modeTeamBattle,
      );

      final room = await _loadRoom(firestore, roomId);
      expect(room.mode, Room.modeTeamBattle);
      expect(room.phase, Room.phaseLobby);
      expect(room.started, isFalse);
      expect(room.players['host']!.teamId, Room.teamA);
      expect(room.players['host']!.score, 0);
      expect(room.players['host']!.answeredCount, 0);
      expect(room.winnerTeamId, isNull);
    });

    test('joining assigns balanced teams and switching works before start',
        () async {
      final roomId = await service.createRoom(
        hostId: 'host',
        maxPlayers: 4,
        mode: Room.modeTeamBattle,
      );

      await service.joinRoom(roomId: roomId, userId: 'p2');

      var room = await _loadRoom(firestore, roomId);
      expect(room.players['host']!.teamId, Room.teamA);
      expect(room.players['p2']!.teamId, Room.teamB);

      await service.switchTeam(roomId: roomId, userId: 'p2');

      room = await _loadRoom(firestore, roomId);
      expect(room.players['p2']!.teamId, Room.teamA);
      expect(room.teamSize(Room.teamA), 2);
      expect(room.teamSize(Room.teamB), 0);
    });

    test('starting rejects invalid Team Battle distributions', () async {
      final roomId = await service.createRoom(
        hostId: 'host',
        maxPlayers: 4,
        mode: Room.modeTeamBattle,
      );
      await service.joinRoom(roomId: roomId, userId: 'p2');
      await service.joinRoom(roomId: roomId, userId: 'p3');

      await firestore.collection('rooms').doc(roomId).update({
        'players.host.teamId': Room.teamA,
        'players.p2.teamId': Room.teamA,
        'players.p3.teamId': Room.teamA,
      });

      await expectLater(
        service.startRoom(roomId: roomId, userId: 'host'),
        throwsA(isA<StateError>()),
      );

      final room = await _loadRoom(firestore, roomId);
      expect(room.started, isFalse);
      expect(room.phase, Room.phaseLobby);
    });

    test('balanced full Team Battle room auto starts cleanly', () async {
      final roomId = await service.createRoom(
        hostId: 'host',
        maxPlayers: 4,
        mode: Room.modeTeamBattle,
      );
      await service.joinRoom(roomId: roomId, userId: 'p2');
      await service.joinRoom(roomId: roomId, userId: 'p3');
      await service.joinRoom(roomId: roomId, userId: 'p4');

      final room = await _loadRoom(firestore, roomId);
      expect(room.started, isTrue);
      expect(room.phase, Room.phasePlaying);
      expect(room.playerCount, 4);
      expect(room.teamSize(Room.teamA), 2);
      expect(room.teamSize(Room.teamB), 2);
      expect(
          room.players.values.every((player) => player.ready == false), isTrue);
    });

    test('host start fills bots while preserving a valid Team Battle balance',
        () async {
      final roomId = await service.createRoom(
        hostId: 'host',
        maxPlayers: 4,
        mode: Room.modeTeamBattle,
      );
      await service.joinRoom(roomId: roomId, userId: 'p2');
      await service.joinRoom(roomId: roomId, userId: 'p3');

      await service.startRoom(roomId: roomId, userId: 'host');

      final room = await _loadRoom(firestore, roomId);
      final botEntries = room.players.entries
          .where((entry) => Room.isBotUserId(entry.key))
          .toList(growable: false);

      expect(room.started, isTrue);
      expect(room.phase, Room.phasePlaying);
      expect(room.playerCount, 4);
      expect(room.teamSize(Room.teamA), 2);
      expect(room.teamSize(Room.teamB), 2);
      expect(botEntries, hasLength(1));
      expect(botEntries.single.value.teamId, Room.teamB);
    });

    test('final score submission rolls up team totals and resolves winner',
        () async {
      final roomId = await service.createRoom(
        hostId: 'host',
        maxPlayers: 4,
        mode: Room.modeTeamBattle,
      );
      await service.joinRoom(roomId: roomId, userId: 'p2');
      await service.joinRoom(roomId: roomId, userId: 'p3');
      await service.startRoom(roomId: roomId, userId: 'host');

      await service.submitFinalScore(
        roomId: roomId,
        userId: 'host',
        score: 15,
        answeredCount: 15,
      );
      await service.submitFinalScore(
        roomId: roomId,
        userId: 'p2',
        score: 0,
        answeredCount: 15,
      );
      await service.submitFinalScore(
        roomId: roomId,
        userId: 'p3',
        score: 15,
        answeredCount: 15,
      );

      final room = await _loadRoom(firestore, roomId);
      final botEntries = room.players.entries
          .where((entry) => Room.isBotUserId(entry.key))
          .toList(growable: false);
      final teamAContribution = room
          .teamEntries(Room.teamA)
          .fold<int>(0, (totalScore, entry) => totalScore + entry.value.score);
      final teamBContribution = room
          .teamEntries(Room.teamB)
          .fold<int>(0, (totalScore, entry) => totalScore + entry.value.score);

      expect(room.phase, Room.phaseFinished);
      expect(room.winnerId, isNull);
      expect(room.winnerTeamId, Room.teamA);
      expect(room.teamScore(Room.teamA), 30);
      expect(room.teamScore(Room.teamB), teamBContribution);
      expect(room.teamScore(Room.teamA), teamAContribution);
      expect(botEntries, hasLength(1));
      expect(botEntries.single.value.completedAt, isNotNull);
      expect(botEntries.single.value.answeredCount, 15);
    });

    test('tied Team Battle totals finish as a draw with no winner team',
        () async {
      final roomId = await service.createRoom(
        hostId: 'host',
        maxPlayers: 2,
        mode: Room.modeTeamBattle,
      );
      await service.joinRoom(roomId: roomId, userId: 'p2');

      await service.submitFinalScore(
        roomId: roomId,
        userId: 'host',
        score: 9,
        answeredCount: 15,
      );
      await service.submitFinalScore(
        roomId: roomId,
        userId: 'p2',
        score: 9,
        answeredCount: 15,
      );

      final room = await _loadRoom(firestore, roomId);
      expect(room.phase, Room.phaseFinished);
      expect(room.winnerId, isNull);
      expect(room.winnerTeamId, isNull);
      expect(room.isTeamBattleDraw, isTrue);
      expect(room.teamScore(Room.teamA), 9);
      expect(room.teamScore(Room.teamB), 9);
    });

    test('players cannot switch teams after Team Battle has started', () async {
      final roomId = await service.createRoom(
        hostId: 'host',
        maxPlayers: 2,
        mode: Room.modeTeamBattle,
      );
      await service.joinRoom(roomId: roomId, userId: 'p2');

      await expectLater(
        service.switchTeam(roomId: roomId, userId: 'host'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('RoomService non-survival regressions', () {
    late FakeFirebaseFirestore firestore;
    late RoomService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = RoomService(firestore: firestore);
    });

    test('elimination next round clears current answer for surviving players',
        () async {
      final roomId = await service.createRoom(
        hostId: 'host',
        maxPlayers: 3,
        mode: Room.modeElimination,
      );
      await service.joinRoom(roomId: roomId, userId: 'p2');
      await service.joinRoom(roomId: roomId, userId: 'p3');
      await service.startRoom(roomId: roomId, userId: 'host');

      await service.submitEliminationAnswer(
        roomId: roomId,
        userId: 'host',
        answer: 'A',
        isCorrect: true,
      );
      await service.submitEliminationAnswer(
        roomId: roomId,
        userId: 'p2',
        answer: 'B',
        isCorrect: true,
      );
      await service.submitEliminationAnswer(
        roomId: roomId,
        userId: 'p3',
        answer: 'C',
        isCorrect: true,
      );

      await firestore.collection('rooms').doc(roomId).update({
        'players.host.score': 2,
        'players.p2.score': 1,
        'players.p3.score': 0,
      });

      await service.processEliminationRound(roomId: roomId);
      await service.startNextEliminationRound(roomId: roomId, userId: 'host');

      final room = await _loadRoom(firestore, roomId);
      expect(room.phase, Room.phasePlayingRound);
      expect(room.players['host']!.currentAnswer, isNull);
      expect(room.players['p2']!.currentAnswer, isNull);
      expect(room.players['host']!.answeredCount, 0);
      expect(room.players['p2']!.answeredCount, 0);
      expect(room.players['host']!.completedAt, isNull);
      expect(room.players['p2']!.completedAt, isNull);
      expect(room.players['host']!.score, 0);
      expect(room.players['p2']!.score, 0);
    });

    test('battle rooms still finalize an individual winner after direct scores',
        () async {
      final roomId = await service.createRoom(
        hostId: 'host',
        maxPlayers: 2,
        mode: Room.modeBattle,
      );
      await service.joinRoom(roomId: roomId, userId: 'p2');

      await service.submitFinalScore(
        roomId: roomId,
        userId: 'host',
        score: 7,
        answeredCount: 15,
      );
      await service.submitFinalScore(
        roomId: roomId,
        userId: 'p2',
        score: 5,
        answeredCount: 15,
      );

      final room = await _loadRoom(firestore, roomId);
      expect(room.phase, Room.phaseFinished);
      expect(room.winnerId, 'host');
      expect(room.winnerTeamId, isNull);
    });

    test('mid-game join stores the replaced bot seat id for resume', () async {
      final roomId = await service.createRoom(
        hostId: 'host',
        maxPlayers: 2,
        mode: Room.modeBattle,
      );
      await service.startRoom(roomId: roomId, userId: 'host');

      var room = await _loadRoom(firestore, roomId);
      final botEntry = room.players.entries
          .firstWhere((entry) => Room.isBotUserId(entry.key));

      await firestore.collection('rooms').doc(roomId).update({
        'players.${botEntry.key}.score': 7,
        'players.${botEntry.key}.answeredCount': 4,
      });

      final joinResult = await service.joinRoom(roomId: roomId, userId: 'p2');

      room = await _loadRoom(firestore, roomId);
      final joinedPlayer = room.players['p2']!;
      expect(joinResult.joinedMidGame, isTrue);
      expect(joinResult.seatSourceId, botEntry.key);
      expect(joinedPlayer.seatSourceId, botEntry.key);
      expect(joinedPlayer.score, 7);
      expect(joinedPlayer.answeredCount, 4);
      expect(room.players.containsKey(botEntry.key), isFalse);
    });

    test('purge removes rooms with no active human players', () async {
      await firestore.collection('rooms').doc('bots_only').set({
        'hostId': 'host',
        'maxPlayers': 2,
        'mode': Room.modeBattle,
        'phase': Room.phasePlaying,
        'started': true,
        'startedAt': Timestamp.fromDate(DateTime.now()),
        'players': {
          'bot_room_bots_only_1': {
            'score': 0,
            'ready': false,
          },
          'host': {
            'score': 0,
            'ready': false,
            'disconnected': true,
          },
        },
      });

      await service.purgeStaleRooms(force: true);

      final snapshot =
          await firestore.collection('rooms').doc('bots_only').get();
      expect(snapshot.exists, isFalse);
    });

    test('blitz native result is persisted after the timer expires', () async {
      final roomId = await service.createRoom(
        hostId: 'host',
        maxPlayers: 2,
        mode: Room.modeBlitz,
        roundDurationSeconds: 60,
      );
      await service.joinRoom(roomId: roomId, userId: 'p2');

      await firestore.collection('rooms').doc(roomId).update({
        'started': true,
        'phase': Room.phasePlaying,
        'startedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      });

      await service.finalizeBlitzMatchFromNative(
        roomId: roomId,
        userId: 'host',
        score: 11,
        answeredCount: 11,
      );

      final room = await _loadRoom(firestore, roomId);
      expect(room.phase, Room.phaseFinished);
      expect(room.players['host']!.score, 11);
      expect(room.players['host']!.answeredCount, 11);
      expect(room.players['host']!.completedAt, isNotNull);
      expect(room.winnerId, isNotNull);
    });
  });
}

Future<String> _createStartedSurvivalRoom(
  RoomService service, {
  required int maxPlayers,
  List<String> extraPlayers = const [],
}) async {
  final roomId = await service.createRoom(
    hostId: 'host',
    maxPlayers: maxPlayers,
    mode: Room.modeSurvival,
  );
  for (final playerId in extraPlayers) {
    await service.joinRoom(roomId: roomId, userId: playerId);
  }
  await service.startRoom(roomId: roomId, userId: 'host');
  return roomId;
}

Future<void> _playSurvivalRound(
  RoomService service,
  String roomId,
  Map<String, bool> answers,
) async {
  for (final entry in answers.entries) {
    await service.submitSurvivalAnswer(
      roomId: roomId,
      userId: entry.key,
      answer: entry.key,
      isCorrect: entry.value,
    );
  }
}

Future<Room> _loadRoom(
  FirebaseFirestore firestore,
  String roomId,
) async {
  final snapshot = await firestore.collection('rooms').doc(roomId).get();
  return Room.fromSnapshot(snapshot);
}
