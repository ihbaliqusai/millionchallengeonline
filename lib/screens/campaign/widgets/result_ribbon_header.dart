import 'package:flutter/material.dart';

class ResultRibbonHeader extends StatelessWidget {
  const ResultRibbonHeader({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 146,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          const Positioned(
            top: 46,
            left: 12,
            right: 12,
            child: CustomPaint(
              painter: _RibbonPainter(),
              child: SizedBox(height: 62),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Path()
      ..moveTo(24, 12)
      ..lineTo(size.width - 24, 12)
      ..lineTo(size.width - 6, size.height * 0.52)
      ..lineTo(size.width - 24, size.height - 6)
      ..lineTo(24, size.height - 6)
      ..lineTo(6, size.height * 0.52)
      ..close();
    canvas.drawPath(
      shadow.shift(const Offset(0, 6)),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );

    final leftFold = Path()
      ..moveTo(0, size.height * 0.22)
      ..lineTo(32, size.height * 0.08)
      ..lineTo(42, size.height * 0.84)
      ..lineTo(8, size.height)
      ..lineTo(17, size.height * 0.60)
      ..close();
    final rightFold = Path()
      ..moveTo(size.width, size.height * 0.22)
      ..lineTo(size.width - 32, size.height * 0.08)
      ..lineTo(size.width - 42, size.height * 0.84)
      ..lineTo(size.width - 8, size.height)
      ..lineTo(size.width - 17, size.height * 0.60)
      ..close();
    final foldPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC22132), Color(0xFF7E1020)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(leftFold, foldPaint);
    canvas.drawPath(rightFold, foldPaint);

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(26, 0, size.width - 52, size.height * 0.86),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF6071), Color(0xFFE01F36), Color(0xFFA40F27)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      body.deflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.22),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(48, 8, size.width - 96, 10),
        const Radius.circular(99),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.24),
    );
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter oldDelegate) => false;
}
