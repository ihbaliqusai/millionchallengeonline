import 'dart:ui';

import 'package:flutter/material.dart';

class GameShell extends StatelessWidget {
  const GameShell({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.action,
    this.padding,
    this.showMascot = true,
    this.showWatermark = true,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsets? padding;
  final bool showMascot;
  final bool showWatermark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ui/bg_main.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        const Color(0xFF0A1B4A).withOpacity(0.72),
                        const Color(0xFF060C24).withOpacity(0.88),
                      ],
                    ),
                  ),
                ),
              ),
              if (showWatermark)
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.18,
                      child: Center(
                        child: Image.asset(
                          'assets/ui/logo.png',
                          width: 180,
                        ),
                      ),
                    ),
                  ),
                ),
              if (showMascot)
                Positioned(
                  right: 14,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.14,
                      child: Image.asset(
                        'assets/ui/person_welcome.png',
                        height: 250,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: padding ?? const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (title != null || action != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                if (title != null)
                                  Text(
                                    title!,
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                if (subtitle != null) ...<Widget>[
                                  const SizedBox(height: 5),
                                  Text(
                                    subtitle!,
                                    style: const TextStyle(
                                      color: Color(0xFFE5E7EB),
                                      fontSize: 14,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (action != null) ...<Widget>[
                            const SizedBox(width: 12),
                            action!,
                          ],
                        ],
                      ),
                    if (title != null || action != null) const SizedBox(height: 16),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 26,
    this.tint,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                (tint ?? const Color(0xFF0B173F)).withOpacity(0.86),
                const Color(0xFF5B21B6).withOpacity(0.68),
              ],
            ),
            border: Border.all(color: const Color(0xFF7DD3FC).withOpacity(0.92), width: 1.8),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.compact = false,
    this.gold = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool compact;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return _AnimatedNeonButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      compact: compact,
      gold: gold,
    );
  }
}

class _AnimatedNeonButton extends StatefulWidget {
  const _AnimatedNeonButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.compact,
    required this.gold,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool compact;
  final bool gold;

  @override
  State<_AnimatedNeonButton> createState() => _AnimatedNeonButtonState();
}

class _AnimatedNeonButtonState extends State<_AnimatedNeonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final colors = widget.gold
        ? const <Color>[Color(0xFFF8D34C), Color(0xFFF59E0B)]
        : const <Color>[Color(0xFF2D3FFF), Color(0xFF14B8FF)];
    final border = widget.gold ? const Color(0xFFFFF2B3) : const Color(0xFFA5F3FC);
    final foreground = widget.gold ? const Color(0xFF1F2937) : Colors.white;
    final radius = BorderRadius.circular(widget.compact ? 18 : 24);

    return AnimatedScale(
      scale: _pressed && enabled ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      child: SizedBox(
        height: widget.compact ? 56 : 68,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled ? 1 : 0.45,
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  colors: _pressed && enabled
                      ? colors.map((color) => Color.lerp(color, Colors.black, 0.12)!).toList()
                      : colors,
                ),
                border: Border.all(color: border, width: 2),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: (widget.gold ? const Color(0xFFF59E0B) : const Color(0xFF2563EB)).withOpacity(0.28),
                    blurRadius: _pressed ? 10 : 20,
                    offset: Offset(0, _pressed ? 4 : 10),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: radius,
                onTap: widget.onPressed,
                onHighlightChanged: enabled ? (value) => setState(() => _pressed = value) : null,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.compact ? 18 : 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: widget.compact ? 34 : 40,
                        height: widget.compact ? 34 : 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(widget.gold ? 0.34 : 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, color: foreground, size: widget.compact ? 18 : 22),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: foreground,
                            fontSize: widget.compact ? 17 : 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HudChip extends StatelessWidget {
  const HudChip({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor = const Color(0xFFFACC15),
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 8 : 10),
      decoration: BoxDecoration(
        color: const Color(0xFF08112F).withOpacity(0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: compact ? 16 : 18, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class SideMenuButton extends StatelessWidget {
  const SideMenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: 88,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: highlight ? const Color(0xFFFACC15).withOpacity(0.24) : const Color(0xFF091332).withOpacity(0.90),
            border: Border.all(color: highlight ? const Color(0xFFFCD34D) : Colors.white.withOpacity(0.12), width: 1.6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: highlight ? const Color(0xFFFCD34D) : const Color(0xFF7DD3FC), size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgressStrip extends StatelessWidget {
  const ProgressStrip({
    super.key,
    required this.value,
    required this.label,
  });

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 12,
            value: safeValue,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFACC15)),
          ),
        ),
      ],
    );
  }
}
