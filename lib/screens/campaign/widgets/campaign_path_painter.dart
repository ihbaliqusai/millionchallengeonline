import 'package:flutter/material.dart';

class CampaignPathPainter extends CustomPainter {
  const CampaignPathPainter({
    required this.points,
  });

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final deepShadowPaint = Paint()
      ..color = const Color(0xFF2E1B08).withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 44
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shadowPaint = Paint()
      ..color = const Color(0xFF7B471B).withValues(alpha: 0.46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 38
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rimPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6B3714), Color(0xFFB96D25), Color(0xFF7C421F)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pathPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF7C9), Color(0xFFFFD56D), Color(0xFFFFECA7)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = _buildSmoothPath(points);
    canvas.drawPath(path.shift(const Offset(0, 9)), deepShadowPaint);
    canvas.drawPath(path.shift(const Offset(0, 5)), shadowPaint);
    canvas.drawPath(path, rimPaint);
    canvas.drawPath(path, pathPaint);
    canvas.drawPath(path.shift(const Offset(-1, -3)), highlightPaint);

    final pebblePaint = Paint()..color = const Color(0xFFFFF4BF);
    final smallPebblePaint = Paint()..color = const Color(0xFFFFE9A8);
    final pebbleShadow = Paint()
      ..color = const Color(0xFFD49B45).withValues(alpha: 0.28);
    for (var i = 0; i < points.length - 1; i += 1) {
      final a = points[i];
      final b = points[i + 1];
      final mid = Offset.lerp(a, b, 0.48)!;
      final side = i.isEven ? -10.0 : 10.0;
      final pebbleRect = Rect.fromCenter(
        center: Offset(mid.dx + side, mid.dy + 7),
        width: 10,
        height: 6,
      );
      canvas.drawOval(pebbleRect.shift(const Offset(0, 1.2)), pebbleShadow);
      canvas.drawOval(
        pebbleRect,
        pebblePaint,
      );
      if (i % 3 == 0) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(mid.dx - side * 0.7, mid.dy - 14),
            width: 7,
            height: 4.5,
          ),
          smallPebblePaint,
        );
      }
    }
  }

  Path _buildSmoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i += 1) {
      final current = points[i];
      final next = points[i + 1];
      final controlY = (current.dy + next.dy) / 2;
      final bow = (next.dx - current.dx).abs().clamp(18.0, 82.0) * 0.22;
      path.cubicTo(
        current.dx + (i.isEven ? bow : -bow),
        controlY,
        next.dx - (i.isEven ? bow : -bow),
        controlY,
        next.dx,
        next.dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CampaignPathPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
