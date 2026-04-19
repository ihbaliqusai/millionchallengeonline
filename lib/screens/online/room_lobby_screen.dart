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
  });

  final String roomId;
  final bool createdByCurrentUser;

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen>
    with SingleTickerProviderStateMixin {
  bool _starting = false;
  bool _leaving = false;
  bool _navigatedToGame = false;
  // Tracks the startedAt timestamp of the last launched round so elimination
  // mode can re-launch the native game for each new round.
  DateTime? _lastLaunchedRoundAt;
  late final AnimationController _pulseCtrl;

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
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _leaveRoom() async {
    if (_leaving) return;
    final userId = context.read<AppState>().user?.uid;
    if (userId == null) return;
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
        SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
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
        SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
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
  }) async {
    final profileService = context.read<ProfileService>();
    final nativeBridgeService = context.read<NativeBridgeService>();
    final opponentIds =
        room.playerIds.where((id) => id != currentUserId).toList(growable: false);
    final opponents = <Map<String, dynamic>>[];

    for (final opponentId in opponentIds) {
      if (Room.isBotUserId(opponentId)) {
        final roomPlayer = room.players[opponentId];
        final botProfile = Room.botProfile(opponentId);
        opponents.add(<String, dynamic>{
          'id': opponentId,
          'name': botProfile.displayName,
          'photo': botProfile.nativePhoto,
          'level': (botProfile.intelligence / 10).ceil(),
          'intelligence': botProfile.intelligence,
          'score': roomPlayer?.score ?? 0,
          'bot': true,
        });
        continue;
      }
      var opponentProfile = profiles[opponentId];
      if (_needsProfileHydration(opponentProfile)) {
        try {
          final fetched = await profileService.fetchProfile(opponentId);
          if (_hasMoreProfileData(current: opponentProfile, candidate: fetched)) {
            opponentProfile = fetched;
          }
        } catch (_) {}
      }
      final roomPlayer = room.players[opponentId];
      opponents.add(<String, dynamic>{
        'id': opponentId,
        'name': opponentProfile?.username ?? _fallbackName(opponentId),
        'photo': opponentProfile?.photoUrl ?? '',
        'level': 1,
        'score': roomPlayer?.score ?? 0,
        'bot': false,
      });
    }

    if (opponents.isEmpty) {
      opponents.add(const <String, dynamic>{
        'id': 'fictitious',
        'name': 'Computer',
        'photo': '',
        'level': 1,
        'score': 0,
        'bot': true,
      });
    }

    if (!mounted) return;
    await nativeBridgeService.launchLegacyRoomMatch(
      opponents: opponents,
      meOwner: currentUserId == room.hostId,
      matchMode: matchMode,
    );
  }

  Future<void> _shareRoom(Room room) async {
    try {
      await Share.share(
        'انضم إلى غرفتي في تحدي المليون أونلاين.\nكود الغرفة: ${room.id}\nافتح قسم اللعب الجماعي والصق الكود للانضمام.',
        subject: 'دعوة للعب الجماعي',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر فتح نافذة المشاركة على هذا الجهاز.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _confirmLeave() async {
    if (_leaving) return false;
    final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: const Color(0xFF152055),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    'سيتم إزالتك من غرفة الانتظار.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
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
                    return _ClosedState(onBack: () => Navigator.of(context).pop());
                  }

                  if (!room.containsPlayer(currentUserId)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    });
                  }

                  final playerIds = room.playerIds;

                  return StreamBuilder<Map<String, PlayerProfile>>(
                    stream:
                        context.read<ProfileService>().watchProfiles(playerIds),
                    builder: (context, profileSnapshot) {
                      final profiles =
                          profileSnapshot.data ?? const <String, PlayerProfile>{};
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
                      const roundBasedModes = {'elimination', 'survival', 'series'};
                      final isRoundBased = roundBasedModes.contains(room.mode);
                      final shouldLaunch = room.started && (
                        (!isRoundBased && !_navigatedToGame) ||
                        (isRoundBased &&
                          room.phase == 'playing_round' &&
                          room.startedAt != null &&
                          room.startedAt != _lastLaunchedRoundAt)
                      );
                      if (shouldLaunch) {
                        _navigatedToGame = true;
                        _lastLaunchedRoundAt = room.startedAt;
                        WidgetsBinding.instance
                            .addPostFrameCallback((_) async {
                          if (!mounted) return;
                          await _launchNativeMatchIfPossible(
                            room: room,
                            profiles: profiles,
                            currentUserId: currentUserId,
                            matchMode: room.mode,
                          );
                        });
                      }

                      return Column(
                        children: [
                          // ── Header ────────────────────────────────
                          _LobbyHeader(
                            room: room,
                            pulseCtrl: _pulseCtrl,
                            onBack: _confirmLeave,
                          ),
                          // ── Content ───────────────────────────────
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final narrow = constraints.maxWidth < 700;

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
                                  readyValue: readyValue,
                                  starting: _starting,
                                  leaving: _leaving,
                                  onToggleReady: (v) => _toggleReady(room, v),
                                  onStartRoom: () => _startRoom(room),
                                  onShareRoom: () => _shareRoom(room),
                                  onLeaveRoom: _confirmLeave,
                                );

                                if (narrow) {
                                  return SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                        14, 0, 14, 16),
                                    child: Column(
                                      children: [
                                        controlsPanel,
                                        const SizedBox(height: 14),
                                        SizedBox(
                                          height: 320,
                                          child: playersPanel,
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      14, 0, 14, 14),
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
        candidate.username.trim().isNotEmpty) { return true; }
    if ((current.photoUrl ?? '').trim().isEmpty &&
        (candidate.photoUrl ?? '').trim().isNotEmpty) { return true; }
    return false;
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _LobbyHeader extends StatelessWidget {
  const _LobbyHeader({
    required this.room,
    required this.pulseCtrl,
    required this.onBack,
  });

  final Room room;
  final AnimationController pulseCtrl;
  final Future<bool> Function() onBack;

  @override
  Widget build(BuildContext context) {
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
                  'ID: ${room.id}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600),
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

// ─── Players panel ────────────────────────────────────────────────────────────

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
    // Fill empty slots
    final totalSlots = room.maxPlayers;
    final emptyCount = totalSlots - sortedIds.length;

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
            color: const Color(0xFF7C3AED).withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups_rounded, color: Color(0xFFA78BFA), size: 18),
              SizedBox(width: 8),
              Text(
                'اللاعبون',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                ...sortedIds.map((id) {
                  final player = room.players[id]!;
                  final profile = profiles[id];
                  final isBot = Room.isBotUserId(id);
                  final botProfile = isBot ? Room.botProfile(id) : null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PlayerTile(
                      isHost: id == room.hostId,
                      isCurrentUser: id == currentUserId,
                      isBot: isBot,
                      username: isBot
                          ? botProfile!.displayName
                          : profile?.username ??
                              _RoomLobbyScreenState._fallbackName(id),
                      photoUrl: profile?.photoUrl,
                      botSeed: botProfile?.avatarSeed ?? 0,
                      botIntelligence: botProfile?.intelligence,
                      ready: player.ready,
                      score: player.score,
                    ),
                  );
                }),
                // Empty slots
                ...List.generate(emptyCount, (i) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: _EmptySlot(),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
    required this.score,
  });

  final bool isHost;
  final bool isCurrentUser;
  final bool isBot;
  final String username;
  final String? photoUrl;
  final int botSeed;
  final int? botIntelligence;
  final bool ready;
  final int score;

  @override
  Widget build(BuildContext context) {
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
          _Avatar(
              isBot: isBot, photoUrl: photoUrl, seed: botSeed, size: 42),
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
                          color: const Color(0xFFFACC15).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'مضيف',
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
                        label: 'AI ${botIntelligence!}%',
                        color: const Color(0xFF38BDF8),
                      ),
                      const SizedBox(width: 5),
                    ],
                    _MiniChip(
                      label: '$score pts',
                      color: const Color(0xFFFACC15),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Ready status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: ready
                  ? const Color(0xFF4ADE80).withValues(alpha: 0.15)
                  : const Color(0xFF374151).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: ready
                    ? const Color(0xFF4ADE80).withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  ready
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_top_rounded,
                  size: 13,
                  color: ready
                      ? const Color(0xFF4ADE80)
                      : Colors.white.withValues(alpha: 0.35),
                ),
                const SizedBox(width: 4),
                Text(
                  ready ? 'جاهز' : 'انتظار',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ready
                        ? const Color(0xFF4ADE80)
                        : Colors.white.withValues(alpha: 0.35),
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
            'في انتظار لاعب...',
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

// ─── Controls panel ───────────────────────────────────────────────────────────

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
    required this.room,
    required this.profiles,
    required this.currentUserId,
    required this.isHost,
    required this.readyValue,
    required this.starting,
    required this.leaving,
    required this.onToggleReady,
    required this.onStartRoom,
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
  final VoidCallback onShareRoom;
  final Future<bool> Function() onLeaveRoom;

  @override
  Widget build(BuildContext context) {
    final hostName = profiles[room.hostId]?.username ??
        _RoomLobbyScreenState._fallbackName(room.hostId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Ready toggle ───────────────────────────────────────
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
                        readyValue ? 'جاهز!' : 'غير جاهز',
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

        // ── Start game button (host only) ──────────────────────
        _ActionBtn(
          label: starting
              ? 'جاري البدء...'
              : isHost
                  ? 'بدء المباراة'
                  : 'ينتظر المضيف',
          icon: Icons.rocket_launch_rounded,
          colors: const [Color(0xFFF8D34C), Color(0xFFF59E0B)],
          borderColor: const Color(0xFFFFF3A3),
          textColor: const Color(0xFF1F2937),
          enabled: isHost && !starting,
          onTap: isHost && !starting ? onStartRoom : null,
        ),
        const SizedBox(height: 8),

        // ── Waiting message (non-host) ─────────────────────────
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
                    'في انتظار $hostName للبدء',
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

        // ── Share Room ─────────────────────────────────────────
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

        // ── Leave Room ─────────────────────────────────────────
        _ActionBtn(
          label: leaving ? 'جاري المغادرة...' : 'مغادرة الغرفة',
          icon: Icons.logout_rounded,
          colors: const [Color(0xFF7F1D1D), Color(0xFF450A0A)],
          borderColor: const Color(0xFFF87171),
          textColor: Colors.white,
          enabled: !leaving,
          onTap: leaving ? null : onLeaveRoom,
        ),
        const SizedBox(height: 12),

        // ── Info note ──────────────────────────────────────────
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
                      'وضع الإقصاء: خطأ واحد = خروج فوري.',
                    'survival' =>
                      'وضع النجاة: 3 أرواح لكل لاعب — تُقصى عند نفادها.',
                    'series' =>
                      'وضع السلسلة: الفائز بجولتين أولاً يكسب السلسلة.',
                    'team_battle' =>
                      'وضع الفرق: الفريق A مقابل الفريق B — المجموع يحدد الفائز.',
                    'blitz' =>
                      'وضع البلتز: أجب على أكبر عدد ممكن قبل انتهاء الوقت.',
                    _ =>
                      'المضيف يمكنه البدء مبكراً، وستُملأ المقاعد الفارغة بلاعبين آليين.',
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

// ─── Loading / Closed states ──────────────────────────────────────────────────

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
            'جاري الاتصال...',
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
              'الغرفة مغلقة',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'ربما حذفها المضيف أو انتهت صلاحيتها.',
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
                  'العودة',
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

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
      child: Icon(Icons.smart_toy_rounded,
          color: Colors.white, size: size * 0.45),
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
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800, color: color),
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
