import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/player_rank.dart';
import '../../core/trophy_league.dart';
import '../../services/native_bridge_service.dart';

Future<void> _showEditUsernameDialog(BuildContext context) async {
  final appState = context.read<AppState>();
  final controller = TextEditingController(
    text: appState.user?.displayName ?? '',
  );
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF152055),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Row(
        children: [
          Icon(Icons.edit_rounded, color: Color(0xFFFACC15), size: 20),
          SizedBox(width: 8),
          Text(
            'تغيير الاسم',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 20,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'اسم اللاعب الجديد',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFACC15),
            foregroundColor: const Color(0xFF1F2937),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child:
              const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ],
    ),
  );
  final newName = controller.text.trim();
  controller.dispose();
  if (confirmed != true || !context.mounted) return;
  if (newName.isEmpty) return;
  try {
    await context.read<AppState>().updateUsername(newName);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث الاسم بنجاح ✓'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل تحديث الاسم، حاول مرة أخرى'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ── Trophy League Definitions ─────────────────────────────────────────────────

class _League {
  final String name;
  final String nameAr;
  final Color color;
  final IconData icon;
  final int min;
  final int? max; // null = no cap (top league)

  const _League(
      this.name, this.nameAr, this.color, this.icon, this.min, this.max);

  bool contains(int trophies) =>
      trophies >= min && (max == null || trophies <= max!);

  double progress(int trophies) {
    if (max == null) return 1.0;
    return ((trophies - min) / (max! - min + 1)).clamp(0.0, 1.0);
  }

  int trophiesLeft(int trophies) {
    if (max == null) return 0;
    return (max! + 1 - trophies).clamp(0, max! + 1);
  }
}

const List<_League> _leagues = [
  _League(
      'Rookie', 'مبتدئ', Color(0xFF94A3B8), Icons.star_outline_rounded, 0, 149),
  _League('Bronze', 'برونز', Color(0xFFCD7F32), Icons.shield_rounded, 150, 399),
  _League('Silver', 'فضة', Color(0xFFCBD5E1), Icons.shield_rounded, 400, 799),
  _League(
      'Gold', 'ذهب', Color(0xFFFACC15), Icons.military_tech_rounded, 800, 1399),
  _League('Diamond', 'دايموند', Color(0xFF38BDF8), Icons.diamond_rounded, 1400,
      2299),
  _League('Master', 'ماستر', Color(0xFF8B5CF6), Icons.workspace_premium_rounded,
      2300, 3499),
  _League('Legend', 'أسطورة', Color(0xFFEF4444),
      Icons.local_fire_department_rounded, 3500, null),
];

_League _leagueFor(int trophies) =>
    _leagues.lastWhere((l) => trophies >= l.min, orElse: () => _leagues.first);

// ── Screen ────────────────────────────────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;
    final username =
        (user?.displayName ?? user?.email?.split('@').first ?? 'Player').trim();
    final uid = user?.uid ?? '';
    final level = appState.level;

    final totalMatches = _stats['gamesPlayed'] ?? 0;
    final wins = _stats['wins'] ?? 0;
    final rawLosses = totalMatches - wins;
    final losses = rawLosses < 0 ? 0 : rawLosses;
    final winRate = totalMatches > 0 ? (wins / totalMatches * 100).round() : 0;
    final winStreak = _stats['winStreak'] ?? 0;
    final bestStreak = _stats['bestWinStreak'] ?? 0;

    // ── Trophy formula: total earnings ÷ 1000 (كل 1000 ريال = كأس) ──────────
    final trophies = appState.trophies;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B4B),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFACC15)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Left: Profile + Account ───────────────────────────────
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBackButton(),
                          const SizedBox(height: 12),
                          _sectionLabel('PROFILE'),
                          const SizedBox(height: 8),
                          _buildProfileCard(
                              username, level, trophies, user?.photoURL),
                          const SizedBox(height: 12),
                          _sectionLabel('ACCOUNT'),
                          const SizedBox(height: 8),
                          _buildAccountCard(uid),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ── Center: Battle Record ─────────────────────────────────
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
                            losses: losses,
                            winRate: winRate,
                            winStreak: winStreak,
                            bestStreak: bestStreak,
                            trophies: trophies,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ── Right: Trophy League ──────────────────────────────────
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 48),
                          _sectionLabel('TROPHY LEAGUE'),
                          const SizedBox(height: 8),
                          _buildTrophyLeagueCard(trophies),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Back button ─────────────────────────────────────────────────────────────

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

  // ── Profile Card ─────────────────────────────────────────────────────────────

  Widget _buildProfileCard(
      String username, int level, int trophies, String? photoUrl) {
    final rank = PlayerRank.titleForLevel(level);
    final rankClr = PlayerRank.colorForLevel(level);
    final league = _leagueFor(trophies);
    final nextIdx = _leagues.indexOf(league) + 1;
    final hasNext = nextIdx < _leagues.length;
    final progress = league.progress(trophies);

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
              GestureDetector(
                onTap: () => _showEditUsernameDialog(context),
                child: Icon(Icons.edit_rounded,
                    size: 14, color: Colors.white.withValues(alpha: 0.5)),
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
                      : const Icon(Icons.person_rounded,
                          size: 28, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: rankClr),
                        const SizedBox(width: 4),
                        Text(rank,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: rankClr)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Trophy count + league badge
          Row(
            children: [
              Icon(league.icon, color: league.color, size: 20),
              const SizedBox(width: 6),
              Text(
                '$trophies',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: league.color),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: league.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: league.color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  league.nameAr,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: league.color),
                ),
              ),
            ],
          ),

          // Progress bar to next league
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(league.color),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasNext
                ? '${league.trophiesLeft(trophies)} كأس للدوري التالي'
                : 'أعلى دوري!',
            style: TextStyle(
                fontSize: 9, color: Colors.white.withValues(alpha: 0.45)),
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

  // ── Account Card ─────────────────────────────────────────────────────────────

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
              border: Border.all(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.link_rounded,
                color: Color(0xFFEC4899), size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LINKED!',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF22C55E))),
                Text('ID: $shortId',
                    style: const TextStyle(fontSize: 9, color: Colors.white54)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: uid)),
            child:
                const Icon(Icons.copy_rounded, size: 14, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  // ── Battle Record ────────────────────────────────────────────────────────────

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
          _battleRow(Icons.sports_esports_rounded, const Color(0xFF38BDF8),
              'TOTAL BATTLES', '$totalMatches'),
          const Divider(color: Colors.white12, height: 16),
          Row(
            children: [
              Expanded(
                  child: _battleTile(Icons.emoji_events_rounded,
                      const Color(0xFFFACC15), 'WINS', '$wins')),
              const SizedBox(width: 8),
              Expanded(
                  child: _battleTile(Icons.mood_bad_rounded,
                      const Color(0xFFEF4444), 'LOSSES', '$losses')),
            ],
          ),
          const SizedBox(height: 6),
          _battleRow(Icons.shield_rounded, const Color(0xFF22C55E), 'WIN RATE',
              '$winRate%'),
          _battleRow(Icons.local_fire_department_rounded,
              const Color(0xFFF97316), 'WIN STREAK', '$winStreak'),
          _battleRow(Icons.military_tech_rounded, const Color(0xFFFACC15),
              'BEST WIN STREAK', '$bestStreak'),
          const Divider(color: Colors.white12, height: 16),
          // Trophy change per game
          _trophyChangeRow(),
          _battleRow(Icons.emoji_events_rounded, const Color(0xFFFACC15),
              'TROPHIES', '$trophies'),
        ],
      ),
    );
  }

  Widget _trophyChangeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.monetization_on_rounded,
              color: Color(0xFFFACC15), size: 16),
          const SizedBox(width: 8),
          const Text('أساس الكؤوس',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFACC15).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              TrophyProgression.trophyBasisLabelAr,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFACC15)),
            ),
          ),
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
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
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
              Text(label,
                  style: TextStyle(
                      fontSize: 9,
                      color: color.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Trophy League Card ────────────────────────────────────────────────────────

  Widget _buildTrophyLeagueCard(int trophies) {
    final league = _leagueFor(trophies);
    final lIdx = _leagues.indexOf(league);
    final hasNext = lIdx + 1 < _leagues.length;
    final next = hasNext ? _leagues[lIdx + 1] : null;
    final progress = league.progress(trophies);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF152055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Current league badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  league.color.withValues(alpha: 0.2),
                  league.color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: league.color.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                Icon(league.icon, color: league.color, size: 36),
                const SizedBox(height: 6),
                Text(
                  league.nameAr,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: league.color),
                ),
                Text(
                  league.max == null
                      ? '${league.min}+ كأس'
                      : '${league.min} – ${league.max} كأس',
                  style: TextStyle(
                      fontSize: 10, color: league.color.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(league.color),
                      minHeight: 7,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  next != null
                      ? '${league.trophiesLeft(trophies)} كأس للـ ${next.nameAr}'
                      : 'أعلى دوري! 🏆',
                  style: TextStyle(
                      fontSize: 10, color: Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // All leagues ladder
          ..._leagues.reversed.map((l) {
            final achieved = trophies >= l.min;
            final isCurrent = l == league;
            return Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isCurrent
                    ? l.color.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isCurrent
                      ? l.color.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.07),
                ),
              ),
              child: Row(
                children: [
                  Icon(l.icon,
                      color: achieved ? l.color : Colors.white24, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.nameAr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: achieved ? l.color : Colors.white30,
                          ),
                        ),
                        Text(
                          l.max == null ? '${l.min}+' : '${l.min}–${l.max}',
                          style: TextStyle(
                            fontSize: 9,
                            color: achieved
                                ? l.color.withValues(alpha: 0.6)
                                : Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: l.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'الآن',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: l.color),
                      ),
                    )
                  else if (achieved)
                    Icon(Icons.check_circle_rounded,
                        color: l.color.withValues(alpha: 0.7), size: 16)
                  else
                    const Icon(Icons.lock_rounded,
                        color: Colors.white24, size: 14),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
