import 'package:flutter/material.dart';

import '../../../services/campaign_service.dart';

class ResultRewardPanel extends StatelessWidget {
  const ResultRewardPanel({
    super.key,
    required this.result,
    required this.currencyRewardApplied,
  });

  final StageSubmissionResult result;
  final bool currencyRewardApplied;

  @override
  Widget build(BuildContext context) {
    final hasReward = result.rewardGranted ||
        result.rewardCoinsGranted > 0 ||
        result.rewardGemsGranted > 0 ||
        result.rewardXpGranted > 0;
    final status = currencyRewardApplied
        ? 'تمت إضافة المكافأة'
        : hasReward
            ? 'المكافأة محفوظة وسيتم إعادة المحاولة'
            : 'لا توجد مكافأة جديدة';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF071742).withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.card_giftcard_rounded,
                color: Color(0xFFFFD66B),
                size: 20,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'مكافأة المرحلة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: hasReward
                        ? const Color(0xFFFFD66B)
                        : Colors.white.withValues(alpha: 0.62),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (hasReward) ...[
            const SizedBox(height: 9),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 7,
              children: [
                _RewardChip(
                  icon: Icons.monetization_on_rounded,
                  value: '${result.rewardCoinsGranted}',
                  label: 'عملة',
                  color: const Color(0xFFFFD66B),
                ),
                _RewardChip(
                  icon: Icons.diamond_rounded,
                  value: '${result.rewardGemsGranted}',
                  label: 'جوهرة',
                  color: const Color(0xFF6FE7FF),
                ),
                _RewardChip(
                  icon: Icons.bolt_rounded,
                  value: '${result.rewardXpGranted}',
                  label: 'خبرة',
                  color: const Color(0xFF54F088),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 5),
          Text(
            '$value $label',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
