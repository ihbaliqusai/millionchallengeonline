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

class TrophyProgression {
  static const List<TrophyLeague> leagues = [
    TrophyLeague(
      name: 'Rookie',
      nameAr: 'روكي',
      color: Color(0xFF94A3B8),
      icon: Icons.star_outline_rounded,
      min: 0,
      max: 149,
    ),
    TrophyLeague(
      name: 'Bronze',
      nameAr: 'برونز',
      color: Color(0xFFCD7F32),
      icon: Icons.shield_rounded,
      min: 150,
      max: 399,
    ),
    TrophyLeague(
      name: 'Silver',
      nameAr: 'فضة',
      color: Color(0xFFCBD5E1),
      icon: Icons.shield_moon_rounded,
      min: 400,
      max: 799,
    ),
    TrophyLeague(
      name: 'Gold',
      nameAr: 'ذهب',
      color: Color(0xFFFACC15),
      icon: Icons.military_tech_rounded,
      min: 800,
      max: 1399,
    ),
    TrophyLeague(
      name: 'Diamond',
      nameAr: 'دايموند',
      color: Color(0xFF38BDF8),
      icon: Icons.diamond_rounded,
      min: 1400,
      max: 2299,
    ),
    TrophyLeague(
      name: 'Master',
      nameAr: 'ماستر',
      color: Color(0xFF8B5CF6),
      icon: Icons.workspace_premium_rounded,
      min: 2300,
      max: 3499,
    ),
    TrophyLeague(
      name: 'Legend',
      nameAr: 'أسطورة',
      color: Color(0xFFEF4444),
      icon: Icons.local_fire_department_rounded,
      min: 3500,
      max: null,
    ),
  ];

  static TrophyLeague leagueFor(int trophies) =>
      leagues.lastWhere((league) => league.contains(trophies),
          orElse: () => leagues.first);

  static int computeTrophies(Map<String, int> stats) {
    final gamesPlayed = stats['gamesPlayed'] ?? 0;
    final wins = stats['wins'] ?? 0;
    final onlineWins = stats['onlineWins'] ?? 0;
    final correctAnswers = stats['correctAnswers'] ?? 0;
    final bestStreak = stats['bestStreak'] ?? 0;
    final bestWinStreak = stats['bestWinStreak'] ?? 0;
    final totalEarnings = stats['totalEarnings'] ?? 0;

    final trophies = gamesPlayed * 8 +
        wins * 16 +
        onlineWins * 8 +
        (correctAnswers ~/ 20) +
        bestStreak * 2 +
        bestWinStreak * 5 +
        (totalEarnings ~/ 20000).clamp(0, 120);

    return trophies.clamp(0, 999999);
  }

  static const String trophyBasisLabelAr =
      'الإنهاء، الفوز، الأداء، والنتائج الأونلاين';
}
