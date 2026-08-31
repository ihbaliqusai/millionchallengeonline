import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cross_promo_challengeland_dialog.dart';

class CrossPromoChallengeLandBadge extends StatefulWidget {
  const CrossPromoChallengeLandBadge({
    super.key,
    this.compact = false,
    this.showSubtitle = true,
  });

  final bool compact;
  final bool showSubtitle;

  @override
  State<CrossPromoChallengeLandBadge> createState() =>
      _CrossPromoChallengeLandBadgeState();
}

class _CrossPromoChallengeLandBadgeState
    extends State<CrossPromoChallengeLandBadge>
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
            CrossPromoChallengeLandDialog.show(context);
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
                  Color(0xFF0F2B5C),
                  Color(0xFF07142E),
                ],
              ),
              border: Border.all(
                color: Color.lerp(
                  const Color(0xFF38BDF8),
                  const Color(0xFFFACC15),
                  _pulseCtrl.value,
                )!,
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: glow),
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
                        color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                      ),
                    ),
                    const Icon(
                      Icons.sports_kabaddi_rounded,
                      color: Color(0xFF38BDF8),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'أرض التحدي',
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
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'العب ⚔️',
                    style: TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFACC15),
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
