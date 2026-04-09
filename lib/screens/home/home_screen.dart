import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:millionaire_flutter_exact/screens/online/rooms_screen.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import 'store_screen.dart';
import '../online/settings_screen.dart';
import '../online/stats_screen.dart';
import '../online/achievements_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _idleCtrl;
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadCurrency();
    });
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppState>().loadCurrency();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleCtrl.dispose();
    _glowCtrl.dispose();
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
                      const Color(0xFF0A1B4A).withOpacity(0.80),
                      const Color(0xFF060C24).withOpacity(0.90),
                    ],
                  ),
                ),
              ),
            ),

            // ── Main layout: LEFT sidebar | CENTER castle | RIGHT sidebar ──
            Positioned.fill(
              child: Row(
                children: [
                  // ── LEFT SIDEBAR ─────────────────────────────────────
                  _LeftSidebar(appState: appState),

                  // ── CENTER: Castle + Battle button ───────────────────
                  Expanded(
                    child: _CenterArena(
                      appState: appState,
                      idleCtrl: _idleCtrl,
                      glowCtrl: _glowCtrl,
                    ),
                  ),

                  // ── RIGHT SIDEBAR ────────────────────────────────────
                  _RightSidebar(
                    appState: appState,
                    username: username,
                    user: user,
                  ),
                ],
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
                ),
                const SizedBox(width: 8),
                _CurrencyChip(
                  icon: Icons.diamond_rounded,
                  color: const Color(0xFF38BDF8),
                  label: appState.gems.toString(),
                ),
              ],
            ),
          ),
          // Level badge — exactly centered
          Positioned(
            top: top,
            left: 0,
            right: 0,
            child: const Center(
              child: _LevelBadge(),
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
  });
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
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
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFACC15).withOpacity(0.6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFFACC15), size: 18),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'LEVEL 1',
                style: TextStyle(
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
                    value: 0.30,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFACC15)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          Text(
            '30/100',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HudIconButton extends StatelessWidget {
  const _HudIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
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
          // Forge / daily reward slot
          _SideCard(
            label: 'FORGE',
            icon: Icons.hardware_rounded,
            iconColor: const Color(0xFFF97316),
            badge: 'NEW',
            badgeColor: const Color(0xFF22C55E),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const StoreScreen()),
            ),
          ),
          const SizedBox(height: 8),
          // Chest slot counter
          _ChestCounter(current: 1, total: 3),
          const SizedBox(height: 8),
          // Daily quests / offline game
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
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
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
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_rounded, color: const Color(0xFF38BDF8), size: 22),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final filled = i < current;
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: filled ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
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
    return Column(
      children: [
        const Spacer(),

        // ── Castle illustration (idle float) ──────────────────
        Expanded(
          flex: 5,
          child: AnimatedBuilder(
            animation: idleCtrl,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, math.sin(idleCtrl.value * math.pi) * 6),
              child: child,
            ),
            child: _CastleWidget(),
          ),
        ),

        // ── Ranking button ────────────────────────────────────
        _RankingButton(),

        const SizedBox(height: 8),

        // ── BATTLE + SPEED BATTLE buttons ─────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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

        SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
      ],
    );
  }
}

class _CastleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CastlePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _CastlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.55;
    final w = size.width * 0.38;
    final h = size.height * 0.65;

    final wallPaint = Paint()..color = const Color(0xFF8B6914);
    final darkPaint = Paint()..color = const Color(0xFF5C4510);
    final roofPaint = Paint()..color = const Color(0xFF1D4ED8);
    final stonePaint = Paint()
      ..color = const Color(0xFF6B7280).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + h / 2 + 8), width: w * 1.1, height: 16),
      shadowPaint,
    );

    // Main tower body
    final body = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(6)),
      wallPaint,
    );

    // Wood panels
    final panelPaint = Paint()..color = const Color(0xFF92400E).withOpacity(0.65);
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 2; col++) {
        final px = cx - w / 2 + 8 + col * (w / 2 - 8);
        final py = cy - h / 4 + row * (h / 3.5);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(px, py, w / 2 - 16, h / 4.5),
            const Radius.circular(4),
          ),
          panelPaint,
        );
      }
    }

    // Stone grid lines
    for (int row = 0; row < 6; row++) {
      canvas.drawLine(
        Offset(cx - w / 2, cy - h / 2 + row * (h / 6)),
        Offset(cx + w / 2, cy - h / 2 + row * (h / 6)),
        stonePaint,
      );
    }

    // Roof triangle
    final roofPath = Path()
      ..moveTo(cx, cy - h / 2 - h * 0.28)
      ..lineTo(cx - w * 0.42, cy - h / 2)
      ..lineTo(cx + w * 0.42, cy - h / 2)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // Roof outline
    canvas.drawPath(
      roofPath,
      Paint()
        ..color = const Color(0xFF1E40AF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Gate arch
    final gateW = w * 0.28;
    final gateH = h * 0.22;
    final gatePath = Path()
      ..moveTo(cx - gateW / 2, cy + h / 2)
      ..lineTo(cx - gateW / 2, cy + h / 4)
      ..arcToPoint(
        Offset(cx + gateW / 2, cy + h / 4),
        radius: Radius.circular(gateW / 2),
        clockwise: false,
      )
      ..lineTo(cx + gateW / 2, cy + h / 2)
      ..close();
    canvas.drawPath(gatePath, darkPaint);

    // Crenellations
    final crenW = w / 10;
    final crenH = h * 0.07;
    for (int i = 0; i < 5; i++) {
      if (i.isEven) {
        canvas.drawRect(
          Rect.fromLTWH(
            cx - w / 2 + i * (w / 5),
            cy - h / 2 - crenH,
            crenW * 1.5,
            crenH,
          ),
          wallPaint,
        );
      }
    }

    // Gear wheels on gate
    final gearPaint = Paint()
      ..color = const Color(0xFF374151)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(cx - gateW / 2 - 10, cy + h / 2 - 8), 8, gearPaint);
    canvas.drawCircle(Offset(cx + gateW / 2 + 10, cy + h / 2 - 8), 8, gearPaint);

    // Player figure at gate
    final figPaint = Paint()..color = const Color(0xFF92400E);
    canvas.drawCircle(Offset(cx, cy + h / 2 + 2), 9, figPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + h / 2 + 16), width: 14, height: 18),
        const Radius.circular(3),
      ),
      figPaint,
    );
  }

  @override
  bool shouldRepaint(_CastlePainter old) => false;
}

class _RankingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
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
                    color: glowColor.withOpacity(glow),
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

          // Daily chests — center
          _DailyChests(),

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
          color: const Color(0xFF091332).withOpacity(0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
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
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFACC15).withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'DAILY CHESTS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFACC15),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(4, (i) {
              final colors = [
                const Color(0xFF22C55E),
                const Color(0xFFEC4899),
                const Color(0xFF38BDF8),
                const Color(0xFFEC4899),
              ];
              return Container(
                width: 26,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: colors[i].withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors[i].withOpacity(0.7), width: 1.5),
                ),
                child: Icon(Icons.inventory_2_rounded, size: 14, color: colors[i]),
              );
            }),
          ),
        ],
      ),
    );
  }
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
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                      const Icon(Icons.star_rounded, size: 12, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 3),
                      Text(
                        'Beginner',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF38BDF8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Edit icon
            Icon(Icons.edit_rounded, size: 14, color: Colors.white.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
