import 'package:flutter/material.dart';

class PlayerRankTier {
  const PlayerRankTier({
    required this.name,
    required this.nameAr,
    required this.color,
    required this.icon,
    required this.minLevel,
    required this.maxLevel,
  });

  final String name;
  final String nameAr;
  final Color color;
  final IconData icon;
  final int minLevel;
  final int? maxLevel;

  bool contains(int level) =>
      level >= minLevel && (maxLevel == null || level <= maxLevel!);

  double progress(int level) {
    if (maxLevel == null) return 1.0;
    return ((level - minLevel + 1) / (maxLevel! - minLevel + 1))
        .clamp(0.0, 1.0);
  }
}

class PlayerRank {
  static const List<PlayerRankTier> tiers = [
    PlayerRankTier(
      name: 'Rookie',
      nameAr: 'مبتدئ',
      color: Color(0xFF38BDF8),
      icon: Icons.star_outline_rounded,
      minLevel: 1,
      maxLevel: 4,
    ),
    PlayerRankTier(
      name: 'Bronze',
      nameAr: 'برونزي',
      color: Color(0xFFB45309),
      icon: Icons.shield_rounded,
      minLevel: 5,
      maxLevel: 9,
    ),
    PlayerRankTier(
      name: 'Silver',
      nameAr: 'فضي',
      color: Color(0xFF94A3B8),
      icon: Icons.shield_moon_rounded,
      minLevel: 10,
      maxLevel: 19,
    ),
    PlayerRankTier(
      name: 'Gold',
      nameAr: 'ذهبي',
      color: Color(0xFFFACC15),
      icon: Icons.military_tech_rounded,
      minLevel: 20,
      maxLevel: 29,
    ),
    PlayerRankTier(
      name: 'Diamond',
      nameAr: 'ماسي',
      color: Color(0xFF38BDF8),
      icon: Icons.diamond_rounded,
      minLevel: 30,
      maxLevel: 44,
    ),
    PlayerRankTier(
      name: 'Master',
      nameAr: 'خبير',
      color: Color(0xFF8B5CF6),
      icon: Icons.workspace_premium_rounded,
      minLevel: 45,
      maxLevel: 59,
    ),
    PlayerRankTier(
      name: 'Legend',
      nameAr: 'أسطورة',
      color: Color(0xFFEF4444),
      icon: Icons.local_fire_department_rounded,
      minLevel: 60,
      maxLevel: null,
    ),
  ];

  static PlayerRankTier tierForLevel(int level) => tiers
      .lastWhere((tier) => tier.contains(level), orElse: () => tiers.first);

  static PlayerRankTier? nextTierForLevel(int level) {
    final current = tierForLevel(level);
    final index = tiers.indexOf(current);
    if (index < 0 || index + 1 >= tiers.length) return null;
    return tiers[index + 1];
  }

  static String titleForLevel(int level) => tierForLevel(level).nameAr;

  static Color colorForLevel(int level) => tierForLevel(level).color;

  static IconData iconForLevel(int level) => tierForLevel(level).icon;

  static int xpNeededForLevel(int level) {
    final safeLevel = level.clamp(1, 999999);
    if (safeLevel < 5) return 120 + (safeLevel - 1) * 40;
    if (safeLevel < 10) return 320 + (safeLevel - 5) * 55;
    if (safeLevel < 20) return 620 + (safeLevel - 10) * 80;
    if (safeLevel < 30) return 1450 + (safeLevel - 20) * 130;
    if (safeLevel < 45) return 2850 + (safeLevel - 30) * 210;
    if (safeLevel < 60) return 6000 + (safeLevel - 45) * 360;
    return 11500 + (safeLevel - 60) * 550;
  }

  static int levelForXp(int totalXp) {
    var remaining = totalXp.clamp(0, 2147483647);
    var level = 1;
    while (remaining >= xpNeededForLevel(level)) {
      remaining -= xpNeededForLevel(level);
      level++;
    }
    return level;
  }

  static int xpIntoLevel(int totalXp) {
    var remaining = totalXp.clamp(0, 2147483647);
    var level = 1;
    while (remaining >= xpNeededForLevel(level)) {
      remaining -= xpNeededForLevel(level);
      level++;
    }
    return remaining;
  }
}
