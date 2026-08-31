import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cross_promo_millionaire_dialog.dart';

class CrossPromoMillionaireBadge extends StatefulWidget {
  const CrossPromoMillionaireBadge({
    super.key,
    this.onLaunch,
  });

  final Future<void> Function()? onLaunch;

  @override
  State<CrossPromoMillionaireBadge> createState() =>
      _CrossPromoMillionaireBadgeState();
}

class _CrossPromoMillionaireBadgeState extends State<CrossPromoMillionaireBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final glow = 0.35 + _pulseCtrl.value * 0.45;
        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            CrossPromoMillionaireDialog.show(
              context,
              onLaunch: widget.onLaunch,
            );
          },
          child: Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2A1B4E),
                  Color(0xFF14092B),
                ],
              ),
              border: Border.all(
                color: Color.lerp(
                  const Color(0xFFF59E0B),
                  const Color(0xFFFACC15),
                  _pulseCtrl.value,
                )!,
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: glow),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      ),
                    ),
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFFACC15),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'تحدي المليون',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'العب 🏆',
                    style: TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF34D399),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
