import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/player_profile.dart';
import '../../models/room.dart';
import '../../services/profile_service.dart';
import '../../services/room_service.dart';
import '../../widgets/game_shell.dart';
import 'room_lobby_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final TextEditingController _roomCodeController = TextEditingController();
  int _maxPlayers = 4;
  bool _creatingRoom = false;
  bool _joiningRoom = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RoomService>().purgeStaleRooms();
    });
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
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
          builder: (_) => RoomLobbyScreen(
            roomId: roomId,
            createdByCurrentUser: true,
          ),
        ),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) {
        setState(() => _creatingRoom = false);
      }
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
      if (mounted) {
        setState(() => _joiningRoom = false);
      }
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Room Multiplayer',
      subtitle:
          'Create a room for your squad or join an existing room code in real time.',
      action: IconButton.filledTonal(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactHeight = constraints.maxHeight < 700;
          final compactWidth = constraints.maxWidth < 1100;
          final stacked = compactHeight || compactWidth;

          final creationPanel = _RoomActionsPanel(
            maxPlayers: _maxPlayers,
            creatingRoom: _creatingRoom,
            joiningRoom: _joiningRoom,
            roomCodeController: _roomCodeController,
            onMaxPlayersChanged: (value) => setState(() => _maxPlayers = value),
            onCreateRoom: _createRoom,
            onJoinRoom: () => _joinRoom(_roomCodeController.text),
          );

          final liveRoomsPanel = _OpenRoomsPanel(
            onJoinRoom: (roomId) {
              _roomCodeController.text = roomId;
              _joinRoom(roomId);
            },
            joiningRoomId: _joiningRoom ? _roomCodeController.text.trim() : '',
          );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: stacked
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: <Widget>[
                          creationPanel,
                          const SizedBox(height: 16),
                          SizedBox(
                            height: compactHeight ? 320 : 380,
                            child: liveRoomsPanel,
                          ),
                        ],
                      ),
                    )
                  : Row(
                      children: <Widget>[
                        Expanded(flex: 5, child: creationPanel),
                        const SizedBox(width: 18),
                        Expanded(flex: 6, child: liveRoomsPanel),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _RoomActionsPanel extends StatelessWidget {
  const _RoomActionsPanel({
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
    return GlassPanel(
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Create Or Join',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            'Rooms stay separate from the classic matchmaking flow. Share the room ID with friends or join a lobby from the live list.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Create Room',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: maxPlayers,
                  decoration: const InputDecoration(
                    labelText: 'Max Players',
                    prefixIcon: Icon(Icons.groups_rounded),
                  ),
                  items: const <DropdownMenuItem<int>>[
                    DropdownMenuItem<int>(value: 2, child: Text('2 Players')),
                    DropdownMenuItem<int>(value: 3, child: Text('3 Players')),
                    DropdownMenuItem<int>(value: 4, child: Text('4 Players')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    onMaxPlayersChanged(value);
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: NeonButton(
                    label: creatingRoom ? 'Creating...' : 'Create Room',
                    icon: Icons.add_circle_outline_rounded,
                    compact: true,
                    onPressed:
                        creatingRoom || joiningRoom ? null : onCreateRoom,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Join By Code',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: roomCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Room ID',
                    prefixIcon: Icon(Icons.key_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: NeonButton(
                    label: joiningRoom ? 'Joining...' : 'Join Room',
                    icon: Icons.login_rounded,
                    gold: true,
                    compact: true,
                    onPressed: creatingRoom || joiningRoom ? null : onJoinRoom,
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

class _OpenRoomsPanel extends StatelessWidget {
  const _OpenRoomsPanel({
    required this.onJoinRoom,
    required this.joiningRoomId,
  });

  final ValueChanged<String> onJoinRoom;
  final String joiningRoomId;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 28,
      child: StreamBuilder<List<Room>>(
        stream: context.read<RoomService>().watchOpenRooms(),
        builder: (context, roomSnapshot) {
          if (roomSnapshot.hasError) {
            return Center(
              child: Text(
                roomSnapshot.error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  height: 1.35,
                ),
              ),
            );
          }

          final rooms = roomSnapshot.data ?? const <Room>[];
          final hostIds = rooms.map((room) => room.hostId);

          return StreamBuilder<Map<String, PlayerProfile>>(
            stream: context.read<ProfileService>().watchProfiles(hostIds),
            builder: (context, profileSnapshot) {
              final profiles =
                  profileSnapshot.data ?? const <String, PlayerProfile>{};

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Live Rooms',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Available lobbies update in real time. Tap any room that is not full to join immediately.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.76),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: rooms.isEmpty
                        ? Center(
                            child: Text(
                              'No open rooms yet.\nCreate one and invite the first players in.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.68),
                                height: 1.45,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: rooms.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final room = rooms[index];
                              final host = profiles[room.hostId];
                              return _RoomCard(
                                room: room,
                                hostName:
                                    host?.username ?? _shortLabel(room.hostId),
                                onJoin: room.isFull
                                    ? null
                                    : () => onJoinRoom(room.id),
                                isJoining: joiningRoomId == room.id,
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
    );
  }

  static String _shortLabel(String value) {
    if (value.length <= 8) return value;
    return '${value.substring(0, 8)}...';
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.hostName,
    required this.onJoin,
    required this.isJoining,
  });

  final Room room;
  final String hostName;
  final VoidCallback? onJoin;
  final bool isJoining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF2563EB), Color(0xFF06B6D4)],
              ),
            ),
            child: const Icon(Icons.meeting_room_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Room ${room.id}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Host: $hostName',
                  style: TextStyle(color: Colors.white.withOpacity(0.76)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    HudChip(
                      icon: Icons.groups_rounded,
                      label: '${room.playerCount}/${room.maxPlayers}',
                      compact: true,
                    ),
                    HudChip(
                      icon: Icons.hourglass_top_rounded,
                      label: room.started ? 'Started' : 'Waiting',
                      compact: true,
                      iconColor: room.started
                          ? const Color(0xFFFACC15)
                          : const Color(0xFF34D399),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 150,
            child: NeonButton(
              label: room.isFull
                  ? 'Full'
                  : isJoining
                      ? 'Joining...'
                      : 'Join',
              icon: room.isFull ? Icons.lock_rounded : Icons.login_rounded,
              compact: true,
              gold: !room.isFull,
              onPressed: room.isFull || isJoining ? null : onJoin,
            ),
          ),
        ],
      ),
    );
  }
}
