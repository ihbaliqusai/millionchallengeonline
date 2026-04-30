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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

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
                      const Color(0xFF040914).withValues(alpha: 0.58),
                      const Color(0xFF071126).withValues(alpha: 0.92),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _Header(onBack: () => Navigator.of(context).pop()),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _loading
                          ? const _LoadingState()
                          : _StatsDashboard(
                              appState: appState,
                              stats: _stats,
                            ),
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

class _StatsDashboard extends StatelessWidget {
  const _StatsDashboard({
    required this.appState,
    required this.stats,
  });

  final AppState appState;
  final Map<String, int> stats;

  int _value(String key) => stats[key] ?? 0;

  @override
  Widget build(BuildContext context) {
    final games = _value('gamesPlayed');
    final wins = _value('wins');
    final recordedLosses = _value('losses');
    final losses = recordedLosses > 0
        ? recordedLosses
        : (games - wins < 0 ? 0 : games - wins);
    final correct = _value('correctAnswers');
    final wrong = _value('wrongAnswers');
    final totalAnswered =
        _value('totalAnswered') > 0 ? _value('totalAnswered') : correct + wrong;
    final winPercent = _value('winPercent') > 0
        ? _value('winPercent')
        : (games > 0 ? (wins * 100 / games).round() : 0);
    final accuracy = _value('accuracy') > 0
        ? _value('accuracy')
        : (totalAnswered > 0 ? (correct * 100 / totalAnswered).round() : 0);
    final trophies = appState.trophies;
    final league = TrophyProgression.leagueFor(trophies);

    final items = <_StatItem>[
      _StatItem(
        icon: Icons.sports_esports_rounded,
        color: const Color(0xFF38BDF8),
        value: _compactNumber(games),
        label: 'المباريات',
      ),
      _StatItem(
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFFACC15),
        value: _compactNumber(wins),
        label: 'الانتصارات',
      ),
      _StatItem(
        icon: Icons.flag_rounded,
        color: const Color(0xFFFB7185),
        value: _compactNumber(losses),
        label: 'الخسائر',
      ),
      _StatItem(
        icon: Icons.public_rounded,
        color: const Color(0xFF22D3EE),
        value: _compactNumber(_value('onlineWins')),
        label: 'فوز أونلاين',
      ),
      _StatItem(
        icon: Icons.quiz_rounded,
        color: const Color(0xFFA78BFA),
        value: _compactNumber(totalAnswered),
        label: 'الأسئلة',
      ),
      _StatItem(
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF34D399),
        value: _compactNumber(correct),
        label: 'صحيحة',
      ),
      _StatItem(
        icon: Icons.cancel_rounded,
        color: const Color(0xFFF87171),
        value: _compactNumber(wrong),
        label: 'خاطئة',
      ),
      _StatItem(
        icon: Icons.bolt_rounded,
        color: const Color(0xFFF97316),
        value: _compactNumber(_value('bestStreak')),
        label: 'أفضل تتابع',
      ),
      _StatItem(
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFFB020),
        value: _compactNumber(_value('winStreak')),
        label: 'سلسلة الفوز',
      ),
      _StatItem(
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF4ADE80),
        value: _moneyNumber(_value('totalEarnings')),
        label: 'الأرباح',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 300 || constraints.maxWidth < 760;
        final gap = compact ? 8.0 : 12.0;
        final horizontalPadding = compact ? 10.0 : 16.0;
        final bottomPadding = compact ? 10.0 : 14.0;
        final sideWidth = constraints.maxWidth < 720
            ? 204.0
            : constraints.maxWidth < 980
                ? 240.0
                : 270.0;
        final heroHeight = compact ? 88.0 : 106.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            bottomPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: sideWidth,
                child: _PlayerPanel(
                  appState: appState,
                  games: games,
                  wins: wins,
                  trophies: trophies,
                  league: league,
                  compact: compact,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: heroHeight,
                      child: Row(
                        children: [
                          Expanded(
                            child: _HeroMetric(
                              icon: Icons.trending_up_rounded,
                              color: const Color(0xFF4ADE80),
                              value: '$winPercent%',
                              label: 'نسبة الفوز',
                              caption: '$wins فوز من $games',
                              progress: winPercent / 100,
                              compact: compact,
                            ),
                          ),
                          SizedBox(width: gap),
                          Expanded(
                            child: _HeroMetric(
                              icon: Icons.task_alt_rounded,
                              color: const Color(0xFF38BDF8),
                              value: '$accuracy%',
                              label: 'دقة الإجابات',
                              caption: '$correct صحيحة',
                              progress: accuracy / 100,
                              compact: compact,
                            ),
                          ),
                          SizedBox(width: gap),
                          Expanded(
                            child: _HeroMetric(
                              icon: league.icon,
                              color: league.color,
                              value: _compactNumber(trophies),
                              label: 'الكؤوس',
                              caption: league.nameAr,
                              progress: league.progress(trophies),
                              compact: compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: gap),
                    Expanded(
                      child: _StatsGrid(
                        items: items,
                        compact: compact,
                        gap: gap,
                      ),
                    ),
                  ],
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
                  'الإحصائيات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'لوحة أداء اللاعب',
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

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({
    required this.appState,
    required this.games,
    required this.wins,
    required this.trophies,
    required this.league,
    required this.compact,
  });

  final AppState appState;
  final int games;
  final int wins;
  final int trophies;
  final TrophyLeague league;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final username = (appState.user?.displayName ??
            appState.user?.email?.split('@').first ??
            'لاعب')
        .trim();
    final rankTitle = PlayerRank.titleForLevel(appState.level);
    final rankColor = PlayerRank.colorForLevel(appState.level);
    final xpNeeded =
        appState.xpNeededForLevel == 0 ? 1 : appState.xpNeededForLevel;
    final xpProgress = (appState.xpInCurrentLevel / xpNeeded).clamp(0.0, 1.0);
    final avatarSize = compact ? 46.0 : 54.0;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF111827),
                  border: Border.all(color: league.color, width: 2),
                ),
                child: ClipOval(
                  child: appState.user?.photoURL?.isNotEmpty == true
                      ? Image.network(
                          appState.user!.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username.isEmpty ? 'لاعب' : username,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 15 : 17,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: rankColor, size: 15),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            rankTitle,
                            style: TextStyle(
                              color: rankColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          _LevelProgress(
            level: appState.level,
            xpText: '${appState.xpInCurrentLevel} / $xpNeeded XP',
            progress: xpProgress,
            color: rankColor,
            compact: compact,
          ),
          _LeagueLine(
            league: league,
            trophies: trophies,
            compact: compact,
          ),
          _PlayerSummary(
            games: games,
            wins: wins,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _LevelProgress extends StatelessWidget {
  const _LevelProgress({
    required this.level,
    required this.xpText,
    required this.progress,
    required this.color,
    required this.compact,
  });

  final int level;
  final String xpText;
  final double progress;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'المستوى $level',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              xpText,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            minHeight: compact ? 5 : 6,
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _LeagueLine extends StatelessWidget {
  const _LeagueLine({
    required this.league,
    required this.trophies,
    required this.compact,
  });

  final TrophyLeague league;
  final int trophies;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(league.icon, color: league.color, size: compact ? 17 : 19),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                league.nameAr,
                style: TextStyle(
                  color: league.color,
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _compactNumber(trophies),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            minHeight: compact ? 5 : 6,
            value: league.progress(trophies),
            backgroundColor: Colors.white.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(league.color),
          ),
        ),
      ],
    );
  }
}

class _PlayerSummary extends StatelessWidget {
  const _PlayerSummary({
    required this.games,
    required this.wins,
    required this.compact,
  });

  final int games;
  final int wins;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = games == 0
        ? 'ابدأ أول مباراة لتظهر أرقامك هنا'
        : '$games مباراة - $wins فوز';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.78),
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w800,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.caption,
    required this.progress,
    required this.compact,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String caption;
  final double progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: _panelDecoration(accent: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: compact ? 16 : 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.64),
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 19 : 23,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: TextStyle(
              color: color.withValues(alpha: 0.86),
              fontSize: compact ? 8 : 9,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.items,
    required this.compact,
    required this.gap,
  });

  final List<_StatItem> items;
  final bool compact;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final firstRow = items.take(5).toList();
    final secondRow = items.skip(5).take(5).toList();

    return Column(
      children: [
        Expanded(child: _StatRow(items: firstRow, compact: compact, gap: gap)),
        SizedBox(height: gap),
        Expanded(child: _StatRow(items: secondRow, compact: compact, gap: gap)),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.items,
    required this.compact,
    required this.gap,
  });

  final List<_StatItem> items;
  final bool compact;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: _StatTile(item: items[i], compact: compact)),
          if (i != items.length - 1) SizedBox(width: gap),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.item,
    required this.compact,
  });

  final _StatItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 7 : 9,
      ),
      decoration: _panelDecoration(accent: item.color, subtle: true),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: item.color, size: compact ? 18 : 21),
          SizedBox(height: compact ? 4 : 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.value,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 17 : 20,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          SizedBox(height: compact ? 3 : 4),
          Text(
            item.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 34,
        height: 34,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Color(0xFFFACC15),
        ),
      ),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
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

String _moneyNumber(int value) => '\$${_compactNumber(value)}';
