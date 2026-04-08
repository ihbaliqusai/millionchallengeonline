import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/room.dart';

class RoomService {
  static const Duration roomExpiry = Duration(minutes: 20);

  RoomService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  DateTime? _lastPurgeAt;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('rooms');

  Stream<List<Room>> watchOpenRooms() {
    _scheduleStaleRoomCleanup();
    return _rooms.snapshots().map((snapshot) {
      final cutoff = DateTime.now().subtract(roomExpiry);
      final rooms = snapshot.docs
          .map(Room.fromSnapshot)
          .where(
            (room) =>
                !room.started &&
                room.playerCount > 0 &&
                !_isExpiredOpenRoom(room, cutoff: cutoff),
          )
          .toList(growable: false)
        ..sort((a, b) {
          final left = a.createdAt;
          final right = b.createdAt;
          if (left == null && right == null) return a.id.compareTo(b.id);
          if (left == null) return 1;
          if (right == null) return -1;
          return right.compareTo(left);
        });

      return rooms;
    });
  }

  Stream<Room?> watchRoom(String roomId) {
    _scheduleStaleRoomCleanup();
    return _rooms.doc(roomId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final room = Room.fromSnapshot(snapshot);
      if (_isExpiredOpenRoom(room)) {
        unawaited(_deleteRoomSilently(room.id));
        return null;
      }
      return room;
    });
  }

  Future<void> purgeStaleRooms({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastPurgeAt != null &&
        now.difference(_lastPurgeAt!) < const Duration(minutes: 2)) {
      return;
    }

    _lastPurgeAt = now;
    final snapshot = await _rooms.get();
    final cutoff = now.subtract(roomExpiry);
    for (final doc in snapshot.docs) {
      final room = Room.fromSnapshot(doc);
      if (_isExpiredOpenRoom(room, cutoff: cutoff)) {
        await _deleteRoomSilently(doc.id);
      }
    }
  }

  Future<String> createRoom({
    required String hostId,
    int maxPlayers = 4,
  }) =>
      _guard(() async {
        await purgeStaleRooms(force: true);
        final doc = _rooms.doc();
        await doc.set(<String, dynamic>{
          'hostId': hostId,
          'maxPlayers': maxPlayers,
          'started': false,
          'players': <String, dynamic>{
            hostId: const RoomPlayer(score: 0, ready: true).toMap(),
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
        return doc.id;
      });

  Future<void> joinRoom({
    required String roomId,
    required String userId,
  }) =>
      _guard(() async {
        await purgeStaleRooms(force: true);
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw StateError('This room no longer exists.');
          }

          final room = Room.fromSnapshot(snapshot);
          if (_isExpiredOpenRoom(room)) {
            transaction.delete(ref);
            throw StateError(
              'This room expired after 20 minutes without starting.',
            );
          }
          if (room.started) {
            throw StateError('This room has already started.');
          }
          if (room.containsPlayer(userId)) {
            return;
          }
          if (room.isFull) {
            throw StateError('This room is already full.');
          }

          final updates = <String, dynamic>{
            'players.$userId': const RoomPlayer(score: 0, ready: true).toMap(),
          };

          final nextPlayerCount = room.playerCount + 1;
          if (nextPlayerCount >= room.maxPlayers) {
            updates['started'] = true;
            updates['startedAt'] = FieldValue.serverTimestamp();

            for (final playerId in <String>[...room.playerIds, userId]) {
              updates['players.$playerId.ready'] = false;
              updates['players.$playerId.answeredCount'] = 0;
              updates['players.$playerId.completedAt'] = FieldValue.delete();
              updates['players.$playerId.score'] = 0;
            }
          }

          transaction.update(ref, updates);
        });
      });

  Future<void> setPlayerReady({
    required String roomId,
    required String userId,
    required bool ready,
  }) =>
      _guard(() async {
        await _rooms.doc(roomId).update(<String, dynamic>{
          'players.$userId.ready': ready,
        });
      });

  Future<void> startRoom({
    required String roomId,
    required String userId,
  }) =>
      _guard(() async {
        await purgeStaleRooms(force: true);
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw StateError('This room no longer exists.');
          }

          final room = Room.fromSnapshot(snapshot);
          if (_isExpiredOpenRoom(room)) {
            transaction.delete(ref);
            throw StateError(
              'This room expired after 20 minutes without starting.',
            );
          }
          if (room.hostId != userId) {
            throw StateError('Only the host can start the room.');
          }
          if (room.started) {
            return;
          }

          final updates = <String, dynamic>{
            'started': true,
            'startedAt': FieldValue.serverTimestamp(),
          };

          final existingPlayerIds = <String>[...room.playerIds];
          final missingPlayers = room.maxPlayers - room.playerCount;
          for (var slot = 0; slot < missingPlayers; slot++) {
            final botId = _buildBotId(room.id, slot + 1);
            updates['players.$botId'] =
                const RoomPlayer(score: 0, ready: false).toMap();
          }

          for (final playerId in existingPlayerIds) {
            updates['players.$playerId.ready'] = false;
            updates['players.$playerId.answeredCount'] = 0;
            updates['players.$playerId.completedAt'] = FieldValue.delete();
            updates['players.$playerId.score'] = 0;
          }

          transaction.update(ref, updates);
        });
      });

  Future<void> seedBotScores({
    required String roomId,
    required int totalQuestions,
  }) =>
      _guard(() async {
        if (totalQuestions <= 0) return;

        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw StateError('This room no longer exists.');
          }

          final room = Room.fromSnapshot(snapshot);
          final updates = <String, dynamic>{};

          for (final playerId in room.playerIds.where(Room.isBotUserId)) {
            final player = room.players[playerId];
            if (player == null) continue;
            if (player.completedAt != null &&
                player.answeredCount >= totalQuestions) {
              continue;
            }

            updates['players.$playerId.score'] =
                _buildBotScore(roomId, playerId, totalQuestions);
            updates['players.$playerId.answeredCount'] = totalQuestions;
            updates['players.$playerId.completedAt'] =
                FieldValue.serverTimestamp();
          }

          if (updates.isNotEmpty) {
            transaction.update(ref, updates);
          }
        });
      });

  Future<void> submitFinalScore({
    required String roomId,
    required String userId,
    required int score,
    required int answeredCount,
  }) =>
      _guard(() async {
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw StateError('This room no longer exists.');
          }

          final room = Room.fromSnapshot(snapshot);
          if (!room.containsPlayer(userId)) {
            throw StateError('You are no longer in this room.');
          }

          final current = room.players[userId]!;
          if (current.completedAt != null &&
              current.score >= score &&
              current.answeredCount >= answeredCount) {
            return;
          }

          transaction.update(ref, <String, dynamic>{
            'players.$userId.score': score,
            'players.$userId.answeredCount': answeredCount,
            'players.$userId.completedAt': FieldValue.serverTimestamp(),
          });
        });
      });

  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  }) =>
      _guard(() async {
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) return;

          final room = Room.fromSnapshot(snapshot);
          if (!room.containsPlayer(userId)) return;

          final remainingPlayers = Map<String, RoomPlayer>.from(room.players)
            ..remove(userId);

          if (remainingPlayers.isEmpty) {
            transaction.delete(ref);
            return;
          }

          final nextHostId =
              room.hostId == userId ? remainingPlayers.keys.first : room.hostId;

          transaction.update(ref, <String, dynamic>{
            'hostId': nextHostId,
            'players.$userId': FieldValue.delete(),
          });
        });
      });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw StateError(
          'Firestore rules are blocking room updates. Publish the latest rules for the rooms collection in Firebase Console, then try again.',
        );
      }
      throw StateError(e.message ?? e.code);
    }
  }

  static String _buildBotId(String roomId, int slot) =>
      '${Room.botIdPrefix}${roomId}_$slot';

  bool _isExpiredOpenRoom(
    Room room, {
    DateTime? cutoff,
  }) {
    if (room.started) return false;
    final createdAt = room.createdAt;
    if (createdAt == null) return false;
    final effectiveCutoff = cutoff ?? DateTime.now().subtract(roomExpiry);
    return !createdAt.isAfter(effectiveCutoff);
  }

  void _scheduleStaleRoomCleanup() {
    unawaited(purgeStaleRooms());
  }

  Future<void> _deleteRoomSilently(String roomId) async {
    try {
      await _rooms.doc(roomId).delete();
    } catch (_) {
      // Ignore cleanup failures so room browsing stays responsive.
    }
  }

  static int _buildBotScore(
    String roomId,
    String botId,
    int totalQuestions,
  ) {
    final minScore = math.max(1, totalQuestions ~/ 3);
    final hash = _stableHash('$roomId|$botId');
    final span = math.max(1, totalQuestions - minScore + 1);
    return math.min(totalQuestions, minScore + (hash % span));
  }

  static int _stableHash(String value) {
    var hash = 5381;
    for (final unit in value.codeUnits) {
      hash = ((hash << 5) + hash) ^ unit;
    }
    return hash & 0x7fffffff;
  }
}
