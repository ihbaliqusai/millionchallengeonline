import 'package:flutter/material.dart';

class CampaignHeader extends StatelessWidget {
  const CampaignHeader({
    super.key,
    required this.totalStars,
    required this.completedStages,
    required this.totalStages,
    required this.milestone,
  });

  final int totalStars;
  final int completedStages;
  final int totalStages;
  final String milestone;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 112),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.white.withValues(alpha: 0.92),
            const Color(0xFFFFE38E).withValues(alpha: 0.94),
            const Color(0xFFFFB84A).withValues(alpha: 0.96),
          ],
        ),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.92), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFFFE58B).withValues(alpha: 0.24),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF65FF87), Color(0xFF16A33F)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 9,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'رحلة المليون',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4A2D0A),
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'اجمع النجوم وافتح الطريق',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF74450D),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _HeaderPill(
                icon: Icons.star_rounded,
                color: const Color(0xFFFFD43B),
                label: '$totalStars نجمة',
              ),
              _HeaderPill(
                icon: Icons.flag_rounded,
                color: const Color(0xFF44E273),
                label: '$completedStages/$totalStages مكتملة',
              ),
              _HeaderPill(
                icon: Icons.shield_rounded,
                color: const Color(0xFF67D7FF),
                label: milestone,
                wide: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.icon,
    required this.color,
    required this.label,
    this.wide = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: wide ? const BoxConstraints(maxWidth: 176) : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF5A350C).withValues(alpha: 0.78),
            const Color(0xFF2F1E0C).withValues(alpha: 0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
