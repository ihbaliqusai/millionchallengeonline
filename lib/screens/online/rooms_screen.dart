import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/player_profile.dart';
import '../../models/room.dart';
import '../../services/profile_service.dart';
import '../../services/room_service.dart';
import 'room_lobby_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _roomCodeController = TextEditingController();
  int _maxPlayers = 4;
  bool _creatingRoom = false;
  bool _joiningRoom = false;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RoomService>().purgeStaleRooms();
    });
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final userId = context.read<AppState>().user?.uid;
    if (userId == null) return;
    setState(() => _creatingRoom = true);
    try {
      final roomId = await context.read<RoomService>().createRoom(
            hostId: userId,
            maxPlayers: _maxPlayers,
          );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              RoomLobbyScreen(roomId: roomId, createdByCurrentUser: true),
        ),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _creatingRoom = false);
    }
  }

  Future<void> _joinRoom(String roomId) async {
    final trimmedId = roomId.trim();
    final userId = context.read<AppState>().user?.uid;
    if (trimmedId.isEmpty || userId == null) return;
    setState(() => _joiningRoom = true);
    try {
      await context.read<RoomService>().joinRoom(
            roomId: trimmedId,
            userId: userId,
          );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RoomLobbyScreen(roomId: trimmedId),
        ),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _joiningRoom = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: const Color(0xFF7F1D1D),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: Column(
              children: [
                _BattleHeader(onBack: () => Navigator.of(context).pop()),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 700;
                      final leftPanel = _CreateJoinPanel(
                        maxPlayers: _maxPlayers,
                        creatingRoom: _creatingRoom,
                        joiningRoom: _joiningRoom,
                        roomCodeController: _roomCodeController,
                        onMaxPlayersChanged: (v) =>
                            setState(() => _maxPlayers = v),
                        onCreateRoom: _createRoom,
                        onJoinRoom: () =>
                            _joinRoom(_roomCodeController.text),
                      );
                      final rightPanel = _LiveRoomsPanel(
                        pulseCtrl: _pulseCtrl,
                        onJoinRoom: (id) {
                          _roomCodeController.text = id;
                          _joinRoom(id);
                        },
                        joiningRoomId: _joiningRoom
                            ? _roomCodeController.text.trim()
                            : '',
                      );

                      if (narrow) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                          child: Column(
                            children: [
                              leftPanel,
                              const SizedBox(height: 14),
                              SizedBox(height: 340, child: rightPanel),
                            ],
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: SingleChildScrollView(child: leftPanel),
                            ),
                            const SizedBox(width: 14),
                            Expanded(flex: 6, child: rightPanel),
                          ],
                        ),
                      );
                    },
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

// ─── Header ───────────────────────────────────────────────────────────────────

class _BattleHeader extends StatelessWidget {
  const _BattleHeader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF8D34C), Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sports_kabaddi_rounded,
                color: Color(0xFF1F2937), size: 22),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Battle',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                'Multiplayer Rooms',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Create / Join panel ──────────────────────────────────────────────────────

class _CreateJoinPanel extends StatelessWidget {
  const _CreateJoinPanel({
    required this.maxPlayers,
    required this.creatingRoom,
    required this.joiningRoom,
    required this.roomCodeController,
    required this.onMaxPlayersChanged,
    required this.onCreateRoom,
    required this.onJoinRoom,
  });

  final int maxPlayers;
  final bool creatingRoom;
  final bool joiningRoom;
  final TextEditingController roomCodeController;
  final ValueChanged<int> onMaxPlayersChanged;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Create Room card ────────────────────────────────────
        _Card(
          gradient: const [Color(0xFF1E3A8A), Color(0xFF1E1B4B)],
          borderColor: const Color(0xFF3B82F6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_circle_rounded,
                        color: Color(0xFF38BDF8), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'إنشاء غرفة',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Player count selector
              const Text(
                'عدد اللاعبين',
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13].map((n) {
                  final selected = maxPlayers == n;
                  return GestureDetector(
                    onTap: () => onMaxPlayersChanged(n),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 52,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF3B82F6)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF60A5FA)
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_rounded,
                              size: 16,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF64748B)),
                          const SizedBox(height: 2),
                          Text(
                            '$n',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _GradientButton(
                label: creatingRoom ? 'جاري الإنشاء...' : 'إنشاء غرفة جديدة',
                icon: Icons.add_circle_outline_rounded,
                colors: const [Color(0xFF2563EB), Color(0xFF06B6D4)],
                borderColor: const Color(0xFFA5F3FC),
                textColor: Colors.white,
                onTap: creatingRoom || joiningRoom ? null : onCreateRoom,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── Join by code card ────────────────────────────────────
        _Card(
          gradient: const [Color(0xFF3B1F08), Color(0xFF1C1207)],
          borderColor: const Color(0xFFF59E0B),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.key_rounded,
                        color: Color(0xFFFACC15), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'انضمام بكود',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roomCodeController,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'أدخل كود الغرفة',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 14),
                  prefixIcon:
                      Icon(Icons.tag_rounded, color: const Color(0xFFFACC15).withValues(alpha: 0.8)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFFACC15), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              _GradientButton(
                label: joiningRoom ? 'جاري الانضمام...' : 'انضمام للغرفة',
                icon: Icons.login_rounded,
                colors: const [Color(0xFFF8D34C), Color(0xFFF59E0B)],
                borderColor: const Color(0xFFFFF3A3),
                textColor: const Color(0xFF1F2937),
                onTap: creatingRoom || joiningRoom ? null : onJoinRoom,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Live rooms panel ─────────────────────────────────────────────────────────

class _LiveRoomsPanel extends StatelessWidget {
  const _LiveRoomsPanel({
    required this.pulseCtrl,
    required this.onJoinRoom,
    required this.joiningRoomId,
  });

  final AnimationController pulseCtrl;
  final ValueChanged<String> onJoinRoom;
  final String joiningRoomId;

  @override
  Widget build(BuildContext context) {
    return _Card(
      gradient: const [Color(0xFF0F1F3D), Color(0xFF0A1228)],
      borderColor: const Color(0xFF7C3AED),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.podcasts_rounded,
                    color: Color(0xFFA78BFA), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'الغرف المتاحة',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
              ),
              // Live dot
              AnimatedBuilder(
                animation: pulseCtrl,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14532D).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF4ADE80).withValues(
                            alpha: 0.4 + pulseCtrl.value * 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
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
                      const SizedBox(width: 5),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4ADE80),
                            letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
          const SizedBox(height: 10),
          // Rooms list
          Expanded(
            child: StreamBuilder<List<Room>>(
              stream: context.read<RoomService>().watchOpenRooms(),
              builder: (context, roomSnap) {
                if (roomSnap.hasError) {
                  return _ErrorState(message: roomSnap.error.toString());
                }
                final rooms = roomSnap.data ?? [];
                if (rooms.isEmpty && roomSnap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7C3AED),
                      strokeWidth: 2,
                    ),
                  );
                }
                final hostIds = rooms.map((r) => r.hostId);
                return StreamBuilder<Map<String, PlayerProfile>>(
                  stream: context.read<ProfileService>().watchProfiles(hostIds),
                  builder: (context, profileSnap) {
                    final profiles = profileSnap.data ?? {};
                    if (rooms.isEmpty) {
                      return _EmptyState();
                    }
                    return ListView.separated(
                      itemCount: rooms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final room = rooms[i];
                        final host = profiles[room.hostId];
                        return _RoomCard(
                          room: room,
                          hostName: host?.username ?? _short(room.hostId),
                          isJoining: joiningRoomId == room.id,
                          onJoin: room.isFull ? null : () => onJoinRoom(room.id),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _short(String s) =>
      s.length <= 8 ? s : '${s.substring(0, 8)}...';
}

// ─── Room card ────────────────────────────────────────────────────────────────

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.hostName,
    required this.isJoining,
    required this.onJoin,
  });

  final Room room;
  final String hostName;
  final bool isJoining;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final isFull = room.isFull;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFull
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFF7C3AED).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isFull
                    ? [const Color(0xFF374151), const Color(0xFF1F2937)]
                    : [const Color(0xFF7C3AED), const Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                hostName.isNotEmpty ? hostName[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hostName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Player slots
                    ...List.generate(room.maxPlayers, (i) {
                      final filled = i < room.playerCount;
                      return Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          color: filled
                              ? const Color(0xFF4ADE80)
                              : Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: filled
                                ? const Color(0xFF86EFAC)
                                : Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 6),
                    Text(
                      '${room.playerCount}/${room.maxPlayers}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: room.started
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                            : const Color(0xFF4ADE80).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        room.started ? 'بدأت' : 'انتظار',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: room.started
                              ? const Color(0xFFFACC15)
                              : const Color(0xFF4ADE80),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Join button
          GestureDetector(
            onTap: onJoin,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: isFull
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFF8D34C), Color(0xFFF59E0B)]),
                color: isFull ? Colors.white.withValues(alpha: 0.06) : null,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isFull
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFFFF3A3),
                ),
              ),
              child: Text(
                isFull
                    ? 'ممتلئة'
                    : isJoining
                        ? '...'
                        : 'انضمام',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isFull ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF1F2937),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    required this.gradient,
    required this.borderColor,
  });

  final Widget child;
  final List<Color> gradient;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GradientButton extends StatefulWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final Color borderColor;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled ? 1.0 : 0.45,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.colors),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.borderColor, width: 1.5),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: widget.colors.last.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.meeting_room_outlined,
              size: 48, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            'لا توجد غرف متاحة',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'أنشئ غرفة وادعُ أصدقاءك',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: const Color(0xFFF87171).withValues(alpha: 0.8),
          height: 1.4,
        ),
      ),
    );
  }
}
