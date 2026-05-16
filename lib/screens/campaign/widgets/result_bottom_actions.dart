import 'package:flutter/material.dart';

class ResultBottomActions extends StatefulWidget {
  const ResultBottomActions({
    super.key,
    required this.onMap,
    required this.onRetry,
    this.launching = false,
  });

  final VoidCallback onMap;
  final VoidCallback onRetry;
  final bool launching;

  @override
  State<ResultBottomActions> createState() => _ResultBottomActionsState();
}

class _ResultBottomActionsState extends State<ResultBottomActions>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..forward();
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
      builder: (context, child) {
        final value = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GameActionButton(
            icon: Icons.map_rounded,
            label: 'الخريطة',
            color: const Color(0xFF4366FF),
            onPressed: widget.onMap,
          ),
          const SizedBox(width: 16),
          _GameActionButton(
            icon: widget.launching
                ? Icons.hourglass_top_rounded
                : Icons.refresh_rounded,
            label: widget.launching ? 'جارٍ البدء' : 'إعادة',
            color: const Color(0xFF536178),
            onPressed: widget.launching ? null : widget.onRetry,
          ),
        ],
      ),
    );
  }
}

class _GameActionButton extends StatelessWidget {
  const _GameActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const size = 66.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.30),
                    onPressed == null ? const Color(0xFF647085) : color,
                    Color.lerp(
                      onPressed == null ? const Color(0xFF647085) : color,
                      Colors.black,
                      0.30,
                    )!,
                  ],
                  stops: const [0, 0.42, 1],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.76),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                  BoxShadow(
                    color: color.withValues(alpha: 0.34),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 31,
                shadows: const [
                  Shadow(
                    color: Color(0x99000000),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Color(0xAA000000),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
