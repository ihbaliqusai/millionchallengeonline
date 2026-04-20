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
      expect(after.players['p2']!.answeredCount, before.players['p2']!.answeredCount);
      expect(after.players['p2']!.currentAnswer, before.players['p2']!.currentAnswer);
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
      expect(botPlayers.every((player) => player.currentAnswer != null), isTrue);
      expect(botPlayers.every((player) => player.answeredCount == 1), isTrue);
      expect(botPlayers.every((player) => player.lives >= 2), isTrue);
    });
  });

  group('RoomService non-survival regressions', () {
    late FakeFirebaseFirestore firestore;
    late RoomService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = RoomService(firestore: firestore);
    });

    test('elimination next round clears current answer for surviving players', () async {
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
