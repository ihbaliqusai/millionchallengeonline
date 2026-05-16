import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedResultStars extends StatefulWidget {
  const AnimatedResultStars({
    super.key,
    required this.stars,
  });

  final int stars;

  @override
  State<AnimatedResultStars> createState() => _AnimatedResultStarsState();
}

class _AnimatedResultStarsState extends State<AnimatedResultStars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedResultStars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stars != widget.stars) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final earned = widget.stars.clamp(0, 3);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          height: 132,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              for (var index = 0; index < 3; index += 1)
                Positioned(
                  left: _leftFor(index, MediaQuery.sizeOf(context).width),
                  top: index == 1 ? 0 : 24,
                  child: _AnimatedStar(
                    index: index,
                    earned: index < earned,
                    center: index == 1,
                    progress: _controller.value,
                    fullGlow: earned == 3,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  double _leftFor(int index, double width) {
    final starWidth = index == 1 ? 108.0 : 92.0;
    final center = width / 2;
    switch (index) {
      case 0:
        return center - 142;
      case 1:
        return center - starWidth / 2;
      default:
        return center + 50;
    }
  }
}

class _AnimatedStar extends StatelessWidget {
  const _AnimatedStar({
    required this.index,
    required this.earned,
    required this.center,
    required this.progress,
    required this.fullGlow,
  });

  final int index;
  final bool earned;
  final bool center;
  final double progress;
  final bool fullGlow;

  @override
  Widget build(BuildContext context) {
    final start = 0.12 + index * 0.20;
    final end = start + 0.34;
    final raw = ((progress - start) / (end - start)).clamp(0.0, 1.0);
    final pop = Curves.elasticOut.transform(raw);
    final sparkle = ((progress - start) / 0.56).clamp(0.0, 1.0);
    final size = center ? 108.0 : 92.0;
    final visibleScale = earned ? pop : 1.0;
    final dimOpacity = earned ? 1.0 : 0.62;

    return Transform.rotate(
      angle: center ? 0 : (index == 0 ? -0.16 : 0.16),
      child: Transform.scale(
        scale: earned ? visibleScale : 0.94,
        child: Opacity(
          opacity: earned ? raw.clamp(0.0, 1.0) : dimOpacity,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (earned)
                  Container(
                    width: size * 0.94,
                    height: size * 0.94,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFE569).withValues(
                            alpha: fullGlow ? 0.62 : 0.42,
                          ),
                          blurRadius: fullGlow ? 34 : 24,
                          spreadRadius: fullGlow ? 7 : 3,
                        ),
                      ],
                    ),
                  ),
                if (earned)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SparkleBurstPainter(
                        progress: sparkle,
                        seed: index,
                      ),
                    ),
                  ),
                CustomPaint(
                  size: Size.square(size),
                  painter: _GameStarPainter(filled: earned),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameStarPainter extends CustomPainter {
  const _GameStarPainter({required this.filled});

  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _starPath(size);
    canvas.drawPath(
      path.shift(Offset(0, size.height * 0.08)),
      Paint()..color = Colors.black.withValues(alpha: 0.30),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = filled ? const Color(0xFFFFF7C7) : const Color(0xFF24346D),
    );

    final inner = _starPath(Size(size.width * 0.82, size.height * 0.82)).shift(
      Offset(size.width * 0.09, size.height * 0.06),
    );
    canvas.drawPath(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: filled
              ? const [
                  Color(0xFFFFFFFF),
                  Color(0xFFFFF16A),
                  Color(0xFFFFC02F),
                  Color(0xFFFF7A1E),
                ]
              : const [
                  Color(0xFF52629A),
                  Color(0xFF28345F),
                  Color(0xFF141C3F),
                ],
          stops: filled ? const [0, 0.28, 0.72, 1] : null,
        ).createShader(Offset.zero & size),
    );

    if (filled) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.40, size.height * 0.30),
          width: size.width * 0.18,
          height: size.height * 0.08,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.62),
      );
    }
  }

  Path _starPath(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.width * 0.48;
    final inner = outer * 0.46;
    final path = Path();
    for (var i = 0; i < 10; i += 1) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _GameStarPainter oldDelegate) {
    return oldDelegate.filled != filled;
  }
}

class _SparkleBurstPainter extends CustomPainter {
  const _SparkleBurstPainter({
    required this.progress,
    required this.seed,
  });

  final double progress;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFFFFF0A8).withValues(alpha: opacity);
    for (var i = 0; i < 12; i += 1) {
      final angle = i * math.pi / 6 + seed * 0.18;
      final distance = size.width * (0.28 + progress * 0.42);
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(point, 2.2 + (i % 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleBurstPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.seed != seed;
  }
}
