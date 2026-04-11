import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';

// Reward for each of the 30 days: {coins, gems}
const _kDayRewards = [
  {'coins': 100,  'gems': 0},   // Day 1
  {'coins': 150,  'gems': 0},   // Day 2
  {'coins': 200,  'gems': 1},   // Day 3
  {'coins': 250,  'gems': 0},   // Day 4
  {'coins': 300,  'gems': 1},   // Day 5
  {'coins': 400,  'gems': 2},   // Day 6
  {'coins': 500,  'gems': 3},   // Day 7  ← week bonus
  {'coins': 300,  'gems': 1},   // Day 8
  {'coins': 350,  'gems': 1},   // Day 9
  {'coins': 400,  'gems': 2},   // Day 10
  {'coins': 450,  'gems': 2},   // Day 11
  {'coins': 500,  'gems': 3},   // Day 12
  {'coins': 600,  'gems': 3},   // Day 13
  {'coins': 800,  'gems': 5},   // Day 14 ← 2-week bonus
  {'coins': 400,  'gems': 2},   // Day 15
  {'coins': 450,  'gems': 2},   // Day 16
  {'coins': 500,  'gems': 3},   // Day 17
  {'coins': 550,  'gems': 3},   // Day 18
  {'coins': 600,  'gems': 4},   // Day 19
  {'coins': 700,  'gems': 4},   // Day 20
  {'coins': 1000, 'gems': 7},   // Day 21 ← 3-week bonus
  {'coins': 600,  'gems': 3},   // Day 22
  {'coins': 650,  'gems': 4},   // Day 23
  {'coins': 700,  'gems': 4},   // Day 24
  {'coins': 750,  'gems': 5},   // Day 25
  {'coins': 800,  'gems': 5},   // Day 26
  {'coins': 900,  'gems': 6},   // Day 27
  {'coins': 1000, 'gems': 7},   // Day 28
  {'coins': 1200, 'gems': 8},   // Day 29
  {'coins': 2000, 'gems': 15},  // Day 30 ← grand bonus
];

class DailyStreakScreen extends StatefulWidget {
  const DailyStreakScreen({super.key});

  @override
  State<DailyStreakScreen> createState() => _DailyStreakScreenState();
}

class _DailyStreakScreenState extends State<DailyStreakScreen> {
  bool _loading = true;
  int _streakDay = 1;       // 1–30
  bool _claimedToday = false;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final uid = context.read<AppState>().user?.uid;
    if (uid == null) { setState(() => _loading = false); return; }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data() ?? {};

      final lastClaimTs = data['lastStreakClaimDate'] as Timestamp?;
      final savedDay = (data['streakDay'] as num?)?.toInt() ?? 1;

      if (lastClaimTs == null) {
        // First time ever
        setState(() { _streakDay = 1; _claimedToday = false; _loading = false; });
        return;
      }

      final lastClaim = lastClaimTs.toDate();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastDay = DateTime(lastClaim.year, lastClaim.month, lastClaim.day);
      final diff = today.difference(lastDay).inDays;

      if (diff == 0) {
        // Already claimed today
        setState(() { _streakDay = savedDay; _claimedToday = true; _loading = false; });
      } else if (diff == 1) {
        // Consecutive day — advance to next (unclaimed)
        final nextDay = savedDay >= 30 ? 1 : savedDay + 1;
        setState(() { _streakDay = nextDay; _claimedToday = false; _loading = false; });
      } else {
        // Missed — reset
        setState(() { _streakDay = 1; _claimedToday = false; _loading = false; });
        await FirebaseFirestore.instance.collection('users').doc(uid).set(
          {'streakDay': 1},
          SetOptions(merge: true),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _claimReward() async {
    if (_claimedToday || _claiming) return;
    setState(() => _claiming = true);

    final uid = context.read<AppState>().user?.uid;
    if (uid == null) { setState(() => _claiming = false); return; }

    final reward = _kDayRewards[_streakDay - 1];
    final now = DateTime.now();

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'streakDay': _streakDay,
          'lastStreakClaimDate': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );

      if (mounted) {
        setState(() { _claimedToday = true; _claiming = false; });
        _showRewardDialog(reward['coins']!, reward['gems']!);
      }
    } catch (_) {
      if (mounted) setState(() => _claiming = false);
    }
  }

  void _showRewardDialog(int coins, int gems) {
    showDialog<void>(
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
                  Text('+$coins', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
            if (gems > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.diamond_rounded, color: Color(0xFF38BDF8), size: 28),
                  const SizedBox(width: 8),
                  Text('+$gems', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('رائع!', style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1640),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
            : Column(
                children: [
                  _buildHeader(),
                  _buildStreakInfo(),
                  const SizedBox(height: 8),
                  Expanded(child: _buildDaysGrid()),
                  _buildClaimButton(),
                  const SizedBox(height: 12),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
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
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'المكافآت اليومية',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF152055)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFACC15).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFACC15).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFACC15)),
            ),
            child: Center(
              child: Text(
                '$_streakDay',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFFACC15)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _claimedToday ? 'تم الاستلام اليوم ✓' : 'اليوم $_streakDay من 30',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  _claimedToday
                      ? 'عد غداً للمكافأة التالية'
                      : 'افتح الصندوق لاستلام مكافأتك!',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316), size: 28),
              Text(
                '$_streakDay يوم',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFF97316)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaysGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.75,
      ),
      itemCount: 30,
      itemBuilder: (_, i) {
        final day = i + 1;
        final reward = _kDayRewards[i];
        final isPast = day < _streakDay;
        final isCurrent = day == _streakDay;
        final isFuture = day > _streakDay;
        final isWeekBonus = day == 7 || day == 14 || day == 21 || day == 30;

        Color borderColor;
        Color bgColor;
        if (isCurrent && _claimedToday) {
          borderColor = const Color(0xFF22C55E);
          bgColor = const Color(0xFF22C55E).withValues(alpha: 0.2);
        } else if (isCurrent) {
          borderColor = const Color(0xFFFACC15);
          bgColor = const Color(0xFFFACC15).withValues(alpha: 0.15);
        } else if (isPast) {
          borderColor = const Color(0xFF22C55E).withValues(alpha: 0.5);
          bgColor = const Color(0xFF22C55E).withValues(alpha: 0.1);
        } else {
          borderColor = Colors.white.withValues(alpha: 0.12);
          bgColor = Colors.white.withValues(alpha: 0.04);
        }

        if (isWeekBonus && !isPast) {
          borderColor = const Color(0xFFA855F7);
          bgColor = const Color(0xFFA855F7).withValues(alpha: isCurrent ? 0.2 : 0.08);
        }

        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'يوم',
                style: TextStyle(fontSize: 8, color: Colors.white.withValues(alpha: 0.5)),
              ),
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isCurrent
                      ? const Color(0xFFFACC15)
                      : isPast
                          ? const Color(0xFF22C55E)
                          : Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              if (isPast)
                const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 14)
              else if (isFuture && isCurrent == false)
                Icon(Icons.lock_rounded, color: Colors.white.withValues(alpha: 0.3), size: 12)
              else ...[
                if ((reward['gems'] ?? 0) > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.diamond_rounded, size: 9, color: isCurrent ? const Color(0xFF38BDF8) : Colors.white38),
                      Text(
                        '${reward['gems']}',
                        style: TextStyle(fontSize: 8, color: isCurrent ? const Color(0xFF38BDF8) : Colors.white38),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monetization_on_rounded, size: 9, color: isCurrent ? const Color(0xFFFACC15) : Colors.white38),
                      Text(
                        '${reward['coins']}',
                        style: TextStyle(fontSize: 7, color: isCurrent ? const Color(0xFFFACC15) : Colors.white38),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildClaimButton() {
    if (_claimedToday) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 20),
            SizedBox(width: 8),
            Text('تم الاستلام — عد غداً!',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white70)),
          ],
        ),
      );
    }

    final reward = _kDayRewards[_streakDay - 1];
    return GestureDetector(
      onTap: _claiming ? null : _claimReward,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEAB308)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: _claiming
            ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_rounded, color: Color(0xFF1F2937), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'افتح الصندوق  •  ${reward['coins']} 🪙${(reward['gems'] ?? 0) > 0 ? '  +${reward['gems']} 💎' : ''}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
                  ),
                ],
              ),
      ),
    );
  }
}
