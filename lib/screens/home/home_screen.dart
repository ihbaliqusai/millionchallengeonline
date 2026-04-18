import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:millionaire_flutter_exact/screens/online/rooms_screen.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/player_rank.dart';
import 'store_screen.dart';
import 'leaderboard_screen.dart';
import 'daily_streak_screen.dart';
import 'profile_screen.dart';
import '../online/settings_screen.dart';
import '../online/stats_screen.dart';
import '../online/achievements_screen.dart';
import '../../widgets/currency_reward_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _idleCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadCurrency();
      // loadLevelData sets _lastKnownGamesPlayed then calls checkAndAwardXpForGames.
      // Called here because didChangeAppLifecycleState(resumed) is NOT fired
      // when the native game Activity restarts MainActivity with FLAG_ACTIVITY_CLEAR_TASK.
      context.read<AppState>().loadLevelData();
    });
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppState>().loadCurrency();
      context.read<AppState>().checkAndAwardXpForGames();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleCtrl.dispose();
    _glowCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;
    final username = (user?.displayName ?? user?.email?.split('@').first ?? 'Player').trim();

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ui/bg_main.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // ── Dark overlay ──────────────────────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0A1B4A).withValues(alpha:0.80),
                      const Color(0xFF060C24).withValues(alpha:0.90),
                    ],
                  ),
                ),
              ),
            ),

            // ── Animated sparkles ─────────────────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _SparklesPainter(_bgCtrl.value),
                ),
              ),
            ),

            // ── CENTER arena — full screen width so content is truly centred ──
            Positioned.fill(
              child: _CenterArena(
                appState: appState,
                idleCtrl: _idleCtrl,
                glowCtrl: _glowCtrl,
              ),
            ),

            // ── LEFT SIDEBAR — overlays the center ───────────────────────
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: _LeftSidebar(appState: appState),
            ),

            // ── RIGHT SIDEBAR — overlays the center ──────────────────────
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: _RightSidebar(
                appState: appState,
                username: username,
                user: user,
              ),
            ),

            // ── TOP BAR: currency + arena progress ───────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(appState: appState),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  TOP BAR
// ──────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 6;
    return SizedBox(
      height: top + 52,
      child: Stack(
        children: [
          // Currency chips — top left
          Positioned(
            top: top,
            left: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CurrencyChip(
                  icon: Icons.monetization_on_rounded,
                  color: const Color(0xFFFACC15),
                  label: appState.coins.toString(),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const StoreScreen()),
                  ),
                ),
                const SizedBox(width: 8),
                _CurrencyChip(
                  icon: Icons.diamond_rounded,
                  color: const Color(0xFF38BDF8),
                  label: appState.gems.toString(),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const StoreScreen()),
                  ),
                ),
              ],
            ),
          ),
          // Level badge — exactly centered
          Positioned(
            top: top,
            left: 0,
            right: 0,
            child: Center(
              child: _LevelBadge(appState: appState),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, size: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final level = appState.level;
    final xpIn = appState.xpInCurrentLevel;
    final xpFor = appState.xpNeededForLevel;
    final progress = xpFor > 0 ? (xpIn / xpFor).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFACC15).withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFFACC15), size: 18),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LEVEL $level',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(
                width: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFACC15)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          Text(
            '$xpIn/$xpFor',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  LEFT SIDEBAR
// ──────────────────────────────────────────────────────────────────────────────
class _LeftSidebar extends StatelessWidget {
  const _LeftSidebar({required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          10, MediaQuery.of(context).padding.top + 8, 6, MediaQuery.of(context).padding.bottom + 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STATS → Stats screen
          _SideCard(
            label: 'STATS',
            icon: Icons.bar_chart_rounded,
            iconColor: const Color(0xFFF97316),
            badge: 'NEW',
            badgeColor: const Color(0xFF22C55E),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const StatsScreen()),
            ),
          ),
          const SizedBox(height: 8),
          // Daily streak chest counter
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DailyStreakScreen()),
            ),
            child: _ChestCounter(
              current: () {
                final completed = appState.claimedToday
                    ? appState.streakDay
                    : (appState.streakDay > 1 ? appState.streakDay - 1 : 0);
                return completed > 0 ? (completed - 1) % 7 + 1 : 0;
              }(),
              total: 7,
            ),
          ),
          const SizedBox(height: 8),
          // Offline game
          _SideCard(
            label: 'أوفلاين',
            icon: Icons.sports_esports_rounded,
            iconColor: const Color(0xFF60A5FA),
            onTap: () => context.read<AppState>().openOfflineGame(),
          ),
        ],
      ),
    );
  }
}

class _SideCard extends StatelessWidget {
  const _SideCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha:0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha:0.18), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: 26),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChestCounter extends StatelessWidget {
  const _ChestCounter({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha:0.18), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_rounded, color: Color(0xFF38BDF8), size: 22),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? (current / total).clamp(0.0, 1.0) : 0,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$current/$total',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  CENTER ARENA (Castle + Battle button)
// ──────────────────────────────────────────────────────────────────────────────
class _CenterArena extends StatelessWidget {
  const _CenterArena({
    required this.appState,
    required this.idleCtrl,
    required this.glowCtrl,
  });
  final AppState appState;
  final AnimationController idleCtrl;
  final AnimationController glowCtrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // ── Logo — slightly above centre ──────────────────────
        Align(
          alignment: const Alignment(0, -0.2),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220, maxWidth: 340),
            child: AnimatedBuilder(
              animation: idleCtrl,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, math.sin(idleCtrl.value * math.pi) * 6),
                child: child,
              ),
              child: _CastleWidget(),
            ),
          ),
        ),

        // ── Ranking + Battle buttons — pinned to bottom ───────
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 8,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RankingButton(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BattleButton(
                    glowCtrl: glowCtrl,
                    label: 'Battle',
                    gold: true,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const RoomsScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _BattleButton(
                    glowCtrl: glowCtrl,
                    label: 'Speed Battle',
                    gold: false,
                    onPressed: () => context.read<AppState>().openSpeedBattle(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CastleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/ui/logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _RankingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LeaderboardScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha:0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha:0.2)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_rounded, size: 18, color: Color(0xFFFACC15)),
            SizedBox(width: 6),
            Text(
              'RANKING',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleButton extends StatefulWidget {
  const _BattleButton({
    required this.glowCtrl,
    required this.label,
    required this.onPressed,
    this.gold = true,
  });
  final AnimationController glowCtrl;
  final String label;
  final VoidCallback onPressed;
  final bool gold;

  @override
  State<_BattleButton> createState() => _BattleButtonState();
}

class _BattleButtonState extends State<_BattleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isGold = widget.gold;
    final gradColors = isGold
        ? const [Color(0xFFF8D34C), Color(0xFFF59E0B)]
        : const [Color(0xFF6D28D9), Color(0xFF2563EB)];
    final borderColor = isGold ? const Color(0xFFFFF3A3) : const Color(0xFFA5F3FC);
    final glowColor = isGold ? const Color(0xFFF59E0B) : const Color(0xFF2563EB);
    final textColor = isGold ? const Color(0xFF1F2937) : Colors.white;

    return AnimatedBuilder(
      animation: widget.glowCtrl,
      builder: (_, __) {
        final glow = 0.3 + widget.glowCtrl.value * 0.4;
        return AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onPressed();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: Container(
              width: 160,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(colors: gradColors),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha:glow),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _showChestRewardDialog(BuildContext context, int coins, int gems) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF152055),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        '🎁 تم فتح الصندوق!',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (coins > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on_rounded, color: Color(0xFFFACC15), size: 28),
                const SizedBox(width: 8),
                Text('+$coins',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          if (gems > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.diamond_rounded, color: Color(0xFF38BDF8), size: 28),
                const SizedBox(width: 8),
                Text('+$gems',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('رائع!',
              style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.w900)),
        ),
      ],
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
//  RIGHT SIDEBAR
// ──────────────────────────────────────────────────────────────────────────────
class _RightSidebar extends StatelessWidget {
  const _RightSidebar({
    required this.appState,
    required this.username,
    required this.user,
  });
  final AppState appState;
  final String username;
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get the top inset safely (works with immersive mode)
    final topPad = MediaQuery.of(context).padding.top + 8;
    final botPad = MediaQuery.of(context).padding.bottom + 8;

    return Padding(
      padding: EdgeInsets.fromLTRB(6, topPad, 10, botPad),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Nav buttons column — fixed size, won't grow
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NavButton(
                label: 'إحصائيات',
                icon: Icons.bar_chart_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const StatsScreen()),
                ),
              ),
              const SizedBox(height: 4),
              _NavButton(
                label: 'إنجازات',
                icon: Icons.emoji_events_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
                ),
              ),
              const SizedBox(height: 4),
              _NavButton(
                label: 'متجر',
                icon: Icons.storefront_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const StoreScreen()),
                ),
              ),
              const SizedBox(height: 4),
              _NavButton(
                label: 'إعدادات',
                icon: Icons.settings_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),

          // Daily chests — tap to claim directly
          GestureDetector(
            onTap: () async {
              final reward = await context.read<AppState>().claimDailyStreak();
              if (reward != null && context.mounted) {
                await _showChestRewardDialog(
                  context,
                  reward['coins']!,
                  reward['gems']!,
                );
                if (context.mounted) {
                  showCurrencyRewardOverlay(
                    context,
                    coins: reward['coins']!,
                    gems: reward['gems']!,
                  );
                }
              }
            },
            child: _DailyChests(appState: appState),
          ),

          // Player profile card — bottom
          _PlayerCard(
            appState: appState,
            username: username,
            user: user,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF091332).withValues(alpha:0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha:0.18), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF7DD3FC), size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyChests extends StatelessWidget {
  const _DailyChests({required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final completed = appState.claimedToday
        ? appState.streakDay
        : (appState.streakDay > 1 ? appState.streakDay - 1 : 0);
    final opened = completed > 0 ? (completed - 1) % 7 + 1 : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFACC15).withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'صناديق يومية',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFACC15),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(7, (i) {
              final isOpened = i < opened;
              final colors = [
                const Color(0xFF22C55E),
                const Color(0xFF60A5FA),
                const Color(0xFFEC4899),
                const Color(0xFF38BDF8),
                const Color(0xFF60A5FA),
                const Color(0xFFEC4899),
                const Color(0xFFA855F7),
              ];
              final color = colors[i];
              return Container(
                width: 26,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isOpened ? color.withValues(alpha: 0.5) : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOpened ? color : color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isOpened ? Icons.inventory_2_rounded : Icons.lock_rounded,
                  size: 14,
                  color: isOpened ? color : color.withValues(alpha: 0.3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  SPARKLES BACKGROUND PAINTER
// ──────────────────────────────────────────────────────────────────────────────
class _SparklesPainter extends CustomPainter {
  _SparklesPainter(this.t);
  final double t; // 0..1 repeating

  static const int _count = 55;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < _count; i++) {
      final seed = i * 2654435761 & 0xFFFFFFFF;
      final fx = ((seed ^ (seed >> 16)) & 0xFFFF) / 0xFFFF;
      final fy = ((seed ^ (seed >> 8)) & 0xFFFF) / 0xFFFF;
      final phase = (i * 0.37) % 1.0;
      // Integer speed (1, 2, 3): particle travels exactly N full screen heights
      // per cycle → position at t=0 equals position at t=1 → zero visible jump.
      final speed = (1 + i % 3).toDouble();
      final radius = 1.0 + (i % 4) * 0.9;

      // Upward drift with seamless full loop
      final raw = (fy - t * speed) % 1.0;
      final dy = raw < 0 ? raw + 1.0 : raw;

      final alpha = math.sin((t * speed + phase) * 2 * math.pi) * 0.5 + 0.5;
      final opacity = (0.15 + alpha * 0.75).clamp(0.0, 1.0);

      final Color base;
      final mod = i % 3;
      if (mod == 0) {
        base = const Color(0xFFFACC15);
      } else if (mod == 1) {
        base = const Color(0xFF38BDF8);
      } else {
        base = Colors.white;
      }

      // Glow halo for larger particles
      if (radius > 2.2) {
        paint
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
          ..color = base.withValues(alpha: opacity * 0.35);
        canvas.drawCircle(
          Offset(fx * size.width, dy * size.height),
          radius * 1.8,
          paint,
        );
        paint.maskFilter = null;
      }

      paint.color = base.withValues(alpha: opacity);
      canvas.drawCircle(
        Offset(fx * size.width, dy * size.height),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklesPainter old) => old.t != t;
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.appState,
    required this.username,
    required this.user,
  });
  final AppState appState;
  final String username;
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final rankTitle = PlayerRank.titleForLevel(appState.level);
    final rankColor = PlayerRank.colorForLevel(appState.level);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
      ),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha:0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha:0.2)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C3AED),
                border: Border.all(color: const Color(0xFFFACC15), width: 2),
              ),
              child: ClipOval(
                child: user?.photoURL?.isNotEmpty == true
                    ? Image.network(user!.photoURL!, fit: BoxFit.cover)
                    : const Icon(Icons.person_rounded, size: 20, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    username.isEmpty ? 'Player' : username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: rankColor),
                      const SizedBox(width: 3),
                      Text(
                        rankTitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: rankColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Edit icon
            Icon(Icons.edit_rounded, size: 14, color: Colors.white.withValues(alpha:0.5)),
          ],
        ),
      ),
    );
  }
}
