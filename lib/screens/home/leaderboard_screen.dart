import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/player_rank.dart';
import '../../core/trophy_league.dart';

class _LeaderboardPlayer {
  const _LeaderboardPlayer({
    required this.uid,
    required this.username,
    required this.trophies,
    required this.level,
    required this.photoUrl,
  });

  final String uid;
  final String username;
  final int trophies;
  final int level;
  final String photoUrl;

  factory _LeaderboardPlayer.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return _LeaderboardPlayer(
      uid: doc.id,
      username: _resolveUsername(data),
      trophies: (data['trophies'] as num?)?.toInt() ?? 0,
      level: (data['level'] as num?)?.toInt() ?? 1,
      photoUrl: (data['photoUrl'] ?? '').toString(),
    );
  }

  factory _LeaderboardPlayer.local(AppState appState) {
    final user = appState.user;
    final name = user?.displayName?.trim();
    final emailName = user?.email?.split('@').first.trim();
    return _LeaderboardPlayer(
      uid: user?.uid ?? '',
      username: (name != null && name.isNotEmpty)
          ? name
          : (emailName != null && emailName.isNotEmpty)
              ? emailName
              : 'لاعب',
      trophies: appState.trophies,
      level: appState.level,
      photoUrl: user?.photoURL ?? '',
    );
  }

  static String _resolveUsername(Map<String, dynamic> data) {
    final candidates = <String?>[
      data['username']?.toString(),
      data['playerName']?.toString(),
      data['displayName']?.toString(),
      data['name']?.toString(),
      data['email']?.toString().split('@').first,
    ];

    for (final candidate in candidates) {
      final normalized = candidate?.trim() ?? '';
      if (normalized.isEmpty) continue;
      final lowered = normalized.toLowerCase();
      if (lowered == 'guest' || lowered == 'player') continue;
      return normalized;
    }
    return 'لاعب';
  }
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _loading = true;
  List<_LeaderboardPlayer> _players = <_LeaderboardPlayer>[];
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _load();
  }

  Future<void> _load() async {
    final appState = context.read<AppState>();
    _currentUid = appState.user?.uid;

    try {
      await appState.checkAndAwardXpForGames();
      final snap = await FirebaseFirestore.instance
          .collection('public_profiles')
          .orderBy('trophies', descending: true)
          .limit(200)
          .get();

      final list = snap.docs
          .map(_LeaderboardPlayer.fromDoc)
          .where((player) => player.uid.trim().isNotEmpty)
          .toList();

      list.sort((a, b) {
        final trophyCompare = b.trophies.compareTo(a.trophies);
        if (trophyCompare != 0) return trophyCompare;
        final levelCompare = b.level.compareTo(a.level);
        if (levelCompare != 0) return levelCompare;
        return a.username.compareTo(b.username);
      });

      if (!mounted) return;
      setState(() {
        _players = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final myIndex = _players.indexWhere((player) => player.uid == _currentUid);
    final myRank = myIndex == -1 ? null : myIndex + 1;
    final myPlayer =
        myIndex == -1 ? _LeaderboardPlayer.local(appState) : _players[myIndex];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF071126),
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Image.asset('assets/ui/bg_main.png', fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      const Color(0xFF040914).withValues(alpha: 0.58),
                      const Color(0xFF071126).withValues(alpha: 0.94),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  _Header(
                    total: _players.length,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _loading
                          ? const _LoadingState()
                          : _LeaderboardDashboard(
                              players: _players,
                              currentUid: _currentUid,
                              myRank: myRank,
                              myPlayer: myPlayer,
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

class _LeaderboardDashboard extends StatelessWidget {
  const _LeaderboardDashboard({
    required this.players,
    required this.currentUid,
    required this.myRank,
    required this.myPlayer,
  });

  final List<_LeaderboardPlayer> players;
  final String? currentUid;
  final int? myRank;
  final _LeaderboardPlayer myPlayer;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return const _EmptyState();
    }

    final topPlayers = players.take(3).toList(growable: false);
    final leader = players.first;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 760 ? 12.0 : 16.0;
        final wide = constraints.maxWidth >= 900;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                2,
                horizontalPadding,
                14,
              ),
              sliver: SliverToBoxAdapter(
                child: wide
                    ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(
                              flex: 6,
                              child: _OverviewPanel(
                                leader: leader,
                                myPlayer: myPlayer,
                                myRank: myRank,
                                total: players.length,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 6,
                              child: _PodiumPanel(
                                players: topPlayers,
                                currentUid: currentUid,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: <Widget>[
                          _OverviewPanel(
                            leader: leader,
                            myPlayer: myPlayer,
                            myRank: myRank,
                            total: players.length,
                          ),
                          const SizedBox(height: 10),
                          _PodiumPanel(
                            players: topPlayers,
                            currentUid: currentUid,
                          ),
                        ],
                      ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                10,
              ),
              sliver: const SliverToBoxAdapter(
                child: _SectionHeader(
                  icon: Icons.format_list_numbered_rtl_rounded,
                  title: 'ترتيب اللاعبين',
                  subtitle: 'الترتيب حسب الكؤوس، ثم المستوى عند التعادل',
                  color: Color(0xFFFACC15),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                22,
              ),
              sliver: SliverList.separated(
                itemCount: players.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final player = players[index];
                  return _RankRow(
                    player: player,
                    rank: index + 1,
                    total: players.length,
                    isMe: player.uid == currentUid,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.total,
    required this.onBack,
  });

  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'لوحة الصدارة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  total == 0
                      ? 'أفضل اللاعبين حسب الكؤوس'
                      : 'أفضل ${_compactNumber(total)} لاعب حسب الكؤوس',
                  style: const TextStyle(
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

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.leader,
    required this.myPlayer,
    required this.myRank,
    required this.total,
  });

  final _LeaderboardPlayer leader;
  final _LeaderboardPlayer myPlayer;
  final int? myRank;
  final int total;

  @override
  Widget build(BuildContext context) {
    final league = TrophyProgression.leagueFor(myPlayer.trophies);
    final rankTier = PlayerRank.tierForLevel(myPlayer.level);
    final topPercent = myRank == null || total == 0
        ? null
        : ((myRank! / total) * 100).ceil().clamp(1, 100);

    return Container(
      decoration: _panelDecoration(accent: const Color(0xFFFACC15)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC15).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFACC15).withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.leaderboard_rounded,
                  color: Color(0xFFFACC15),
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'سباق الكؤوس',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'المتصدر: ${leader.username}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricCard(
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFFFACC15),
                  value: _compactNumber(leader.trophies),
                  label: 'كؤوس المتصدر',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: Icons.place_rounded,
                  color: const Color(0xFF38BDF8),
                  value: myRank == null ? '--' : '#$myRank',
                  label: 'ترتيبك',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: Icons.groups_rounded,
                  color: const Color(0xFF34D399),
                  value: _compactNumber(total),
                  label: 'لاعب',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _InfoPill(
                icon: league.icon,
                color: league.color,
                label: 'الدوري',
                value: league.nameAr,
              ),
              _InfoPill(
                icon: rankTier.icon,
                color: rankTier.color,
                label: 'المستوى',
                value: '${rankTier.nameAr} ${myPlayer.level}',
              ),
              _InfoPill(
                icon: Icons.percent_rounded,
                color: const Color(0xFFA78BFA),
                label: 'النطاق',
                value:
                    topPercent == null ? 'خارج أعلى 200' : 'أفضل $topPercent%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumPanel extends StatelessWidget {
  const _PodiumPanel({
    required this.players,
    required this.currentUid,
  });

  final List<_LeaderboardPlayer> players;
  final String? currentUid;

  @override
  Widget build(BuildContext context) {
    final first = players.isNotEmpty ? players[0] : null;
    final second = players.length > 1 ? players[1] : null;
    final third = players.length > 2 ? players[2] : null;

    return Container(
      decoration: _panelDecoration(accent: const Color(0xFF38BDF8)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionHeader(
            icon: Icons.workspace_premium_rounded,
            title: 'منصة الأوائل',
            subtitle: 'أقوى ثلاثة لاعبين حاليا',
            color: Color(0xFF38BDF8),
            compact: true,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: _PodiumSlot(
                  player: second,
                  rank: 2,
                  height: 92,
                  currentUid: currentUid,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PodiumSlot(
                  player: first,
                  rank: 1,
                  height: 122,
                  currentUid: currentUid,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PodiumSlot(
                  player: third,
                  rank: 3,
                  height: 78,
                  currentUid: currentUid,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.player,
    required this.rank,
    required this.height,
    required this.currentUid,
  });

  final _LeaderboardPlayer? player;
  final int rank;
  final double height;
  final String? currentUid;

  @override
  Widget build(BuildContext context) {
    final color = _rankColor(rank);
    final isMe = player?.uid == currentUid;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        _Avatar(
          photoUrl: player?.photoUrl ?? '',
          name: player?.username ?? '',
          size: rank == 1 ? 56 : 48,
          borderColor: isMe ? const Color(0xFFFACC15) : color,
        ),
        const SizedBox(height: 8),
        Text(
          player?.username ?? 'لاعب',
          style: TextStyle(
            color: isMe ? const Color(0xFFFACC15) : Colors.white,
            fontSize: rank == 1 ? 13 : 11,
            fontWeight: FontWeight.w900,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFACC15),
              size: 13,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                player == null ? '0' : _compactNumber(player!.trophies),
                style: const TextStyle(
                  color: Color(0xFFFACC15),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.17),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.36)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                color: color,
                fontSize: rank == 1 ? 28 : 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.player,
    required this.rank,
    required this.total,
    required this.isMe,
  });

  final _LeaderboardPlayer player;
  final int rank;
  final int total;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColor(rank);
    final league = TrophyProgression.leagueFor(player.trophies);
    final tier = PlayerRank.tierForLevel(player.level);
    final topPercent =
        total > 0 ? ((rank / total) * 100).ceil().clamp(1, 100) : 100;

    return Container(
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFFF59E0B).withValues(alpha: 0.18)
            : const Color(0xFF081328).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMe
              ? const Color(0xFFFACC15).withValues(alpha: 0.72)
              : rankColor.withValues(alpha: rank <= 3 ? 0.44 : 0.18),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: <Widget>[
          _RankBadge(rank: rank, color: rankColor),
          const SizedBox(width: 12),
          _Avatar(
            photoUrl: player.photoUrl,
            name: player.username,
            size: 44,
            borderColor: isMe ? const Color(0xFFFACC15) : rankColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        player.username,
                        style: TextStyle(
                          color: isMe ? const Color(0xFFFACC15) : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe)
                      const _MiniLabel(
                        text: 'أنت',
                        color: Color(0xFFFACC15),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: <Widget>[
                    _MiniStat(
                      icon: league.icon,
                      color: league.color,
                      text: league.nameAr,
                    ),
                    _MiniStat(
                      icon: tier.icon,
                      color: tier.color,
                      text: 'مستوى ${player.level}',
                    ),
                    _MiniStat(
                      icon: Icons.percent_rounded,
                      color: const Color(0xFFA78BFA),
                      text: 'أفضل $topPercent%',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFFACC15),
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                _compactNumber(player.trophies),
                style: const TextStyle(
                  color: Color(0xFFFACC15),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: compact ? 36 : 40,
          height: compact ? 36 : 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Icon(icon, color: color, size: compact ? 20 : 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 15 : 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.52),
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (!compact)
          Container(
            height: 2,
            width: 76,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.27)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.54),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({
    required this.rank,
    required this.color,
  });

  final int rank;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: TextStyle(
            color: color,
            fontSize: rank < 100 ? 16 : 13,
            fontWeight: FontWeight.w900,
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.photoUrl,
    required this.name,
    required this.size,
    required this.borderColor,
  });

  final String photoUrl;
  final String name;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? '؟' : name.trim().characters.first;
    final hasPhoto = photoUrl.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        color: borderColor.withValues(alpha: 0.16),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _AvatarFallback(initials: initials),
            )
          : _AvatarFallback(initials: initials),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFFFACC15)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(18),
        decoration: _panelDecoration(accent: const Color(0xFFFACC15)),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.leaderboard_rounded,
              color: Color(0xFFFACC15),
              size: 42,
            ),
            SizedBox(height: 10),
            Text(
              'لا يوجد لاعبون بعد',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'سيظهر الترتيب بعد تسجيل أول نتائج في الحسابات العامة.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration({required Color accent}) {
  return BoxDecoration(
    color: const Color(0xFF081328).withValues(alpha: 0.84),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: accent.withValues(alpha: 0.27)),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.20),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

Color _rankColor(int rank) {
  if (rank == 1) return const Color(0xFFFACC15);
  if (rank == 2) return const Color(0xFFCBD5E1);
  if (rank == 3) return const Color(0xFFCD7F32);
  return const Color(0xFF38BDF8);
}

String _compactNumber(int value) {
  final sign = value < 0 ? '-' : '';
  final abs = value.abs();
  if (abs >= 1000000) {
    final number = abs / 1000000;
    return '$sign${number.toStringAsFixed(number >= 10 ? 0 : 1)}M';
  }
  if (abs >= 1000) {
    final number = abs / 1000;
    return '$sign${number.toStringAsFixed(number >= 10 ? 0 : 1)}K';
  }
  return value.toString();
}
