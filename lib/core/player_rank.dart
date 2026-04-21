import 'package:flutter/material.dart';

class PlayerRank {
  static String titleForLevel(int level) {
    if (level >= 60) return 'Legend';
    if (level >= 45) return 'Master';
    if (level >= 30) return 'Diamond';
    if (level >= 20) return 'Gold';
    if (level >= 10) return 'Silver';
    if (level >= 5) return 'Bronze';
    return 'Rookie';
  }

  static Color colorForLevel(int level) {
    if (level >= 60) return const Color(0xFFEF4444);
    if (level >= 45) return const Color(0xFF8B5CF6);
    if (level >= 30) return const Color(0xFF38BDF8);
    if (level >= 20) return const Color(0xFFFACC15);
    if (level >= 10) return const Color(0xFF94A3B8);
    if (level >= 5) return const Color(0xFFB45309);
    return const Color(0xFF38BDF8);
  }
}
