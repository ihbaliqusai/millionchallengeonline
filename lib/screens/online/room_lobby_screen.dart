import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_state.dart';
import '../../models/player_profile.dart';
import '../../models/room.dart';
import '../../services/native_bridge_service.dart';
import '../../services/profile_service.dart';
import '../../services/room_service.dart';
import '../../widgets/game_shell.dart';

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

class _RoomLobbyScreenState extends State<RoomLobbyScreen> {
  bool _starting = false;
  bool _leaving = false;
  bool _navigatedToGame = false;

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
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _leaving = false);
      }
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
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _startRoom() async {
    final userId = context.read<AppState>().user?.uid;
    if (userId == null) return;

    setState(() => _starting = true);
    try {
      await context.read<RoomService>().startRoom(
            roomId: widget.roomId,
            userId: userId,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  Future<void> _launchNativeMatchIfPossible({
    required Room room,
    required Map<String, PlayerProfile> profiles,
    required String currentUserId,
  }) async {
    final profileService = context.read<ProfileService>();
    final nativeBridgeService = context.read<NativeBridgeService>();

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
          final fetchedProfile = await profileService.fetchProfile(opponentId);
          if (_hasMoreProfileData(
            current: opponentProfile,
            candidate: fetchedProfile,
          )) {
            opponentProfile = fetchedProfile;
          }
        } catch (_) {
          // Fall back to the live snapshot data if an eager fetch fails.
        }
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
    );
  }

  Future<void> _shareRoom(Room room) async {
    final shareText =
        'Join my Million Challenge Online room.\nRoom ID: ${room.id}\nOpen Room Multiplayer and paste this code to join.';

    try {
      await Share.share(shareText, subject: 'Room Multiplayer Invite');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the share sheet on this device.'),
        ),
      );
    }
  }

  Future<bool> _confirmLeave() async {
    if (_leaving) return false;
    final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Room?'),
            content: const Text('You will be removed from the room lobby.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldLeave) {
      unawaited(_leaveRoom());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AppState>().user?.uid ?? '';

    return WillPopScope(
      onWillPop: _confirmLeave,
      child: StreamBuilder<Room?>(
        stream: context.read<RoomService>().watchRoom(widget.roomId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const _RoomLobbyLoadingState();
          }

          final room = snapshot.data;

          if (room == null) {
            return GameShell(
              title: 'Room Lobby',
              subtitle: 'This room is no longer available.',
              action: IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
              child: Center(
                child: GlassPanel(
                  radius: 28,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Room Closed',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'The room may have been deleted or the host may have left.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.74)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (!room.containsPlayer(currentUserId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).pop();
            });
          }

          final playerIds = room.playerIds;

          return GameShell(
            title: 'Room Lobby',
            subtitle:
                'Share the room ID, wait for players, then let the host launch the match.',
            action: IconButton.filledTonal(
              onPressed: _leaving ? null : _confirmLeave,
              icon: const Icon(Icons.close_rounded),
            ),
            child: StreamBuilder<Map<String, PlayerProfile>>(
              stream: context.read<ProfileService>().watchProfiles(playerIds),
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
                final isCurrentUserHost =
                    widget.createdByCurrentUser || currentUserId == room.hostId;

                if (room.started && !_navigatedToGame) {
                  _navigatedToGame = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (!mounted) return;
                    await _launchNativeMatchIfPossible(
                      room: room,
                      profiles: profiles,
                      currentUserId: currentUserId,
                    );
                  });
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final compactHeight = constraints.maxHeight < 700;
                    final compactWidth = constraints.maxWidth < 1100;
                    final stacked = compactHeight || compactWidth;

                    final playersPanel = _LobbyPlayersPanel(
                      room: room,
                      sortedIds: sortedIds,
                      profiles: profiles,
                      currentUserId: currentUserId,
                    );

                    final controlsPanel = _LobbyControlsPanel(
                      room: room,
                      profiles: profiles,
                      currentUserId: currentUserId,
                      isCurrentUserHost: isCurrentUserHost,
                      readyValue: readyValue,
                      starting: _starting,
                      leaving: _leaving,
                      onToggleReady: (value) => _toggleReady(room, value),
                      onStartRoom: _startRoom,
                      onShareRoom: () => _shareRoom(room),
                      onLeaveRoom: _leaveRoom,
                    );

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: stacked
                            ? SingleChildScrollView(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  children: <Widget>[
                                    controlsPanel,
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: compactHeight ? 260 : 320,
                                      child: playersPanel,
                                    ),
                                  ],
                                ),
                              )
                            : Row(
                                children: <Widget>[
                                  Expanded(flex: 6, child: playersPanel),
                                  const SizedBox(width: 18),
                                  Expanded(flex: 4, child: controlsPanel),
                                ],
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  static String _fallbackName(String value) {
    if (Room.isBotUserId(value)) return Room.botDisplayName(value);
    if (value.length <= 8) return value;
    return '${value.substring(0, 8)}...';
  }

  static bool _needsProfileHydration(PlayerProfile? profile) {
    if (profile == null) return true;
    final username = profile.username.trim();
    final photoUrl = (profile.photoUrl ?? '').trim();
    return username.isEmpty || photoUrl.isEmpty;
  }

  static bool _hasMoreProfileData({
    required PlayerProfile? current,
    required PlayerProfile? candidate,
  }) {
    if (candidate == null) return false;
    if (current == null) return true;

    final currentUsername = current.username.trim();
    final candidateUsername = candidate.username.trim();
    final currentPhoto = (current.photoUrl ?? '').trim();
    final candidatePhoto = (candidate.photoUrl ?? '').trim();

    if (currentUsername.isEmpty && candidateUsername.isNotEmpty) return true;
    if (currentPhoto.isEmpty && candidatePhoto.isNotEmpty) return true;
    return false;
  }
}

class _RoomLobbyLoadingState extends StatelessWidget {
  const _RoomLobbyLoadingState();

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Room Lobby',
      subtitle: 'Connecting to the live room...',
      action: IconButton.filledTonal(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _LobbyPlayersPanel extends StatelessWidget {
  const _LobbyPlayersPanel({
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
    return GlassPanel(
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              HudChip(
                icon: Icons.vpn_key_rounded,
                label: 'Room ${room.id}',
              ),
              HudChip(
                icon: Icons.groups_rounded,
                label: '${room.playerCount}/${room.maxPlayers} players',
                iconColor: const Color(0xFF34D399),
              ),
              const HudChip(
                icon: Icons.sync_rounded,
                label: 'Live lobby',
                iconColor: Color(0xFF7DD3FC),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: sortedIds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final playerId = sortedIds[index];
                final player = room.players[playerId]!;
                final profile = profiles[playerId];
                final isBot = Room.isBotUserId(playerId);
                final botProfile = isBot ? Room.botProfile(playerId) : null;
                return _LobbyPlayerTile(
                  isHost: playerId == room.hostId,
                  isCurrentUser: playerId == currentUserId,
                  isBot: isBot,
                  username: isBot
                      ? botProfile!.displayName
                      : profile?.username ??
                          _RoomLobbyScreenState._fallbackName(playerId),
                  photoUrl: profile?.photoUrl,
                  botAvatarSeed: botProfile?.avatarSeed ?? 0,
                  botIntelligence: botProfile?.intelligence,
                  ready: player.ready,
                  score: player.score,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyControlsPanel extends StatelessWidget {
  const _LobbyControlsPanel({
    required this.room,
    required this.profiles,
    required this.currentUserId,
    required this.isCurrentUserHost,
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
  final bool isCurrentUserHost;
  final bool readyValue;
  final bool starting;
  final bool leaving;
  final ValueChanged<bool> onToggleReady;
  final VoidCallback onStartRoom;
  final VoidCallback onShareRoom;
  final VoidCallback onLeaveRoom;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Lobby Controls',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: readyValue,
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFFFACC15),
            title: const Text(
              'Ready',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              'Let the host know you are ready to start.',
              style: TextStyle(color: Colors.white.withOpacity(0.72)),
            ),
            onChanged: onToggleReady,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: NeonButton(
              label: starting
                  ? 'Starting...'
                  : isCurrentUserHost
                      ? 'Start Game'
                      : 'Host Starts Game',
              icon: Icons.rocket_launch_rounded,
              gold: true,
              compact: true,
              onPressed: isCurrentUserHost && !starting ? onStartRoom : null,
            ),
          ),
          if (!isCurrentUserHost) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Text(
                'Waiting for ${profiles[room.hostId]?.username ?? _RoomLobbyScreenState._fallbackName(room.hostId)} to start the match.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: NeonButton(
              label: 'Share Room',
              icon: Icons.share_rounded,
              compact: true,
              onPressed: onShareRoom,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: NeonButton(
              label: leaving ? 'Leaving...' : 'Leave Room',
              icon: Icons.logout_rounded,
              compact: true,
              onPressed: leaving ? null : onLeaveRoom,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Host only: you can start early, and any empty seats will be filled by computer players before the match opens.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyPlayerTile extends StatelessWidget {
  const _LobbyPlayerTile({
    required this.isHost,
    required this.isCurrentUser,
    required this.isBot,
    required this.username,
    required this.photoUrl,
    required this.botAvatarSeed,
    required this.botIntelligence,
    required this.ready,
    required this.score,
  });

  final bool isHost;
  final bool isCurrentUser;
  final bool isBot;
  final String username;
  final String? photoUrl;
  final int botAvatarSeed;
  final int? botIntelligence;
  final bool ready;
  final int score;

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
          _LobbyAvatar(
            isBot: isBot,
            photoUrl: photoUrl,
            seed: botAvatarSeed,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        isCurrentUser ? '$username (You)' : username,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isHost) ...<Widget>[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACC15).withOpacity(0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFCD34D),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    if (isBot && botIntelligence != null)
                      HudChip(
                        icon: Icons.memory_rounded,
                        label: 'AI ${botIntelligence!}%',
                        compact: true,
                        iconColor: const Color(0xFF7DD3FC),
                      ),
                    HudChip(
                      icon: ready
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_empty_rounded,
                      label: ready ? 'Ready' : 'Waiting',
                      compact: true,
                      iconColor: ready
                          ? const Color(0xFF34D399)
                          : const Color(0xFF7DD3FC),
                    ),
                    HudChip(
                      icon: Icons.stars_rounded,
                      label: '$score pts',
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyAvatar extends StatelessWidget {
  const _LobbyAvatar({
    required this.isBot,
    required this.photoUrl,
    required this.seed,
  });

  final bool isBot;
  final String? photoUrl;
  final int seed;

  @override
  Widget build(BuildContext context) {
    if (!isBot) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: const Color(0xFF0F172A),
        backgroundImage:
            photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
        child: photoUrl?.isNotEmpty == true
            ? null
            : const Icon(Icons.person_rounded, color: Colors.white),
      );
    }

    final palettes = <List<Color>>[
      const <Color>[Color(0xFF2563EB), Color(0xFF06B6D4)],
      const <Color>[Color(0xFFF97316), Color(0xFFFB7185)],
      const <Color>[Color(0xFF10B981), Color(0xFF22D3EE)],
      const <Color>[Color(0xFF8B5CF6), Color(0xFFEC4899)],
      const <Color>[Color(0xFFF59E0B), Color(0xFFEAB308)],
      const <Color>[Color(0xFF14B8A6), Color(0xFF3B82F6)],
      const <Color>[Color(0xFFEF4444), Color(0xFFF97316)],
      const <Color>[Color(0xFF6366F1), Color(0xFF22C55E)],
    ];
    final colors = palettes[seed % palettes.length];

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors),
      ),
      child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
    );
  }
}
