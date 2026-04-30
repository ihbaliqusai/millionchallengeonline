import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../widgets/currency_reward_overlay.dart';

const _kDayRewards = [
  {'coins': 100, 'gems': 0},
  {'coins': 150, 'gems': 0},
  {'coins': 200, 'gems': 1},
  {'coins': 250, 'gems': 0},
  {'coins': 300, 'gems': 1},
  {'coins': 400, 'gems': 2},
  {'coins': 500, 'gems': 3},
  {'coins': 300, 'gems': 1},
  {'coins': 350, 'gems': 1},
  {'coins': 400, 'gems': 2},
  {'coins': 450, 'gems': 2},
  {'coins': 500, 'gems': 3},
  {'coins': 600, 'gems': 3},
  {'coins': 800, 'gems': 5},
  {'coins': 400, 'gems': 2},
  {'coins': 450, 'gems': 2},
  {'coins': 500, 'gems': 3},
  {'coins': 550, 'gems': 3},
  {'coins': 600, 'gems': 4},
  {'coins': 700, 'gems': 4},
  {'coins': 1000, 'gems': 7},
  {'coins': 600, 'gems': 3},
  {'coins': 650, 'gems': 4},
  {'coins': 700, 'gems': 4},
  {'coins': 750, 'gems': 5},
  {'coins': 800, 'gems': 5},
  {'coins': 900, 'gems': 6},
  {'coins': 1000, 'gems': 7},
  {'coins': 1200, 'gems': 8},
  {'coins': 2000, 'gems': 15},
];

class DailyStreakScreen extends StatefulWidget {
  const DailyStreakScreen({super.key});

  @override
  State<DailyStreakScreen> createState() => _DailyStreakScreenState();
}

class _DailyStreakScreenState extends State<DailyStreakScreen> {
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _claimReward() async {
    final appState = context.read<AppState>();
    if (appState.claimedToday || _claiming) return;
    setState(() => _claiming = true);

    final reward = await appState.claimDailyStreak();

    if (!mounted) return;
    setState(() => _claiming = false);

    if (reward != null) {
      await _showRewardDialog(reward['coins']!, reward['gems']!);
      if (mounted) {
        showCurrencyRewardOverlay(
          context,
          coins: reward['coins']!,
          gems: reward['gems']!,
        );
      }
    }
  }

  Future<void> _showRewardDialog(int coins, int gems) {
    return showDialog<void>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF081328),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_rounded, color: Color(0xFFFACC15)),
              SizedBox(width: 8),
              Text(
                'تم فتح الصندوق',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (coins > 0)
                _RewardChip(
                  icon: Icons.monetization_on_rounded,
                  color: const Color(0xFFFACC15),
                  value: '+$coins',
                ),
              if (coins > 0 && gems > 0) const SizedBox(width: 10),
              if (gems > 0)
                _RewardChip(
                  icon: Icons.diamond_rounded,
                  color: const Color(0xFF38BDF8),
                  value: '+$gems',
                ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'رائع',
                style: TextStyle(
                  color: Color(0xFFFACC15),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final streakDay = appState.streakDay.clamp(1, 30);
    final claimedToday = appState.claimedToday;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF071126),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/ui/bg_main.png', fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF040914).withValues(alpha: 0.56),
                      const Color(0xFF071126).withValues(alpha: 0.94),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _Header(onBack: () => Navigator.pop(context)),
                  Expanded(
                    child: _DailyRewardsDashboard(
                      streakDay: streakDay,
                      claimedToday: claimedToday,
                      claiming: _claiming,
                      onClaim: _claimReward,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyRewardsDashboard extends StatelessWidget {
  const _DailyRewardsDashboard({
    required this.streakDay,
    required this.claimedToday,
    required this.claiming,
    required this.onClaim,
  });

  final int streakDay;
  final bool claimedToday;
  final bool claiming;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 300 || constraints.maxWidth < 760;
        final panelGap = compact ? 8.0 : 12.0;
        final gridGap = constraints.maxHeight < 360
            ? 5.0
            : compact
                ? 6.0
                : 8.0;
        final sideWidth = constraints.maxWidth < 740
            ? 220.0
            : constraints.maxWidth < 980
                ? 260.0
                : 292.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 10 : 16,
            0,
            compact ? 10 : 16,
            compact ? 10 : 14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: sideWidth,
                child: _RewardPanel(
                  streakDay: streakDay,
                  claimedToday: claimedToday,
                  claiming: claiming,
                  onClaim: onClaim,
                  compact: compact,
                ),
              ),
              SizedBox(width: panelGap),
              Expanded(
                child: _RewardsGrid(
                  streakDay: streakDay,
                  claimedToday: claimedToday,
                  compact: compact,
                  gap: gridGap,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'المكافآت اليومية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'سلسلة 30 يوم',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'رجوع',
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: Colors.white,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardPanel extends StatelessWidget {
  const _RewardPanel({
    required this.streakDay,
    required this.claimedToday,
    required this.claiming,
    required this.onClaim,
    required this.compact,
  });

  final int streakDay;
  final bool claimedToday;
  final bool claiming;
  final VoidCallback onClaim;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final reward = _kDayRewards[streakDay - 1];
    final nextMilestone = _nextMilestone(streakDay);
    final progress = streakDay / 30;
    final coins = reward['coins'] ?? 0;
    final gems = reward['gems'] ?? 0;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TodayBadge(
            streakDay: streakDay,
            claimedToday: claimedToday,
            compact: compact,
          ),
          SizedBox(height: compact ? 8 : 12),
          _RewardPreview(coins: coins, gems: gems, compact: compact),
          SizedBox(height: compact ? 8 : 12),
          _ProgressBlock(
            streakDay: streakDay,
            nextMilestone: nextMilestone,
            progress: progress,
            compact: compact,
          ),
          const Spacer(),
          _ClaimButton(
            coins: coins,
            gems: gems,
            claimedToday: claimedToday,
            claiming: claiming,
            onClaim: onClaim,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _TodayBadge extends StatelessWidget {
  const _TodayBadge({
    required this.streakDay,
    required this.claimedToday,
    required this.compact,
  });

  final int streakDay;
  final bool claimedToday;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 48 : 58,
          height: compact ? 48 : 58,
          decoration: BoxDecoration(
            color: const Color(0xFFFACC15).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFACC15), width: 1.5),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$streakDay',
                style: TextStyle(
                  color: const Color(0xFFFACC15),
                  fontSize: compact ? 24 : 30,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                claimedToday ? 'تم استلام مكافأة اليوم' : 'اليوم $streakDay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                claimedToday ? 'المكافأة التالية غداً' : 'صندوق اليوم جاهز',
                style: TextStyle(
                  color: claimedToday
                      ? const Color(0xFF22C55E)
                      : Colors.white.withValues(alpha: 0.62),
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RewardPreview extends StatelessWidget {
  const _RewardPreview({
    required this.coins,
    required this.gems,
    required this.compact,
  });

  final int coins;
  final int gems;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration:
          _panelDecoration(accent: const Color(0xFFFACC15), subtle: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'مكافأة اليوم',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: compact ? 8 : 10),
          Row(
            children: [
              Expanded(
                child: _RewardValue(
                  icon: Icons.monetization_on_rounded,
                  color: const Color(0xFFFACC15),
                  value: _compactNumber(coins),
                  label: 'عملة',
                  compact: compact,
                ),
              ),
              if (gems > 0) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _RewardValue(
                    icon: Icons.diamond_rounded,
                    color: const Color(0xFF38BDF8),
                    value: _compactNumber(gems),
                    label: 'جوهرة',
                    compact: compact,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardValue extends StatelessWidget {
  const _RewardValue({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.compact,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: compact ? 18 : 22),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 18 : 22,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.78),
                  fontSize: compact ? 9 : 10,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({
    required this.streakDay,
    required this.nextMilestone,
    required this.progress,
    required this.compact,
  });

  final int streakDay;
  final int nextMilestone;
  final double progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final milestoneText =
        streakDay >= 30 ? 'أكملت السلسلة' : '$nextMilestone - مكافأة كبرى';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: const Color(0xFFF97316),
              size: compact ? 17 : 19,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$streakDay من 30 يوم',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              milestoneText,
              style: TextStyle(
                color: const Color(0xFFFACC15),
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: compact ? 5 : 6,
            backgroundColor: Colors.white.withValues(alpha: 0.10),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
          ),
        ),
      ],
    );
  }
}

class _ClaimButton extends StatelessWidget {
  const _ClaimButton({
    required this.coins,
    required this.gems,
    required this.claimedToday,
    required this.claiming,
    required this.onClaim,
    required this.compact,
  });

  final int coins;
  final int gems;
  final bool claimedToday;
  final bool claiming;
  final VoidCallback onClaim;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enabled = !claimedToday && !claiming;

    return SizedBox(
      width: double.infinity,
      height: compact ? 42 : 48,
      child: FilledButton.icon(
        onPressed: enabled ? onClaim : null,
        icon: claiming
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF111827),
                ),
              )
            : Icon(claimedToday
                ? Icons.check_circle_rounded
                : Icons.inventory_2_rounded),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            claimedToday
                ? 'تم الاستلام'
                : 'استلام ${_compactNumber(coins)} عملة${gems > 0 ? ' + $gems جوهرة' : ''}',
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFACC15),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.10),
          foregroundColor: const Color(0xFF111827),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.58),
          textStyle: TextStyle(
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _RewardsGrid extends StatelessWidget {
  const _RewardsGrid({
    required this.streakDay,
    required this.claimedToday,
    required this.compact,
    required this.gap,
  });

  final int streakDay;
  final bool claimedToday;
  final bool compact;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (row) {
        final children = List.generate(6, (col) {
          final day = row * 6 + col + 1;
          final reward = _kDayRewards[day - 1];
          return Expanded(
            child: _DayTile(
              day: day,
              coins: reward['coins'] ?? 0,
              gems: reward['gems'] ?? 0,
              state: _dayState(day, streakDay, claimedToday),
              compact: compact,
            ),
          );
        });

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: row == 4 ? 0 : gap),
            child: Row(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1) SizedBox(width: gap),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.coins,
    required this.gems,
    required this.state,
    required this.compact,
  });

  final int day;
  final int coins;
  final int gems;
  final _RewardDayState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isMilestone = day == 7 || day == 14 || day == 21 || day == 30;
    final accent = switch (state) {
      _RewardDayState.claimed => const Color(0xFF22C55E),
      _RewardDayState.todayAvailable => const Color(0xFFFACC15),
      _RewardDayState.todayClaimed => const Color(0xFF22C55E),
      _RewardDayState.future => isMilestone
          ? const Color(0xFFA78BFA)
          : Colors.white.withValues(alpha: 0.28),
    };

    final bgColor = switch (state) {
      _RewardDayState.claimed =>
        const Color(0xFF22C55E).withValues(alpha: 0.12),
      _RewardDayState.todayAvailable =>
        const Color(0xFFFACC15).withValues(alpha: 0.16),
      _RewardDayState.todayClaimed =>
        const Color(0xFF22C55E).withValues(alpha: 0.18),
      _RewardDayState.future => isMilestone
          ? const Color(0xFFA78BFA).withValues(alpha: 0.09)
          : Colors.white.withValues(alpha: 0.045),
    };

    final borderWidth = state == _RewardDayState.todayAvailable ||
            state == _RewardDayState.todayClaimed
        ? 1.8
        : 1.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent, width: borderWidth),
        boxShadow: state == _RewardDayState.todayAvailable
            ? [
                BoxShadow(
                  color: const Color(0xFFFACC15).withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: state == _RewardDayState.future
                        ? Colors.white.withValues(alpha: 0.66)
                        : Colors.white,
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                if (isMilestone) ...[
                  const SizedBox(width: 3),
                  Icon(Icons.workspace_premium_rounded,
                      color: accent, size: compact ? 10 : 12),
                ],
              ],
            ),
            SizedBox(height: compact ? 3 : 4),
            _TileRewardLine(
              icon: Icons.monetization_on_rounded,
              color: const Color(0xFFFACC15),
              value: _compactNumber(coins),
              compact: compact,
            ),
            if (gems > 0) ...[
              const SizedBox(height: 1),
              _TileRewardLine(
                icon: Icons.diamond_rounded,
                color: const Color(0xFF38BDF8),
                value: _compactNumber(gems),
                compact: compact,
              ),
            ],
            SizedBox(height: compact ? 2 : 3),
            Icon(
              switch (state) {
                _RewardDayState.claimed => Icons.check_circle_rounded,
                _RewardDayState.todayAvailable => Icons.inventory_2_rounded,
                _RewardDayState.todayClaimed => Icons.check_circle_rounded,
                _RewardDayState.future => Icons.lock_rounded,
              },
              color: accent,
              size: compact ? 12 : 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _TileRewardLine extends StatelessWidget {
  const _TileRewardLine({
    required this.icon,
    required this.color,
    required this.value,
    required this.compact,
  });

  final IconData icon;
  final Color color;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: compact ? 9 : 11),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: compact ? 7 : 8,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.color,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: _panelDecoration(accent: color, subtle: true),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

enum _RewardDayState {
  claimed,
  todayAvailable,
  todayClaimed,
  future,
}

_RewardDayState _dayState(int day, int streakDay, bool claimedToday) {
  if (day < streakDay) return _RewardDayState.claimed;
  if (day == streakDay) {
    return claimedToday
        ? _RewardDayState.todayClaimed
        : _RewardDayState.todayAvailable;
  }
  return _RewardDayState.future;
}

int _nextMilestone(int streakDay) {
  for (final milestone in const [7, 14, 21, 30]) {
    if (streakDay <= milestone) return milestone;
  }
  return 30;
}

BoxDecoration _panelDecoration({
  Color? accent,
  bool subtle = false,
}) {
  final borderColor = accent == null
      ? Colors.white.withValues(alpha: 0.12)
      : accent.withValues(alpha: subtle ? 0.26 : 0.34);

  return BoxDecoration(
    color: const Color(0xFF081328).withValues(alpha: subtle ? 0.82 : 0.88),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: subtle ? 0.16 : 0.24),
        blurRadius: subtle ? 8 : 14,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

String _compactNumber(int value) {
  final abs = value.abs();
  if (abs >= 1000000) {
    final decimals = abs >= 10000000 ? 0 : 1;
    return '${(value / 1000000).toStringAsFixed(decimals)}m';
  }
  if (abs >= 1000) {
    final decimals = abs >= 10000 ? 0 : 1;
    return '${(value / 1000).toStringAsFixed(decimals)}k';
  }
  return '$value';
}
