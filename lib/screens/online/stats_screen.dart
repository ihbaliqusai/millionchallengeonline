import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/player_rank.dart';
import '../../core/trophy_league.dart';
import '../../services/native_bridge_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
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
      final appState = context.read<AppState>();
      final nativeBridge = context.read<NativeBridgeService>();
      await appState.checkAndAwardXpForGames();
      final stats = await nativeBridge.getPlayerStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(String key) {
    final v = _stats[key] ?? 0;
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}k';
    }
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final trophies = appState.trophies;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1640),
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      children: [
                        _PlayerInfoCard(appState: appState),
                        const SizedBox(height: 12),
                        Text(
                          'الأداء العام',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.4,
                          children: [
                            _StatCard(
                              icon: Icons.sports_esports_rounded,
                              color: const Color(0xFF38BDF8),
                              value: _fmt('gamesPlayed'),
                              label: 'المباريات',
                            ),
                            _StatCard(
                              icon: Icons.emoji_events_rounded,
                              color: const Color(0xFFFACC15),
                              value: _fmt('wins'),
                              label: 'انتصارات',
                            ),
                            _StatCard(
                              icon: Icons.trending_up_rounded,
                              color: const Color(0xFF4ADE80),
                              value: '${_stats['winPercent'] ?? 0}%',
                              label: 'نسبة الفوز',
                            ),
                            _StatCard(
                              icon: Icons.public_rounded,
                              color: const Color(0xFF38BDF8),
                              value: _fmt('onlineWins'),
                              label: 'انتصارات أونلاين',
                            ),
                            _StatCard(
                              icon: Icons.bolt_rounded,
                              color: const Color(0xFFF97316),
                              value: _fmt('bestStreak'),
                              label: 'تتالي الإجابات',
                            ),
                            _StatCard(
                              icon: Icons.local_fire_department_rounded,
                              color: const Color(0xFFFB7185),
                              value: _fmt('winStreak'),
                              label: 'سلسلة الفوز',
                            ),
                            _StatCard(
                              icon: Icons.workspace_premium_rounded,
                              color: const Color(0xFFFACC15),
                              value: _fmt('bestWinStreak'),
                              label: 'أفضل سلسلة فوز',
                            ),
                            _StatCard(
                              icon: Icons.quiz_rounded,
                              color: const Color(0xFFA78BFA),
                              value: _fmt('totalAnswered'),
                              label: 'الأسئلة',
                            ),
                            _StatCard(
                              icon: Icons.check_circle_rounded,
                              color: const Color(0xFF34D399),
                              value: '${_stats['accuracy'] ?? 0}%',
                              label: 'الدقة',
                            ),
                            _StatCard(
                              icon: Icons.emoji_events_rounded,
                              color: const Color(0xFFFACC15),
                              value: trophies >= 1000
                                  ? '${(trophies / 1000).toStringAsFixed(1)}k'
                                  : '$trophies',
                              label: 'الكؤوس',
                            ),
                          ],
                        ),
                        if ((_stats['gamesPlayed'] ?? 0) == 0) ...[
                          const SizedBox(height: 24),
                          Center(
                            child: Text(
                              'العب مباراة لترى إحصائياتك هنا',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Text(
            'الإحصائيات',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Player info card ─────────────────────────────────────────────────────────

class _PlayerInfoCard extends StatelessWidget {
  const _PlayerInfoCard({required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final username =
        appState.user?.displayName ?? appState.user?.email ?? 'لاعب';
    final rankTitle = PlayerRank.titleForLevel(appState.level);
    final rankColor = PlayerRank.colorForLevel(appState.level);
    final league = TrophyProgression.leagueFor(appState.trophies);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF152055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: rankColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rankTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: rankColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(league.icon, color: league.color, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      '${appState.trophies} ${league.nameAr}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: league.color,
                      ),
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

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2B6B), Color(0xFF152055)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
