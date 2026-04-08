import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../widgets/game_shell.dart';
import 'rooms_screen.dart';
import 'settings_screen.dart';

class OnlineMenuScreen extends StatelessWidget {
  const OnlineMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;
    final username =
        (user?.displayName ?? user?.email?.split('@').first ?? 'Player').trim();

    return GameShell(
      title: 'Online Arena',
      subtitle:
          'Choose the live mode you want without touching the existing 1v1 experience.',
      action: IconButton.filledTonal(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SettingsScreen(),
            ),
          );
        },
        icon: const Icon(Icons.settings_rounded),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactHeight = constraints.maxHeight < 620;
          final compactWidth = constraints.maxWidth < 980;
          final stacked = compactHeight || compactWidth;

          final modesPanel = _ModesPanel(
            appState: appState,
            compact: stacked,
          );
          final playerPanel = _PlayerPanel(
            appState: appState,
            username: username,
          );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: stacked
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: <Widget>[
                          modesPanel,
                          const SizedBox(height: 16),
                          playerPanel,
                        ],
                      ),
                    )
                  : Row(
                      children: <Widget>[
                        Expanded(flex: 6, child: modesPanel),
                        const SizedBox(width: 18),
                        Expanded(flex: 4, child: playerPanel),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _ModesPanel extends StatelessWidget {
  const _ModesPanel({
    required this.appState,
    required this.compact,
  });

  final AppState appState;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final modeCards = compact
        ? Column(
            children: <Widget>[
              _ModeCard(
                title: '1v1 Matchmaking',
                subtitle:
                    'Use the existing working online mode with zero changes to its current logic.',
                icon: Icons.flash_on_rounded,
                accent: const <Color>[
                  Color(0xFFF59E0B),
                  Color(0xFFFACC15),
                ],
                compact: true,
                primaryAction: NeonButton(
                  label: 'Open 1v1',
                  icon: Icons.play_arrow_rounded,
                  gold: true,
                  compact: true,
                  onPressed: appState.isBusy
                      ? null
                      : () async {
                          try {
                            await context
                                .read<AppState>()
                                .openAuthenticatedLanding();
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                ),
              ),
              const SizedBox(height: 12),
              _ModeCard(
                title: 'Room Multiplayer',
                subtitle:
                    'Create a private room, gather players in a live lobby, then start the quiz together.',
                icon: Icons.meeting_room_rounded,
                accent: const <Color>[
                  Color(0xFF2563EB),
                  Color(0xFF06B6D4),
                ],
                compact: true,
                primaryAction: NeonButton(
                  label: 'Open Rooms',
                  icon: Icons.groups_rounded,
                  compact: true,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RoomsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          )
        : Row(
            children: <Widget>[
              Expanded(
                child: _ModeCard(
                  title: '1v1 Matchmaking',
                  subtitle:
                      'Use the existing working online mode with zero changes to its current logic.',
                  icon: Icons.flash_on_rounded,
                  accent: const <Color>[
                    Color(0xFFF59E0B),
                    Color(0xFFFACC15),
                  ],
                  primaryAction: NeonButton(
                    label: 'Open 1v1',
                    icon: Icons.play_arrow_rounded,
                    gold: true,
                    onPressed: appState.isBusy
                        ? null
                        : () async {
                            try {
                              await context
                                  .read<AppState>()
                                  .openAuthenticatedLanding();
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _ModeCard(
                  title: 'Room Multiplayer',
                  subtitle:
                      'Create a private room, gather players in a live lobby, then start the quiz together.',
                  icon: Icons.meeting_room_rounded,
                  accent: const <Color>[
                    Color(0xFF2563EB),
                    Color(0xFF06B6D4),
                  ],
                  primaryAction: NeonButton(
                    label: 'Open Rooms',
                    icon: Icons.groups_rounded,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RoomsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );

    return GlassPanel(
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Game Modes',
            style: TextStyle(
              fontSize: compact ? 24 : 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Classic matchmaking still launches the current native 1v1 flow exactly as-is. Room Multiplayer runs in its own Firestore-backed path.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          modeCards,
        ],
      ),
    );
  }
}

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({
    required this.appState,
    required this.username,
  });

  final AppState appState;
  final String username;

  @override
  Widget build(BuildContext context) {
    final user = appState.user;

    return GlassPanel(
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Player',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF0F172A),
                  backgroundImage: user?.photoURL?.isNotEmpty == true
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL?.isNotEmpty == true
                      ? null
                      : const Icon(Icons.person_rounded, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        username.isEmpty ? 'Player' : username,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'Signed in',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              HudChip(
                icon: Icons.security_rounded,
                label: '1v1 logic preserved separately',
                iconColor: Color(0xFF34D399),
              ),
              HudChip(
                icon: Icons.cloud_done_rounded,
                label: 'Room lobbies sync in real time',
                iconColor: Color(0xFF7DD3FC),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: NeonButton(
              label: 'Sign Out',
              icon: Icons.logout_rounded,
              compact: true,
              onPressed: appState.isBusy
                  ? null
                  : () async {
                      await context.read<AppState>().signOut();
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.primaryAction,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> accent;
  final Widget primaryAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: compact ? 56 : 64,
            height: compact ? 56 : 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(colors: accent),
            ),
            child: Icon(icon, color: Colors.white, size: compact ? 26 : 30),
          ),
          SizedBox(height: compact ? 14 : 18),
          Text(
            title,
            style: TextStyle(
              fontSize: compact ? 20 : 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              height: 1.35,
            ),
          ),
          SizedBox(height: compact ? 14 : 18),
          SizedBox(width: double.infinity, child: primaryAction),
        ],
      ),
    );
  }
}
