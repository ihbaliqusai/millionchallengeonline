import 'package:flutter/material.dart';

class StarRatingView extends StatelessWidget {
  const StarRatingView({
    super.key,
    required this.stars,
    this.size = 18,
  });

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    final safeStars = stars.clamp(0, 3);
    return SizedBox(
      width: size * 3.05,
      height: size * 1.18,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(3, (index) {
          final filled = index < safeStars;
          final scale = index == 1 ? 1.12 : 1.0;
          final top = index == 1 ? 0.0 : size * 0.12;
          return Positioned(
            left: index * size * 0.9,
            top: top,
            child: Transform.rotate(
              angle: index == 0 ? -0.18 : (index == 2 ? 0.18 : 0),
              child: SizedBox(
                width: size * scale,
                height: size * scale,
                child: CustomPaint(
                  painter: _PremiumStarPainter(filled: filled),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PremiumStarPainter extends CustomPainter {
  const _PremiumStarPainter({required this.filled});

  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _starPath(size);
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path.shift(Offset(0, size.height * 0.09)), shadow);

    final outline = Paint()
      ..color = filled ? const Color(0xFFFFF8D0) : const Color(0xFF6B3D42)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, outline);

    final insetPath = _starPath(Size(size.width * 0.78, size.height * 0.78))
        .shift(Offset(size.width * 0.11, size.height * 0.08));
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: filled
            ? const [Color(0xFFFFF07A), Color(0xFFFFC72F), Color(0xFFFF8F1F)]
            : const [Color(0xFF8A5A5F), Color(0xFF58343B), Color(0xFF33242B)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(insetPath, fill);

    if (filled) {
      canvas.drawCircle(
        Offset(size.width * 0.35, size.height * 0.26),
        size.width * 0.08,
        Paint()..color = Colors.white.withValues(alpha: 0.55),
      );
    }
  }

  Path _starPath(Size size) {
    const points = 5;
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.width * 0.48;
    final inner = outer * 0.47;
    final path = Path();
    for (var i = 0; i < points * 2; i += 1) {
      final radius = i.isEven ? outer : inner;
      final angle = -1.5708 + i * 3.14159 / points;
      final point = Offset(
        center.dx + radius * _cos(angle),
        center.dy + radius * _sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  double _sin(double x) => Offset.fromDirection(x).dy;

  double _cos(double x) => Offset.fromDirection(x).dx;

  @override
  bool shouldRepaint(covariant _PremiumStarPainter oldDelegate) {
    return oldDelegate.filled != filled;
  }
}
