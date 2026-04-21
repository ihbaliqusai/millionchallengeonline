import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _players = [];
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
          .collection('users')
          .orderBy('trophies', descending: true)
          .limit(200)
          .get();

      final list = snap.docs.map((d) {
        final data = d.data();
        return <String, dynamic>{
          'uid': d.id,
          'username': data['username'] ?? data['playerName'] ?? 'Player',
          'trophies': (data['trophies'] as num?)?.toInt() ?? 0,
          'level': (data['level'] as num?)?.toInt() ?? 1,
          'photoUrl': data['photoUrl'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _players = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPlayers = _players.take(6).toList();
    final myIndex = _players.indexWhere((p) => p['uid'] == _currentUid);
    final myRank = myIndex == -1 ? null : myIndex + 1;
    final total = _players.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1640),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(total),
            if (_loading)
              const Expanded(
                  child: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFFACC15))))
            else
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildRankedList(myRank, total)),
                    SizedBox(
                        width: 178,
                        child: _buildBestPlayers(topPlayers, myRank)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Global Leaderboard',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.people_rounded, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text(
                total > 1000000
                    ? '${(total / 1000000).toStringAsFixed(2)}M'
                    : '$total',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankedList(int? myRank, int total) {
    if (_players.isEmpty) {
      return const Center(
        child: Text('لا يوجد لاعبون بعد',
            style: TextStyle(color: Colors.white54, fontSize: 14)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: _players.length,
      itemBuilder: (ctx, i) {
        final p = _players[i];
        final rank = i + 1;
        final isMe = p['uid'] == _currentUid;
        final topPercent = total > 0 ? (rank / total * 100).round() : 100;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isMe
                ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                : const Color(0xFF152055).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isMe
                  ? const Color(0xFFF59E0B)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Top\n$topPercent%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C3AED),
                  border: Border.all(
                    color: isMe ? const Color(0xFFFACC15) : Colors.white24,
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.person_rounded,
                    size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p['username'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isMe ? const Color(0xFFFACC15) : Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      size: 13, color: Color(0xFFFACC15)),
                  const SizedBox(width: 2),
                  Text(
                    '${p['trophies']}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFACC15)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBestPlayers(List<Map<String, dynamic>> topPlayers, int? myRank) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 6),
          child: Text(
            'BEST PLAYERS',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFACC15),
                letterSpacing: 1),
          ),
        ),
        ...topPlayers.asMap().entries.map((e) {
          final rank = e.key + 1;
          final p = e.value;
          final Color rankColor = rank == 1
              ? const Color(0xFFEAB308)
              : rank == 2
                  ? const Color(0xFF94A3B8)
                  : rank == 3
                      ? const Color(0xFFB45309)
                      : const Color(0xFF1E3A8A);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: rank <= 3 ? 0.3 : 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: rankColor.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration:
                      BoxDecoration(color: rankColor, shape: BoxShape.circle),
                  child: Center(
                    child: Text('#$rank',
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    p['username'] as String,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        size: 11, color: Color(0xFFFACC15)),
                    Text('${p['trophies']}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFACC15))),
                  ],
                ),
              ],
            ),
          );
        }),
        if (myRank != null && myRank > 6 && myRank - 1 < _players.length) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(color: Colors.white24, height: 1),
          ),
          const Text('أنت',
              style: TextStyle(color: Colors.white54, fontSize: 10)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B), shape: BoxShape.circle),
                  child: Center(
                    child: Text('#$myRank',
                        style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _players[myRank - 1]['username'] as String,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFACC15)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        size: 11, color: Color(0xFFFACC15)),
                    Text('${_players[myRank - 1]['trophies']}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFACC15))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
