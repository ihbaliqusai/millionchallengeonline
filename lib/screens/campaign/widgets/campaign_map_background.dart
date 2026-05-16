import 'package:flutter/material.dart';

class CampaignMapBackground extends StatelessWidget {
  const CampaignMapBackground({
    super.key,
    required this.height,
    required this.stageCount,
  });

  final double height;
  final int stageCount;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _CampaignMapBackgroundPainter(stageCount: stageCount),
    );
  }
}

class _CampaignMapBackgroundPainter extends CustomPainter {
  const _CampaignMapBackgroundPainter({required this.stageCount});

  final int stageCount;

  @override
  void paint(Canvas canvas, Size size) {
    final grass = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFBDFB6D),
          Color(0xFF61D936),
          Color(0xFF18A934),
          Color(0xFF087633),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, grass);

    _drawSoftLight(canvas, size);
    _drawSkyWater(canvas, size);
    _drawWater(canvas, size, top: false);
    _drawHillBands(canvas, size);
    _drawDepthRidges(canvas, size);
    _drawLandPatches(canvas, size);
    _drawDecorations(canvas, size);
    _drawVignette(canvas, size);
  }

  void _drawSoftLight(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.55),
        radius: 1.1,
        colors: [
          Colors.white.withValues(alpha: 0.24),
          const Color(0xFFD8FF78).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawSkyWater(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, -24)
      ..cubicTo(
          size.width * 0.25, 20, size.width * 0.56, -14, size.width * 0.84, 14)
      ..quadraticBezierTo(size.width * 0.94, 23, size.width, 12)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF9BF2FF).withValues(alpha: 0.82),
            const Color(0xFF16B7F0).withValues(alpha: 0.58),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  void _drawWater(Canvas canvas, Size size, {required bool top}) {
    final y = top ? -18.0 : size.height - 72;
    final waterPath = Path()
      ..moveTo(0, y + (top ? 0 : 24))
      ..quadraticBezierTo(size.width * 0.25, y + 48, size.width * 0.52, y + 22)
      ..quadraticBezierTo(size.width * 0.78, y - 4, size.width, y + 26)
      ..lineTo(size.width, top ? 0 : size.height)
      ..lineTo(0, top ? 0 : size.height)
      ..close();

    canvas.drawPath(
      waterPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF78E7FF), Color(0xFF18B7EF), Color(0xFF0679C5)],
        ).createShader(Offset.zero & size),
    );
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 9; i += 1) {
      final dx = (i * 58.0) % size.width;
      final dy = y + 18 + (i % 3) * 16;
      canvas.drawArc(
        Rect.fromLTWH(dx, dy, 42, 18),
        0.15,
        2.7,
        false,
        shine,
      );
    }

    final bank = Path()
      ..moveTo(0, y + 55)
      ..quadraticBezierTo(size.width * 0.3, y + 87, size.width * 0.62, y + 55)
      ..quadraticBezierTo(size.width * 0.85, y + 35, size.width, y + 62);
    canvas.drawPath(
      bank,
      Paint()
        ..color = const Color(0xFF7C421F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18,
    );
    canvas.drawPath(
      bank,
      Paint()
        ..color = const Color(0xFFE9B15E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
  }

  void _drawHillBands(Canvas canvas, Size size) {
    final lightPaint = Paint()..color = Colors.white.withValues(alpha: 0.075);
    final darkPaint = Paint()
      ..color = const Color(0xFF087A1D).withValues(alpha: 0.12);
    for (var i = 0; i < 18; i += 1) {
      final path = Path()
        ..moveTo(size.width * -0.1, size.height - 112.0 * i)
        ..lineTo(size.width * 1.1, size.height - 218.0 - 112.0 * i)
        ..lineTo(size.width * 1.1, size.height - 178.0 - 112.0 * i)
        ..lineTo(size.width * -0.1, size.height + 45.0 - 112.0 * i)
        ..close();
      canvas.drawPath(path, i.isEven ? lightPaint : darkPaint);
    }
  }

  void _drawDepthRidges(Canvas canvas, Size size) {
    final dark = Paint()
      ..color = const Color(0xFF075F23).withValues(alpha: 0.10);
    final glow = Paint()
      ..color = const Color(0xFFD6FF70).withValues(alpha: 0.13);
    for (var i = 0; i < stageCount + 5; i += 1) {
      final y = size.height - 84 - i * 90.0;
      final path = Path()
        ..moveTo(-40, y)
        ..cubicTo(size.width * 0.22, y - 24, size.width * 0.56, y + 24,
            size.width + 40, y - 11)
        ..lineTo(size.width + 40, y + 23)
        ..cubicTo(
            size.width * 0.58, y + 52, size.width * 0.24, y + 5, -40, y + 36)
        ..close();
      canvas.drawPath(path, i.isEven ? dark : glow);
    }
  }

  void _drawLandPatches(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = const Color(0xFF0A6E24).withValues(alpha: 0.16);
    final light = Paint()
      ..color = const Color(0xFFA8EE42).withValues(alpha: 0.34);
    for (var i = 0; i < stageCount + 6; i += 1) {
      final y = size.height - 118 - i * 82.0;
      if (y < 80 || y > size.height - 100) continue;
      final x = i.isEven ? size.width * 0.22 : size.width * 0.78;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 76, height: 24),
        i.isEven ? shadow : light,
      );
    }
  }

  void _drawDecorations(Canvas canvas, Size size) {
    for (var i = 0; i < stageCount + 9; i += 1) {
      final y = size.height - 86 - i * 76.0;
      if (y < 78 || y > size.height - 85) {
        continue;
      }
      final leftSide = i.isEven;
      final x =
          leftSide ? 18.0 + (i % 3) * 10 : size.width - 30.0 - (i % 4) * 9;
      if (i % 5 == 0) {
        _drawFence(canvas, Offset(x, y + 20), leftSide);
      } else if (i % 4 == 0) {
        _drawRock(canvas, Offset(x, y + 8));
      } else if (i % 3 == 0) {
        _drawTree(canvas, Offset(x, y), large: i % 6 == 0);
      } else {
        _drawBush(canvas, Offset(x, y + 12));
      }

      if (i % 2 == 0) {
        _drawGrassTuft(
            canvas, Offset(size.width * 0.5 + (i % 5 - 2) * 26, y + 34));
      }
      if (i % 3 == 1) {
        _drawFlowers(
            canvas, Offset(size.width * (leftSide ? 0.72 : 0.28), y + 30));
      }
    }
  }

  void _drawTree(Canvas canvas, Offset center, {required bool large}) {
    final trunk = Paint()..color = const Color(0xFF9A5B22);
    final leaf = Paint()..color = const Color(0xFF28B84A);
    final leafDark = Paint()..color = const Color(0xFF15923B);
    final r = large ? 31.0 : 24.0;
    canvas.drawOval(
      Rect.fromCenter(
          center: center + Offset(0, r * 1.12),
          width: r * 2.3,
          height: r * 0.58),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: center + Offset(0, r * 0.72), width: 16, height: 42),
        const Radius.circular(8),
      ),
      trunk,
    );
    canvas.drawCircle(center, r, leafDark);
    canvas.drawCircle(center + Offset(-r * 0.45, 4), r * 0.82, leaf);
    canvas.drawCircle(center + Offset(r * 0.42, 3), r * 0.9, leaf);
    canvas.drawCircle(center + Offset(0, -r * 0.42), r * 0.86, leaf);
    canvas.drawCircle(center + Offset(-r * 0.25, -r * 0.42), 5,
        Paint()..color = Colors.white.withValues(alpha: 0.35));
  }

  void _drawBush(Canvas canvas, Offset center) {
    final paint = Paint()..color = const Color(0xFF57C927);
    final dark = Paint()..color = const Color(0xFF289915);
    canvas.drawOval(
        Rect.fromCenter(center: center, width: 58, height: 28), dark);
    for (var i = 0; i < 4; i += 1) {
      canvas.drawCircle(
          center + Offset(-22 + i * 14, -4 - (i % 2) * 4), 13, paint);
    }
  }

  void _drawFlowers(Canvas canvas, Offset center) {
    final colors = [
      const Color(0xFFFFE66D),
      const Color(0xFFFF7AAD),
      const Color(0xFFFFFFFF),
    ];
    for (var i = 0; i < 4; i += 1) {
      final c = center + Offset((i - 1.5) * 13, (i.isEven ? 0 : 7));
      final paint = Paint()..color = colors[i % colors.length];
      for (var p = 0; p < 5; p += 1) {
        final petal = c + Offset.fromDirection(p * 1.256, 4);
        canvas.drawCircle(petal, 3.2, paint);
      }
      canvas.drawCircle(c, 2.3, Paint()..color = const Color(0xFFFFB800));
    }
  }

  void _drawRock(Canvas canvas, Offset center) {
    final rock = Paint()..color = const Color(0xFF7B8794);
    final light = Paint()..color = const Color(0xFFA8B0BC);
    final path = Path()
      ..moveTo(center.dx - 25, center.dy + 14)
      ..lineTo(center.dx - 12, center.dy - 12)
      ..lineTo(center.dx + 14, center.dy - 18)
      ..lineTo(center.dx + 28, center.dy + 9)
      ..quadraticBezierTo(
          center.dx + 6, center.dy + 22, center.dx - 25, center.dy + 14)
      ..close();
    canvas.drawPath(path, rock);
    canvas.drawOval(
        Rect.fromCenter(
            center: center + const Offset(-2, -6), width: 20, height: 7),
        light);
  }

  void _drawFence(Canvas canvas, Offset center, bool leanRight) {
    final paint = Paint()
      ..color = const Color(0xFFC97332)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i += 1) {
      final x = center.dx + i * 18 * (leanRight ? 1 : -1);
      canvas.drawLine(
          Offset(x, center.dy - 16), Offset(x, center.dy + 18), paint);
    }
    canvas.drawLine(center + const Offset(-8, -2),
        center + Offset(48 * (leanRight ? 1 : -1), 4), paint);
  }

  void _drawGrassTuft(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = const Color(0xFF098F43)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = -2; i <= 2; i += 1) {
      canvas.drawLine(
          center, center + Offset(i * 5.0, -14 + i.abs() * 2), paint);
    }
  }

  void _drawVignette(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        radius: 0.95,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.08),
          Colors.black.withValues(alpha: 0.16),
        ],
        stops: const [0.58, 0.86, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _CampaignMapBackgroundPainter oldDelegate) {
    return oldDelegate.stageCount != stageCount;
  }
}
