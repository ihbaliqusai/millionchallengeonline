import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';

enum _AchStatus { done, progress, locked }

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1640),
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            const _SummaryBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: const [
                  _AchievementCard(
                    icon: Icons.emoji_events_rounded,
                    color: Color(0xFFFACC15),
                    title: 'أول انتصار',
                    desc: 'فز بأول مباراة',
                    status: _AchStatus.done,
                  ),
                  SizedBox(height: 8),
                  _AchievementCard(
                    icon: Icons.bolt_rounded,
                    color: Color(0xFFF97316),
                    title: 'سريع البرق',
                    desc: 'أجب في أقل من 3 ثوانٍ',
                    status: _AchStatus.done,
                  ),
                  SizedBox(height: 8),
                  _AchievementCard(
                    icon: Icons.people_rounded,
                    color: Color(0xFF38BDF8),
                    title: 'لاعب اجتماعي',
                    desc: 'العب مع 50 خصماً مختلفاً',
                    status: _AchStatus.progress,
                    current: 12,
                    total: 50,
                  ),
                  SizedBox(height: 8),
                  _AchievementCard(
                    icon: Icons.local_fire_department_rounded,
                    color: Color(0xFFEF4444),
                    title: 'على نار',
                    desc: 'فز 5 مباريات متتالية',
                    status: _AchStatus.progress,
                    current: 3,
                    total: 5,
                  ),
                  SizedBox(height: 8),
                  _AchievementCard(
                    icon: Icons.school_rounded,
                    color: Color(0xFF4ADE80),
                    title: 'عالم المعرفة',
                    desc: 'أجب على 1000 سؤال صحيح',
                    status: _AchStatus.progress,
                    current: 847,
                    total: 1000,
                  ),
                  SizedBox(height: 8),
                  _AchievementCard(
                    icon: Icons.diamond_rounded,
                    color: Color(0xFF38BDF8),
                    title: 'جامع الجواهر',
                    desc: 'اجمع 500 جوهرة',
                    status: _AchStatus.progress,
                    current: 0,
                    total: 500,
                  ),
                  SizedBox(height: 8),
                  _AchievementCard(
                    icon: Icons.military_tech_rounded,
                    color: Color(0xFFA78BFA),
                    title: 'المحارب المتمرس',
                    desc: 'العب 500 مباراة',
                    status: _AchStatus.progress,
                    current: 142,
                    total: 500,
                  ),
                  SizedBox(height: 8),
                  _AchievementCard(
                    icon: Icons.star_rounded,
                    color: Color(0xFFFACC15),
                    title: 'نجم المنافسة',
                    desc: 'احتل المركز الأول 3 مرات',
                    status: _AchStatus.locked,
                  ),
                  SizedBox(height: 8),
                  _AchievementCard(
                    icon: Icons.workspace_premium_rounded,
                    color: Color(0xFFE879F9),
                    title: 'البطل المطلق',
                    desc: 'فز بـ100 مباراة متتالية',
                    status: _AchStatus.locked,
                  ),
                  SizedBox(height: 8),
                  _AchievementCard(
                    icon: Icons.auto_awesome_rounded,
                    color: Color(0xFFFBBF24),
                    title: 'الأسطورة',
                    desc: 'أكمل جميع الإنجازات الأخرى',
                    status: _AchStatus.locked,
                  ),
                  SizedBox(height: 16),
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
            'Achievements',
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
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary bar ─────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          _SummaryChip(
            icon: Icons.emoji_events_rounded,
            label: '12 مفتوح',
            color: Color(0xFFFACC15),
          ),
          SizedBox(width: 8),
          _SummaryChip(
            icon: Icons.timer_rounded,
            label: '8 قيد التقدم',
            color: Color(0xFF38BDF8),
          ),
          SizedBox(width: 8),
          _SummaryChip(
            icon: Icons.lock_rounded,
            label: '5 مغلق',
            color: Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Achievement card ─────────────────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.status,
    this.current,
    this.total,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final _AchStatus status;
  final int? current;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final isLocked = status == _AchStatus.locked;
    final isDone = status == _AchStatus.done;
    final isProgress = status == _AchStatus.progress;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF152055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon container
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.white.withValues(alpha: 0.05)
                      : color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isLocked ? const Color(0xFF4B5563) : color,
                  size: 24,
                ),
              ),
              if (isLocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1640).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Middle content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isLocked
                        ? Colors.white.withValues(alpha: 0.35)
                        : Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: isLocked ? 0.25 : 0.55),
                  ),
                ),
                if (isProgress && current != null && total != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: total! > 0 ? current! / total! : 0.0,
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFACC15)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$current/$total',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Status badge
          if (isDone)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFACC15).withValues(alpha: 0.5)),
              ),
              child: const Center(
                child: Text(
                  '✓',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFACC15),
                  ),
                ),
              ),
            )
          else if (isLocked)
            Icon(
              Icons.lock_rounded,
              color: Colors.white.withValues(alpha: 0.25),
              size: 20,
            ),
        ],
      ),
    );
  }
}
