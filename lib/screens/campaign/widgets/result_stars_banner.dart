import 'package:flutter/material.dart';

class ResultStarsBanner extends StatelessWidget {
  const ResultStarsBanner({
    super.key,
    required this.stars,
    required this.completed,
  });

  final int stars;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final safeStars = stars.clamp(0, 3);
    final accent = safeStars >= 3
        ? const Color(0xFFFACC15)
        : completed
            ? const Color(0xFF38BDF8)
            : const Color(0xFFF87171);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            accent.withValues(alpha: 0.28),
            const Color(0xFF0B173F).withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.58), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: accent, size: 28),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _starsText(safeStars),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$safeStars/3',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final filled = index < safeStars;
              return Transform.translate(
                offset: Offset(0, index == 1 ? -4 : 0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: index == 1 ? 54 : 48,
                        color: Colors.black.withValues(alpha: 0.28),
                      ),
                      Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        size: index == 1 ? 50 : 44,
                        color: filled
                            ? const Color(0xFFFACC15)
                            : Colors.white.withValues(alpha: 0.32),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _starsText(int safeStars) {
    if (!completed) return 'لم تكتمل المرحلة';
    switch (safeStars) {
      case 1:
        return 'حصلت على نجمة واحدة';
      case 2:
        return 'حصلت على نجمتين';
      case 3:
        return 'حصلت على 3 من 3';
      default:
        return 'أكملت المرحلة بدون نجوم';
    }
  }
}
