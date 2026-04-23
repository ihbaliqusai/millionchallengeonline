import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/room.dart';

class RoomService {
  static const Duration roomExpiry = Duration(minutes: 20);
  static const int _defaultDirectScoreQuestionCount = 15;

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
    String mode = Room.modeBattle,
    int roundDurationSeconds = 60,
    int seriesTarget = 2,
  }) =>
      _guard(() async {
        _validateCreateRoomOptions(mode: mode, maxPlayers: maxPlayers);
        await purgeStaleRooms(force: true);
        final doc = _rooms.doc();
        await doc.set(<String, dynamic>{
          'hostId': hostId,
          'maxPlayers': maxPlayers,
          'mode': mode,
          'phase': Room.phaseLobby,
          'started': false,
          'players': <String, dynamic>{
            hostId: RoomPlayer(
              score: 0,
              ready: true,
              teamId: mode == Room.modeTeamBattle ? Room.teamA : null,
            ).toMap(),
          },
          'createdAt': FieldValue.serverTimestamp(),
          if (mode == Room.modeBlitz)
            'roundDurationSeconds': roundDurationSeconds,
          if (mode == Room.modeSeries) 'seriesTarget': seriesTarget,
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
            throw StateError('هذه الغرفة لم تعد موجودة.');
          }

          final room = Room.fromSnapshot(snapshot);
          if (_isExpiredOpenRoom(room)) {
            transaction.delete(ref);
            throw StateError(
              'انتهت صلاحية هذه الغرفة بعد 20 دقيقة من دون بدء.',
            );
          }
          if (room.started) {
            throw StateError('هذه الغرفة بدأت بالفعل.');
          }
          if (room.containsPlayer(userId)) {
            return;
          }
          if (room.isFull) {
            throw StateError('هذه الغرفة ممتلئة بالفعل.');
          }

          final joiningPlayer = RoomPlayer(
            score: 0,
            ready: true,
            teamId: room.mode == Room.modeTeamBattle
                ? _assignLobbyTeamId(room.players, room.maxPlayers)
                : null,
          );
          final updates = <String, dynamic>{
            'players.$userId': joiningPlayer.toMap(),
          };

          final nextPlayerCount = room.playerCount + 1;
          // Modes that require host initiation (question IDs or round tracking).
          const hostStartModes = {
            Room.modeElimination,
            Room.modeSurvival,
            Room.modeSeries,
          };
          if (nextPlayerCount >= room.maxPlayers &&
              !hostStartModes.contains(room.mode)) {
            if (room.mode == Room.modeTeamBattle) {
              final previewPlayers = Map<String, RoomPlayer>.from(room.players)
                ..[userId] = joiningPlayer;
              try {
                updates.addAll(
                  _buildTeamBattleStartUpdates(
                    room: room,
                    lobbyPlayers: previewPlayers,
                  ),
                );
              } on StateError {
                // Leave the room in lobby so players can rebalance teams manually.
              }
            } else {
              updates['started'] = true;
              updates['startedAt'] = FieldValue.serverTimestamp();
              updates['phase'] = Room.phasePlaying;
              updates['winnerId'] = FieldValue.delete();
              updates['winnerTeamId'] = FieldValue.delete();

              for (final playerId in <String>[...room.playerIds, userId]) {
                updates['players.$playerId.ready'] = false;
                updates['players.$playerId.answeredCount'] = 0;
                updates['players.$playerId.completedAt'] = FieldValue.delete();
                updates['players.$playerId.currentAnswer'] =
                    FieldValue.delete();
                updates['players.$playerId.score'] = 0;
              }
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
    List<int>? eliminationQuestionIds,
  }) =>
      _guard(() async {
        await purgeStaleRooms(force: true);
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw StateError('هذه الغرفة لم تعد موجودة.');
          }

          final room = Room.fromSnapshot(snapshot);
          if (_isExpiredOpenRoom(room)) {
            transaction.delete(ref);
            throw StateError(
              'انتهت صلاحية هذه الغرفة بعد 20 دقيقة من دون بدء.',
            );
          }
          if (room.hostId != userId) {
            throw StateError('فقط المضيف يمكنه بدء الغرفة.');
          }
          if (room.started) {
            return;
          }

          final updates = <String, dynamic>{
            'started': true,
            'startedAt': FieldValue.serverTimestamp(),
            'winnerId': FieldValue.delete(),
            'winnerTeamId': FieldValue.delete(),
          };
          if (eliminationQuestionIds != null &&
              (room.mode == Room.modeElimination ||
                  room.mode == Room.modeSurvival)) {
            updates['questionIds'] = eliminationQuestionIds;
            updates['currentQuestionIndex'] = 0;
            updates['questionStartedAt'] = FieldValue.delete();
          }

          final existingPlayerIds = <String>[...room.playerIds];

          if (room.mode == Room.modeElimination) {
            updates['phase'] = Room.phasePlayingRound;
            final missingPlayers = room.maxPlayers - room.playerCount;
            for (var slot = 0; slot < missingPlayers; slot++) {
              final botId = _buildBotId(room.id, slot + 1);
              updates['players.$botId'] = const RoomPlayer(
                score: 0,
                ready: false,
                eliminated: false,
              ).toMap();
            }
            for (final playerId in existingPlayerIds) {
              updates['players.$playerId.ready'] = false;
              updates['players.$playerId.eliminated'] = false;
              updates['players.$playerId.score'] = 0;
              updates['players.$playerId.answeredCount'] = 0;
              updates['players.$playerId.completedAt'] = FieldValue.delete();
              updates['players.$playerId.currentAnswer'] = FieldValue.delete();
            }
          } else if (room.mode == Room.modeSurvival) {
            updates['phase'] = Room.phasePlayingRound;
            updates['roundNumber'] = 1;
            final missingPlayers = room.maxPlayers - room.playerCount;
            for (var slot = 0; slot < missingPlayers; slot++) {
              final botId = _buildBotId(room.id, slot + 1);
              updates['players.$botId'] = const RoomPlayer(
                score: 0,
                ready: false,
                eliminated: false,
                lives: Room.initialSurvivalLives,
              ).toMap();
            }
            for (final playerId in existingPlayerIds) {
              updates['players.$playerId.ready'] = false;
              updates['players.$playerId.eliminated'] = false;
              updates['players.$playerId.lives'] = Room.initialSurvivalLives;
              updates['players.$playerId.score'] = 0;
              updates['players.$playerId.answeredCount'] = 0;
              updates['players.$playerId.completedAt'] = FieldValue.delete();
              updates['players.$playerId.currentAnswer'] = FieldValue.delete();
            }
          } else if (room.mode == Room.modeSeries) {
            // Best-of-N: multiple battle rounds tracked by roundWins.
            updates['phase'] = Room.phasePlayingRound;
            updates['roundNumber'] = 1;
            final missingPlayers = room.maxPlayers - room.playerCount;
            for (var slot = 0; slot < missingPlayers; slot++) {
              final botId = _buildBotId(room.id, slot + 1);
              updates['players.$botId'] =
                  const RoomPlayer(score: 0, ready: false).toMap();
            }
            for (final playerId in existingPlayerIds) {
              updates['players.$playerId.ready'] = false;
              updates['players.$playerId.score'] = 0;
              updates['players.$playerId.answeredCount'] = 0;
              updates['players.$playerId.completedAt'] = FieldValue.delete();
              updates['players.$playerId.currentAnswer'] = FieldValue.delete();
            }
          } else if (room.mode == Room.modeTeamBattle) {
            updates.addAll(
              _buildTeamBattleStartUpdates(
                room: room,
                lobbyPlayers: room.players,
              ),
            );
          } else {
            // battle / blitz: fill missing slots with bots and start immediately.
            updates['phase'] = Room.phasePlaying;
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
              updates['players.$playerId.currentAnswer'] = FieldValue.delete();
              updates['players.$playerId.score'] = 0;
            }
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

  /// Blitz mode: save the player's score. Rejects calls once time has expired.
  Future<void> submitBlitzScore({
    required String roomId,
    required String userId,
    required int score,
    required int answeredCount,
  }) =>
      _guard(() async {
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) throw StateError('هذه الغرفة لم تعد موجودة.');

          final room = Room.fromSnapshot(snapshot);
          if (room.mode != Room.modeBlitz) return;
          if (!room.containsPlayer(userId)) {
            throw StateError('لم تعد ضمن هذه الغرفة.');
          }
          if (room.phase == Room.phaseFinished) return;
          if (room.isBlitzExpired) return; // post-timeout — reject silently

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

  /// Seeds bot scores, resolves the winner, and marks the blitz room finished.
  /// Idempotent: no-ops if already finished or timer has not expired yet.
  Future<void> finalizeBlitzRoom({required String roomId}) => _guard(() async {
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) return;

          final room = Room.fromSnapshot(snapshot);
          if (room.mode != Room.modeBlitz) return;
          if (room.phase == Room.phaseFinished) return;
          if (!room.isBlitzExpired) return; // too early

          final updates = <String, dynamic>{'phase': Room.phaseFinished};

          for (final botId in room.playerIds.where(Room.isBotUserId)) {
            final player = room.players[botId];
            if (player == null || player.completedAt != null) continue;
            final botScore = _buildBlitzBotScore(
              roomId: room.id,
              botId: botId,
              durationSeconds: room.roundDurationSeconds,
            );
            updates['players.$botId.score'] = botScore;
            updates['players.$botId.answeredCount'] = botScore;
            updates['players.$botId.completedAt'] =
                FieldValue.serverTimestamp();
          }

          // Build the effective players map with bot scores applied.
          final effectivePlayers = Map<String, RoomPlayer>.from(room.players);
          for (final botId in room.playerIds.where(Room.isBotUserId)) {
            final botScore = updates['players.$botId.score'] as int?;
            if (botScore != null) {
              effectivePlayers[botId] = effectivePlayers[botId]!.copyWith(
                score: botScore,
                answeredCount: botScore,
                completedAt: DateTime.now(),
              );
            }
          }

          final winnerId = _computeBlitzWinner(effectivePlayers);
          if (winnerId != null) {
            updates['winnerId'] = winnerId;
          } else {
            updates['winnerId'] = FieldValue.delete();
          }

          transaction.update(ref, updates);
        });
      });

  /// Persists the returning native blitz result even after the local timer has
  /// expired, then finalizes the room in the same transaction.
  Future<void> finalizeBlitzMatchFromNative({
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
            throw StateError('هذه الغرفة لم تعد موجودة.');
          }

          final room = Room.fromSnapshot(snapshot);
          if (room.mode != Room.modeBlitz) return;
          if (!room.containsPlayer(userId)) {
            throw StateError('لم تعد ضمن هذه الغرفة.');
          }
          if (room.phase == Room.phaseFinished) return;

          final current = room.players[userId]!;
          final safeScore = math.max(0, score);
          final safeAnsweredCount = math.max(0, answeredCount);
          final updates = <String, dynamic>{};
          final effectivePlayers = Map<String, RoomPlayer>.from(room.players);
          final shouldUpdatePlayer = current.completedAt == null ||
              current.score < safeScore ||
              current.answeredCount < safeAnsweredCount;

          if (shouldUpdatePlayer) {
            updates['players.$userId.score'] = safeScore;
            updates['players.$userId.answeredCount'] = safeAnsweredCount;
            updates['players.$userId.completedAt'] =
                FieldValue.serverTimestamp();
            effectivePlayers[userId] = current.copyWith(
              score: safeScore,
              answeredCount: safeAnsweredCount,
              completedAt: DateTime.now(),
            );
          }

          if (!room.isBlitzExpired) {
            if (updates.isNotEmpty) {
              transaction.update(ref, updates);
            }
            return;
          }

          updates['phase'] = Room.phaseFinished;
          for (final botId in room.playerIds.where(Room.isBotUserId)) {
            final player = effectivePlayers[botId];
            if (player == null || player.completedAt != null) continue;

            final botScore = _buildBlitzBotScore(
              roomId: room.id,
              botId: botId,
              durationSeconds: room.roundDurationSeconds,
            );
            updates['players.$botId.score'] = botScore;
            updates['players.$botId.answeredCount'] = botScore;
            updates['players.$botId.completedAt'] =
                FieldValue.serverTimestamp();
            effectivePlayers[botId] = player.copyWith(
              score: botScore,
              answeredCount: botScore,
              completedAt: DateTime.now(),
            );
          }

          final winnerId = _computeBlitzWinner(effectivePlayers);
          if (winnerId == null) {
            updates['winnerId'] = FieldValue.delete();
          } else {
            updates['winnerId'] = winnerId;
          }

          transaction.update(ref, updates);
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
            throw StateError('هذه الغرفة لم تعد موجودة.');
          }

          final room = Room.fromSnapshot(snapshot);
          if (!room.containsPlayer(userId)) {
            throw StateError('لم تعد ضمن هذه الغرفة.');
          }
          if (room.phase == Room.phaseFinished) {
            return;
          }

          final current = room.players[userId]!;
          if (current.completedAt != null &&
              current.score >= score &&
              current.answeredCount >= answeredCount) {
            return;
          }

          final updates = <String, dynamic>{
            'players.$userId.score': score,
            'players.$userId.answeredCount': answeredCount,
            'players.$userId.completedAt': FieldValue.serverTimestamp(),
          };

          final effectivePlayers = Map<String, RoomPlayer>.from(room.players)
            ..[userId] = current.copyWith(
              score: score,
              answeredCount: answeredCount,
              completedAt: DateTime.now(),
            );

          if (room.mode == Room.modeBattle ||
              room.mode == Room.modeTeamBattle) {
            _maybeFinalizeDirectScoreRoom(
              room: room,
              players: effectivePlayers,
              updates: updates,
              totalQuestions: _defaultDirectScoreQuestionCount,
            );
          }

          transaction.update(ref, updates);
        });
      });

  Future<void> finalizeSeriesMatchFromNative({
    required String roomId,
    required String userId,
    required int score,
    required int answeredCount,
    required int roundWins,
    required String winnerId,
    required List<Map<String, dynamic>> opponents,
  }) =>
      _guard(() async {
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw StateError('هذه الغرفة لم تعد موجودة.');
          }

          final room = Room.fromSnapshot(snapshot);
          if (room.mode != Room.modeSeries) {
            return;
          }
          if (!room.containsPlayer(userId)) {
            throw StateError('لم تعد ضمن هذه الغرفة.');
          }

          final updates = <String, dynamic>{
            'phase': Room.phaseFinished,
            'players.$userId.score': score,
            'players.$userId.answeredCount': answeredCount,
            'players.$userId.roundWins': math.max(0, roundWins),
            'players.$userId.completedAt': FieldValue.serverTimestamp(),
          };

          final safeWinnerId = winnerId.trim();
          if (safeWinnerId.isEmpty) {
            updates['winnerId'] = FieldValue.delete();
          } else {
            updates['winnerId'] = safeWinnerId;
          }

          var playedRounds = math.max(0, roundWins);
          for (final opponent in opponents) {
            final opponentId = (opponent['id'] ?? '').toString().trim();
            if (opponentId.isEmpty || !room.containsPlayer(opponentId)) {
              continue;
            }

            final opponentScore = (opponent['score'] as num?)?.toInt() ??
                room.players[opponentId]?.score ??
                0;
            final opponentAnsweredCount =
                (opponent['correctAnswers'] as num?)?.toInt() ??
                    (opponent['answeredCount'] as num?)?.toInt() ??
                    room.players[opponentId]?.answeredCount ??
                    0;
            final opponentRoundWins = (opponent['sets'] as num?)?.toInt() ??
                room.players[opponentId]?.roundWins ??
                0;

            updates['players.$opponentId.score'] = opponentScore;
            updates['players.$opponentId.answeredCount'] =
                opponentAnsweredCount;
            updates['players.$opponentId.roundWins'] =
                math.max(0, opponentRoundWins);
            updates['players.$opponentId.completedAt'] =
                FieldValue.serverTimestamp();
            playedRounds += math.max(0, opponentRoundWins);
          }

          if (playedRounds > 0) {
            updates['roundNumber'] = math.max(room.roundNumber, playedRounds);
          }

          transaction.update(ref, updates);
        });
      });

  Future<void> finalizeRoundBasedMatchFromNative({
    required String roomId,
    required String userId,
    required String matchMode,
    required int score,
    required int answeredCount,
    required String winnerId,
    required bool myEliminated,
    required int myLivesRemaining,
    required List<Map<String, dynamic>> opponents,
  }) =>
      _guard(() async {
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw StateError('هذه الغرفة لم تعد موجودة.');
          }

          final room = Room.fromSnapshot(snapshot);
          if (room.mode != matchMode ||
              (room.mode != Room.modeElimination &&
                  room.mode != Room.modeSurvival)) {
            return;
          }
          if (!room.containsPlayer(userId)) {
            throw StateError('لم تعد ضمن هذه الغرفة.');
          }

          final updates = <String, dynamic>{
            'phase': Room.phaseFinished,
            'players.$userId.score': score,
            'players.$userId.answeredCount': answeredCount,
            'players.$userId.completedAt': FieldValue.serverTimestamp(),
            'players.$userId.eliminated': myEliminated,
          };
          if (room.mode == Room.modeSurvival) {
            updates['players.$userId.lives'] = math.max(0, myLivesRemaining);
          }

          final safeWinnerId = winnerId.trim();
          if (safeWinnerId.isEmpty) {
            updates['winnerId'] = FieldValue.delete();
          } else {
            updates['winnerId'] = safeWinnerId;
          }

          for (final opponent in opponents) {
            final opponentId = (opponent['id'] ?? '').toString().trim();
            if (opponentId.isEmpty || !room.containsPlayer(opponentId)) {
              continue;
            }

            final opponentScore = (opponent['score'] as num?)?.toInt() ??
                room.players[opponentId]?.score ??
                0;
            final opponentAnsweredCount =
                (opponent['correctAnswers'] as num?)?.toInt() ??
                    (opponent['answeredCount'] as num?)?.toInt() ??
                    room.players[opponentId]?.answeredCount ??
                    0;
            final opponentEliminated = opponent['eliminated'] == true;

            updates['players.$opponentId.score'] = opponentScore;
            updates['players.$opponentId.answeredCount'] =
                opponentAnsweredCount;
            updates['players.$opponentId.completedAt'] =
                FieldValue.serverTimestamp();
            updates['players.$opponentId.eliminated'] = opponentEliminated;

            if (room.mode == Room.modeSurvival) {
              updates['players.$opponentId.lives'] = math.max(
                  0, (opponent['livesRemaining'] as num?)?.toInt() ?? 0);
            }
          }

          transaction.update(ref, updates);
        });
      });

  /// Called when all alive players finish a native-game round in elimination mode.
  /// Eliminates the player(s) with the lowest score and transitions the phase.
  Future<void> processEliminationRound({required String roomId}) =>
      _guard(() async {
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) return;

          final room = Room.fromSnapshot(snapshot);
          if (room.phase != Room.phasePlayingRound) return;

          final activePlayers =
              room.players.entries.where((e) => !e.value.eliminated).toList();

          if (activePlayers.isEmpty) {
            transaction.update(ref, {'phase': Room.phaseFinished});
            return;
          }

          // Require all alive players to have submitted before processing
          final allSubmitted =
              activePlayers.every((e) => e.value.completedAt != null);
          if (!allSubmitted) return;

          final updates = <String, dynamic>{};
          final minScore =
              activePlayers.map((e) => e.value.score).reduce(math.min);

          // Eliminate players tied for the lowest score
          for (final entry in activePlayers) {
            if (entry.value.score == minScore) {
              updates['players.${entry.key}.eliminated'] = true;
            }
          }

          // Survivors are those who scored above the minimum
          final survivors = activePlayers
              .where((e) => e.value.score > minScore)
              .map((e) => e.key)
              .toList();

          if (survivors.length <= 1) {
            updates['phase'] = Room.phaseFinished;
            if (survivors.length == 1) {
              updates['winnerId'] = survivors.first;
            } else {
              updates['winnerId'] = FieldValue.delete();
            }
          } else {
            updates['phase'] = Room.phaseRoundOver;
            updates['winnerId'] = FieldValue.delete();
          }

          transaction.update(ref, updates);
        });
      });

  /// Host starts the next elimination round.
  /// Resets per-round scores for alive players and transitions phase back
  /// to 'playing_round' so all clients re-launch the native game.
  Future<void> startNextEliminationRound({
    required String roomId,
    required String userId,
  }) =>
      _guard(() async {
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) return;

          final room = Room.fromSnapshot(snapshot);
          if (room.hostId != userId) {
            throw StateError('فقط المضيف يمكنه بدء الجولة التالية.');
          }
          if (room.phase != Room.phaseRoundOver) return;

          final updates = <String, dynamic>{
            'phase': Room.phasePlayingRound,
            'startedAt': FieldValue.serverTimestamp(),
          };

          // Reset per-round tracking for alive players
          for (final entry in room.players.entries) {
            if (!entry.value.eliminated) {
              updates['players.${entry.key}.score'] = 0;
              updates['players.${entry.key}.answeredCount'] = 0;
              updates['players.${entry.key}.completedAt'] = FieldValue.delete();
              updates['players.${entry.key}.currentAnswer'] =
                  FieldValue.delete();
            }
          }

          transaction.update(ref, updates);
        });
      });

  /// Submit an answer in elimination mode.
  /// Correct answer → increments score.
  /// Wrong answer → marks player as eliminated.
  Future<void> submitEliminationAnswer({
    required String roomId,
    required String userId,
    required String answer,
    required bool isCorrect,
  }) =>
      _guard(() async {
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) return;

          final room = Room.fromSnapshot(snapshot);
          if (room.mode != Room.modeElimination ||
              room.phase != Room.phasePlayingRound) {
            return;
          }
          if (!room.containsPlayer(userId)) return;

          final player = room.players[userId]!;
          if (player.eliminated) return; // Already out
          if (_hasSubmittedRound(player)) return;

          final updates = <String, dynamic>{
            'players.$userId.currentAnswer': answer,
            'players.$userId.answeredCount': 1,
            'players.$userId.completedAt': FieldValue.serverTimestamp(),
          };

          if (isCorrect) {
            updates['players.$userId.score'] = player.score + 1;
          } else {
            updates['players.$userId.eliminated'] = true;
          }

          transaction.update(ref, updates);
        });
      });

  // ── Survival with Lives ────────────────────────────────────────────────────

  /// Submit an answer in survival mode.
  /// Correct → score +1. Wrong → lose one life; eliminated when lives reach 0.
  Future<void> submitSurvivalAnswer({
    required String roomId,
    required String userId,
    required String answer,
    required bool isCorrect,
  }) =>
      _guard(() async {
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) return;

          final room = Room.fromSnapshot(snapshot);
          if (room.mode != Room.modeSurvival ||
              room.phase != Room.phasePlayingRound) {
            return;
          }
          if (!room.containsPlayer(userId)) return;

          final player = room.players[userId]!;
          if (!_isActiveSurvivalPlayer(player)) return;
          if (_hasSubmittedRound(player)) return;

          final updates = <String, dynamic>{};
          final playersAfter = Map<String, RoomPlayer>.from(room.players);
          final answeredPlayer = _answeredSurvivalPlayer(
            player,
            answer: answer,
            isCorrect: isCorrect,
          );
          playersAfter[userId] = answeredPlayer;
          _writeSurvivalSubmission(
            updates,
            playerId: userId,
            player: answeredPlayer,
          );
          _applyPendingSurvivalBotTurns(
            roomId: room.id,
            roundNumber: room.roundNumber,
            players: playersAfter,
            updates: updates,
          );

          if (_allActiveSurvivalPlayersSubmitted(playersAfter)) {
            _applySurvivalRoundOutcome(playersAfter, updates);
          }

          transaction.update(ref, updates);
        });
      });

  /// Eliminates players with 0 lives and transitions phase after a survival round.
  Future<void> processSurvivalRound({required String roomId}) =>
      _guard(() async {
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) return;

          final room = Room.fromSnapshot(snapshot);
          if (room.mode != Room.modeSurvival ||
              room.phase != Room.phasePlayingRound) {
            return;
          }

          final updates = <String, dynamic>{};
          final playersAfter = Map<String, RoomPlayer>.from(room.players);
          _applyPendingSurvivalBotTurns(
            roomId: room.id,
            roundNumber: room.roundNumber,
            players: playersAfter,
            updates: updates,
          );

          final activePlayers = playersAfter.entries
              .where((entry) => _isActiveSurvivalPlayer(entry.value))
              .toList(growable: false);
          if (activePlayers.isEmpty) {
            updates['phase'] = Room.phaseFinished;
            updates['winnerId'] = FieldValue.delete();
            transaction.update(ref, updates);
            return;
          }

          if (!_allActiveSurvivalPlayersSubmitted(playersAfter)) {
            if (updates.isNotEmpty) {
              transaction.update(ref, updates);
            }
            return;
          }

          _applySurvivalRoundOutcome(playersAfter, updates);
          transaction.update(ref, updates);
        });
      });

  /// Host starts the next survival round — resets per-round scores for alive players.
  Future<void> startNextSurvivalRound({
    required String roomId,
    required String userId,
  }) =>
      _guard(() async {
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) return;

          final room = Room.fromSnapshot(snapshot);
          if (room.hostId != userId) {
            throw StateError('فقط المضيف يمكنه بدء الجولة التالية.');
          }
          if (room.mode != Room.modeSurvival ||
              room.phase != Room.phaseRoundOver) {
            return;
          }

          final updates = <String, dynamic>{
            'phase': Room.phasePlayingRound,
            'startedAt': FieldValue.serverTimestamp(),
            'roundNumber': room.roundNumber + 1,
            'winnerId': FieldValue.delete(),
          };
          final playersAfter = Map<String, RoomPlayer>.from(room.players);

          for (final entry in room.players.entries) {
            if (_isActiveSurvivalPlayer(entry.value)) {
              updates['players.${entry.key}.answeredCount'] = 0;
              updates['players.${entry.key}.completedAt'] = FieldValue.delete();
              updates['players.${entry.key}.currentAnswer'] =
                  FieldValue.delete();
              playersAfter[entry.key] = _clearedRoundPlayer(
                entry.value,
                resetScore: false,
              );
            }
          }

          final aliveHumans = playersAfter.entries
              .where(
                (entry) =>
                    _isActiveSurvivalPlayer(entry.value) &&
                    !Room.isBotUserId(entry.key),
              )
              .length;
          if (aliveHumans == 0) {
            _applyPendingSurvivalBotTurns(
              roomId: room.id,
              roundNumber: room.roundNumber + 1,
              players: playersAfter,
              updates: updates,
            );
            if (_allActiveSurvivalPlayersSubmitted(playersAfter)) {
              _applySurvivalRoundOutcome(playersAfter, updates);
            }
          }

          transaction.update(ref, updates);
        });
      });

  // ── Best of N Series ───────────────────────────────────────────────────────

  /// Determines the round winner, increments their roundWins, and either
  /// declares a series winner or moves to 'round_over' for the next round.
  Future<void> processSeriesRound({required String roomId}) => _guard(() async {
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) return;

          final room = Room.fromSnapshot(snapshot);
          if (room.phase != Room.phasePlayingRound) return;

          final activePlayers = room.players.entries.toList();
          final allSubmitted =
              activePlayers.every((e) => e.value.completedAt != null);
          if (!allSubmitted) return;

          final updates = <String, dynamic>{};

          // Find the highest score for this round.
          final maxScore =
              activePlayers.map((e) => e.value.score).reduce(math.max);
          final roundWinners = activePlayers
              .where((e) => e.value.score == maxScore)
              .map((e) => e.key)
              .toList();

          // Award a round win to each player tied for the top score.
          String? seriesWinnerId;
          for (final winnerId in roundWinners) {
            final newWins = room.players[winnerId]!.roundWins + 1;
            updates['players.$winnerId.roundWins'] = newWins;
            if (newWins >= room.seriesTarget) {
              seriesWinnerId = winnerId;
            }
          }

          if (seriesWinnerId != null) {
            updates['phase'] = Room.phaseFinished;
            updates['winnerId'] = seriesWinnerId;
          } else {
            updates['phase'] = Room.phaseRoundOver;
            updates['winnerId'] = FieldValue.delete();
          }

          transaction.update(ref, updates);
        });
      });

  /// Host starts the next series round — resets per-round scores.
  Future<void> startNextSeriesRound({
    required String roomId,
    required String userId,
  }) =>
      _guard(() async {
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) return;

          final room = Room.fromSnapshot(snapshot);
          if (room.hostId != userId) {
            throw StateError('فقط المضيف يمكنه بدء الجولة التالية.');
          }
          if (room.phase != Room.phaseRoundOver) return;

          final updates = <String, dynamic>{
            'phase': Room.phasePlayingRound,
            'startedAt': FieldValue.serverTimestamp(),
            'roundNumber': room.roundNumber + 1,
          };

          for (final entry in room.players.entries) {
            updates['players.${entry.key}.score'] = 0;
            updates['players.${entry.key}.answeredCount'] = 0;
            updates['players.${entry.key}.completedAt'] = FieldValue.delete();
          }

          transaction.update(ref, updates);
        });
      });

  // ── Team Battle ────────────────────────────────────────────────────────────

  /// Computes team scores from individual scores and sets the winning team.
  /// Call after all players have submitted their final scores.
  Future<void> processTeamBattleResult({required String roomId}) =>
      _guard(() async {
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) return;

          final room = Room.fromSnapshot(snapshot);
          if (room.mode != Room.modeTeamBattle ||
              room.phase == Room.phaseFinished) {
            return;
          }

          final updates = <String, dynamic>{};
          final effectivePlayers = Map<String, RoomPlayer>.from(room.players);
          _maybeFinalizeDirectScoreRoom(
            room: room,
            players: effectivePlayers,
            updates: updates,
            totalQuestions: _defaultDirectScoreQuestionCount,
          );

          if (updates.isNotEmpty) {
            transaction.update(ref, updates);
          }
        });
      });

  /// Advance to the next question in elimination mode.
  /// Uses [fromIndex] as a guard to prevent double-advance.
  Future<void> advanceEliminationQuestion({
    required String roomId,
    required int fromIndex,
    required int totalQuestions,
  }) =>
      _guard(() async {
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) return;

          final room = Room.fromSnapshot(snapshot);
          // Guard: only advance if we're still on the same question
          if (room.currentQuestionIndex != fromIndex) return;
          if (room.phase != Room.phasePlayingRound) return;

          final updates = <String, dynamic>{};

          // Eliminate players who didn't answer in time
          for (final entry in room.players.entries) {
            if (!entry.value.eliminated && entry.value.currentAnswer == null) {
              updates['players.${entry.key}.eliminated'] = true;
            }
          }

          // Determine which players survive into the next round
          final aliveIds = room.players.entries
              .where((e) {
                if (e.value.eliminated) return false;
                if (updates.containsKey('players.${e.key}.eliminated')) {
                  return false;
                }
                return true;
              })
              .map((e) => e.key)
              .toList();

          // Clear current answers for survivors
          for (final id in aliveIds) {
            updates['players.$id.currentAnswer'] = FieldValue.delete();
          }

          final nextIndex = fromIndex + 1;

          if (aliveIds.length <= 1 || nextIndex >= totalQuestions) {
            // Game over
            updates['phase'] = Room.phaseFinished;
            if (aliveIds.length == 1) {
              updates['winnerId'] = aliveIds.first;
            }
          } else {
            updates['currentQuestionIndex'] = nextIndex;
            updates['questionStartedAt'] = FieldValue.serverTimestamp();
          }

          transaction.update(ref, updates);
        });
      });

  /// يبدّل فريق اللاعب بين A وB (في وضع team_battle فقط، قبل بدء المباراة).
  Future<void> switchTeam({
    required String roomId,
    required String userId,
  }) =>
      _guard(() async {
        final ref = _rooms.doc(roomId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) return;
          final room = Room.fromSnapshot(snapshot);
          if (room.mode != Room.modeTeamBattle) return;
          if (room.started || room.phase != Room.phaseLobby) {
            throw StateError('يمكن تغيير الفريق قبل بدء المواجهة فقط.');
          }

          final player = room.players[userId];
          if (player == null) {
            throw StateError('هذا اللاعب لم يعد داخل الغرفة.');
          }

          final capacity = _teamCapacityForRoom(room.maxPlayers);
          final currentTeam = Room.normalizeTeamId(player.teamId) ?? Room.teamA;
          final newTeam = currentTeam == Room.teamA ? Room.teamB : Room.teamA;
          final counts = room.teamSizes;
          counts[currentTeam] = (counts[currentTeam] ?? 0) - 1;
          counts[newTeam] = (counts[newTeam] ?? 0) + 1;

          if ((counts[newTeam] ?? 0) > capacity) {
            throw StateError(
              'هذا النقل سيجعل ${newTeam == Room.teamA ? 'الفريق أ' : 'الفريق ب'} يتجاوز العدد المسموح.',
            );
          }

          transaction.update(ref, <String, dynamic>{
            'players.$userId.teamId': newTeam,
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

          // Use a deterministic host selection: prefer existing host, otherwise
          // pick the lexicographically smallest non-bot player ID for consistency
          // across all clients (Map key order is not guaranteed).
          String nextHostId = room.hostId;
          if (room.hostId == userId) {
            final candidates = remainingPlayers.keys
                .where((id) => !Room.isBotUserId(id))
                .toList()
              ..sort();
            nextHostId = candidates.isNotEmpty
                ? candidates.first
                : (remainingPlayers.keys.toList()..sort()).first;
          }

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
          'قواعد Firestore تمنع تحديثات الغرف. انشر أحدث قواعد مجموعة rooms من Firebase Console ثم أعد المحاولة.',
        );
      }
      if (e.code == 'unavailable') {
        throw StateError(
            'الخدمة غير متاحة الآن. تحقق من الاتصال وحاول مرة أخرى.');
      }
      if (e.code == 'deadline-exceeded') {
        throw StateError('انتهت مهلة الاتصال. حاول مرة أخرى.');
      }
      throw StateError('تعذر تنفيذ العملية على الغرفة. حاول مرة أخرى.');
    }
  }

  static String _buildBotId(String roomId, int slot) =>
      '${Room.botIdPrefix}${roomId}_$slot';

  static bool _hasSubmittedRound(RoomPlayer player) =>
      player.completedAt != null ||
      player.currentAnswer != null ||
      player.answeredCount > 0;

  static bool _isActiveSurvivalPlayer(RoomPlayer player) =>
      !player.eliminated && player.lives > 0;

  static RoomPlayer _answeredSurvivalPlayer(
    RoomPlayer player, {
    required String answer,
    required bool isCorrect,
  }) {
    final nextLives = isCorrect ? player.lives : math.max(0, player.lives - 1);
    return RoomPlayer(
      score: isCorrect ? player.score + 1 : player.score,
      ready: player.ready,
      answeredCount: 1,
      completedAt: DateTime.now(),
      eliminated: player.eliminated || nextLives == 0,
      currentAnswer: answer,
      lives: nextLives,
      roundWins: player.roundWins,
      teamId: player.teamId,
    );
  }

  static RoomPlayer _clearedRoundPlayer(
    RoomPlayer player, {
    required bool resetScore,
  }) {
    return RoomPlayer(
      score: resetScore ? 0 : player.score,
      ready: player.ready,
      answeredCount: 0,
      completedAt: null,
      eliminated: player.eliminated,
      currentAnswer: null,
      lives: player.lives,
      roundWins: player.roundWins,
      teamId: player.teamId,
    );
  }

  static void _writeSurvivalSubmission(
    Map<String, dynamic> updates, {
    required String playerId,
    required RoomPlayer player,
  }) {
    updates['players.$playerId.currentAnswer'] = player.currentAnswer;
    updates['players.$playerId.answeredCount'] = player.answeredCount;
    updates['players.$playerId.completedAt'] = FieldValue.serverTimestamp();
    updates['players.$playerId.score'] = player.score;
    updates['players.$playerId.lives'] = player.lives;
    updates['players.$playerId.eliminated'] = player.eliminated;
  }

  static void _applyPendingSurvivalBotTurns({
    required String roomId,
    required int roundNumber,
    required Map<String, RoomPlayer> players,
    required Map<String, dynamic> updates,
  }) {
    for (final entry in players.entries.toList(growable: false)) {
      if (!Room.isBotUserId(entry.key) ||
          !_isActiveSurvivalPlayer(entry.value)) {
        continue;
      }
      if (_hasSubmittedRound(entry.value)) {
        continue;
      }

      final botProfile = Room.botProfile(entry.key);
      final isCorrect = _isSurvivalBotCorrect(
        roomId: roomId,
        playerId: entry.key,
        roundNumber: roundNumber,
        intelligence: botProfile.intelligence,
      );
      final answeredPlayer = _answeredSurvivalPlayer(
        entry.value,
        answer: isCorrect ? 'bot_correct' : 'bot_wrong',
        isCorrect: isCorrect,
      );
      players[entry.key] = answeredPlayer;
      _writeSurvivalSubmission(
        updates,
        playerId: entry.key,
        player: answeredPlayer,
      );
    }
  }

  static bool _allActiveSurvivalPlayersSubmitted(
    Map<String, RoomPlayer> players,
  ) {
    final activePlayers =
        players.values.where(_isActiveSurvivalPlayer).toList();
    if (activePlayers.isEmpty) {
      return true;
    }
    return activePlayers.every(_hasSubmittedRound);
  }

  static void _applySurvivalRoundOutcome(
    Map<String, RoomPlayer> players,
    Map<String, dynamic> updates,
  ) {
    final survivors = players.entries
        .where((entry) => _isActiveSurvivalPlayer(entry.value))
        .map((entry) => entry.key)
        .toList(growable: false);

    if (survivors.length <= 1) {
      updates['phase'] = Room.phaseFinished;
      if (survivors.length == 1) {
        updates['winnerId'] = survivors.first;
      } else {
        updates['winnerId'] = FieldValue.delete();
      }
      return;
    }

    updates['phase'] = Room.phaseRoundOver;
    updates['winnerId'] = FieldValue.delete();
  }

  static bool _isSurvivalBotCorrect({
    required String roomId,
    required String playerId,
    required int roundNumber,
    required int intelligence,
  }) {
    final roll = _stableHash('$roomId|$playerId|$roundNumber') % 100;
    return roll < intelligence;
  }

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

  static int _buildBlitzBotScore({
    required String roomId,
    required String botId,
    required int durationSeconds,
  }) {
    final profile = Room.botProfile(botId);
    // ~1 answer per 5 s at 100 % intelligence; scaled by actual intelligence.
    final maxAnswers = math.max(1, (durationSeconds / 5.0).round());
    final expected = (maxAnswers * profile.intelligence / 100).round();
    final minScore = math.max(0, expected - 3);
    final hash = _stableHash('blitz|$roomId|$botId');
    return math.min(maxAnswers, minScore + (hash % 7));
  }

  /// Returns the UID of the blitz winner using deterministic tie-breaking.
  /// Returns null only when every player scored 0.
  static String? _computeBlitzWinner(Map<String, RoomPlayer> players) {
    if (players.isEmpty) return null;

    final sorted = players.entries.toList()
      ..sort((a, b) {
        final scoreCmp = b.value.score.compareTo(a.value.score);
        if (scoreCmp != 0) return scoreCmp;
        final answerCmp =
            b.value.answeredCount.compareTo(a.value.answeredCount);
        if (answerCmp != 0) return answerCmp;
        final aAt = a.value.completedAt;
        final bAt = b.value.completedAt;
        if (aAt != null && bAt != null) {
          final timeCmp = aAt.compareTo(bAt);
          if (timeCmp != 0) return timeCmp;
        } else if (aAt != null) {
          return -1;
        } else if (bAt != null) {
          return 1;
        }
        return _stableHash(a.key).compareTo(_stableHash(b.key));
      });

    if (sorted.first.value.score == 0) return null;
    return sorted.first.key;
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

  static void _validateCreateRoomOptions({
    required String mode,
    required int maxPlayers,
  }) {
    if (mode != Room.modeTeamBattle) return;
    if (maxPlayers < 2) {
      throw StateError('غرف مواجهة الفرق تحتاج لاعبين على الأقل.');
    }
    if (maxPlayers.isOdd) {
      throw StateError('غرف مواجهة الفرق تتطلب عدد لاعبين زوجيًا.');
    }
  }

  static int _teamCapacityForRoom(int maxPlayers) {
    if (maxPlayers < 2 || maxPlayers.isOdd) {
      throw StateError('غرف مواجهة الفرق تتطلب عدد لاعبين زوجيًا.');
    }
    return maxPlayers ~/ 2;
  }

  static String _assignLobbyTeamId(
    Map<String, RoomPlayer> players,
    int maxPlayers,
  ) {
    final capacity = _teamCapacityForRoom(maxPlayers);
    final counts = <String, int>{
      Room.teamA: 0,
      Room.teamB: 0,
    };

    for (final player in players.values) {
      final teamId = Room.normalizeTeamId(player.teamId);
      if (teamId != null) {
        counts[teamId] = (counts[teamId] ?? 0) + 1;
      }
    }

    return _pickBalancedTeam(counts, capacity: capacity);
  }

  static String _pickBalancedTeam(
    Map<String, int> counts, {
    required int capacity,
  }) {
    final countA = counts[Room.teamA] ?? 0;
    final countB = counts[Room.teamB] ?? 0;
    final canJoinA = countA < capacity;
    final canJoinB = countB < capacity;

    if (!canJoinA && !canJoinB) {
      throw StateError('الفريقان ممتلئان بالفعل.');
    }
    if (canJoinA && !canJoinB) {
      return Room.teamA;
    }
    if (canJoinB && !canJoinA) {
      return Room.teamB;
    }
    return countA <= countB ? Room.teamA : Room.teamB;
  }

  Map<String, dynamic> _buildTeamBattleStartUpdates({
    required Room room,
    required Map<String, RoomPlayer> lobbyPlayers,
  }) {
    final capacity = _teamCapacityForRoom(room.maxPlayers);
    final missingPlayers = room.maxPlayers - lobbyPlayers.length;
    if (missingPlayers < 0) {
      throw StateError('هذه الغرفة تحتوي لاعبين أكثر من المقاعد المتاحة.');
    }

    final teamAssignments = <String, String>{};
    final teamCounts = <String, int>{
      Room.teamA: 0,
      Room.teamB: 0,
    };
    final unassignedPlayerIds = <String>[];

    for (final entry in lobbyPlayers.entries) {
      final teamId = Room.normalizeTeamId(entry.value.teamId);
      if (teamId == null) {
        unassignedPlayerIds.add(entry.key);
        continue;
      }
      teamAssignments[entry.key] = teamId;
      teamCounts[teamId] = (teamCounts[teamId] ?? 0) + 1;
    }

    if ((teamCounts[Room.teamA] ?? 0) > capacity ||
        (teamCounts[Room.teamB] ?? 0) > capacity) {
      throw StateError(
        'أحد الفريقين يضم لاعبين أكثر من المسموح لغرفة مواجهة فرق بسعة ${room.maxPlayers}.',
      );
    }

    final sortedUnassignedIds = [...unassignedPlayerIds]..sort();
    for (final playerId in sortedUnassignedIds) {
      final teamId = _pickBalancedTeam(teamCounts, capacity: capacity);
      teamAssignments[playerId] = teamId;
      teamCounts[teamId] = (teamCounts[teamId] ?? 0) + 1;
    }

    final updates = <String, dynamic>{
      'started': true,
      'startedAt': FieldValue.serverTimestamp(),
      'phase': Room.phasePlaying,
      'winnerId': FieldValue.delete(),
      'winnerTeamId': FieldValue.delete(),
    };

    var nextBotSlot = 1;
    while (teamAssignments.length < room.maxPlayers) {
      final botId = _buildBotId(room.id, nextBotSlot++);
      final teamId = _pickBalancedTeam(teamCounts, capacity: capacity);
      teamAssignments[botId] = teamId;
      teamCounts[teamId] = (teamCounts[teamId] ?? 0) + 1;
      updates['players.$botId'] = RoomPlayer(
        score: 0,
        ready: false,
        teamId: teamId,
      ).toMap();
    }

    if ((teamCounts[Room.teamA] ?? 0) != capacity ||
        (teamCounts[Room.teamB] ?? 0) != capacity) {
      throw StateError(
        'يجب توازن الفريقين قبل بدء مواجهة الفرق.',
      );
    }

    for (final playerId in teamAssignments.keys) {
      final teamId = teamAssignments[playerId]!;
      updates['players.$playerId.teamId'] = teamId;
      updates['players.$playerId.ready'] = false;
      updates['players.$playerId.score'] = 0;
      updates['players.$playerId.answeredCount'] = 0;
      updates['players.$playerId.completedAt'] = FieldValue.delete();
      updates['players.$playerId.currentAnswer'] = FieldValue.delete();
    }

    return updates;
  }

  static bool _allHumanPlayersCompleted(Map<String, RoomPlayer> players) {
    final humanPlayers = players.entries
        .where((entry) => !Room.isBotUserId(entry.key))
        .toList(growable: false);
    if (humanPlayers.isEmpty) {
      return false;
    }
    return humanPlayers.every((entry) => entry.value.completedAt != null);
  }

  static void _seedPendingDirectScoreBots({
    required String roomId,
    required Map<String, RoomPlayer> players,
    required Map<String, dynamic> updates,
    required int totalQuestions,
  }) {
    for (final entry in players.entries.toList(growable: false)) {
      if (!Room.isBotUserId(entry.key) || entry.value.completedAt != null) {
        continue;
      }
      final botScore = _buildBotScore(roomId, entry.key, totalQuestions);
      players[entry.key] = entry.value.copyWith(
        score: botScore,
        answeredCount: totalQuestions,
        completedAt: DateTime.now(),
      );
      updates['players.${entry.key}.score'] = botScore;
      updates['players.${entry.key}.answeredCount'] = totalQuestions;
      updates['players.${entry.key}.completedAt'] =
          FieldValue.serverTimestamp();
    }
  }

  static void _maybeFinalizeDirectScoreRoom({
    required Room room,
    required Map<String, RoomPlayer> players,
    required Map<String, dynamic> updates,
    required int totalQuestions,
  }) {
    if (!_allHumanPlayersCompleted(players)) {
      return;
    }

    _seedPendingDirectScoreBots(
      roomId: room.id,
      players: players,
      updates: updates,
      totalQuestions: totalQuestions,
    );

    if (!players.values.every((player) => player.completedAt != null)) {
      return;
    }

    updates['phase'] = Room.phaseFinished;

    if (room.mode == Room.modeTeamBattle) {
      final scoreA = players.values
          .where((player) => player.teamId == Room.teamA)
          .fold(0, (totalScore, player) => totalScore + player.score);
      final scoreB = players.values
          .where((player) => player.teamId == Room.teamB)
          .fold(0, (totalScore, player) => totalScore + player.score);
      final winnerTeam = scoreA > scoreB
          ? Room.teamA
          : scoreB > scoreA
              ? Room.teamB
              : null;
      updates['winnerId'] = FieldValue.delete();
      if (winnerTeam == null) {
        updates['winnerTeamId'] = FieldValue.delete();
      } else {
        updates['winnerTeamId'] = winnerTeam;
      }
      return;
    }

    final winnerId = _computeBlitzWinner(players);
    if (winnerId == null) {
      updates['winnerId'] = FieldValue.delete();
    } else {
      updates['winnerId'] = winnerId;
    }
    updates['winnerTeamId'] = FieldValue.delete();
  }
}
