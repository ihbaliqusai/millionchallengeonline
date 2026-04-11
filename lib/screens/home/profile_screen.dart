import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../services/native_bridge_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await context.read<NativeBridgeService>().getPlayerStats();
      if (!mounted) return;
      setState(() { _stats = stats; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _rankTitle(int level) {
    if (level >= 50) return 'Legend';
    if (level >= 30) return 'Diamond';
    if (level >= 20) return 'Gold';
    if (level >= 10) return 'Silver';
    if (level >= 5)  return 'Bronze';
    return 'Beginner';
  }

  Color _rankColor(int level) {
    if (level >= 50) return const Color(0xFFA855F7);
    if (level >= 30) return const Color(0xFF38BDF8);
    if (level >= 20) return const Color(0xFFFACC15);
    if (level >= 10) return const Color(0xFF94A3B8);
    if (level >= 5)  return const Color(0xFFB45309);
    return const Color(0xFF38BDF8);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;
    final username = (user?.displayName ?? user?.email?.split('@').first ?? 'Player').trim();
    final uid = user?.uid ?? '';
    final level = appState.level;
    final wins = _stats['wins'] ?? 0;
    final losses = (_stats['gamesPlayed'] ?? 0) - wins;
    final totalMatches = _stats['gamesPlayed'] ?? 0;
    final winRate = totalMatches > 0 ? (wins / totalMatches * 100).round() : 0;
    final winStreak = _stats['winStreak'] ?? 0;
    final bestStreak = _stats['bestStreak'] ?? 0;
    final trophies = wins * 30;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B4B),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Left: Profile + Account ────────────────────────────
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBackButton(),
                          const SizedBox(height: 12),
                          _sectionLabel('PROFILE'),
                          const SizedBox(height: 8),
                          _buildProfileCard(username, level, trophies, user?.photoURL),
                          const SizedBox(height: 12),
                          _sectionLabel('ACCOUNT'),
                          const SizedBox(height: 8),
                          _buildAccountCard(uid),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ── Center: Battle Record ──────────────────────────────
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 48),
                          _sectionLabel('BATTLE RECORD'),
                          const SizedBox(height: 8),
                          _buildBattleRecord(
                            totalMatches: totalMatches,
                            wins: wins,
                            losses: losses < 0 ? 0 : losses,
                            winRate: winRate,
                            winStreak: winStreak,
                            bestStreak: bestStreak,
                            trophies: trophies,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ── Right: Tournament ──────────────────────────────────
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 48),
                          _sectionLabel('TOURNAMENT'),
                          const SizedBox(height: 8),
                          _buildTournamentCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Colors.white54,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildProfileCard(String username, int level, int trophies, String? photoUrl) {
    final rank = _rankTitle(level);
    final rankClr = _rankColor(level);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF152055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Edit pencil icon (top-left of card)
              GestureDetector(
                onTap: () {},
                child: Icon(Icons.edit_rounded, size: 14, color: Colors.white.withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C3AED),
                  border: Border.all(color: const Color(0xFFFACC15), width: 2),
                ),
                child: ClipOval(
                  child: photoUrl?.isNotEmpty == true
                      ? Image.network(photoUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.person_rounded, size: 28, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: rankClr),
                        const SizedBox(width: 4),
                        Text(rank, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: rankClr)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFFACC15), size: 16),
              const SizedBox(width: 4),
              Text(
                '$trophies',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFFACC15)),
              ),
            ],
          ),
          // Avatar showcase row (decorative)
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final colors = [
                const Color(0xFF22C55E),
                const Color(0xFFEC4899),
                const Color(0xFF7C3AED),
                const Color(0xFFF97316),
                const Color(0xFF38BDF8),
              ];
              return Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[i].withValues(alpha: 0.3),
                  border: Border.all(color: colors[i].withValues(alpha: 0.7)),
                ),
                child: Icon(Icons.person_rounded, size: 14, color: colors[i]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(String uid) {
    final shortId = uid.length > 20 ? '${uid.substring(0, 20)}...' : uid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF152055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.link_rounded, color: Color(0xFFEC4899), size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('LINKED!', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF22C55E))),
                  ],
                ),
                Text('ID: $shortId', style: const TextStyle(fontSize: 9, color: Colors.white54)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: uid)),
            child: const Icon(Icons.copy_rounded, size: 14, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleRecord({
    required int totalMatches,
    required int wins,
    required int losses,
    required int winRate,
    required int winStreak,
    required int bestStreak,
    required int trophies,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF152055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _battleRow(Icons.sports_esports_rounded, const Color(0xFF38BDF8), 'TOTAL BATTLES', '$totalMatches'),
          const Divider(color: Colors.white12, height: 16),
          Row(
            children: [
              Expanded(
                child: _battleTile(Icons.emoji_events_rounded, const Color(0xFFFACC15), 'WINS', '$wins'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _battleTile(Icons.mood_bad_rounded, const Color(0xFFEF4444), 'LOSSES', '$losses'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _battleRow(Icons.shield_rounded, const Color(0xFF22C55E), 'WIN RATE', '$winRate%'),
          _battleRow(Icons.local_fire_department_rounded, const Color(0xFFF97316), 'WIN STREAK', '$winStreak'),
          _battleRow(Icons.military_tech_rounded, const Color(0xFFFACC15), 'BEST STREAK', '$bestStreak'),
          _battleRow(Icons.emoji_events_rounded, const Color(0xFFFACC15), 'HIGHEST TROPHIES', '$trophies'),
        ],
      ),
    );
  }

  Widget _battleRow(IconData icon, Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _battleTile(IconData icon, Color color, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w700)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF152055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white54, size: 14),
              const SizedBox(width: 6),
              const Text('HISTORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white54)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Text('Last 10', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70)),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white54, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if ((_stats['gamesPlayed'] ?? 0) == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'لم تلعب أي بطولة بعد',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                ),
              ),
            )
          else
            ..._buildTournamentHistory(),
        ],
      ),
    );
  }

  List<Widget> _buildTournamentHistory() {
    // Show last few matches as placeholder tournament entries
    final matches = _stats['gamesPlayed'] ?? 0;
    final count = matches.clamp(0, 5);
    return List.generate(count, (i) {
      final rank = i * 7 + 12;
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2B6B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Text(
              '#$rank',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFFACC15)),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Battle Round', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFFACC15), size: 16),
          ],
        ),
      );
    });
  }
}
