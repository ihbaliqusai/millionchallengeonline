import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/native_bridge_service.dart';

enum _AchStatus { done, progress, locked }

class _AchDef {
  const _AchDef({
    required this.key,
    required this.titleAr,
    required this.descAr,
    required this.icon,
    required this.color,
    required this.rewardCoins,
    required this.rewardXp,
    this.progressKey,
    this.progressTarget,
    this.progressLabel = '',
    this.progressIsMoney = false,
    this.progressSuffix = '',
    this.gateKey,
    this.gateTarget,
    this.gateLabel = '',
  });

  final String key;
  final String titleAr;
  final String descAr;
  final IconData icon;
  final Color color;
  final int rewardCoins;
  final int rewardXp;
  final String? progressKey;
  final int? progressTarget;
  final String progressLabel;
  final bool progressIsMoney;
  final String progressSuffix;
  final String? gateKey;
  final int? gateTarget;
  final String gateLabel;
}

class _Category {
  const _Category({
    required this.titleAr,
    required this.subtitleAr,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String titleAr;
  final String subtitleAr;
  final IconData icon;
  final Color color;
  final List<_AchDef> items;
}

const List<_Category> _kCategories = <_Category>[
  _Category(
    titleAr: 'البداية',
    subtitleAr: 'خطوات اللاعب الأولى',
    icon: Icons.flag_rounded,
    color: Color(0xFF34D399),
    items: <_AchDef>[
      _AchDef(
        key: 'ACH_FIRST_GAME',
        titleAr: 'أول خطوة',
        descAr: 'العب أول مباراة في اللعبة.',
        icon: Icons.sports_esports_rounded,
        color: Color(0xFF34D399),
        rewardCoins: 150,
        rewardXp: 40,
        progressKey: 'gamesPlayed',
        progressTarget: 1,
        progressLabel: 'مباراة',
      ),
      _AchDef(
        key: 'ACH_FIRST_WIN',
        titleAr: 'أول انتصار',
        descAr: 'حقق أول فوز كامل.',
        icon: Icons.emoji_events_rounded,
        color: Color(0xFFFACC15),
        rewardCoins: 250,
        rewardXp: 70,
        progressKey: 'wins',
        progressTarget: 1,
        progressLabel: 'فوز',
      ),
      _AchDef(
        key: 'ACH_FIRST_ONLINE',
        titleAr: 'المنافس الأول',
        descAr: 'ادخل أول مباراة أونلاين.',
        icon: Icons.public_rounded,
        color: Color(0xFF38BDF8),
        rewardCoins: 250,
        rewardXp: 70,
      ),
      _AchDef(
        key: 'ACH_BUY_POWERUP',
        titleAr: 'المتسوق',
        descAr: 'اشتر وسيلة مساعدة من المتجر.',
        icon: Icons.shopping_bag_rounded,
        color: Color(0xFFA78BFA),
        rewardCoins: 200,
        rewardXp: 60,
      ),
    ],
  ),
  _Category(
    titleAr: 'الرتبة والمستوى',
    subtitleAr: 'من مبتدئ إلى أسطورة',
    icon: Icons.workspace_premium_rounded,
    color: Color(0xFF60A5FA),
    items: <_AchDef>[
      _AchDef(
        key: 'ACH_LEVEL_5',
        titleAr: 'برونزي',
        descAr: 'بلغ المستوى 5 وافتح رتبة البرونز.',
        icon: Icons.shield_rounded,
        color: Color(0xFFB45309),
        rewardCoins: 300,
        rewardXp: 100,
        progressKey: 'level',
        progressTarget: 5,
        progressLabel: 'مستوى',
      ),
      _AchDef(
        key: 'ACH_LEVEL_10',
        titleAr: 'فضي',
        descAr: 'بلغ المستوى 10 وافتح رتبة الفضة.',
        icon: Icons.shield_moon_rounded,
        color: Color(0xFF94A3B8),
        rewardCoins: 500,
        rewardXp: 150,
        progressKey: 'level',
        progressTarget: 10,
        progressLabel: 'مستوى',
      ),
      _AchDef(
        key: 'ACH_LEVEL_20',
        titleAr: 'ذهبي',
        descAr: 'بلغ المستوى 20 وافتح رتبة الذهب.',
        icon: Icons.military_tech_rounded,
        color: Color(0xFFFACC15),
        rewardCoins: 900,
        rewardXp: 250,
        progressKey: 'level',
        progressTarget: 20,
        progressLabel: 'مستوى',
      ),
      _AchDef(
        key: 'ACH_LEVEL_30',
        titleAr: 'ماسي',
        descAr: 'بلغ المستوى 30 وافتح رتبة الماس.',
        icon: Icons.diamond_rounded,
        color: Color(0xFF38BDF8),
        rewardCoins: 1400,
        rewardXp: 400,
        progressKey: 'level',
        progressTarget: 30,
        progressLabel: 'مستوى',
      ),
      _AchDef(
        key: 'ACH_LEVEL_45',
        titleAr: 'خبير',
        descAr: 'بلغ المستوى 45 وافتح رتبة الخبير.',
        icon: Icons.workspace_premium_rounded,
        color: Color(0xFF8B5CF6),
        rewardCoins: 2200,
        rewardXp: 650,
        progressKey: 'level',
        progressTarget: 45,
        progressLabel: 'مستوى',
      ),
      _AchDef(
        key: 'ACH_LEVEL_60',
        titleAr: 'أسطورة',
        descAr: 'بلغ المستوى 60 وادخل رتبة الأساطير.',
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFEF4444),
        rewardCoins: 3500,
        rewardXp: 1000,
        progressKey: 'level',
        progressTarget: 60,
        progressLabel: 'مستوى',
      ),
    ],
  ),
  _Category(
    titleAr: 'المواظبة',
    subtitleAr: 'عدد المباريات التي لعبتها',
    icon: Icons.repeat_rounded,
    color: Color(0xFF818CF8),
    items: <_AchDef>[
      _AchDef(
        key: 'ACH_GAMES_10',
        titleAr: 'مواظب',
        descAr: 'العب 10 مباريات.',
        icon: Icons.sports_esports_rounded,
        color: Color(0xFF818CF8),
        rewardCoins: 250,
        rewardXp: 80,
        progressKey: 'gamesPlayed',
        progressTarget: 10,
        progressLabel: 'مباراة',
      ),
      _AchDef(
        key: 'ACH_GAMES_25',
        titleAr: 'مجتهد',
        descAr: 'العب 25 مباراة.',
        icon: Icons.timeline_rounded,
        color: Color(0xFF60A5FA),
        rewardCoins: 450,
        rewardXp: 120,
        progressKey: 'gamesPlayed',
        progressTarget: 25,
        progressLabel: 'مباراة',
      ),
      _AchDef(
        key: 'ACH_GAMES_50',
        titleAr: 'لاعب ثابت',
        descAr: 'العب 50 مباراة.',
        icon: Icons.timer_rounded,
        color: Color(0xFF38BDF8),
        rewardCoins: 700,
        rewardXp: 180,
        progressKey: 'gamesPlayed',
        progressTarget: 50,
        progressLabel: 'مباراة',
      ),
      _AchDef(
        key: 'ACH_GAMES_100',
        titleAr: 'لاعب حقيقي',
        descAr: 'العب 100 مباراة.',
        icon: Icons.verified_rounded,
        color: Color(0xFFF97316),
        rewardCoins: 1100,
        rewardXp: 260,
        progressKey: 'gamesPlayed',
        progressTarget: 100,
        progressLabel: 'مباراة',
      ),
      _AchDef(
        key: 'ACH_GAMES_250',
        titleAr: 'حضور قوي',
        descAr: 'العب 250 مباراة.',
        icon: Icons.auto_graph_rounded,
        color: Color(0xFFE879F9),
        rewardCoins: 1800,
        rewardXp: 420,
        progressKey: 'gamesPlayed',
        progressTarget: 250,
        progressLabel: 'مباراة',
      ),
      _AchDef(
        key: 'ACH_GAMES_500',
        titleAr: 'خبير الساحة',
        descAr: 'العب 500 مباراة.',
        icon: Icons.military_tech_rounded,
        color: Color(0xFFFBBF24),
        rewardCoins: 3000,
        rewardXp: 700,
        progressKey: 'gamesPlayed',
        progressTarget: 500,
        progressLabel: 'مباراة',
      ),
    ],
  ),
  _Category(
    titleAr: 'الانتصارات',
    subtitleAr: 'الفوز عبر كل أطوار اللعبة',
    icon: Icons.emoji_events_rounded,
    color: Color(0xFFFACC15),
    items: <_AchDef>[
      _AchDef(
        key: 'ACH_WIN_5',
        titleAr: 'منتصر',
        descAr: 'حقق 5 انتصارات.',
        icon: Icons.thumb_up_rounded,
        color: Color(0xFF34D399),
        rewardCoins: 350,
        rewardXp: 100,
        progressKey: 'wins',
        progressTarget: 5,
        progressLabel: 'فوز',
      ),
      _AchDef(
        key: 'ACH_WIN_10',
        titleAr: 'بطل',
        descAr: 'حقق 10 انتصارات.',
        icon: Icons.emoji_events_rounded,
        color: Color(0xFFFACC15),
        rewardCoins: 600,
        rewardXp: 160,
        progressKey: 'wins',
        progressTarget: 10,
        progressLabel: 'فوز',
      ),
      _AchDef(
        key: 'ACH_WIN_25',
        titleAr: 'محارب',
        descAr: 'حقق 25 انتصارا.',
        icon: Icons.shield_rounded,
        color: Color(0xFFF97316),
        rewardCoins: 1000,
        rewardXp: 260,
        progressKey: 'wins',
        progressTarget: 25,
        progressLabel: 'فوز',
      ),
      _AchDef(
        key: 'ACH_WIN_50',
        titleAr: 'قائد',
        descAr: 'حقق 50 انتصارا.',
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFEF4444),
        rewardCoins: 1600,
        rewardXp: 420,
        progressKey: 'wins',
        progressTarget: 50,
        progressLabel: 'فوز',
      ),
      _AchDef(
        key: 'ACH_WIN_100',
        titleAr: 'سيد الفوز',
        descAr: 'حقق 100 انتصار.',
        icon: Icons.workspace_premium_rounded,
        color: Color(0xFFE879F9),
        rewardCoins: 2600,
        rewardXp: 650,
        progressKey: 'wins',
        progressTarget: 100,
        progressLabel: 'فوز',
      ),
      _AchDef(
        key: 'ACH_WIN_250',
        titleAr: 'اسم لا ينسى',
        descAr: 'حقق 250 انتصارا.',
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFFFBBF24),
        rewardCoins: 4500,
        rewardXp: 1100,
        progressKey: 'wins',
        progressTarget: 250,
        progressLabel: 'فوز',
      ),
    ],
  ),
  _Category(
    titleAr: 'المعرفة والدقة',
    subtitleAr: 'الإجابات الصحيحة ونسبة الدقة',
    icon: Icons.psychology_rounded,
    color: Color(0xFFFBBF24),
    items: <_AchDef>[
      _AchDef(
        key: 'ACH_CORRECT_10',
        titleAr: 'بداية ذكية',
        descAr: 'أجب 10 أسئلة بشكل صحيح.',
        icon: Icons.lightbulb_outline_rounded,
        color: Color(0xFFFBBF24),
        rewardCoins: 180,
        rewardXp: 60,
        progressKey: 'correctAnswers',
        progressTarget: 10,
        progressLabel: 'إجابة',
      ),
      _AchDef(
        key: 'ACH_CORRECT_50',
        titleAr: 'ذكاء واضح',
        descAr: 'أجب 50 سؤالا بشكل صحيح.',
        icon: Icons.lightbulb_rounded,
        color: Color(0xFFFBBF24),
        rewardCoins: 400,
        rewardXp: 120,
        progressKey: 'correctAnswers',
        progressTarget: 50,
        progressLabel: 'إجابة',
      ),
      _AchDef(
        key: 'ACH_CORRECT_100',
        titleAr: 'موسوعي',
        descAr: 'أجب 100 سؤال بشكل صحيح.',
        icon: Icons.menu_book_rounded,
        color: Color(0xFF34D399),
        rewardCoins: 700,
        rewardXp: 180,
        progressKey: 'correctAnswers',
        progressTarget: 100,
        progressLabel: 'إجابة',
      ),
      _AchDef(
        key: 'ACH_CORRECT_500',
        titleAr: 'عبقري',
        descAr: 'أجب 500 سؤال بشكل صحيح.',
        icon: Icons.psychology_rounded,
        color: Color(0xFF38BDF8),
        rewardCoins: 1500,
        rewardXp: 350,
        progressKey: 'correctAnswers',
        progressTarget: 500,
        progressLabel: 'إجابة',
      ),
      _AchDef(
        key: 'ACH_CORRECT_1000',
        titleAr: 'عالم المعرفة',
        descAr: 'أجب 1,000 سؤال بشكل صحيح.',
        icon: Icons.school_rounded,
        color: Color(0xFF818CF8),
        rewardCoins: 2500,
        rewardXp: 550,
        progressKey: 'correctAnswers',
        progressTarget: 1000,
        progressLabel: 'إجابة',
      ),
      _AchDef(
        key: 'ACH_CORRECT_2500',
        titleAr: 'ذاكرة حادة',
        descAr: 'أجب 2,500 سؤال بشكل صحيح.',
        icon: Icons.auto_stories_rounded,
        color: Color(0xFFE879F9),
        rewardCoins: 4200,
        rewardXp: 900,
        progressKey: 'correctAnswers',
        progressTarget: 2500,
        progressLabel: 'إجابة',
      ),
      _AchDef(
        key: 'ACH_CORRECT_5000',
        titleAr: 'أستاذ الأسئلة',
        descAr: 'أجب 5,000 سؤال بشكل صحيح.',
        icon: Icons.workspace_premium_rounded,
        color: Color(0xFFF43F5E),
        rewardCoins: 7000,
        rewardXp: 1500,
        progressKey: 'correctAnswers',
        progressTarget: 5000,
        progressLabel: 'إجابة',
      ),
      _AchDef(
        key: 'ACH_ACCURACY_70',
        titleAr: 'تركيز ثابت',
        descAr: 'حافظ على دقة 70% بعد 50 سؤالا.',
        icon: Icons.task_alt_rounded,
        color: Color(0xFF34D399),
        rewardCoins: 600,
        rewardXp: 180,
        progressKey: 'accuracy',
        progressTarget: 70,
        progressLabel: 'الدقة',
        progressSuffix: '%',
        gateKey: 'totalAnswered',
        gateTarget: 50,
        gateLabel: 'الأسئلة',
      ),
      _AchDef(
        key: 'ACH_ACCURACY_80',
        titleAr: 'عين خبيرة',
        descAr: 'حافظ على دقة 80% بعد 100 سؤال.',
        icon: Icons.verified_rounded,
        color: Color(0xFF38BDF8),
        rewardCoins: 1100,
        rewardXp: 300,
        progressKey: 'accuracy',
        progressTarget: 80,
        progressLabel: 'الدقة',
        progressSuffix: '%',
        gateKey: 'totalAnswered',
        gateTarget: 100,
        gateLabel: 'الأسئلة',
      ),
      _AchDef(
        key: 'ACH_ACCURACY_90',
        titleAr: 'إتقان نادر',
        descAr: 'حافظ على دقة 90% بعد 250 سؤالا.',
        icon: Icons.diamond_rounded,
        color: Color(0xFFA78BFA),
        rewardCoins: 2200,
        rewardXp: 600,
        progressKey: 'accuracy',
        progressTarget: 90,
        progressLabel: 'الدقة',
        progressSuffix: '%',
        gateKey: 'totalAnswered',
        gateTarget: 250,
        gateLabel: 'الأسئلة',
      ),
    ],
  ),
  _Category(
    titleAr: 'الجوائز والأرباح',
    subtitleAr: 'أرقامك المالية داخل الجولات',
    icon: Icons.payments_rounded,
    color: Color(0xFF4ADE80),
    items: <_AchDef>[
      _AchDef(
        key: 'ACH_PRIZE_1000',
        titleAr: 'ألف مبروك',
        descAr: 'حقق جائزة 1,000 أو أكثر في مباراة واحدة.',
        icon: Icons.payments_rounded,
        color: Color(0xFF4ADE80),
        rewardCoins: 200,
        rewardXp: 60,
        progressKey: 'highestMoney',
        progressTarget: 1000,
        progressLabel: 'أعلى جائزة',
        progressIsMoney: true,
      ),
      _AchDef(
        key: 'ACH_PRIZE_32000',
        titleAr: 'على الطريق',
        descAr: 'حقق جائزة 32,000 في مباراة واحدة.',
        icon: Icons.monetization_on_rounded,
        color: Color(0xFFFACC15),
        rewardCoins: 450,
        rewardXp: 130,
        progressKey: 'highestMoney',
        progressTarget: 32000,
        progressLabel: 'أعلى جائزة',
        progressIsMoney: true,
      ),
      _AchDef(
        key: 'ACH_PRIZE_500000',
        titleAr: 'نصف المليون',
        descAr: 'حقق جائزة 500,000 في مباراة واحدة.',
        icon: Icons.diamond_rounded,
        color: Color(0xFF38BDF8),
        rewardCoins: 1200,
        rewardXp: 350,
        progressKey: 'highestMoney',
        progressTarget: 500000,
        progressLabel: 'أعلى جائزة',
        progressIsMoney: true,
      ),
      _AchDef(
        key: 'ACH_PRIZE_1000000',
        titleAr: 'المليونير الحقيقي',
        descAr: 'اربح المليون كاملا في مباراة واحدة.',
        icon: Icons.workspace_premium_rounded,
        color: Color(0xFFFBBF24),
        rewardCoins: 2500,
        rewardXp: 700,
        progressKey: 'highestMoney',
        progressTarget: 1000000,
        progressLabel: 'أعلى جائزة',
        progressIsMoney: true,
      ),
      _AchDef(
        key: 'ACH_EARNINGS_100000',
        titleAr: 'رصيد واعد',
        descAr: 'اجمع 100,000 من أرباح المباريات.',
        icon: Icons.account_balance_wallet_rounded,
        color: Color(0xFF34D399),
        rewardCoins: 500,
        rewardXp: 150,
        progressKey: 'totalEarnings',
        progressTarget: 100000,
        progressLabel: 'الأرباح',
        progressIsMoney: true,
      ),
      _AchDef(
        key: 'ACH_EARNINGS_1000000',
        titleAr: 'مليون تراكمي',
        descAr: 'اجمع 1,000,000 من أرباح المباريات.',
        icon: Icons.savings_rounded,
        color: Color(0xFF38BDF8),
        rewardCoins: 1500,
        rewardXp: 400,
        progressKey: 'totalEarnings',
        progressTarget: 1000000,
        progressLabel: 'الأرباح',
        progressIsMoney: true,
      ),
      _AchDef(
        key: 'ACH_EARNINGS_10000000',
        titleAr: 'ثروة الأساطير',
        descAr: 'اجمع 10,000,000 من أرباح المباريات.',
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFFFBBF24),
        rewardCoins: 4000,
        rewardXp: 900,
        progressKey: 'totalEarnings',
        progressTarget: 10000000,
        progressLabel: 'الأرباح',
        progressIsMoney: true,
      ),
    ],
  ),
  _Category(
    titleAr: 'السلاسل',
    subtitleAr: 'التتابع في الإجابات والفوز',
    icon: Icons.bolt_rounded,
    color: Color(0xFFF97316),
    items: <_AchDef>[
      _AchDef(
        key: 'ACH_STREAK_3',
        titleAr: 'أول سلسلة',
        descAr: 'أجب 3 أسئلة متتالية بشكل صحيح.',
        icon: Icons.flash_on_rounded,
        color: Color(0xFFFBBF24),
        rewardCoins: 200,
        rewardXp: 70,
        progressKey: 'bestStreak',
        progressTarget: 3,
        progressLabel: 'إجابة متتالية',
      ),
      _AchDef(
        key: 'ACH_STREAK_5',
        titleAr: 'تسلسل',
        descAr: 'أجب 5 أسئلة متتالية بشكل صحيح.',
        icon: Icons.bolt_rounded,
        color: Color(0xFFF97316),
        rewardCoins: 350,
        rewardXp: 100,
        progressKey: 'bestStreak',
        progressTarget: 5,
        progressLabel: 'إجابة متتالية',
      ),
      _AchDef(
        key: 'ACH_STREAK_10',
        titleAr: 'لا يتوقف',
        descAr: 'أجب 10 أسئلة متتالية بشكل صحيح.',
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFEF4444),
        rewardCoins: 800,
        rewardXp: 220,
        progressKey: 'bestStreak',
        progressTarget: 10,
        progressLabel: 'إجابة متتالية',
      ),
      _AchDef(
        key: 'ACH_STREAK_15',
        titleAr: 'جولة كاملة',
        descAr: 'أجب 15 سؤالا متتاليا بشكل صحيح.',
        icon: Icons.whatshot_rounded,
        color: Color(0xFFF43F5E),
        rewardCoins: 1600,
        rewardXp: 450,
        progressKey: 'bestStreak',
        progressTarget: 15,
        progressLabel: 'إجابة متتالية',
      ),
      _AchDef(
        key: 'ACH_WIN_STREAK_3',
        titleAr: 'زخم الفوز',
        descAr: 'حقق 3 انتصارات متتالية.',
        icon: Icons.trending_up_rounded,
        color: Color(0xFF34D399),
        rewardCoins: 500,
        rewardXp: 150,
        progressKey: 'bestWinStreak',
        progressTarget: 3,
        progressLabel: 'فوز متتال',
      ),
      _AchDef(
        key: 'ACH_WIN_STREAK_5',
        titleAr: 'موجة قوية',
        descAr: 'حقق 5 انتصارات متتالية.',
        icon: Icons.waterfall_chart_rounded,
        color: Color(0xFF38BDF8),
        rewardCoins: 1000,
        rewardXp: 260,
        progressKey: 'bestWinStreak',
        progressTarget: 5,
        progressLabel: 'فوز متتال',
      ),
      _AchDef(
        key: 'ACH_WIN_STREAK_10',
        titleAr: 'هيمنة كاملة',
        descAr: 'حقق 10 انتصارات متتالية.',
        icon: Icons.military_tech_rounded,
        color: Color(0xFFFACC15),
        rewardCoins: 2200,
        rewardXp: 600,
        progressKey: 'bestWinStreak',
        progressTarget: 10,
        progressLabel: 'فوز متتال',
      ),
    ],
  ),
  _Category(
    titleAr: 'الثروة والمخزون',
    subtitleAr: 'العملات والجواهر والاستعداد',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFFFACC15),
    items: <_AchDef>[
      _AchDef(
        key: 'ACH_COINS_1000',
        titleAr: 'مدخر',
        descAr: 'امتلك 1,000 كوين.',
        icon: Icons.savings_rounded,
        color: Color(0xFFFACC15),
        rewardCoins: 200,
        rewardXp: 60,
        progressKey: 'coins',
        progressTarget: 1000,
        progressLabel: 'كوين',
      ),
      _AchDef(
        key: 'ACH_COINS_5000',
        titleAr: 'ثري',
        descAr: 'امتلك 5,000 كوين.',
        icon: Icons.monetization_on_rounded,
        color: Color(0xFFF97316),
        rewardCoins: 500,
        rewardXp: 140,
        progressKey: 'coins',
        progressTarget: 5000,
        progressLabel: 'كوين',
      ),
      _AchDef(
        key: 'ACH_COINS_10000',
        titleAr: 'كنز الكوين',
        descAr: 'امتلك 10,000 كوين.',
        icon: Icons.account_balance_wallet_rounded,
        color: Color(0xFFEF4444),
        rewardCoins: 900,
        rewardXp: 240,
        progressKey: 'coins',
        progressTarget: 10000,
        progressLabel: 'كوين',
      ),
      _AchDef(
        key: 'ACH_COINS_50000',
        titleAr: 'خزنة ممتلئة',
        descAr: 'امتلك 50,000 كوين.',
        icon: Icons.account_balance_rounded,
        color: Color(0xFFFBBF24),
        rewardCoins: 2200,
        rewardXp: 550,
        progressKey: 'coins',
        progressTarget: 50000,
        progressLabel: 'كوين',
      ),
      _AchDef(
        key: 'ACH_GEMS_50',
        titleAr: 'جامع الجواهر',
        descAr: 'امتلك 50 جوهرة.',
        icon: Icons.diamond_outlined,
        color: Color(0xFF38BDF8),
        rewardCoins: 450,
        rewardXp: 120,
        progressKey: 'gems',
        progressTarget: 50,
        progressLabel: 'جوهرة',
      ),
      _AchDef(
        key: 'ACH_GEMS_500',
        titleAr: 'ثروة الجواهر',
        descAr: 'امتلك 500 جوهرة.',
        icon: Icons.diamond_rounded,
        color: Color(0xFF818CF8),
        rewardCoins: 1500,
        rewardXp: 380,
        progressKey: 'gems',
        progressTarget: 500,
        progressLabel: 'جوهرة',
      ),
      _AchDef(
        key: 'ACH_GEMS_1000',
        titleAr: 'مصرف الجواهر',
        descAr: 'امتلك 1,000 جوهرة.',
        icon: Icons.diamond_rounded,
        color: Color(0xFFA78BFA),
        rewardCoins: 2600,
        rewardXp: 650,
        progressKey: 'gems',
        progressTarget: 1000,
        progressLabel: 'جوهرة',
      ),
      _AchDef(
        key: 'ACH_INVENTORY_5',
        titleAr: 'مستعد',
        descAr: 'امتلك 5 وسائل مساعدة في المخزون.',
        icon: Icons.inventory_2_rounded,
        color: Color(0xFF34D399),
        rewardCoins: 300,
        rewardXp: 90,
        progressKey: 'inventoryTotal',
        progressTarget: 5,
        progressLabel: 'وسيلة',
      ),
      _AchDef(
        key: 'ACH_INVENTORY_15',
        titleAr: 'حقيبة محترف',
        descAr: 'امتلك 15 وسيلة مساعدة في المخزون.',
        icon: Icons.business_center_rounded,
        color: Color(0xFF38BDF8),
        rewardCoins: 700,
        rewardXp: 190,
        progressKey: 'inventoryTotal',
        progressTarget: 15,
        progressLabel: 'وسيلة',
      ),
      _AchDef(
        key: 'ACH_INVENTORY_30',
        titleAr: 'مركز الإمداد',
        descAr: 'امتلك 30 وسيلة مساعدة في المخزون.',
        icon: Icons.all_inbox_rounded,
        color: Color(0xFFFACC15),
        rewardCoins: 1300,
        rewardXp: 340,
        progressKey: 'inventoryTotal',
        progressTarget: 30,
        progressLabel: 'وسيلة',
      ),
    ],
  ),
  _Category(
    titleAr: 'وسائل المساعدة',
    subtitleAr: 'استخدام الأدوات داخل الجولات',
    icon: Icons.help_rounded,
    color: Color(0xFFA78BFA),
    items: <_AchDef>[
      _AchDef(
        key: 'ACH_USE_5050',
        titleAr: 'نصف ونصف',
        descAr: 'استخدم وسيلة 50:50 مرة واحدة.',
        icon: Icons.filter_2_rounded,
        color: Color(0xFF60A5FA),
        rewardCoins: 150,
        rewardXp: 50,
      ),
      _AchDef(
        key: 'ACH_USE_AUDIENCE',
        titleAr: 'صوت الجمهور',
        descAr: 'استخدم استشارة الجمهور مرة واحدة.',
        icon: Icons.groups_rounded,
        color: Color(0xFFA78BFA),
        rewardCoins: 150,
        rewardXp: 50,
      ),
      _AchDef(
        key: 'ACH_USE_CALL',
        titleAr: 'مكالمة إنقاذ',
        descAr: 'استخدم الاتصال بصديق مرة واحدة.',
        icon: Icons.phone_rounded,
        color: Color(0xFF34D399),
        rewardCoins: 150,
        rewardXp: 50,
      ),
      _AchDef(
        key: 'ACH_USE_ALL_HELPS',
        titleAr: 'صندوق الأدوات',
        descAr: 'استخدم وسائل المساعدة الثلاث في مباراة واحدة.',
        icon: Icons.handyman_rounded,
        color: Color(0xFFF97316),
        rewardCoins: 700,
        rewardXp: 220,
      ),
      _AchDef(
        key: 'ACH_PERFECT_GAME',
        titleAr: 'انتصار نظيف',
        descAr: 'افز دون استخدام أي وسيلة مساعدة.',
        icon: Icons.star_rounded,
        color: Color(0xFFFBBF24),
        rewardCoins: 1800,
        rewardXp: 500,
      ),
    ],
  ),
  _Category(
    titleAr: 'الأونلاين والأطوار',
    subtitleAr: 'إنجازات المنافسة الجماعية',
    icon: Icons.public_rounded,
    color: Color(0xFF22D3EE),
    items: <_AchDef>[
      _AchDef(
        key: 'ACH_ONLINE_WIN_5',
        titleAr: 'مقاتل الإنترنت',
        descAr: 'حقق 5 انتصارات أونلاين.',
        icon: Icons.wifi_rounded,
        color: Color(0xFF38BDF8),
        rewardCoins: 500,
        rewardXp: 150,
        progressKey: 'onlineWins',
        progressTarget: 5,
        progressLabel: 'فوز أونلاين',
      ),
      _AchDef(
        key: 'ACH_ONLINE_WIN_10',
        titleAr: 'بطل الإنترنت',
        descAr: 'حقق 10 انتصارات أونلاين.',
        icon: Icons.public_rounded,
        color: Color(0xFF818CF8),
        rewardCoins: 900,
        rewardXp: 240,
        progressKey: 'onlineWins',
        progressTarget: 10,
        progressLabel: 'فوز أونلاين',
      ),
      _AchDef(
        key: 'ACH_ONLINE_WIN_25',
        titleAr: 'هيبة أونلاين',
        descAr: 'حقق 25 انتصارا أونلاين.',
        icon: Icons.travel_explore_rounded,
        color: Color(0xFFE879F9),
        rewardCoins: 1800,
        rewardXp: 500,
        progressKey: 'onlineWins',
        progressTarget: 25,
        progressLabel: 'فوز أونلاين',
      ),
      _AchDef(
        key: 'ACH_BLITZ_FINISH_5',
        titleAr: 'سريع وحاسم',
        descAr: 'أكمل 5 مباريات في تحدي السرعة.',
        icon: Icons.flash_on_rounded,
        color: Color(0xFFF97316),
        rewardCoins: 600,
        rewardXp: 180,
        progressKey: 'blitzFinishes',
        progressTarget: 5,
        progressLabel: 'مباراة سرعة',
      ),
      _AchDef(
        key: 'ACH_BLITZ_FINISH_15',
        titleAr: 'نبض السرعة',
        descAr: 'أكمل 15 مباراة في تحدي السرعة.',
        icon: Icons.speed_rounded,
        color: Color(0xFFEF4444),
        rewardCoins: 1500,
        rewardXp: 420,
        progressKey: 'blitzFinishes',
        progressTarget: 15,
        progressLabel: 'مباراة سرعة',
      ),
      _AchDef(
        key: 'ACH_ELIMINATION_WIN_3',
        titleAr: 'ملك الإقصاء',
        descAr: 'افز 3 مرات في طور الإقصاء.',
        icon: Icons.gpp_good_rounded,
        color: Color(0xFFEF4444),
        rewardCoins: 700,
        rewardXp: 200,
        progressKey: 'eliminationWins',
        progressTarget: 3,
        progressLabel: 'فوز',
      ),
      _AchDef(
        key: 'ACH_ELIMINATION_WIN_10',
        titleAr: 'لا ينجو أحد',
        descAr: 'افز 10 مرات في طور الإقصاء.',
        icon: Icons.security_rounded,
        color: Color(0xFFF43F5E),
        rewardCoins: 1800,
        rewardXp: 500,
        progressKey: 'eliminationWins',
        progressTarget: 10,
        progressLabel: 'فوز',
      ),
      _AchDef(
        key: 'ACH_SURVIVAL_WIN_3',
        titleAr: 'آخر الصامدين',
        descAr: 'افز 3 مرات في طور البقاء.',
        icon: Icons.favorite_rounded,
        color: Color(0xFF34D399),
        rewardCoins: 700,
        rewardXp: 200,
        progressKey: 'survivalWins',
        progressTarget: 3,
        progressLabel: 'فوز',
      ),
      _AchDef(
        key: 'ACH_SURVIVAL_WIN_10',
        titleAr: 'صمود أسطوري',
        descAr: 'افز 10 مرات في طور البقاء.',
        icon: Icons.health_and_safety_rounded,
        color: Color(0xFF4ADE80),
        rewardCoins: 1800,
        rewardXp: 500,
        progressKey: 'survivalWins',
        progressTarget: 10,
        progressLabel: 'فوز',
      ),
      _AchDef(
        key: 'ACH_SERIES_WIN_3',
        titleAr: 'سيد السلاسل',
        descAr: 'احسم 3 سلاسل كاملة لصالحك.',
        icon: Icons.stacked_line_chart_rounded,
        color: Color(0xFF38BDF8),
        rewardCoins: 800,
        rewardXp: 230,
        progressKey: 'seriesWins',
        progressTarget: 3,
        progressLabel: 'سلسلة',
      ),
      _AchDef(
        key: 'ACH_SERIES_WIN_10',
        titleAr: 'حاسم السلاسل',
        descAr: 'احسم 10 سلاسل كاملة لصالحك.',
        icon: Icons.query_stats_rounded,
        color: Color(0xFF60A5FA),
        rewardCoins: 2000,
        rewardXp: 550,
        progressKey: 'seriesWins',
        progressTarget: 10,
        progressLabel: 'سلسلة',
      ),
      _AchDef(
        key: 'ACH_TEAM_BATTLE_WIN_5',
        titleAr: 'قائد الفريق',
        descAr: 'افز 5 مرات في طور مواجهة الفرق.',
        icon: Icons.groups_rounded,
        color: Color(0xFF4ADE80),
        rewardCoins: 900,
        rewardXp: 260,
        progressKey: 'teamBattleWins',
        progressTarget: 5,
        progressLabel: 'فوز',
      ),
      _AchDef(
        key: 'ACH_TEAM_BATTLE_WIN_15',
        titleAr: 'قلب الفريق',
        descAr: 'افز 15 مرة في طور مواجهة الفرق.',
        icon: Icons.diversity_3_rounded,
        color: Color(0xFFFACC15),
        rewardCoins: 2200,
        rewardXp: 600,
        progressKey: 'teamBattleWins',
        progressTarget: 15,
        progressLabel: 'فوز',
      ),
    ],
  ),
  _Category(
    titleAr: 'الإنجاز النهائي',
    subtitleAr: 'ختم رحلة الإنجازات',
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFFF43F5E),
    items: <_AchDef>[
      _AchDef(
        key: 'ACH_ALL_DONE',
        titleAr: 'الكمال المطلق',
        descAr: 'أكمل جميع الإنجازات الأخرى.',
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFFF43F5E),
        rewardCoins: 10000,
        rewardXp: 2500,
      ),
    ],
  ),
];

List<_AchDef> get _allAchievements =>
    _kCategories.expand((category) => category.items).toList(growable: false);

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  Map<String, dynamic> _data = <String, dynamic>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      final data = await context.read<NativeBridgeService>().getAchievements();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool _isDone(_AchDef achievement) => _data[achievement.key] == true;

  int _value(String key) => (_data[key] as num?)?.toInt() ?? 0;

  int _current(_AchDef achievement) {
    final key = achievement.progressKey;
    if (key == null) return 0;
    return _value(key);
  }

  int _gateCurrent(_AchDef achievement) {
    final key = achievement.gateKey;
    if (key == null) return 0;
    return _value(key);
  }

  _AchStatus _status(_AchDef achievement) {
    if (_isDone(achievement)) return _AchStatus.done;
    final current = _current(achievement);
    final gate = _gateCurrent(achievement);
    if (current > 0 || gate > 0) return _AchStatus.progress;
    return _AchStatus.locked;
  }

  double _progress(_AchDef achievement) {
    if (_isDone(achievement)) return 1.0;
    final target = achievement.progressTarget;
    if (target == null || target <= 0) return 0.0;
    final primary = (_current(achievement) / target).clamp(0.0, 1.0);
    final gateTarget = achievement.gateTarget;
    if (gateTarget == null || gateTarget <= 0) {
      return primary;
    }
    final gate = (_gateCurrent(achievement) / gateTarget).clamp(0.0, 1.0);
    return math.min(primary, gate);
  }

  String _progressText(_AchDef achievement) {
    final target = achievement.progressTarget;
    if (target == null) return '';
    final current = _current(achievement);
    final currentText = achievement.progressIsMoney
        ? _moneyNumber(current)
        : _compactNumber(current);
    final targetText = achievement.progressIsMoney
        ? _moneyNumber(target)
        : _compactNumber(target);
    final suffix = achievement.progressSuffix;
    final label = achievement.progressLabel.isEmpty
        ? '$currentText$suffix / $targetText$suffix'
        : '${achievement.progressLabel}: $currentText$suffix / $targetText$suffix';
    final gateTarget = achievement.gateTarget;
    if (achievement.gateKey == null || gateTarget == null) return label;
    final gate = _gateCurrent(achievement);
    final gateLabel =
        achievement.gateLabel.isEmpty ? 'المطلوب' : achievement.gateLabel;
    return '$label  •  $gateLabel: ${_compactNumber(gate)} / ${_compactNumber(gateTarget)}';
  }

  List<_AchDef> get _all => _allAchievements;

  int get _totalCount => _all.length;

  int get _doneCount => _all.where(_isDone).length;

  int get _progressCount => _all
      .where((achievement) => _status(achievement) == _AchStatus.progress)
      .length;

  int get _lockedCount => _all
      .where((achievement) => _status(achievement) == _AchStatus.locked)
      .length;

  int get _earnedCoins => _all
      .where(_isDone)
      .fold(0, (sum, achievement) => sum + achievement.rewardCoins);

  int get _earnedXp => _all
      .where(_isDone)
      .fold(0, (sum, achievement) => sum + achievement.rewardXp);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF071126),
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Image.asset('assets/ui/bg_main.png', fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      const Color(0xFF040914).withValues(alpha: 0.58),
                      const Color(0xFF071126).withValues(alpha: 0.94),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  _Header(onBack: () => Navigator.of(context).pop()),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _loading
                          ? const _LoadingState()
                          : _AchievementsDashboard(
                              categories: _kCategories,
                              statusOf: _status,
                              isDone: _isDone,
                              progressOf: _progress,
                              progressTextOf: _progressText,
                              done: _doneCount,
                              inProgress: _progressCount,
                              locked: _lockedCount,
                              total: _totalCount,
                              earnedCoins: _earnedCoins,
                              earnedXp: _earnedXp,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementsDashboard extends StatelessWidget {
  const _AchievementsDashboard({
    required this.categories,
    required this.statusOf,
    required this.isDone,
    required this.progressOf,
    required this.progressTextOf,
    required this.done,
    required this.inProgress,
    required this.locked,
    required this.total,
    required this.earnedCoins,
    required this.earnedXp,
  });

  final List<_Category> categories;
  final _AchStatus Function(_AchDef achievement) statusOf;
  final bool Function(_AchDef achievement) isDone;
  final double Function(_AchDef achievement) progressOf;
  final String Function(_AchDef achievement) progressTextOf;
  final int done;
  final int inProgress;
  final int locked;
  final int total;
  final int earnedCoins;
  final int earnedXp;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 3
            : constraints.maxWidth >= 760
                ? 2
                : 1;
        final horizontalPadding = constraints.maxWidth < 760 ? 12.0 : 16.0;
        final gap = constraints.maxWidth < 760 ? 10.0 : 12.0;
        final cardExtent = columns == 1 ? 174.0 : 158.0;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                2,
                horizontalPadding,
                14,
              ),
              sliver: SliverToBoxAdapter(
                child: _OverviewPanel(
                  done: done,
                  inProgress: inProgress,
                  locked: locked,
                  total: total,
                  earnedCoins: earnedCoins,
                  earnedXp: earnedXp,
                ),
              ),
            ),
            for (final category in categories) ...<Widget>[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  2,
                  horizontalPadding,
                  8,
                ),
                sliver: SliverToBoxAdapter(
                  child: _CategoryHeader(category: category),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  18,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: gap,
                    crossAxisSpacing: gap,
                    mainAxisExtent: cardExtent,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final achievement = category.items[index];
                      return _AchievementCard(
                        achievement: achievement,
                        status: statusOf(achievement),
                        progress: progressOf(achievement),
                        progressText: progressTextOf(achievement),
                      );
                    },
                    childCount: category.items.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'الإنجازات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'رحلة التقدم، الجوائز، والتحديات طويلة المدى',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'رجوع',
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: Colors.white,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.done,
    required this.inProgress,
    required this.locked,
    required this.total,
    required this.earnedCoins,
    required this.earnedXp,
  });

  final int done;
  final int inProgress;
  final int locked;
  final int total;
  final int earnedCoins;
  final int earnedXp;

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? done / total : 0.0;
    final percentText = (percent * 100).round();

    return Container(
      decoration: _panelDecoration(const Color(0xFFFACC15)),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          _ProgressMedal(
            percent: percent,
            label: '$percentText%',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              const Color(0xFFFACC15).withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFFACC15),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'مسار الإنجازات',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '$done من $total إنجاز مكتمل',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFACC15),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _SummaryChip(
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF34D399),
                      label: 'مكتمل',
                      value: _compactNumber(done),
                    ),
                    _SummaryChip(
                      icon: Icons.hourglass_top_rounded,
                      color: const Color(0xFF38BDF8),
                      label: 'قيد التقدم',
                      value: _compactNumber(inProgress),
                    ),
                    _SummaryChip(
                      icon: Icons.lock_rounded,
                      color: const Color(0xFF94A3B8),
                      label: 'مغلق',
                      value: _compactNumber(locked),
                    ),
                    _SummaryChip(
                      icon: Icons.monetization_on_rounded,
                      color: const Color(0xFFFACC15),
                      label: 'جوائز كوين',
                      value: _compactNumber(earnedCoins),
                    ),
                    _SummaryChip(
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFFA78BFA),
                      label: 'خبرة مكتسبة',
                      value: _compactNumber(earnedXp),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressMedal extends StatelessWidget {
  const _ProgressMedal({
    required this.percent,
    required this.label,
  });

  final double percent;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            width: 112,
            height: 112,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFACC15),
              ),
            ),
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFF071126).withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFFACC15),
                  size: 26,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.64),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category});

  final _Category category;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: category.color.withValues(alpha: 0.28)),
          ),
          child: Icon(category.icon, color: category.color, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                category.titleAr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                category.subtitleAr,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.52),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 2,
          width: 76,
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    required this.status,
    required this.progress,
    required this.progressText,
  });

  final _AchDef achievement;
  final _AchStatus status;
  final double progress;
  final String progressText;

  @override
  Widget build(BuildContext context) {
    final done = status == _AchStatus.done;
    final inProgress = status == _AchStatus.progress;
    final locked = status == _AchStatus.locked;
    final color = achievement.color;
    final foreground =
        locked ? Colors.white.withValues(alpha: 0.46) : Colors.white;
    final muted = locked
        ? Colors.white.withValues(alpha: 0.32)
        : Colors.white.withValues(alpha: 0.62);

    return Container(
      decoration: BoxDecoration(
        color: done
            ? color.withValues(alpha: 0.12)
            : const Color(0xFF071126).withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: done
              ? color.withValues(alpha: 0.48)
              : inProgress
                  ? color.withValues(alpha: 0.32)
                  : Colors.white.withValues(alpha: 0.11),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: locked
                  ? Colors.white.withValues(alpha: 0.05)
                  : color.withValues(alpha: 0.17),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: locked
                    ? Colors.white.withValues(alpha: 0.08)
                    : color.withValues(alpha: 0.36),
              ),
            ),
            child: Icon(
              locked ? Icons.lock_rounded : achievement.icon,
              color: locked ? Colors.white.withValues(alpha: 0.28) : color,
              size: 29,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        achievement.titleAr,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(status: status, color: color),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  achievement.descAr,
                  style: TextStyle(
                    color: muted,
                    fontSize: 11.5,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: <Widget>[
                    _RewardPill(
                      icon: Icons.monetization_on_rounded,
                      value: '+${_compactNumber(achievement.rewardCoins)}',
                      color: const Color(0xFFFACC15),
                    ),
                    const SizedBox(width: 6),
                    _RewardPill(
                      icon: Icons.bolt_rounded,
                      value: '+${_compactNumber(achievement.rewardXp)} XP',
                      color: const Color(0xFFA78BFA),
                    ),
                  ],
                ),
                if (achievement.progressTarget != null) ...<Widget>[
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        locked ? Colors.white.withValues(alpha: 0.24) : color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progressText,
                    style: TextStyle(
                      color: locked ? muted : color.withValues(alpha: 0.9),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.status,
    required this.color,
  });

  final _AchStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final done = status == _AchStatus.done;
    final inProgress = status == _AchStatus.progress;
    final label = done
        ? 'مكتمل'
        : inProgress
            ? 'تقدم'
            : 'مغلق';
    final icon = done
        ? Icons.check_rounded
        : inProgress
            ? Icons.hourglass_top_rounded
            : Icons.lock_rounded;
    final pillColor = done
        ? const Color(0xFF34D399)
        : inProgress
            ? color
            : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: pillColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: pillColor.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: pillColor, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: pillColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFFFACC15)),
    );
  }
}

BoxDecoration _panelDecoration(Color color) {
  return BoxDecoration(
    color: const Color(0xFF071126).withValues(alpha: 0.76),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: color.withValues(alpha: 0.24)),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.18),
        blurRadius: 22,
        offset: const Offset(0, 12),
      ),
    ],
  );
}

String _compactNumber(int value) {
  final sign = value < 0 ? '-' : '';
  final absValue = value.abs();
  if (absValue >= 1000000) {
    final number = absValue / 1000000;
    return '$sign${number.toStringAsFixed(number >= 10 ? 0 : 1)}M';
  }
  if (absValue >= 1000) {
    final number = absValue / 1000;
    return '$sign${number.toStringAsFixed(number >= 10 ? 0 : 1)}K';
  }
  return value.toString();
}

String _moneyNumber(int value) {
  if (value >= 1000000) {
    final number = value / 1000000;
    return '${number.toStringAsFixed(number >= 10 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    final number = value / 1000;
    return '${number.toStringAsFixed(number >= 10 ? 0 : 1)}K';
  }
  return value.toString();
}
