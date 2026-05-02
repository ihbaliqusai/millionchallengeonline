import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_state.dart';
import '../../models/player_profile.dart';
import '../../models/room.dart';
import '../../services/native_bridge_service.dart';
import '../../services/profile_service.dart';
import '../../services/room_service.dart';

class RoomLobbyScreen extends StatefulWidget {
  const RoomLobbyScreen({
    super.key,
    required this.roomId,
    this.createdByCurrentUser = false,
    this.isSpectator = false,
    this.isJoiningMidGame = false,
  });

  final String roomId;
  final bool createdByCurrentUser;

  /// True when the user navigated here to watch without joining as a player.
  final bool isSpectator;

  /// True when the user joined a room that was already started (bot replacement
  /// or reconnect), so the native layer resumes the current match state.
  final bool isJoiningMidGame;

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen>
    with SingleTickerProviderStateMixin {
  bool _starting = false;
  bool _leaving = false;
  bool _navigatedToGame = false;
  DateTime? _lastLaunchedRoundAt;
  Room? _latestRoom; // tracked for the leave-confirmation dialog
  late final AnimationController _pulseCtrl;

  Timer? _blitzTimer;
  int _blitzSecondsLeft = 0;
  String? _blitzTimerRoomId;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blitzTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _scheduleBlitzFinalization(Room room) {
    if (_blitzTimerRoomId == room.id) return;
    _blitzTimer?.cancel();
    _blitzTimerRoomId = room.id;

    final remaining = room.blitzSecondsRemaining;
    setState(() => _blitzSecondsLeft = remaining);

    if (remaining <= 0) {
      _triggerBlitzFinalize(room.id);
      return;
    }

    _blitzTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _blitzSecondsLeft = math.max(0, _blitzSecondsLeft - 1);
      });
      if (_blitzSecondsLeft <= 0) {
        timer.cancel();
        _triggerBlitzFinalize(room.id);
      }
    });
  }

  void _triggerBlitzFinalize(String roomId) {
    context
        .read<RoomService>()
        .finalizeBlitzRoom(roomId: roomId)
        .catchError((_) {});
  }

  Future<void> _leaveRoom() async {
    if (_leaving) return;
    final userId = context.read<AppState>().user?.uid;

    // Spectator or unauthenticated — just pop with no Firestore call.
    final isSpectator = widget.isSpectator ||
        userId == null ||
        (_latestRoom != null && !_latestRoom!.containsPlayer(userId));
    if (isSpectator) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() => _leaving = true);
    try {
      await context.read<RoomService>().leaveRoom(
            roomId: widget.roomId,
            userId: userId,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFF7F1D1D),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  Future<void> _toggleReady(Room room, bool nextValue) async {
    final userId = context.read<AppState>().user?.uid;
    if (userId == null || !room.containsPlayer(userId)) return;
    try {
      await context.read<RoomService>().setPlayerReady(
            roomId: widget.roomId,
            userId: userId,
            ready: nextValue,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _startRoom(Room room) async {
    final userId = context.read<AppState>().user?.uid;
    if (userId == null) return;
    // Capture service references before any async gaps.
    final roomService = context.read<RoomService>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _starting = true);

    List<int>? questionIds;
    if (room.mode == 'elimination' || room.mode == 'survival') {
      questionIds = await _generateShuffledQuestionIds();
    }

    try {
      await roomService.startRoom(
        roomId: widget.roomId,
        userId: userId,
        eliminationQuestionIds: questionIds,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(e.toString()), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _startNextRound(Room room) async {
    if (!room.isRoundBasedMode) return;
    final userId = context.read<AppState>().user?.uid;
    if (userId == null) return;
    final roomService = context.read<RoomService>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _starting = true);

    try {
      switch (room.mode) {
        case Room.modeElimination:
          await roomService.startNextEliminationRound(
            roomId: widget.roomId,
            userId: userId,
          );
          break;
        case Room.modeSurvival:
          await roomService.startNextSurvivalRound(
            roomId: widget.roomId,
            userId: userId,
          );
          break;
        case Room.modeSeries:
          await roomService.startNextSeriesRound(
            roomId: widget.roomId,
            userId: userId,
          );
          break;
        default:
          return;
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(e.toString()), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  /// Loads questions.json, shuffles the indices, and returns the first 80.
  Future<List<int>> _generateShuffledQuestionIds() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/questions.json');
      final list = jsonDecode(jsonStr) as List;
      final indices = List.generate(list.length, (i) => i);
      indices.shuffle(math.Random());
      return indices.take(80).toList();
    } catch (_) {
      return List.generate(80, (i) => i);
    }
  }

  Future<void> _launchNativeMatchIfPossible({
    required Room room,
    required Map<String, PlayerProfile> profiles,
    required String currentUserId,
    required String matchMode,
    required bool isResumingMidGame,
  }) async {
    final profileService = context.read<ProfileService>();
    final nativeBridgeService = context.read<NativeBridgeService>();
    final appUser = context.read<AppState>().user;
    final currentPlayer = room.players[currentUserId];
    final currentProfile = profiles[currentUserId];
    final opponentIds = room.playerIds
        .where((id) => id != currentUserId)
        .toList(growable: false);
    final opponents = <Map<String, dynamic>>[];

    for (final opponentId in opponentIds) {
      if (Room.isBotUserId(opponentId)) {
        final roomPlayer = room.players[opponentId];
        final botProfile = Room.botProfile(opponentId);
        opponents.add(<String, dynamic>{
          'id': opponentId,
          'seatId': opponentId,
          'userId': opponentId,
          'name': botProfile.displayName,
          'photo': botProfile.nativePhoto,
          'level': (botProfile.intelligence / 10).ceil(),
          'intelligence': botProfile.intelligence,
          'score': roomPlayer?.score ?? 0,
          'bot': true,
          'teamId': roomPlayer?.teamId ?? '',
          'sets': roomPlayer?.roundWins ?? 0,
          'livesRemaining': roomPlayer?.lives ?? 0,
          'eliminated': roomPlayer?.eliminated ?? false,
        });
        continue;
      }
      var opponentProfile = profiles[opponentId];
      if (_needsProfileHydration(opponentProfile)) {
        try {
          final fetched = await profileService.fetchProfile(opponentId);
          if (_hasMoreProfileData(
              current: opponentProfile, candidate: fetched)) {
            opponentProfile = fetched;
          }
        } catch (_) {}
      }
      final roomPlayer = room.players[opponentId];
      final seatId = (roomPlayer?.seatSourceId?.trim().isNotEmpty ?? false)
          ? roomPlayer!.seatSourceId!.trim()
          : opponentId;
      opponents.add(<String, dynamic>{
        'id': opponentId,
        'seatId': seatId,
        'userId': opponentId,
        'name': opponentProfile?.username ?? _fallbackName(opponentId),
        'photo': opponentProfile?.photoUrl ?? '',
        'level': 1,
        'score': roomPlayer?.score ?? 0,
        'bot': false,
        'teamId': roomPlayer?.teamId ?? '',
        'sets': roomPlayer?.roundWins ?? 0,
        'livesRemaining': roomPlayer?.lives ?? 0,
        'eliminated': roomPlayer?.eliminated ?? false,
      });
    }

    if (opponents.isEmpty) {
      opponents.add(const <String, dynamic>{
        'id': 'fictitious',
        'seatId': 'fictitious',
        'userId': 'fictitious',
        'name': 'خصم آلي',
        'photo': '',
        'level': 1,
        'score': 0,
        'bot': true,
        'teamId': 'B',
      });
    }

    if (!mounted) return;
    final seatId = currentPlayer?.seatSourceId?.trim().isNotEmpty == true
        ? currentPlayer!.seatSourceId!.trim()
        : currentUserId;
    if (isResumingMidGame &&
        currentPlayer?.seatSourceId?.trim().isNotEmpty == true) {
      try {
        await nativeBridgeService.announceRoomSeatClaim(
          roomId: room.id,
          matchMode: matchMode,
          roomRoundNumber: room.roundNumber,
          seatId: seatId,
          userId: currentUserId,
          username: currentProfile?.username.trim().isNotEmpty == true
              ? currentProfile!.username.trim()
              : (appUser?.displayName?.trim().isNotEmpty == true
                  ? appUser!.displayName!.trim()
                  : _fallbackName(currentUserId)),
          photoUrl: (currentProfile?.photoUrl ?? '').trim().isNotEmpty
              ? currentProfile!.photoUrl!.trim()
              : (appUser?.photoURL ?? ''),
          teamId: currentPlayer?.teamId ?? 'A',
          initialScore: currentPlayer?.score ?? 0,
          initialRoundWins: currentPlayer?.roundWins ?? 0,
          initialLivesRemaining: currentPlayer?.lives ?? 0,
          initiallyEliminated: currentPlayer?.eliminated ?? false,
        );
      } catch (_) {}
    }
    await nativeBridgeService.launchLegacyRoomMatch(
      roomId: room.id,
      opponents: opponents,
      meOwner: currentUserId == room.hostId,
      matchMode: matchMode,
      seriesTarget: room.seriesTarget,
      roundDurationSeconds: room.roundDurationSeconds,
      myTeam: room.players[currentUserId]?.teamId ?? 'A',
      roomRoundNumber: room.roundNumber,
      resumeExistingGame: isResumingMidGame,
      seatSourceId: currentPlayer?.seatSourceId ?? '',
      initialScore: currentPlayer?.score ?? 0,
      initialAnsweredCount: currentPlayer?.answeredCount ?? 0,
      initialRoundWins: currentPlayer?.roundWins ?? 0,
      initialLivesRemaining: currentPlayer?.lives ?? 0,
      initiallyEliminated: currentPlayer?.eliminated ?? false,
      // Pass question state so the native game can resume at the correct question
      // when a player joins mid-game or a new round begins in round-based modes.
      questionIds: room.questionIds,
      currentQuestionIndex: room.currentQuestionIndex,
    );
  }

  Future<void> _shareRoom(Room room) async {
    try {
      await Share.share(
        'انضم إلى غرفتي في تحدي المليون.\nرمز الغرفة: ${room.id}\nافتح اللعب الجماعي وأدخل الرمز للانضمام.',
        subject: 'دعوة إلى غرفة جماعية',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح نافذة المشاركة على هذا الجهاز.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _confirmLeave() async {
    if (_leaving) return false;
    final userId = context.read<AppState>().user?.uid;
    final isSpectator = widget.isSpectator ||
        userId == null ||
        (_latestRoom != null && !_latestRoom!.containsPlayer(userId));
    if (isSpectator) {
      unawaited(_leaveRoom());
      return false;
    }
    final gameInProgress = _latestRoom != null &&
        _latestRoom!.started &&
        _latestRoom!.phase != Room.phaseFinished;
    final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: const Color(0xFF152055),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.logout_rounded,
                        color: Color(0xFFF87171), size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'مغادرة الغرفة؟',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gameInProgress
                        ? 'ستفقد مقعدك مؤقتاً لكن يمكنك العودة والانضمام من قائمة الغرف طالما اللعبة مستمرة.'
                        : 'سيتم إخراجك من غرفة الانتظار.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: const Text(
                              'البقاء',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'مغادرة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;

    if (shouldLeave) unawaited(_leaveRoom());
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AppState>().user?.uid ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _confirmLeave();
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/ui/bg_main.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0A1B4A).withValues(alpha: 0.88),
                  const Color(0xFF060C24).withValues(alpha: 0.94),
                ],
              ),
            ),
            child: SafeArea(
              child: StreamBuilder<Room?>(
                stream: context.read<RoomService>().watchRoom(widget.roomId),
                builder: (context, snapshot) {
                  // Loading
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return _LoadingState(
                        onBack: () => Navigator.of(context).pop());
                  }

                  final room = snapshot.data;

                  // Room closed
                  if (room == null) {
                    return _ClosedState(
                        onBack: () => Navigator.of(context).pop());
                  }

                  // Keep _latestRoom in sync for the leave-confirmation dialog.
                  _latestRoom = room;

                  // Spectator: user navigated here to watch, not to play.
                  final isSpectator =
                      widget.isSpectator || !room.containsPlayer(currentUserId);

                  final playerIds = room.playerIds;

                  return StreamBuilder<Map<String, PlayerProfile>>(
                    stream:
                        context.read<ProfileService>().watchProfiles(playerIds),
                    builder: (context, profileSnapshot) {
                      final profiles = profileSnapshot.data ??
                          const <String, PlayerProfile>{};
                      final sortedIds = room.playerIds
                        ..sort((a, b) {
                          if (a == room.hostId) return -1;
                          if (b == room.hostId) return 1;
                          return a.compareTo(b);
                        });

                      final currentPlayer = room.players[currentUserId];
                      final readyValue = currentPlayer?.ready ?? false;
                      final isHost = widget.createdByCurrentUser ||
                          currentUserId == room.hostId;

                      // Round-based modes re-launch native for every new round.
                      const roundBasedModes = {
                        'elimination',
                        'survival',
                        'series'
                      };
                      final isRoundBased = roundBasedModes.contains(room.mode);
                      const isMidGameWaiting = false;

                      // Don't re-launch if the game is already finished, if the
                      // user is only spectating.
                      final shouldLaunch = !isSpectator &&
                          room.started &&
                          room.phase != Room.phaseFinished &&
                          ((!isRoundBased && !_navigatedToGame) ||
                              (isRoundBased &&
                                  room.phase == 'playing_round' &&
                                  room.startedAt != null &&
                                  room.startedAt != _lastLaunchedRoundAt));
                      if (shouldLaunch) {
                        _navigatedToGame = true;
                        _lastLaunchedRoundAt = room.startedAt;
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          if (!mounted) return;
                          await _launchNativeMatchIfPossible(
                            room: room,
                            profiles: profiles,
                            currentUserId: currentUserId,
                            matchMode: room.mode,
                            isResumingMidGame: widget.isJoiningMidGame,
                          );
                        });
                      }

                      // Blitz: start countdown as soon as the game is live.
                      if (room.mode == Room.modeBlitz &&
                          room.phase == Room.phasePlaying &&
                          room.startedAt != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _scheduleBlitzFinalization(room);
                        });
                      }

                      return Column(
                        children: [
                          // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Header ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
                          _LobbyHeader(
                            room: room,
                            pulseCtrl: _pulseCtrl,
                            onBack: _confirmLeave,
                            blitzSecondsLeft: room.mode == Room.modeBlitz &&
                                    room.phase == Room.phasePlaying
                                ? _blitzSecondsLeft
                                : null,
                          ),
                          // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Content ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final narrow = constraints.maxWidth < 700;
                                final shortScreen = constraints.maxHeight < 370;

                                final playersPanel = _PlayersPanel(
                                  room: room,
                                  sortedIds: sortedIds,
                                  profiles: profiles,
                                  currentUserId: currentUserId,
                                );

                                final controlsPanel = _ControlsPanel(
                                  room: room,
                                  profiles: profiles,
                                  currentUserId: currentUserId,
                                  isHost: isHost,
                                  isSpectator: isSpectator,
                                  isMidGameWaiting: isMidGameWaiting,
                                  readyValue: readyValue,
                                  starting: _starting,
                                  leaving: _leaving,
                                  onToggleReady: (v) => _toggleReady(room, v),
                                  onStartRoom: () => _startRoom(room),
                                  onStartNextRound: () => _startNextRound(room),
                                  onShareRoom: () => _shareRoom(room),
                                  onLeaveRoom: _confirmLeave,
                                );

                                if (narrow || shortScreen) {
                                  final playersHeight = shortScreen
                                      ? (constraints.maxHeight - 24)
                                          .clamp(260.0, 330.0)
                                          .toDouble()
                                      : 320.0;
                                  return SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                        14, 0, 14, 16),
                                    child: Column(
                                      children: [
                                        controlsPanel,
                                        const SizedBox(height: 14),
                                        SizedBox(
                                          height: playersHeight,
                                          child: playersPanel,
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 6, child: playersPanel),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        flex: 4,
                                        child: SingleChildScrollView(
                                            child: controlsPanel),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _fallbackName(String value) {
    if (Room.isBotUserId(value)) return Room.botDisplayName(value);
    if (value.length <= 8) return value;
    return '${value.substring(0, 8)}...';
  }

  static bool _needsProfileHydration(PlayerProfile? p) {
    if (p == null) return true;
    return p.username.trim().isEmpty || (p.photoUrl ?? '').trim().isEmpty;
  }

  static bool _hasMoreProfileData({
    required PlayerProfile? current,
    required PlayerProfile? candidate,
  }) {
    if (candidate == null) return false;
    if (current == null) return true;
    if (current.username.trim().isEmpty &&
        candidate.username.trim().isNotEmpty) {
      return true;
    }
    if ((current.photoUrl ?? '').trim().isEmpty &&
        (candidate.photoUrl ?? '').trim().isNotEmpty) {
      return true;
    }
    return false;
  }
}

// ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Header ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

String _roomModeLabel(String mode) => switch (mode) {
      Room.modeElimination => 'إقصاء',
      Room.modeSurvival => 'نجاة',
      Room.modeSeries => 'سلسلة',
      Room.modeTeamBattle => 'مواجهة الفرق',
      Room.modeBlitz => 'بلتز',
      _ => 'تنافس',
    };

Color _roomModeColor(String mode) => switch (mode) {
      Room.modeElimination => const Color(0xFFEF4444),
      Room.modeSurvival => const Color(0xFFF97316),
      Room.modeSeries => const Color(0xFFF59E0B),
      Room.modeTeamBattle => const Color(0xFF8B5CF6),
      Room.modeBlitz => const Color(0xFF10B981),
      _ => const Color(0xFF38BDF8),
    };

String _roomPhaseLabel(String phase) => switch (phase) {
      Room.phasePlayingRound => 'جولة جارية',
      Room.phaseRoundOver => 'نهاية الجولة',
      Room.phaseFinished => 'انتهت',
      Room.phasePlaying => 'جارية',
      _ => 'الانتظار',
    };

Color _roomPhaseColor(String phase) => switch (phase) {
      Room.phasePlayingRound => const Color(0xFF38BDF8),
      Room.phaseRoundOver => const Color(0xFFFACC15),
      Room.phaseFinished => const Color(0xFF4ADE80),
      Room.phasePlaying => const Color(0xFF38BDF8),
      _ => const Color(0xFFA78BFA),
    };

String _roomPlayerName({
  required String playerId,
  required Map<String, PlayerProfile> profiles,
}) {
  if (Room.isBotUserId(playerId)) {
    return Room.botProfile(playerId).displayName;
  }
  return profiles[playerId]?.username ??
      _RoomLobbyScreenState._fallbackName(playerId);
}

String _teamLabel(String teamId) =>
    teamId == Room.teamA ? 'الفريق أ' : 'الفريق ب';

String _teamShortLabel(String teamId) => teamId == Room.teamA ? 'أ' : 'ب';

class _LobbyHeader extends StatelessWidget {
  const _LobbyHeader({
    required this.room,
    required this.pulseCtrl,
    required this.onBack,
    this.blitzSecondsLeft,
  });

  final Room room;
  final AnimationController pulseCtrl;
  final Future<bool> Function() onBack;
  final int? blitzSecondsLeft;

  @override
  Widget build(BuildContext context) {
    final modeColor = _roomModeColor(room.mode);
    final phaseColor = _roomPhaseColor(room.phase);
    final aliveCount = room.mode == Room.modeSurvival
        ? room.survivalAliveCount
        : room.aliveCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.meeting_room_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'غرفة الانتظار',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
                Text(
                  'رمز الغرفة: ${room.id}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MiniChip(
                      label: _roomModeLabel(room.mode),
                      color: modeColor,
                    ),
                    _MiniChip(
                      label: _roomPhaseLabel(room.phase),
                      color: phaseColor,
                    ),
                    if (room.isRoundBasedMode)
                      _MiniChip(
                        label: 'الجولة ${room.roundNumber}',
                        color: const Color(0xFF38BDF8),
                      ),
                    if (room.mode == Room.modeSurvival)
                      _MiniChip(
                        label: 'المتبقي $aliveCount',
                        color: const Color(0xFF4ADE80),
                      ),
                    if (blitzSecondsLeft != null)
                      _MiniChip(
                        label: '$blitzSecondsLeftث',
                        color: blitzSecondsLeft! > 10
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Player count chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF4ADE80).withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: pulseCtrl,
                  builder: (_, __) => Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(
                        const Color(0xFF4ADE80),
                        const Color(0xFF86EFAC),
                        pulseCtrl.value,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${room.playerCount}/${room.maxPlayers}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4ADE80),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Players panel ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

class _PlayersPanel extends StatelessWidget {
  const _PlayersPanel({
    required this.room,
    required this.sortedIds,
    required this.profiles,
    required this.currentUserId,
  });

  final Room room;
  final List<String> sortedIds;
  final Map<String, PlayerProfile> profiles;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final isTeamBattle = room.mode == Room.modeTeamBattle;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1F3D), Color(0xFF0A1228)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.groups_rounded,
                color: Color(0xFFA78BFA),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'اللاعبون',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              if (isTeamBattle) ...[
                const Spacer(),
                const _TeamLegend(),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (isTeamBattle) _buildTeamBattleOverview(),
          if (isTeamBattle) const SizedBox(height: 12),
          Expanded(
            child: isTeamBattle
                ? _buildTeamBattleRoster()
                : ListView(
                    children: [
                      ...sortedIds.map(_buildPlayerTile),
                      ...List.generate(
                        math.max(0, room.maxPlayers - sortedIds.length),
                        (i) => const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: _EmptySlot(),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamBattleOverview() {
    final teamSizes = room.teamSizes;
    final teamScores = room.teamScores;
    final balanceIssue = room.teamBattleBalanceIssue;
    final isDraw = room.isTeamBattleDraw;
    final subtitle = balanceIssue ??
        (room.phase == Room.phaseFinished
            ? (room.winnerTeamId != null
                ? '${_teamLabel(room.winnerTeamId!)} حسم المواجهة بمجموع النقاط.'
                : 'انتهت المواجهة بالتعادل في مجموع النقاط.')
            : room.playerCount < room.maxPlayers
                ? 'سيتم ملء المقاعد الشاغرة بروبوتات متوازنة عند بدء المضيف.'
                : 'الفرق متوازنة وجاهزة للانطلاق.');

    final accentColor = balanceIssue != null
        ? const Color(0xFFEF4444)
        : room.winnerTeamId == Room.teamA
            ? const Color(0xFF3B82F6)
            : room.winnerTeamId == Room.teamB
                ? const Color(0xFFEF4444)
                : isDraw
                    ? const Color(0xFFFACC15)
                    : const Color(0xFF10B981);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, color: accentColor, size: 16),
              const SizedBox(width: 8),
              Text(
                room.phase == Room.phaseFinished
                    ? (room.winnerTeamId != null
                        ? 'الفريق الفائز: ${_teamLabel(room.winnerTeamId!)}'
                        : 'النتيجة النهائية: تعادل')
                    : 'حالة توازن الفرق',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TeamOverviewChip(
                teamId: Room.teamA,
                score: teamScores[Room.teamA] ?? 0,
                sizeLabel:
                    '${teamSizes[Room.teamA] ?? 0}/${room.teamBattleTeamCapacity}',
              ),
              _TeamOverviewChip(
                teamId: Room.teamB,
                score: teamScores[Room.teamB] ?? 0,
                sizeLabel:
                    '${teamSizes[Room.teamB] ?? 0}/${room.teamBattleTeamCapacity}',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamBattleRoster() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 860;
        final teamASection = _buildTeamSection(Room.teamA);
        final teamBSection = _buildTeamSection(Room.teamB);
        if (stacked) {
          return ListView(
            children: [
              teamASection,
              const SizedBox(height: 12),
              teamBSection,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: teamASection),
            const SizedBox(width: 12),
            Expanded(child: teamBSection),
          ],
        );
      },
    );
  }

  Widget _buildTeamSection(String teamId) {
    final isA = teamId == Room.teamA;
    final color = isA ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);
    final teamPlayerIds = sortedIds
        .where((id) => room.players[id]?.teamId == teamId)
        .toList(growable: false);
    final emptyCount =
        math.max(0, room.teamBattleTeamCapacity - teamPlayerIds.length);
    final isWinningTeam = room.phase == Room.phaseFinished &&
        room.winnerTeamId != null &&
        room.winnerTeamId == teamId;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isWinningTeam ? 0.6 : 0.3),
          width: isWinningTeam ? 1.6 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.groups_2_rounded,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _teamLabel(teamId),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isWinningTeam)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFACC15).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFFACC15).withValues(alpha: 0.42),
                    ),
                  ),
                  child: const Text(
                    'فائز',
                    style: TextStyle(
                      color: Color(0xFFFACC15),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChip(
                label: 'الإجمالي ${room.teamScore(teamId)}',
                color: color,
              ),
              _MiniChip(
                label:
                    'التشكيلة ${room.teamSize(teamId)}/${room.teamBattleTeamCapacity}',
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...teamPlayerIds.map(_buildPlayerTile),
          ...List.generate(
            emptyCount,
            (i) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: _EmptySlot(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(String id) {
    final player = room.players[id]!;
    final profile = profiles[id];
    final isBot = Room.isBotUserId(id);
    final botProfile = isBot ? Room.botProfile(id) : null;
    final isMe = id == currentUserId;
    final canSwitchTeam = room.mode == Room.modeTeamBattle &&
        !room.started &&
        !isBot &&
        (isMe || currentUserId == room.hostId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _PlayerTile(
        isHost: id == room.hostId,
        isCurrentUser: isMe,
        isBot: isBot,
        username: isBot
            ? botProfile!.displayName
            : profile?.username ?? _RoomLobbyScreenState._fallbackName(id),
        photoUrl: profile?.photoUrl,
        botSeed: botProfile?.avatarSeed ?? 0,
        botIntelligence: botProfile?.intelligence,
        ready: player.ready,
        roomStarted: room.started,
        mode: room.mode,
        phase: room.phase,
        score: player.score,
        lives: player.lives,
        eliminated: player.eliminated,
        teamId: room.mode == Room.modeTeamBattle ? player.teamId : null,
        canSwitchTeam: canSwitchTeam,
        roomId: room.id,
        userId: id,
      ),
    );
  }
}

class _TeamOverviewChip extends StatelessWidget {
  const _TeamOverviewChip({
    required this.teamId,
    required this.score,
    required this.sizeLabel,
  });

  final String teamId;
  final int score;
  final String sizeLabel;

  @override
  Widget build(BuildContext context) {
    final isA = teamId == Room.teamA;
    final color = isA ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _teamLabel(teamId),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$score نقطة  |  $sizeLabel',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamLegend extends StatelessWidget {
  const _TeamLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _teamDot(const Color(0xFF3B82F6)),
        const SizedBox(width: 2),
        Text(_teamShortLabel(Room.teamA),
            style: const TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 11,
                fontWeight: FontWeight.w800)),
        const SizedBox(width: 10),
        _teamDot(const Color(0xFFEF4444)),
        const SizedBox(width: 2),
        Text(_teamShortLabel(Room.teamB),
            style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 11,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _teamDot(Color color) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.isHost,
    required this.isCurrentUser,
    required this.isBot,
    required this.username,
    required this.photoUrl,
    required this.botSeed,
    required this.botIntelligence,
    required this.ready,
    required this.roomStarted,
    required this.mode,
    required this.phase,
    required this.score,
    required this.lives,
    required this.eliminated,
    this.teamId,
    this.canSwitchTeam = false,
    this.roomId,
    this.userId,
  });

  final bool isHost;
  final bool isCurrentUser;
  final bool isBot;
  final String username;
  final String? photoUrl;
  final int botSeed;
  final int? botIntelligence;
  final bool ready;
  final bool roomStarted;
  final String mode;
  final String phase;
  final int score;
  final int lives;
  final bool eliminated;
  final String? teamId;
  final bool canSwitchTeam;
  final String? roomId;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final showReadyState = !roomStarted || phase == Room.phaseLobby;
    final showsLives = mode == Room.modeSurvival;
    final showsEliminationState =
        mode == Room.modeSurvival || mode == Room.modeElimination;
    final activeStatusLabel = phase == Room.phaseFinished ? 'انتهت' : 'جارية';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFF7C3AED).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          _Avatar(isBot: isBot, photoUrl: photoUrl, seed: botSeed, size: 42),
          const SizedBox(width: 10),
          // Name + badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isCurrentUser ? '$username (أنت)' : username,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isHost) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFACC15).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'المضيف',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFCD34D),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (isBot && botIntelligence != null) ...[
                      _MiniChip(
                        label: 'ذكاء ${botIntelligence!}%',
                        color: const Color(0xFF38BDF8),
                      ),
                      const SizedBox(width: 5),
                    ],
                    _MiniChip(
                      label: '$score نقطة',
                      color: const Color(0xFFFACC15),
                    ),
                    if (showsLives) ...[
                      const SizedBox(width: 5),
                      _MiniChip(
                        label: 'أرواح $lives',
                        color: lives > 1
                            ? const Color(0xFFF97316)
                            : const Color(0xFFEF4444),
                      ),
                    ],
                    if (showsEliminationState) ...[
                      const SizedBox(width: 5),
                      _MiniChip(
                        label: eliminated ? 'مقصي' : 'صامد',
                        color: eliminated
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF4ADE80),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Team badge / switch button
          if (teamId != null) ...[
            const SizedBox(width: 8),
            canSwitchTeam
                ? GestureDetector(
                    onTap: () async {
                      try {
                        await context.read<RoomService>().switchTeam(
                              roomId: roomId!,
                              userId: userId!,
                            );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error.toString()),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: _TeamBadge(teamId: teamId!, tappable: true),
                  )
                : _TeamBadge(teamId: teamId!, tappable: false),
          ],
          const SizedBox(width: 8),
          // Ready status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: showReadyState
                  ? (ready
                      ? const Color(0xFF4ADE80).withValues(alpha: 0.15)
                      : const Color(0xFF374151).withValues(alpha: 0.6))
                  : (eliminated
                      ? const Color(0xFF7F1D1D).withValues(alpha: 0.45)
                      : const Color(0xFF0F766E).withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: showReadyState
                    ? (ready
                        ? const Color(0xFF4ADE80).withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.08))
                    : (eliminated
                        ? const Color(0xFFF87171).withValues(alpha: 0.45)
                        : const Color(0xFF5EEAD4).withValues(alpha: 0.35)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showReadyState
                      ? (ready
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_top_rounded)
                      : (eliminated
                          ? Icons.heart_broken_rounded
                          : Icons.bolt_rounded),
                  size: 13,
                  color: showReadyState
                      ? (ready
                          ? const Color(0xFF4ADE80)
                          : Colors.white.withValues(alpha: 0.35))
                      : (eliminated
                          ? const Color(0xFFF87171)
                          : const Color(0xFF5EEAD4)),
                ),
                const SizedBox(width: 4),
                Text(
                  showReadyState
                      ? (ready ? 'جاهز' : 'بانتظار')
                      : (eliminated ? 'خرج' : activeStatusLabel),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: showReadyState
                        ? (ready
                            ? const Color(0xFF4ADE80)
                            : Colors.white.withValues(alpha: 0.35))
                        : (eliminated
                            ? const Color(0xFFF87171)
                            : const Color(0xFF5EEAD4)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamBadge extends StatelessWidget {
  const _TeamBadge({required this.teamId, required this.tappable});
  final String teamId;
  final bool tappable;

  @override
  Widget build(BuildContext context) {
    final isA = teamId == 'A';
    final color = isA ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _teamLabel(teamId),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          if (tappable) ...[
            const SizedBox(width: 4),
            Icon(Icons.swap_horiz_rounded, size: 13, color: color),
          ],
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  style: BorderStyle.solid),
            ),
            child: Icon(Icons.person_add_rounded,
                size: 18, color: Colors.white.withValues(alpha: 0.2)),
          ),
          const SizedBox(width: 12),
          Text(
            'بانتظار لاعب...',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.2),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Controls panel ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
    required this.room,
    required this.profiles,
    required this.currentUserId,
    required this.isHost,
    required this.isSpectator,
    required this.isMidGameWaiting,
    required this.readyValue,
    required this.starting,
    required this.leaving,
    required this.onToggleReady,
    required this.onStartRoom,
    required this.onStartNextRound,
    required this.onShareRoom,
    required this.onLeaveRoom,
  });

  final Room room;
  final Map<String, PlayerProfile> profiles;
  final String currentUserId;
  final bool isHost;
  final bool isSpectator;
  final bool isMidGameWaiting;
  final bool readyValue;
  final bool starting;
  final bool leaving;
  final ValueChanged<bool> onToggleReady;
  final VoidCallback onStartRoom;
  final VoidCallback onStartNextRound;
  final VoidCallback onShareRoom;
  final Future<bool> Function() onLeaveRoom;

  @override
  Widget build(BuildContext context) {
    if (isSpectator) {
      return _SpectatorPanel(room: room, onLeaveRoom: onLeaveRoom);
    }
    if (isMidGameWaiting) {
      return _MidGameWaitingPanel(room: room, onLeaveRoom: onLeaveRoom);
    }
    return _ControlsPanelBody(
      room: room,
      profiles: profiles,
      currentUserId: currentUserId,
      isHost: isHost,
      readyValue: readyValue,
      starting: starting,
      leaving: leaving,
      onToggleReady: onToggleReady,
      onStartRoom: onStartRoom,
      onStartNextRound: onStartNextRound,
      onShareRoom: onShareRoom,
      onLeaveRoom: onLeaveRoom,
    );

    /*
    final hostName = profiles[room.hostId]?.username ??
        _RoomLobbyScreenState._fallbackName(room.hostId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Ready toggle ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
        GestureDetector(
          onTap: () => onToggleReady(!readyValue),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: readyValue
                    ? [
                        const Color(0xFF14532D),
                        const Color(0xFF166534),
                      ]
                    : [
                        const Color(0xFF1E3A8A),
                        const Color(0xFF1E1B4B),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: readyValue
                    ? const Color(0xFF4ADE80).withValues(alpha: 0.5)
                    : const Color(0xFF3B82F6).withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: readyValue
                        ? const Color(0xFF4ADE80).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    readyValue
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: readyValue
                        ? const Color(0xFF4ADE80)
                        : Colors.white.withValues(alpha: 0.5),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        readyValue ? 'ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â¡ÃƒËœÃ‚Â²!' : 'ÃƒËœÃ‚ÂºÃƒâ„¢Ã…Â ÃƒËœÃ‚Â± ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â¡ÃƒËœÃ‚Â²',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: readyValue
                              ? const Color(0xFF4ADE80)
                              : Colors.white,
                        ),
                      ),
                      Text(
                        'ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¶ÃƒËœÃ‚ÂºÃƒËœÃ‚Â· Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚ÂªÃƒËœÃ‚Â¨ÃƒËœÃ‚Â¯Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Å¾',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle switch
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 26,
                  decoration: BoxDecoration(
                    color: readyValue
                        ? const Color(0xFF4ADE80)
                        : Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: readyValue
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                              offset: Offset(0, 1))
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Start game button (host only) ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
        _ActionBtn(
          label: starting
              ? 'ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â§ÃƒËœÃ‚Â±Ãƒâ„¢Ã…Â  ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â¡...'
              : isHost
                  ? 'ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â¡ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â§ÃƒËœÃ‚Â±ÃƒËœÃ‚Â§ÃƒËœÃ‚Â©'
                  : 'Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚ÂªÃƒËœÃ‚Â¸ÃƒËœÃ‚Â± ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â¶Ãƒâ„¢Ã…Â Ãƒâ„¢Ã‚Â',
          icon: Icons.rocket_launch_rounded,
          colors: const [Color(0xFFF8D34C), Color(0xFFF59E0B)],
          borderColor: const Color(0xFFFFF3A3),
          textColor: const Color(0xFF1F2937),
          enabled: isHost && !starting,
          onTap: isHost && !starting ? onStartRoom : null,
        ),
        const SizedBox(height: 8),

        // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Waiting message (non-host) ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
        if (!isHost)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.hourglass_top_rounded,
                    size: 16,
                    color: const Color(0xFFFACC15).withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ãƒâ„¢Ã‚ÂÃƒâ„¢Ã…Â  ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚ÂªÃƒËœÃ‚Â¸ÃƒËœÃ‚Â§ÃƒËœÃ‚Â± $hostName Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â¡',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Share Room ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
        _ActionBtn(
          label: 'Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â´ÃƒËœÃ‚Â§ÃƒËœÃ‚Â±Ãƒâ„¢Ã†â€™ÃƒËœÃ‚Â© ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚ÂºÃƒËœÃ‚Â±Ãƒâ„¢Ã‚ÂÃƒËœÃ‚Â©',
          icon: Icons.share_rounded,
          colors: const [Color(0xFF1E3A8A), Color(0xFF1E1B4B)],
          borderColor: const Color(0xFF3B82F6),
          textColor: Colors.white,
          enabled: true,
          onTap: onShareRoom,
        ),
        const SizedBox(height: 8),

        // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Leave Room ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
        _ActionBtn(
          label: leaving ? 'ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â§ÃƒËœÃ‚Â±Ãƒâ„¢Ã…Â  ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚ÂºÃƒËœÃ‚Â§ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â±ÃƒËœÃ‚Â©...' : 'Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚ÂºÃƒËœÃ‚Â§ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â±ÃƒËœÃ‚Â© ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚ÂºÃƒËœÃ‚Â±Ãƒâ„¢Ã‚ÂÃƒËœÃ‚Â©',
          icon: Icons.logout_rounded,
          colors: const [Color(0xFF7F1D1D), Color(0xFF450A0A)],
          borderColor: const Color(0xFFF87171),
          textColor: Colors.white,
          enabled: !leaving,
          onTap: leaving ? null : onLeaveRoom,
        ),
        const SizedBox(height: 12),

        // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Info note ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  switch (room.mode) {
                    'elimination' =>
                      'Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¶ÃƒËœÃ‚Â¹ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¥Ãƒâ„¢Ã¢â‚¬Å¡ÃƒËœÃ‚ÂµÃƒËœÃ‚Â§ÃƒËœÃ‚Â¡: ÃƒËœÃ‚Â®ÃƒËœÃ‚Â·ÃƒËœÃ‚Â£ Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â§ÃƒËœÃ‚Â­ÃƒËœÃ‚Â¯ = ÃƒËœÃ‚Â®ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¬ Ãƒâ„¢Ã‚ÂÃƒâ„¢Ã‹â€ ÃƒËœÃ‚Â±Ãƒâ„¢Ã…Â .',
                    'survival' =>
                      'Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¶ÃƒËœÃ‚Â¹ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â§ÃƒËœÃ‚Â©: 3 ÃƒËœÃ‚Â£ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â§ÃƒËœÃ‚Â­ Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã†â€™Ãƒâ„¢Ã¢â‚¬Å¾ Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â¨ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ÃƒËœÃ‚ÂªÃƒâ„¢Ã‚ÂÃƒâ„¢Ã¢â‚¬Å¡ÃƒËœÃ‚ÂµÃƒâ„¢Ã¢â‚¬Â° ÃƒËœÃ‚Â¹Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â¯ Ãƒâ„¢Ã¢â‚¬Â Ãƒâ„¢Ã‚ÂÃƒËœÃ‚Â§ÃƒËœÃ‚Â¯Ãƒâ„¢Ã¢â‚¬Â¡ÃƒËœÃ‚Â§.',
                    'series' =>
                      'Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¶ÃƒËœÃ‚Â¹ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â³Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â³Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â©: ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã‚ÂÃƒËœÃ‚Â§ÃƒËœÃ‚Â¦ÃƒËœÃ‚Â² ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â¬Ãƒâ„¢Ã‹â€ Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚ÂªÃƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Â  ÃƒËœÃ‚Â£Ãƒâ„¢Ã‹â€ Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â¹ Ãƒâ„¢Ã…Â Ãƒâ„¢Ã†â€™ÃƒËœÃ‚Â³ÃƒËœÃ‚Â¨ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â³Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â³Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â©.',
                    'team_battle' =>
                      'Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¶ÃƒËœÃ‚Â¹ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã‚ÂÃƒËœÃ‚Â±Ãƒâ„¢Ã¢â‚¬Å¡: ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã‚ÂÃƒËœÃ‚Â±Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Å¡ A Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã¢â‚¬Å¡ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¨Ãƒâ„¢Ã¢â‚¬Å¾ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã‚ÂÃƒËœÃ‚Â±Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Å¡ B ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â¬Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¹ Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â­ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â¯ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã‚ÂÃƒËœÃ‚Â§ÃƒËœÃ‚Â¦ÃƒËœÃ‚Â².',
                    'blitz' =>
                      'Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¶ÃƒËœÃ‚Â¹ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¨Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚ÂªÃƒËœÃ‚Â²: ÃƒËœÃ‚Â£ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â¨ ÃƒËœÃ‚Â¹Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â° ÃƒËœÃ‚Â£Ãƒâ„¢Ã†â€™ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â± ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â¯ Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã†â€™Ãƒâ„¢Ã¢â‚¬Â  Ãƒâ„¢Ã¢â‚¬Å¡ÃƒËœÃ‚Â¨Ãƒâ„¢Ã¢â‚¬Å¾ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚ÂªÃƒâ„¢Ã¢â‚¬Â¡ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¡ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã‹â€ Ãƒâ„¢Ã¢â‚¬Å¡ÃƒËœÃ‚Âª.',
                    _ =>
                      'ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â¶Ãƒâ„¢Ã…Â Ãƒâ„¢Ã‚Â Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã†â€™Ãƒâ„¢Ã¢â‚¬Â Ãƒâ„¢Ã¢â‚¬Â¡ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â¡ Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â¨Ãƒâ„¢Ã†â€™ÃƒËœÃ‚Â±ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â¹ÃƒËœÃ…â€™ Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â³ÃƒËœÃ‚ÂªÃƒâ„¢Ã‚ÂÃƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â£ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã¢â‚¬Å¡ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â¯ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã‚ÂÃƒËœÃ‚Â§ÃƒËœÃ‚Â±ÃƒËœÃ‚ÂºÃƒËœÃ‚Â© ÃƒËœÃ‚Â¨Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â¨Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Â  ÃƒËœÃ‚Â¢Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã…Â Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Â .',
                  },
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.35),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    */
  }
}

// ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Loading / Closed states ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

class _MidGameWaitingPanel extends StatelessWidget {
  const _MidGameWaitingPanel({required this.room, required this.onLeaveRoom});

  final Room room;
  final Future<bool> Function() onLeaveRoom;

  @override
  Widget build(BuildContext context) {
    final isRoundBased = room.isRoundBasedMode;
    final message = isRoundBased
        ? 'ستنضم تلقائياً في الجولة القادمة عند انتهاء الجولة الحالية'
        : 'ستظهر نتائجك عند انتهاء اللعبة الحالية';
    final phaseColor = _roomPhaseColor(room.phase);
    final phaseLabel = _roomPhaseLabel(room.phase);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1C1207), Color(0xFF3B1F08)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded,
                    color: Color(0xFFFACC15), size: 28),
              ),
              const SizedBox(height: 12),
              const Text(
                'في انتظار الجولة القادمة',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: phaseColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  phaseLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: phaseColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onLeaveRoom,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.exit_to_app_rounded,
                    color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Text(
                  'مغادرة الغرفة',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SpectatorPanel extends StatelessWidget {
  const _SpectatorPanel({required this.room, required this.onLeaveRoom});

  final Room room;
  final Future<bool> Function() onLeaveRoom;

  @override
  Widget build(BuildContext context) {
    final phaseLabel = _roomPhaseLabel(room.phase);
    final phaseColor = _roomPhaseColor(room.phase);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF1E1B4B)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.visibility_rounded,
                    color: Color(0xFF38BDF8), size: 28),
              ),
              const SizedBox(height: 12),
              const Text(
                'أنت تشاهد الآن',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: phaseColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  phaseLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: phaseColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'يمكنك متابعة اللعبة ومشاهدة النتائج في الوقت الفعلي',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onLeaveRoom,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.exit_to_app_rounded,
                    color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Text(
                  'مغادرة المشاهدة',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlsPanelBody extends StatelessWidget {
  const _ControlsPanelBody({
    required this.room,
    required this.profiles,
    required this.currentUserId,
    required this.isHost,
    required this.readyValue,
    required this.starting,
    required this.leaving,
    required this.onToggleReady,
    required this.onStartRoom,
    required this.onStartNextRound,
    required this.onShareRoom,
    required this.onLeaveRoom,
  });

  final Room room;
  final Map<String, PlayerProfile> profiles;
  final String currentUserId;
  final bool isHost;
  final bool readyValue;
  final bool starting;
  final bool leaving;
  final ValueChanged<bool> onToggleReady;
  final VoidCallback onStartRoom;
  final VoidCallback onStartNextRound;
  final VoidCallback onShareRoom;
  final Future<bool> Function() onLeaveRoom;

  @override
  Widget build(BuildContext context) {
    final hostName = _roomPlayerName(playerId: room.hostId, profiles: profiles);
    final currentPlayer = room.players[currentUserId];
    final isLobbyState = !room.started || room.phase == Room.phaseLobby;
    final isRoundOver = room.phase == Room.phaseRoundOver;
    final isFinished = room.phase == Room.phaseFinished;
    final isSurvival = room.mode == Room.modeSurvival;
    final isTeamBattle = room.mode == Room.modeTeamBattle;
    final aliveCount = isSurvival ? room.survivalAliveCount : room.aliveCount;
    final currentPlayerEliminated = currentPlayer?.eliminated == true ||
        (isSurvival && (currentPlayer?.lives ?? 0) <= 0);
    final winnerName = room.winnerId == null
        ? null
        : _roomPlayerName(playerId: room.winnerId!, profiles: profiles);
    final teamBalanceIssue = isTeamBattle ? room.teamBattleBalanceIssue : null;
    final teamAScore = room.teamScore(Room.teamA);
    final teamBScore = room.teamScore(Room.teamB);
    final canStartNow =
        isHost && !starting && (!isTeamBattle || teamBalanceIssue == null);

    final statusTitle = switch (room.phase) {
      Room.phasePlayingRound => room.isRoundBasedMode
          ? 'الجولة ${room.roundNumber} جارية'
          : '${_roomModeLabel(room.mode)} جارٍ',
      Room.phaseRoundOver => 'انتهت الجولة ${room.roundNumber}',
      Room.phaseFinished => 'انتهت المواجهة',
      Room.phasePlaying when isTeamBattle => 'مواجهة الفرق جارية',
      Room.phasePlaying => '${_roomModeLabel(room.mode)} جارٍ',
      _ => '${_roomModeLabel(room.mode)} في الانتظار',
    };

    final statusBody = switch (room.phase) {
      Room.phaseLobby when isTeamBattle && teamBalanceIssue != null =>
        teamBalanceIssue,
      Room.phaseLobby when isTeamBattle && room.playerCount < room.maxPlayers =>
        'توزيع الفرق صالح. يمكن للمضيف البدء الآن، وأي مقاعد شاغرة سيكملها خصوم آليون بشكل متوازن.',
      Room.phaseLobby when isTeamBattle =>
        'الفرق متوازنة وجاهزة. ما زال بإمكان اللاعبين تبديل الفريق قبل بدء المواجهة.',
      Room.phasePlayingRound when isSurvival && currentPlayerEliminated =>
        'تم إقصاؤك. ننتظر اللاعبين الصامدين حتى ينهوا هذه الجولة.',
      Room.phasePlayingRound when isSurvival =>
        'لا يزال $aliveCount لاعبين صامدين في طور النجاة.',
      Room.phasePlayingRound => 'بانتظار انتهاء الجولة الحالية.',
      Room.phasePlaying
          when isTeamBattle && currentPlayer?.completedAt != null =>
        'تم تثبيت نتيجتك. ننتظر بقية اللاعبين حتى يكتمل مجموع الفريقين.',
      Room.phasePlaying when isTeamBattle =>
        'اللاعبون ينهون جولاتهم الفردية الآن، ومجموع الفريقين يتحدث من مجموع نقاط الجميع.',
      Room.phaseRoundOver when isHost =>
        'بقي أكثر من لاعب صامدًا. ابدأ الجولة التالية عندما تكون جاهزًا.',
      Room.phaseRoundOver => 'بانتظار $hostName ليبدأ الجولة التالية.',
      Room.phaseFinished when isTeamBattle && room.winnerTeamId != null =>
        '${_teamLabel(room.winnerTeamId!)} حسمت النتيجة $teamAScore-$teamBScore بمجموع النقاط.',
      Room.phaseFinished when isTeamBattle =>
        'انتهت نتيجة الفريقين بالتعادل $teamAScore-$teamBScore.',
      Room.phaseFinished when winnerName != null => 'الفائز: $winnerName',
      Room.phaseFinished => 'انتهت الغرفة.',
      _ => 'يمكن للمضيف البدء مبكرًا أو ملء المقاعد الشاغرة بخصوم آليين.',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLobbyState) ...[
          GestureDetector(
            onTap: () => onToggleReady(!readyValue),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: readyValue
                      ? [
                          const Color(0xFF14532D),
                          const Color(0xFF166534),
                        ]
                      : [
                          const Color(0xFF1E3A8A),
                          const Color(0xFF1E1B4B),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: readyValue
                      ? const Color(0xFF4ADE80).withValues(alpha: 0.5)
                      : const Color(0xFF3B82F6).withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: readyValue
                          ? const Color(0xFF4ADE80).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      readyValue
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: readyValue
                          ? const Color(0xFF4ADE80)
                          : Colors.white.withValues(alpha: 0.5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          readyValue ? 'جاهز' : 'غير جاهز',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: readyValue
                                ? const Color(0xFF4ADE80)
                                : Colors.white,
                          ),
                        ),
                        Text(
                          'اضغط للتبديل',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 26,
                    decoration: BoxDecoration(
                      color: readyValue
                          ? const Color(0xFF4ADE80)
                          : Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: readyValue
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ActionBtn(
            label: starting
                ? 'جارٍ البدء...'
                : isHost
                    ? 'ابدأ ${_roomModeLabel(room.mode)}'
                    : 'بانتظار المضيف',
            icon: Icons.rocket_launch_rounded,
            colors: const [Color(0xFFF8D34C), Color(0xFFF59E0B)],
            borderColor: const Color(0xFFFFF3A3),
            textColor: const Color(0xFF1F2937),
            enabled: canStartNow,
            onTap: canStartNow ? onStartRoom : null,
          ),
          const SizedBox(height: 8),
          if (isTeamBattle && teamBalanceIssue != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF7F1D1D).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF87171).withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Color(0xFFFCA5A5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      teamBalanceIssue,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!isHost)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    size: 16,
                    color: const Color(0xFFFACC15).withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'بانتظار $hostName ليبدأ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _roomPhaseColor(room.phase).withValues(alpha: 0.18),
                  const Color(0xFF0F172A).withValues(alpha: 0.72),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _roomPhaseColor(room.phase).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isFinished
                          ? Icons.emoji_events_rounded
                          : isRoundOver
                              ? Icons.flag_rounded
                              : Icons.autorenew_rounded,
                      size: 18,
                      color: _roomPhaseColor(room.phase),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        statusTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  statusBody,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MiniChip(
                      label: _roomModeLabel(room.mode),
                      color: _roomModeColor(room.mode),
                    ),
                    _MiniChip(
                      label: _roomPhaseLabel(room.phase),
                      color: _roomPhaseColor(room.phase),
                    ),
                    if (room.isRoundBasedMode)
                      _MiniChip(
                        label: 'الجولة ${room.roundNumber}',
                        color: const Color(0xFF38BDF8),
                      ),
                    if (isTeamBattle)
                      _MiniChip(
                        label: '${_teamLabel(Room.teamA)} $teamAScore',
                        color: const Color(0xFF3B82F6),
                      ),
                    if (isTeamBattle)
                      _MiniChip(
                        label: '${_teamLabel(Room.teamB)} $teamBScore',
                        color: const Color(0xFFEF4444),
                      ),
                    if (isSurvival)
                      _MiniChip(
                        label: 'الصامدون $aliveCount',
                        color: const Color(0xFF4ADE80),
                      ),
                    if (isSurvival && currentPlayer != null)
                      _MiniChip(
                        label: 'أرواحك ${currentPlayer.lives}',
                        color: currentPlayer.lives > 1
                            ? const Color(0xFFF97316)
                            : const Color(0xFFEF4444),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (room.isRoundBasedMode && isRoundOver) ...[
            const SizedBox(height: 10),
            _ActionBtn(
              label: starting
                  ? 'جارٍ بدء الجولة التالية...'
                  : isHost
                      ? 'ابدأ الجولة ${room.roundNumber + 1}'
                      : 'بانتظار المضيف',
              icon: Icons.skip_next_rounded,
              colors: const [Color(0xFF22C55E), Color(0xFF059669)],
              borderColor: const Color(0xFF86EFAC),
              textColor: const Color(0xFF052E16),
              enabled: isHost && !starting,
              onTap: isHost && !starting ? onStartNextRound : null,
            ),
          ],
          const SizedBox(height: 8),
        ],
        _ActionBtn(
          label: 'مشاركة الغرفة',
          icon: Icons.share_rounded,
          colors: const [Color(0xFF1E3A8A), Color(0xFF1E1B4B)],
          borderColor: const Color(0xFF3B82F6),
          textColor: Colors.white,
          enabled: true,
          onTap: onShareRoom,
        ),
        const SizedBox(height: 8),
        _ActionBtn(
          label: leaving ? 'جارٍ المغادرة...' : 'مغادرة الغرفة',
          icon: Icons.logout_rounded,
          colors: const [Color(0xFF7F1D1D), Color(0xFF450A0A)],
          borderColor: const Color(0xFFF87171),
          textColor: Colors.white,
          enabled: !leaving,
          onTap: leaving ? null : onLeaveRoom,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  switch (room.mode) {
                    Room.modeElimination =>
                      'طور الإقصاء: إجابة خاطئة واحدة تعني الخروج الفوري.',
                    Room.modeSurvival =>
                      'طور النجاة: لكل لاعب 3 أرواح، والإجابة الخاطئة تخصم روحًا، والمضيف يبدأ الجولة التالية.',
                    Room.modeSeries =>
                      'طور السلسلة: أول لاعب يصل إلى عدد الجولات المطلوب يحسم السلسلة.',
                    Room.modeTeamBattle =>
                      'مواجهة الفرق: يحتفظ كل لاعب بنقاطه الفردية، ومجموع الفريقين يحدد الفائز، والتعادل ينهي المواجهة بلا فريق منتصر. تبديل الفرق متاح فقط قبل البداية.',
                    Room.modeBlitz =>
                      'طور بلتز: أجب عن أكبر عدد ممكن من الأسئلة قبل انتهاء الوقت.',
                    _ =>
                      'يمكن للمضيف البدء مبكرًا، وأي مقاعد شاغرة سيملؤها خصوم آليون.',
                  },
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.35),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF7C3AED),
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          Text(
            'جارٍ الاتصال...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedState extends StatelessWidget {
  const _ClosedState({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.meeting_room_rounded,
                  color: Color(0xFFF87171), size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'أُغلقت الغرفة',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'قد يكون المضيف حذفها أو انتهت صلاحيتها.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'رجوع',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Helpers ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.isBot,
    required this.photoUrl,
    required this.seed,
    required this.size,
  });

  final bool isBot;
  final String? photoUrl;
  final int seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!isBot) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: const Color(0xFF1E3A8A),
        backgroundImage:
            photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
        child: photoUrl?.isNotEmpty == true
            ? null
            : Icon(Icons.person_rounded,
                color: Colors.white, size: size * 0.45),
      );
    }
    const palettes = [
      [Color(0xFF2563EB), Color(0xFF06B6D4)],
      [Color(0xFFF97316), Color(0xFFFB7185)],
      [Color(0xFF10B981), Color(0xFF22D3EE)],
      [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      [Color(0xFFF59E0B), Color(0xFFEAB308)],
      [Color(0xFF14B8A6), Color(0xFF3B82F6)],
      [Color(0xFFEF4444), Color(0xFFF97316)],
      [Color(0xFF6366F1), Color(0xFF22C55E)],
    ];
    final colors = palettes[seed % palettes.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors),
      ),
      child:
          Icon(Icons.smart_toy_rounded, color: Colors.white, size: size * 0.45),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.colors,
    required this.borderColor,
    required this.textColor,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final Color borderColor;
  final Color textColor;
  final bool enabled;
  final dynamic onTap; // VoidCallback | Future<bool> Function() | null

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              if (widget.onTap != null) widget.onTap!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: widget.enabled ? 1.0 : 0.45,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.colors),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: widget.borderColor.withValues(alpha: 0.6), width: 1.5),
              boxShadow: widget.enabled
                  ? [
                      BoxShadow(
                        color: widget.colors.last.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.textColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: widget.textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
