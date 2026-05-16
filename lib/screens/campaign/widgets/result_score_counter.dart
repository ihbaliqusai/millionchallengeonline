import 'package:flutter/material.dart';

class ResultScoreCounter extends StatelessWidget {
  const ResultScoreCounter({
    super.key,
    required this.score,
  });

  final int score;

  @override
  Widget build(BuildContext context) {
    final safeScore = score.clamp(0, 999999999);
    return Column(
      children: [
        const Text(
          'النقاط',
          style: TextStyle(
            color: Color(0xFFBDEBFF),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: safeScore.toDouble()),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.round().toString(),
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: Color(0xFFFFE77A),
                  fontSize: 58,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: Color(0x99000000),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                    Shadow(
                      color: Color(0xAAFF8A00),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
