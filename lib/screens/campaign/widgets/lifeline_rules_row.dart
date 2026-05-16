import 'package:flutter/material.dart';

class LifelineRulesRow extends StatelessWidget {
  const LifelineRulesRow({
    super.key,
    required this.allow5050,
    required this.allowAudience,
    required this.allowCall,
  });

  final bool allow5050;
  final bool allowAudience;
  final bool allowCall;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 7,
      runSpacing: 7,
      children: [
        _LifelineChip(
          icon: Icons.filter_2_rounded,
          label: '50:50',
          allowed: allow5050,
        ),
        _LifelineChip(
          icon: Icons.groups_rounded,
          label: 'الجمهور',
          allowed: allowAudience,
        ),
        _LifelineChip(
          icon: Icons.call_rounded,
          label: 'الاتصال',
          allowed: allowCall,
        ),
      ],
    );
  }
}

class _LifelineChip extends StatelessWidget {
  const _LifelineChip({
    required this.icon,
    required this.label,
    required this.allowed,
  });

  final IconData icon;
  final String label;
  final bool allowed;

  @override
  Widget build(BuildContext context) {
    final color = allowed ? const Color(0xFF54F088) : const Color(0xFF7B849A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: allowed ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: color.withValues(alpha: allowed ? 0.40 : 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color:
                  allowed ? Colors.white : Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 5),
          Icon(
            allowed ? Icons.check_circle_rounded : Icons.lock_rounded,
            color: color,
            size: 14,
          ),
        ],
      ),
    );
  }
}
