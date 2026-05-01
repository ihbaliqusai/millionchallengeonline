import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/player_rank.dart';
import '../../core/trophy_league.dart';
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

  Future<void> _showEditUsernameDialog() async {
    final appState = context.read<AppState>();
    final initialName = appState.user?.displayName ?? '';

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => _EditUsernameDialog(initialName: initialName),
    );

    if (newName == null || newName.isEmpty || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await appState.updateUsername(newName);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم تحديث الاسم بنجاح'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('فشل تحديث الاسم، حاول مرة أخرى'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF071126),
        resizeToAvoidBottomInset: false,
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
                      const Color(0xFF071126).withValues(alpha: 0.93),
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
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _loading
                          ? const _LoadingState()
                          : _ProfileDashboard(
                              appState: appState,
                              stats: _stats,
                              onEditName: _showEditUsernameDialog,
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

class _ProfileDashboard extends StatelessWidget {
  const _ProfileDashboard({
    required this.appState,
    required this.stats,
    required this.onEditName,
  });

  final AppState appState;
  final Map<String, int> stats;
  final VoidCallback onEditName;

  int _value(String key) => stats[key] ?? 0;

  @override
  Widget build(BuildContext context) {
    final games = _value('gamesPlayed');
    final wins = _value('wins');
    final losses = (_value('losses') > 0 ? _value('losses') : games - wins)
        .clamp(0, 999999);
    final correct = _value('correctAnswers');
    final wrong = _value('wrongAnswers');
    final totalAnswered =
        _value('totalAnswered') > 0 ? _value('totalAnswered') : correct + wrong;
    final accuracy = _value('accuracy') > 0
        ? _value('accuracy')
        : (totalAnswered > 0 ? (correct * 100 / totalAnswered).round() : 0);
    final winRate = _value('winPercent') > 0
        ? _value('winPercent')
        : (games > 0 ? (wins * 100 / games).round() : 0);
    final rank = PlayerRank.tierForLevel(appState.level);
    final nextRank = PlayerRank.nextTierForLevel(appState.level);
    final league = TrophyProgression.leagueFor(appState.trophies);

    final metrics = <_MetricItem>[
      _MetricItem(
        icon: Icons.sports_esports_rounded,
        color: const Color(0xFF38BDF8),
        label: 'المباريات',
        value: _compactNumber(games),
      ),
      _MetricItem(
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFFACC15),
        label: 'الفوز',
        value: _compactNumber(wins),
      ),
      _MetricItem(
        icon: Icons.flag_rounded,
        color: const Color(0xFFFB7185),
        label: 'الخسائر',
        value: _compactNumber(losses),
      ),
      _MetricItem(
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF34D399),
        label: 'الدقة',
        value: '$accuracy%',
      ),
      _MetricItem(
        icon: Icons.public_rounded,
        color: const Color(0xFF22D3EE),
        label: 'أونلاين',
        value: _compactNumber(_value('onlineWins')),
      ),
      _MetricItem(
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFFB020),
        label: 'سلسلة الفوز',
        value: _compactNumber(_value('winStreak')),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 300 || constraints.maxWidth < 820;
        final gap = compact ? 8.0 : 12.0;
        final sideWidth = constraints.maxWidth < 760
            ? 220.0
            : constraints.maxWidth < 980
                ? 248.0
                : 286.0;
        final rulesWidth = constraints.maxWidth < 760
            ? 230.0
            : constraints.maxWidth < 980
                ? 260.0
                : 300.0;

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
                child: _IdentityPanel(
                  appState: appState,
                  rank: rank,
                  league: league,
                  onEditName: onEditName,
                  compact: compact,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: compact ? 112 : 128,
                      child: _LevelPanel(
                        appState: appState,
                        rank: rank,
                        nextRank: nextRank,
                        compact: compact,
                      ),
                    ),
                    SizedBox(height: gap),
                    Expanded(
                      child: _MetricsGrid(
                        metrics: metrics,
                        compact: compact,
                        gap: gap,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: gap),
              SizedBox(
                width: rulesWidth,
                child: _ProgressionPanel(
                  appState: appState,
                  league: league,
                  winRate: winRate,
                  correct: correct,
                  wrong: wrong,
                  compact: compact,
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
                  'الملف الشخصي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'المستوى، الرتبة، ودوري الكؤوس',
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

class _IdentityPanel extends StatelessWidget {
  const _IdentityPanel({
    required this.appState,
    required this.rank,
    required this.league,
    required this.onEditName,
    required this.compact,
  });

  final AppState appState;
  final PlayerRankTier rank;
  final TrophyLeague league;
  final VoidCallback onEditName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final user = appState.user;
    final username =
        (user?.displayName ?? user?.email?.split('@').first ?? 'لاعب').trim();
    final uid = user?.uid ?? '';
    final xpProgress = appState.xpNeededForLevel > 0
        ? (appState.xpInCurrentLevel / appState.xpNeededForLevel)
            .clamp(0.0, 1.0)
        : 0.0;

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
                width: compact ? 52 : 60,
                height: compact ? 52 : 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF111827),
                  border: Border.all(color: rank.color, width: 2),
                ),
                child: ClipOval(
                  child: user?.photoURL?.isNotEmpty == true
                      ? Image.network(
                          user!.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 30,
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
                        fontSize: compact ? 16 : 18,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    _MiniBadge(
                      icon: rank.icon,
                      color: rank.color,
                      text: rank.nameAr,
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'تعديل الاسم',
                child: IconButton(
                  onPressed: onEditName,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  color: Colors.white70,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.07),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          _ProgressLine(
            title: 'المستوى ${appState.level}',
            value:
                '${appState.xpInCurrentLevel}/${appState.xpNeededForLevel} XP',
            progress: xpProgress,
            color: rank.color,
            compact: compact,
          ),
          _ProgressLine(
            title: league.nameAr,
            value: '${_compactNumber(appState.trophies)} كأس',
            progress: league.progress(appState.trophies),
            color: league.color,
            compact: compact,
          ),
          _AccountStrip(uid: uid, compact: compact),
        ],
      ),
    );
  }
}

class _LevelPanel extends StatelessWidget {
  const _LevelPanel({
    required this.appState,
    required this.rank,
    required this.nextRank,
    required this.compact,
  });

  final AppState appState;
  final PlayerRankTier rank;
  final PlayerRankTier? nextRank;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final xpProgress = appState.xpNeededForLevel > 0
        ? (appState.xpInCurrentLevel / appState.xpNeededForLevel)
            .clamp(0.0, 1.0)
        : 0.0;
    final nextText = nextRank == null
        ? 'أعلى رتبة'
        : 'المستوى ${nextRank!.minLevel}: ${nextRank!.nameAr}';

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: _panelDecoration(accent: rank.color),
      child: Row(
        children: [
          Container(
            width: compact ? 64 : 76,
            height: double.infinity,
            decoration: BoxDecoration(
              color: rank.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: rank.color.withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(rank.icon, color: rank.color, size: compact ? 22 : 26),
                const SizedBox(height: 4),
                Text(
                  '${appState.level}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 22 : 28,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                Text(
                  rank.nameAr,
                  style: TextStyle(
                    color: rank.color,
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'تقدم المستوى',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 13 : 15,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      nextText,
                      style: TextStyle(
                        color: rank.color,
                        fontSize: compact ? 9 : 10,
                        fontWeight: FontWeight.w900,
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
                    value: xpProgress,
                    minHeight: compact ? 5 : 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(rank.color),
                  ),
                ),
                const Spacer(),
                _RankPath(currentLevel: appState.level, compact: compact),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankPath extends StatelessWidget {
  const _RankPath({required this.currentLevel, required this.compact});

  final int currentLevel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < PlayerRank.tiers.length; i++) ...[
          Expanded(
            child: _RankChip(
              tier: PlayerRank.tiers[i],
              active: currentLevel >= PlayerRank.tiers[i].minLevel,
              compact: compact,
            ),
          ),
          if (i != PlayerRank.tiers.length - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _RankChip extends StatelessWidget {
  const _RankChip({
    required this.tier,
    required this.active,
    required this.compact,
  });

  final PlayerRankTier tier;
  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 24 : 28,
      decoration: BoxDecoration(
        color: active
            ? tier.color.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: active
              ? tier.color.withValues(alpha: 0.52)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Tooltip(
        message: '${tier.nameAr} - مستوى ${tier.minLevel}',
        child: Icon(
          tier.icon,
          color: active ? tier.color : Colors.white30,
          size: compact ? 13 : 15,
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.metrics,
    required this.compact,
    required this.gap,
  });

  final List<_MetricItem> metrics;
  final bool compact;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final first = metrics.take(3).toList();
    final second = metrics.skip(3).take(3).toList();

    return Column(
      children: [
        Expanded(child: _MetricRow(items: first, compact: compact, gap: gap)),
        SizedBox(height: gap),
        Expanded(child: _MetricRow(items: second, compact: compact, gap: gap)),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.items,
    required this.compact,
    required this.gap,
  });

  final List<_MetricItem> items;
  final bool compact;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: _MetricTile(item: items[i], compact: compact)),
          if (i != items.length - 1) SizedBox(width: gap),
        ],
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.item, required this.compact});

  final _MetricItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: _panelDecoration(accent: item.color, subtle: true),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: item.color, size: compact ? 19 : 22),
          SizedBox(height: compact ? 4 : 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.value,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 19 : 23,
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
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ProgressionPanel extends StatelessWidget {
  const _ProgressionPanel({
    required this.appState,
    required this.league,
    required this.winRate,
    required this.correct,
    required this.wrong,
    required this.compact,
  });

  final AppState appState;
  final TrophyLeague league;
  final int winRate;
  final int correct;
  final int wrong;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LeagueSummary(
            league: league,
            trophies: appState.trophies,
            compact: compact,
          ),
          SizedBox(height: compact ? 8 : 10),
          _PerformanceStrip(
            winRate: winRate,
            correct: correct,
            wrong: wrong,
            compact: compact,
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            'جدول الكؤوس',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _TrophyRulesList(compact: compact),
          ),
        ],
      ),
    );
  }
}

class _LeagueSummary extends StatelessWidget {
  const _LeagueSummary({
    required this.league,
    required this.trophies,
    required this.compact,
  });

  final TrophyLeague league;
  final int trophies;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final nextIndex = TrophyProgression.leagues.indexOf(league) + 1;
    final hasNext = nextIndex < TrophyProgression.leagues.length;
    final next = hasNext ? TrophyProgression.leagues[nextIndex] : null;
    final nextText = next == null
        ? 'أعلى دوري'
        : '${league.trophiesLeft(trophies)} كأس للـ ${next.nameAr}';

    return Container(
      padding: EdgeInsets.all(compact ? 9 : 10),
      decoration: _panelDecoration(accent: league.color, subtle: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(league.icon, color: league.color, size: compact ? 18 : 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  league.nameAr,
                  style: TextStyle(
                    color: league.color,
                    fontSize: compact ? 14 : 16,
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
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: league.progress(trophies),
              minHeight: compact ? 5 : 6,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(league.color),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            nextText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PerformanceStrip extends StatelessWidget {
  const _PerformanceStrip({
    required this.winRate,
    required this.correct,
    required this.wrong,
    required this.compact,
  });

  final int winRate;
  final int correct;
  final int wrong;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TinyStat(
            icon: Icons.trending_up_rounded,
            color: const Color(0xFF4ADE80),
            label: 'فوز',
            value: '$winRate%',
            compact: compact,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _TinyStat(
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF34D399),
            label: 'صحيح',
            value: _compactNumber(correct),
            compact: compact,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _TinyStat(
            icon: Icons.cancel_rounded,
            color: const Color(0xFFF87171),
            label: 'خطأ',
            value: _compactNumber(wrong),
            compact: compact,
          ),
        ),
      ],
    );
  }
}

class _TinyStat extends StatelessWidget {
  const _TinyStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.compact,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: compact ? 14 : 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: compact ? 8 : 9,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TrophyRulesList extends StatelessWidget {
  const _TrophyRulesList({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rowHeight = compact ? 28.0 : 32.0;
    final gap = compact ? 3.0 : 4.0;
    const rules = TrophyProgression.rules;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullHeight = rules.length * rowHeight + (rules.length - 1) * gap;
        final needsScroll =
            constraints.hasBoundedHeight && constraints.maxHeight < fullHeight;

        if (!needsScroll) {
          return Column(
            children: [
              for (var i = 0; i < rules.length; i++) ...[
                SizedBox(
                  height: rowHeight,
                  child: _RuleRow(rule: rules[i], compact: compact),
                ),
                if (i != rules.length - 1) SizedBox(height: gap),
              ],
            ],
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: rules.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return SizedBox(
                height: rowHeight,
                child: _RuleRow(rule: rules[index], compact: compact),
              );
            },
            separatorBuilder: (_, __) => SizedBox(height: gap),
          ),
        );
      },
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.rule, required this.compact});

  final TrophyRule rule;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(rule.icon, color: rule.color, size: compact ? 13 : 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              rule.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            rule.value,
            style: TextStyle(
              color: rule.color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.title,
    required this.value,
    required this.progress,
    required this.color,
    required this.compact,
  });

  final String title;
  final String value;
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
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: compact ? 5 : 6,
            backgroundColor: Colors.white.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _AccountStrip extends StatelessWidget {
  const _AccountStrip({required this.uid, required this.compact});

  final String uid;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final shortId = uid.length > 18 ? '${uid.substring(0, 18)}...' : uid;

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
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: Color(0xFFEC4899), size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              shortId.isEmpty ? 'حساب محلي' : shortId,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: uid.isEmpty
                ? null
                : () => Clipboard.setData(ClipboardData(text: uid)),
            child: Icon(
              Icons.copy_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: uid.isEmpty ? 0.20 : 0.48),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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

class _EditUsernameDialog extends StatefulWidget {
  const _EditUsernameDialog({required this.initialName});

  final String initialName;

  @override
  State<_EditUsernameDialog> createState() => _EditUsernameDialogState();
}

class _EditUsernameDialogState extends State<_EditUsernameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: const Color(0xFF081328),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: Color(0xFFFACC15), size: 20),
            SizedBox(width: 8),
            Text(
              'تغيير الاسم',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: _controller,
          autofocus: true,
          maxLength: 20,
          onSubmitted: (_) => _submit(),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'اسم اللاعب الجديد',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFACC15),
              foregroundColor: const Color(0xFF111827),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _submit,
            child: const Text('حفظ',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _MetricItem {
  const _MetricItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
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
