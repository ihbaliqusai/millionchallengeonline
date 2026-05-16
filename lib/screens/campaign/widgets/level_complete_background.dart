import 'dart:math' as math;

import 'package:flutter/material.dart';

class LevelCompleteBackground extends StatefulWidget {
  const LevelCompleteBackground({super.key});

  @override
  State<LevelCompleteBackground> createState() =>
      _LevelCompleteBackgroundState();
}

class _LevelCompleteBackgroundState extends State<LevelCompleteBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _LevelCompleteBackgroundPainter(_controller.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _LevelCompleteBackgroundPainter extends CustomPainter {
  const _LevelCompleteBackgroundPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A7CE8),
            Color(0xFF0756C8),
            Color(0xFF082D86),
            Color(0xFF061545),
          ],
          stops: [0, 0.38, 0.76, 1],
        ).createShader(rect),
    );

    _drawRadialLight(canvas, size);
    _drawSoftCircles(canvas, size);
    _drawSparkles(canvas, size);
    _drawBottomGlow(canvas, size);
  }

  void _drawRadialLight(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.64),
        radius: 0.78,
        colors: [
          Colors.white.withValues(alpha: 0.34),
          const Color(0xFF54D9FF).withValues(alpha: 0.14),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawSoftCircles(Canvas canvas, Size size) {
    const specs = <_CircleSpec>[
      _CircleSpec(0.16, 0.20, 58, 0.08),
      _CircleSpec(0.86, 0.18, 44, 0.10),
      _CircleSpec(0.12, 0.70, 68, 0.06),
      _CircleSpec(0.82, 0.78, 84, 0.06),
      _CircleSpec(0.52, 0.42, 126, 0.045),
    ];
    for (final spec in specs) {
      canvas.drawCircle(
        Offset(size.width * spec.x, size.height * spec.y),
        spec.radius,
        Paint()..color = Colors.white.withValues(alpha: spec.alpha),
      );
    }
  }

  void _drawSparkles(Canvas canvas, Size size) {
    final sparklePaint = Paint()..color = Colors.white.withValues(alpha: 0.52);
    final goldPaint = Paint()
      ..color = const Color(0xFFFFE07A).withValues(alpha: 0.58);
    for (var i = 0; i < 38; i += 1) {
      final phase = (progress + i * 0.037) % 1;
      final x = size.width * ((i * 37 % 100) / 100);
      final y = size.height * ((i * 53 % 100) / 100);
      final radius = 1.2 + math.sin(phase * math.pi) * 2.4;
      final paint = i % 4 == 0 ? goldPaint : sparklePaint;
      if (i % 3 == 0) {
        _drawStar(
          canvas,
          Offset(x, y),
          radius * 2.2,
          paint..color = paint.color.withValues(alpha: 0.25 + phase * 0.32),
        );
      } else {
        canvas.drawCircle(
          Offset(x, y),
          radius,
          paint..color = paint.color.withValues(alpha: 0.18 + phase * 0.28),
        );
      }
    }
  }

  void _drawBottomGlow(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 1.0),
        radius: 0.72,
        colors: [
          const Color(0xFF140C5E).withValues(alpha: 0.56),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i += 1) {
      final r = i.isEven ? radius : radius * 0.42;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p =
          Offset(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path..close(), paint);
  }

  @override
  bool shouldRepaint(covariant _LevelCompleteBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CircleSpec {
  const _CircleSpec(this.x, this.y, this.radius, this.alpha);

  final double x;
  final double y;
  final double radius;
  final double alpha;
}
