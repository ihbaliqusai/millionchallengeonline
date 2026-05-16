import 'package:flutter/material.dart';

import '../../../models/campaign_stage.dart';

class StageRulesCard extends StatelessWidget {
  const StageRulesCard({
    super.key,
    required this.rules,
  });

  final StageStarRules rules;

  @override
  Widget build(BuildContext context) {
    return _IntroCard(
      title: 'شروط النجوم',
      icon: Icons.star_rounded,
      color: const Color(0xFFFACC15),
      child: Column(
        children: [
          _RuleLine(
            label: 'نجمة واحدة',
            value: _correctAnswerText(
              rules.oneStarMinCorrectAnswers,
              fallbackScore: rules.oneStarMinScore,
            ),
          ),
          _RuleLine(
            label: 'نجمتان',
            value: _correctAnswerText(
              rules.twoStarsMinCorrectAnswers,
              fallbackScore: rules.twoStarsMinScore,
            ),
          ),
          _RuleLine(label: 'ثلاث نجوم', value: _threeStarText()),
        ],
      ),
    );
  }

  String _correctAnswerText(int correctAnswers, {required int fallbackScore}) {
    if (correctAnswers > 0) {
      return '$correctAnswers إجابات صحيحة من 10';
    }
    return 'حسب أداء المرحلة';
  }

  String _threeStarText() {
    final parts = <String>[
      _correctAnswerText(rules.threeStarsMinCorrectAnswers, fallbackScore: 0),
    ];
    if (rules.threeStarsMaxTimeMs != null) {
      parts.add('أنهيها قبل ${_formatTime(rules.threeStarsMaxTimeMs!)}');
    }
    if (rules.threeStarsMaxLifelinesUsed != null) {
      parts.add(
        rules.threeStarsMaxLifelinesUsed == 0
            ? 'بدون استخدام مساعدات'
            : 'مساعدات ${rules.threeStarsMaxLifelinesUsed} أو أقل',
      );
    }
    return parts.join(' - ');
  }

  String _formatTime(int milliseconds) {
    final totalSeconds = (milliseconds / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B173F).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
