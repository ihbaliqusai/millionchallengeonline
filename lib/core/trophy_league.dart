import 'package:flutter/material.dart';

class TrophyLeague {
  const TrophyLeague({
    required this.name,
    required this.nameAr,
    required this.color,
    required this.icon,
    required this.min,
    required this.max,
  });

  final String name;
  final String nameAr;
  final Color color;
  final IconData icon;
  final int min;
  final int? max;

  bool contains(int trophies) =>
      trophies >= min && (max == null || trophies <= max!);

  double progress(int trophies) {
    if (max == null) return 1.0;
    return ((trophies - min) / (max! - min + 1)).clamp(0.0, 1.0);
  }

  int trophiesLeft(int trophies) {
    if (max == null) return 0;
    return (max! + 1 - trophies).clamp(0, max! + 1);
  }

  String rangeLabel() => max == null ? '$min+' : '$min-${max!}';
}

class TrophyRule {
  const TrophyRule({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class TrophyProgression {
  static const List<TrophyLeague> leagues = [
    TrophyLeague(
      name: 'Rookie',
      nameAr: 'مبتدئ',
      color: Color(0xFF94A3B8),
      icon: Icons.star_outline_rounded,
      min: 0,
      max: 199,
    ),
    TrophyLeague(
      name: 'Bronze',
      nameAr: 'برونزي',
      color: Color(0xFFCD7F32),
      icon: Icons.shield_rounded,
      min: 200,
      max: 499,
    ),
    TrophyLeague(
      name: 'Silver',
      nameAr: 'فضي',
      color: Color(0xFFCBD5E1),
      icon: Icons.shield_moon_rounded,
      min: 500,
      max: 999,
    ),
    TrophyLeague(
      name: 'Gold',
      nameAr: 'ذهبي',
      color: Color(0xFFFACC15),
      icon: Icons.military_tech_rounded,
      min: 1000,
      max: 1799,
    ),
    TrophyLeague(
      name: 'Diamond',
      nameAr: 'ماسي',
      color: Color(0xFF38BDF8),
      icon: Icons.diamond_rounded,
      min: 1800,
      max: 2999,
    ),
    TrophyLeague(
      name: 'Master',
      nameAr: 'خبير',
      color: Color(0xFF8B5CF6),
      icon: Icons.workspace_premium_rounded,
      min: 3000,
      max: 4999,
    ),
    TrophyLeague(
      name: 'Legend',
      nameAr: 'أسطورة',
      color: Color(0xFFEF4444),
      icon: Icons.local_fire_department_rounded,
      min: 5000,
      max: null,
    ),
  ];

  static const List<TrophyRule> rules = [
    TrophyRule(
      label: 'إنهاء مباراة',
      value: '+4',
      icon: Icons.sports_esports_rounded,
      color: Color(0xFF38BDF8),
    ),
    TrophyRule(
      label: 'فوز',
      value: '+18',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFFACC15),
    ),
    TrophyRule(
      label: 'فوز أونلاين',
      value: '+12',
      icon: Icons.public_rounded,
      color: Color(0xFF22D3EE),
    ),
    TrophyRule(
      label: '10 إجابات صحيحة',
      value: '+1',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF34D399),
    ),
    TrophyRule(
      label: 'أفضل تتابع',
      value: '+4',
      icon: Icons.bolt_rounded,
      color: Color(0xFFF97316),
    ),
    TrophyRule(
      label: 'أفضل سلسلة فوز',
      value: '+10',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFFB020),
    ),
    TrophyRule(
      label: 'الخسارة',
      value: '-6',
      icon: Icons.flag_rounded,
      color: Color(0xFFFB7185),
    ),
    TrophyRule(
      label: '12 إجابة خاطئة',
      value: '-1',
      icon: Icons.cancel_rounded,
      color: Color(0xFFF87171),
    ),
  ];

  static TrophyLeague leagueFor(int trophies) =>
      leagues.lastWhere((league) => league.contains(trophies),
          orElse: () => leagues.first);

  static int computeTrophies(Map<String, int> stats) {
    final gamesPlayed = stats['gamesPlayed'] ?? 0;
    final wins = stats['wins'] ?? 0;
    final losses = stats['losses'] ?? 0;
    final onlineWins = stats['onlineWins'] ?? 0;
    final correctAnswers = stats['correctAnswers'] ?? 0;
    final wrongAnswers = stats['wrongAnswers'] ?? 0;
    final bestStreak = stats['bestStreak'] ?? 0;
    final bestWinStreak = stats['bestWinStreak'] ?? 0;
    final totalEarnings = stats['totalEarnings'] ?? 0;
    final totalAnswered = correctAnswers + wrongAnswers;

    final participation = gamesPlayed * 4;
    final winScore = wins * 18;
    final onlineScore = onlineWins * 12;
    final answerScore = correctAnswers ~/ 10;
    final streakScore = bestStreak * 4 + bestWinStreak * 10;
    final earningsScore = (totalEarnings ~/ 25000).clamp(0, 300);
    final winRateBonus = _winRateBonus(gamesPlayed, wins);
    final accuracyBonus = _accuracyBonus(totalAnswered, correctAnswers);
    final penalties = losses * 6 + wrongAnswers ~/ 12;

    final trophies = participation +
        winScore +
        onlineScore +
        answerScore +
        streakScore +
        earningsScore +
        winRateBonus +
        accuracyBonus -
        penalties;

    return trophies.clamp(0, 999999);
  }

  static int _winRateBonus(int gamesPlayed, int wins) {
    if (gamesPlayed < 10) return 0;
    final rate = wins / gamesPlayed;
    if (rate >= 0.75) return 180;
    if (rate >= 0.60) return 100;
    if (rate >= 0.45) return 45;
    return 0;
  }

  static int _accuracyBonus(int totalAnswered, int correctAnswers) {
    if (totalAnswered < 40) return 0;
    final accuracy = correctAnswers / totalAnswered;
    if (accuracy >= 0.85) return 140;
    if (accuracy >= 0.75) return 80;
    if (accuracy >= 0.65) return 35;
    return 0;
  }

  static const String trophyBasisLabelAr =
      'الفوز، الاستمرار، الدقة، والأداء الأونلاين';
}
