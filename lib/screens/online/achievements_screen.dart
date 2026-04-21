import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/native_bridge_service.dart';

// ─── Status enum ──────────────────────────────────────────────────────────────

enum _AchStatus { done, progress, locked }

// ─── Achievement definition ───────────────────────────────────────────────────

class _AchDef {
  const _AchDef({
    required this.key,
    required this.titleAr,
    required this.descAr,
    required this.icon,
    required this.color,
    this.progressKey,
    this.progressTarget,
  });
  final String key;
  final String titleAr;
  final String descAr;
  final IconData icon;
  final Color color;

  /// Key in the data map to read progress (e.g. 'gamesPlayed', 'wins').
  final String? progressKey;
  final int? progressTarget;
}

// ─── Achievement category ─────────────────────────────────────────────────────

class _Category {
  const _Category({
    required this.titleAr,
    required this.icon,
    required this.color,
    required this.items,
  });
  final String titleAr;
  final IconData icon;
  final Color color;
  final List<_AchDef> items;
}

// ─── Data ─────────────────────────────────────────────────────────────────────

const _kCategories = [
  _Category(
    titleAr: 'البداية',
    icon: Icons.flag_rounded,
    color: Color(0xFF4ADE80),
    items: [
      _AchDef(
        key: 'ACH_FIRST_GAME',
        titleAr: 'أول خطوة',
        descAr: 'العب أول لعبة',
        icon: Icons.sports_esports_rounded,
        color: Color(0xFF4ADE80),
      ),
      _AchDef(
        key: 'ACH_FIRST_WIN',
        titleAr: 'أول انتصار',
        descAr: 'افز بأول مباراة',
        icon: Icons.emoji_events_rounded,
        color: Color(0xFFFACC15),
      ),
      _AchDef(
        key: 'ACH_FIRST_ONLINE',
        titleAr: 'المنافس الأول',
        descAr: 'العب أول مباراة أونلاين',
        icon: Icons.wifi_rounded,
        color: Color(0xFF38BDF8),
      ),
      _AchDef(
        key: 'ACH_BUY_POWERUP',
        titleAr: 'المتسوق',
        descAr: 'اشترِ وسيلة مساعدة لأول مرة',
        icon: Icons.shopping_cart_rounded,
        color: Color(0xFFA78BFA),
      ),
    ],
  ),
  _Category(
    titleAr: 'الخبرة والمستوى',
    icon: Icons.trending_up_rounded,
    color: Color(0xFF60A5FA),
    items: [
      _AchDef(
        key: 'ACH_LEVEL_5',
        titleAr: 'الصاعد',
        descAr: 'بلغ المستوى 5',
        icon: Icons.star_outline_rounded,
        color: Color(0xFF60A5FA),
        progressKey: 'level',
        progressTarget: 5,
      ),
      _AchDef(
        key: 'ACH_LEVEL_10',
        titleAr: 'المحترف',
        descAr: 'بلغ المستوى 10',
        icon: Icons.star_half_rounded,
        color: Color(0xFF38BDF8),
        progressKey: 'level',
        progressTarget: 10,
      ),
      _AchDef(
        key: 'ACH_LEVEL_20',
        titleAr: 'الخبير',
        descAr: 'بلغ المستوى 20',
        icon: Icons.star_rounded,
        color: Color(0xFF818CF8),
        progressKey: 'level',
        progressTarget: 20,
      ),
      _AchDef(
        key: 'ACH_LEVEL_30',
        titleAr: 'الأستاذ',
        descAr: 'بلغ المستوى 30',
        icon: Icons.military_tech_rounded,
        color: Color(0xFFE879F9),
        progressKey: 'level',
        progressTarget: 30,
      ),
      _AchDef(
        key: 'ACH_LEVEL_50',
        titleAr: 'الأسطورة',
        descAr: 'بلغ المستوى 50',
        icon: Icons.workspace_premium_rounded,
        color: Color(0xFFFBBF24),
        progressKey: 'level',
        progressTarget: 50,
      ),
    ],
  ),
  _Category(
    titleAr: 'الانتصارات',
    icon: Icons.emoji_events_rounded,
    color: Color(0xFFFACC15),
    items: [
      _AchDef(
        key: 'ACH_WIN_5',
        titleAr: 'منتصر',
        descAr: 'افز بـ5 مباريات',
        icon: Icons.thumb_up_rounded,
        color: Color(0xFF4ADE80),
        progressKey: 'wins',
        progressTarget: 5,
      ),
      _AchDef(
        key: 'ACH_WIN_10',
        titleAr: 'بطل',
        descAr: 'افز بـ10 مباريات',
        icon: Icons.emoji_events_rounded,
        color: Color(0xFFFACC15),
        progressKey: 'wins',
        progressTarget: 10,
      ),
      _AchDef(
        key: 'ACH_WIN_25',
        titleAr: 'محارب',
        descAr: 'افز بـ25 مباراة',
        icon: Icons.shield_rounded,
        color: Color(0xFFF97316),
        progressKey: 'wins',
        progressTarget: 25,
      ),
      _AchDef(
        key: 'ACH_WIN_50',
        titleAr: 'قائد',
        descAr: 'افز بـ50 مباراة',
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFEF4444),
        progressKey: 'wins',
        progressTarget: 50,
      ),
      _AchDef(
        key: 'ACH_WIN_100',
        titleAr: 'الغازي',
        descAr: 'افز بـ100 مباراة',
        icon: Icons.verified_rounded,
        color: Color(0xFFE879F9),
        progressKey: 'wins',
        progressTarget: 100,
      ),
    ],
  ),
  _Category(
    titleAr: 'الإجابات الصحيحة',
    icon: Icons.lightbulb_rounded,
    color: Color(0xFFFBBF24),
    items: [
      _AchDef(
        key: 'ACH_CORRECT_50',
        titleAr: 'ذكاء واضح',
        descAr: 'أجب 50 سؤالاً صحيحاً',
        icon: Icons.lightbulb_outline_rounded,
        color: Color(0xFFFBBF24),
        progressKey: 'correctAnswers',
        progressTarget: 50,
      ),
      _AchDef(
        key: 'ACH_CORRECT_100',
        titleAr: 'موسوعي',
        descAr: 'أجب 100 سؤال صحيح',
        icon: Icons.menu_book_rounded,
        color: Color(0xFF4ADE80),
        progressKey: 'correctAnswers',
        progressTarget: 100,
      ),
      _AchDef(
        key: 'ACH_CORRECT_500',
        titleAr: 'عبقري',
        descAr: 'أجب 500 سؤال صحيح',
        icon: Icons.psychology_rounded,
        color: Color(0xFF38BDF8),
        progressKey: 'correctAnswers',
        progressTarget: 500,
      ),
      _AchDef(
        key: 'ACH_CORRECT_1000',
        titleAr: 'عالم المعرفة',
        descAr: 'أجب 1,000 سؤال صحيح',
        icon: Icons.school_rounded,
        color: Color(0xFF818CF8),
        progressKey: 'correctAnswers',
        progressTarget: 1000,
      ),
      _AchDef(
        key: 'ACH_CORRECT_5000',
        titleAr: 'أستاذ الأسئلة',
        descAr: 'أجب 5,000 سؤال صحيح',
        icon: Icons.auto_stories_rounded,
        color: Color(0xFFF43F5E),
        progressKey: 'correctAnswers',
        progressTarget: 5000,
      ),
    ],
  ),
  _Category(
    titleAr: 'الجوائز',
    icon: Icons.attach_money_rounded,
    color: Color(0xFF4ADE80),
    items: [
      _AchDef(
        key: 'ACH_PRIZE_1000',
        titleAr: 'ألف مبروك',
        descAr: 'فز بجائزة 1,000 أو أكثر',
        icon: Icons.payments_rounded,
        color: Color(0xFF4ADE80),
      ),
      _AchDef(
        key: 'ACH_PRIZE_32000',
        titleAr: 'على الطريق',
        descAr: 'فز بجائزة 32,000',
        icon: Icons.monetization_on_rounded,
        color: Color(0xFFFACC15),
      ),
      _AchDef(
        key: 'ACH_PRIZE_500000',
        titleAr: 'نصف المليون',
        descAr: 'فز بجائزة 500,000',
        icon: Icons.diamond_rounded,
        color: Color(0xFF38BDF8),
      ),
      _AchDef(
        key: 'ACH_PRIZE_1000000',
        titleAr: 'المليونير الحقيقي',
        descAr: 'افز بجائزة المليون كاملاً!',
        icon: Icons.workspace_premium_rounded,
        color: Color(0xFFFBBF24),
      ),
    ],
  ),
  _Category(
    titleAr: 'سلاسل الإجابات',
    icon: Icons.bolt_rounded,
    color: Color(0xFFF97316),
    items: [
      _AchDef(
        key: 'ACH_STREAK_3',
        titleAr: 'أول سلسلة',
        descAr: 'أجب 3 أسئلة متتالية',
        icon: Icons.flash_on_rounded,
        color: Color(0xFFFBBF24),
        progressKey: 'bestStreak',
        progressTarget: 3,
      ),
      _AchDef(
        key: 'ACH_STREAK_5',
        titleAr: 'تسلسل',
        descAr: 'أجب 5 أسئلة متتالية',
        icon: Icons.bolt_rounded,
        color: Color(0xFFF97316),
        progressKey: 'bestStreak',
        progressTarget: 5,
      ),
      _AchDef(
        key: 'ACH_STREAK_10',
        titleAr: 'لا يتوقف',
        descAr: 'أجب 10 أسئلة متتالية',
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFEF4444),
        progressKey: 'bestStreak',
        progressTarget: 10,
      ),
      _AchDef(
        key: 'ACH_STREAK_15',
        titleAr: 'آلة الإجابات',
        descAr: 'أجب 15 سؤالاً متتالياً',
        icon: Icons.whatshot_rounded,
        color: Color(0xFFF43F5E),
        progressKey: 'bestStreak',
        progressTarget: 15,
      ),
    ],
  ),
  _Category(
    titleAr: 'المواظبة',
    icon: Icons.repeat_rounded,
    color: Color(0xFF818CF8),
    items: [
      _AchDef(
        key: 'ACH_GAMES_10',
        titleAr: 'مواظب',
        descAr: 'العب 10 ألعاب',
        icon: Icons.sports_esports_rounded,
        color: Color(0xFF818CF8),
        progressKey: 'gamesPlayed',
        progressTarget: 10,
      ),
      _AchDef(
        key: 'ACH_GAMES_25',
        titleAr: 'مجتهد',
        descAr: 'العب 25 لعبة',
        icon: Icons.repeat_rounded,
        color: Color(0xFF60A5FA),
        progressKey: 'gamesPlayed',
        progressTarget: 25,
      ),
      _AchDef(
        key: 'ACH_GAMES_50',
        titleAr: 'مدمن ألعاب',
        descAr: 'العب 50 لعبة',
        icon: Icons.timer_rounded,
        color: Color(0xFF38BDF8),
        progressKey: 'gamesPlayed',
        progressTarget: 50,
      ),
      _AchDef(
        key: 'ACH_GAMES_100',
        titleAr: 'لاعب حقيقي',
        descAr: 'العب 100 لعبة',
        icon: Icons.military_tech_rounded,
        color: Color(0xFFF97316),
        progressKey: 'gamesPlayed',
        progressTarget: 100,
      ),
    ],
  ),
  _Category(
    titleAr: 'الثروة',
    icon: Icons.monetization_on_rounded,
    color: Color(0xFFFACC15),
    items: [
      _AchDef(
        key: 'ACH_COINS_1000',
        titleAr: 'مدخر',
        descAr: 'اجمع 1,000 كوين',
        icon: Icons.savings_rounded,
        color: Color(0xFFFACC15),
        progressKey: 'coins',
        progressTarget: 1000,
      ),
      _AchDef(
        key: 'ACH_COINS_5000',
        titleAr: 'ثري',
        descAr: 'اجمع 5,000 كوين',
        icon: Icons.monetization_on_rounded,
        color: Color(0xFFF97316),
        progressKey: 'coins',
        progressTarget: 5000,
      ),
      _AchDef(
        key: 'ACH_COINS_10000',
        titleAr: 'كنز الكوين',
        descAr: 'اجمع 10,000 كوين',
        icon: Icons.account_balance_wallet_rounded,
        color: Color(0xFFEF4444),
        progressKey: 'coins',
        progressTarget: 10000,
      ),
      _AchDef(
        key: 'ACH_GEMS_50',
        titleAr: 'جامع الجواهر',
        descAr: 'اجمع 50 جوهرة',
        icon: Icons.diamond_outlined,
        color: Color(0xFF38BDF8),
        progressKey: 'gems',
        progressTarget: 50,
      ),
      _AchDef(
        key: 'ACH_GEMS_500',
        titleAr: 'ثروة الجواهر',
        descAr: 'اجمع 500 جوهرة',
        icon: Icons.diamond_rounded,
        color: Color(0xFF818CF8),
        progressKey: 'gems',
        progressTarget: 500,
      ),
    ],
  ),
  _Category(
    titleAr: 'المساعدات',
    icon: Icons.help_rounded,
    color: Color(0xFFA78BFA),
    items: [
      _AchDef(
        key: 'ACH_USE_5050',
        titleAr: 'نصف ونصف',
        descAr: 'استخدم وسيلة 50:50',
        icon: Icons.filter_2_rounded,
        color: Color(0xFF60A5FA),
      ),
      _AchDef(
        key: 'ACH_USE_AUDIENCE',
        titleAr: 'صوت الجمهور',
        descAr: 'استخدم استشارة الجمهور',
        icon: Icons.groups_rounded,
        color: Color(0xFFA78BFA),
      ),
      _AchDef(
        key: 'ACH_USE_CALL',
        titleAr: 'مكالمة إنقاذ',
        descAr: 'استخدم الاتصال بصديق',
        icon: Icons.phone_rounded,
        color: Color(0xFF4ADE80),
      ),
      _AchDef(
        key: 'ACH_USE_ALL_HELPS',
        titleAr: 'صندوق الأدوات',
        descAr: 'استخدم الثلاث مساعدات في لعبة واحدة',
        icon: Icons.handyman_rounded,
        color: Color(0xFFF97316),
      ),
    ],
  ),
  _Category(
    titleAr: 'المباريات الأونلاين',
    icon: Icons.public_rounded,
    color: Color(0xFF38BDF8),
    items: [
      _AchDef(
        key: 'ACH_ONLINE_WIN_5',
        titleAr: 'مقاتل الإنترنت',
        descAr: 'افز بـ5 مباريات أونلاين',
        icon: Icons.wifi_rounded,
        color: Color(0xFF38BDF8),
        progressKey: 'onlineWins',
        progressTarget: 5,
      ),
      _AchDef(
        key: 'ACH_ONLINE_WIN_10',
        titleAr: 'بطل الإنترنت',
        descAr: 'افز بـ10 مباريات أونلاين',
        icon: Icons.public_rounded,
        color: Color(0xFF818CF8),
        progressKey: 'onlineWins',
        progressTarget: 10,
      ),
    ],
  ),
  _Category(
    titleAr: 'أطوار احترافية',
    icon: Icons.auto_graph_rounded,
    color: Color(0xFFF97316),
    items: [
      _AchDef(
        key: 'ACH_BLITZ_FINISH_5',
        titleAr: 'سريع وحاسم',
        descAr: 'أكمل 5 مباريات Blitz للنهاية',
        icon: Icons.flash_on_rounded,
        color: Color(0xFFF97316),
        progressKey: 'blitzFinishes',
        progressTarget: 5,
      ),
      _AchDef(
        key: 'ACH_ELIMINATION_WIN_3',
        titleAr: 'ملك الإقصاء',
        descAr: 'افز 3 مرات في طور الإقصاء',
        icon: Icons.gpp_good_rounded,
        color: Color(0xFFEF4444),
        progressKey: 'eliminationWins',
        progressTarget: 3,
      ),
      _AchDef(
        key: 'ACH_SURVIVAL_WIN_3',
        titleAr: 'آخر الصامدين',
        descAr: 'افز 3 مرات في طور البقاء',
        icon: Icons.favorite_rounded,
        color: Color(0xFF4ADE80),
        progressKey: 'survivalWins',
        progressTarget: 3,
      ),
      _AchDef(
        key: 'ACH_SERIES_WIN_3',
        titleAr: 'سيد السلاسل',
        descAr: 'احسم 3 سلاسل كاملة لصالحك',
        icon: Icons.stacked_line_chart_rounded,
        color: Color(0xFF38BDF8),
        progressKey: 'seriesWins',
        progressTarget: 3,
      ),
      _AchDef(
        key: 'ACH_TEAM_BATTLE_WIN_5',
        titleAr: 'قائد الفريق',
        descAr: 'افز 5 مرات في طور Team Battle',
        icon: Icons.groups_rounded,
        color: Color(0xFFA78BFA),
        progressKey: 'teamBattleWins',
        progressTarget: 5,
      ),
    ],
  ),
  _Category(
    titleAr: 'إنجازات خاصة',
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFFFBBF24),
    items: [
      _AchDef(
        key: 'ACH_PERFECT_GAME',
        titleAr: 'لعبة مثالية',
        descAr: 'افز دون استخدام الثلاث مساعدات',
        icon: Icons.star_rounded,
        color: Color(0xFFFBBF24),
      ),
      _AchDef(
        key: 'ACH_ALL_DONE',
        titleAr: 'الكمال المطلق',
        descAr: 'أكمل جميع الإنجازات الأخرى',
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFFF43F5E),
      ),
    ],
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  Map<String, dynamic> _data = {};
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
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _isDone(_AchDef a) => _data[a.key] == true;

  _AchStatus _status(_AchDef a) {
    if (_isDone(a)) return _AchStatus.done;
    if (a.progressKey != null) {
      final cur = (_data[a.progressKey!] as num?)?.toInt() ?? 0;
      if (cur > 0) return _AchStatus.progress;
    }
    return _AchStatus.locked;
  }

  int _current(_AchDef a) => (_data[a.progressKey ?? ''] as num?)?.toInt() ?? 0;

  // Summary counts
  int get _doneCount =>
      _kCategories.expand((c) => c.items).where(_isDone).length;

  int get _progressCount => _kCategories
      .expand((c) => c.items)
      .where((a) => _status(a) == _AchStatus.progress)
      .length;

  int get _lockedCount => _kCategories
      .expand((c) => c.items)
      .where((a) => _status(a) == _AchStatus.locked)
      .length;

  int get _totalCount => _kCategories.fold(0, (s, c) => s + c.items.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1640),
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            if (!_loading)
              _SummaryBar(
                done: _doneCount,
                inProgress: _progressCount,
                locked: _lockedCount,
                total: _totalCount,
              ),
            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFFACC15)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                      itemCount: _kCategories.length,
                      itemBuilder: (_, ci) {
                        final cat = _kCategories[ci];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ci > 0) const SizedBox(height: 14),
                            _CategoryHeader(cat: cat),
                            const SizedBox(height: 8),
                            for (int ai = 0; ai < cat.items.length; ai++) ...[
                              if (ai > 0) const SizedBox(height: 7),
                              _AchievementCard(
                                def: cat.items[ai],
                                status: _status(cat.items[ai]),
                                current: _current(cat.items[ai]),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: Color(0xFFFACC15), size: 28),
          const SizedBox(width: 10),
          const Text(
            'الإنجازات',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary bar ─────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.done,
    required this.inProgress,
    required this.locked,
    required this.total,
  });
  final int done;
  final int inProgress;
  final int locked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (done / total * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SummaryChip(
                icon: Icons.emoji_events_rounded,
                label: '$done مكتمل',
                color: const Color(0xFFFACC15),
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                icon: Icons.timer_rounded,
                label: '$inProgress قيد التقدم',
                color: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                icon: Icons.lock_rounded,
                label: '$locked مغلق',
                color: const Color(0xFF6B7280),
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFACC15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? done / total : 0.0,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFACC15)),
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
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category header ──────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.cat});
  final _Category cat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cat.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(cat.icon, color: cat.color, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          cat.titleAr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: cat.color,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: cat.color.withValues(alpha: 0.2),
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ─── Achievement card ─────────────────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.def,
    required this.status,
    required this.current,
  });
  final _AchDef def;
  final _AchStatus status;
  final int current;

  @override
  Widget build(BuildContext context) {
    final isLocked = status == _AchStatus.locked;
    final isDone = status == _AchStatus.done;
    final isProgress = status == _AchStatus.progress;

    final iconColor = isLocked
        ? const Color(0xFF374151)
        : isDone
            ? def.color
            : def.color.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: isDone
            ? def.color.withValues(alpha: 0.08)
            : const Color(0xFF152055),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isDone
              ? def.color.withValues(alpha: 0.3)
              : isProgress
                  ? def.color.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Icon ──────────────────────────────────────────────────────────
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isLocked
                  ? Colors.white.withValues(alpha: 0.04)
                  : def.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLocked
                    ? Colors.white.withValues(alpha: 0.08)
                    : def.color.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(def.icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 11),

          // ── Text + progress ───────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        def.titleAr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isLocked
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.white,
                        ),
                      ),
                    ),
                    // Reward badge
                    if (!isLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFACC15).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.monetization_on_rounded,
                                size: 10, color: Color(0xFFFACC15)),
                            SizedBox(width: 2),
                            Text(
                              '250',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFACC15),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  def.descAr,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Colors.white.withValues(alpha: isLocked ? 0.22 : 0.5),
                  ),
                ),
                if (isProgress && def.progressTarget != null) ...[
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: def.progressTarget! > 0
                          ? (current / def.progressTarget!).clamp(0.0, 1.0)
                          : 0.0,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(def.color),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$current / ${def.progressTarget}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: def.color.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Status badge ──────────────────────────────────────────────────
          if (isDone)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: def.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: def.color.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Icon(Icons.check_rounded, color: def.color, size: 16),
              ),
            )
          else if (isLocked)
            Icon(
              Icons.lock_rounded,
              color: Colors.white.withValues(alpha: 0.2),
              size: 18,
            ),
        ],
      ),
    );
  }
}
