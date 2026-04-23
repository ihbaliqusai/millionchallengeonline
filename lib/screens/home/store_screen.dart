import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../services/ad_service.dart';
import '../../services/native_bridge_service.dart';
import '../../widgets/currency_reward_overlay.dart';

class _CoinItem {
  const _CoinItem(this.label, this.gemCostLabel, this.coinAmount, this.gemCost);
  final String label;
  final String gemCostLabel;
  final int coinAmount;
  final int gemCost;
}

class _Tier {
  const _Tier(this.qty, this.cost);
  final int qty;
  final int cost;
}

class _PowerupDef {
  const _PowerupDef({
    required this.type,
    required this.name,
    required this.desc,
    required this.icon,
    required this.color,
    required this.coinTiers,
    required this.gemTiers,
  });

  final String type;
  final String name;
  final String desc;
  final IconData icon;
  final Color color;
  final List<_Tier> coinTiers;
  final List<_Tier> gemTiers;
}

const List<_CoinItem> _kCoinItems = <_CoinItem>[
  _CoinItem('500', '50', 500, 50),
  _CoinItem('2,200', '200', 2200, 200),
  _CoinItem('9,600', '800', 9600, 800),
  _CoinItem('34,500', '3,000', 34500, 3000),
  _CoinItem('120,000', '10,000', 120000, 10000),
];

const List<_PowerupDef> _kPowerups = <_PowerupDef>[
  _PowerupDef(
    type: '5050',
    name: '50:50',
    desc: 'يحذف إجابتين خاطئتين ويترك لك خيارين فقط.',
    icon: Icons.filter_2_rounded,
    color: Color(0xFF60A5FA),
    coinTiers: <_Tier>[_Tier(1, 2000), _Tier(3, 5000), _Tier(5, 7500)],
    gemTiers: <_Tier>[_Tier(1, 20), _Tier(3, 50), _Tier(5, 75)],
  ),
  _PowerupDef(
    type: 'audience',
    name: 'استشارة الجمهور',
    desc: 'يعرض ترجيحات الجمهور لمساعدتك على اتخاذ القرار.',
    icon: Icons.groups_rounded,
    color: Color(0xFFC084FC),
    coinTiers: <_Tier>[_Tier(1, 3000), _Tier(3, 7500), _Tier(5, 11000)],
    gemTiers: <_Tier>[_Tier(1, 30), _Tier(3, 75), _Tier(5, 110)],
  ),
  _PowerupDef(
    type: 'call',
    name: 'اتصال بصديق',
    desc: 'اتصل بالخبير للحصول على تلميح ذكي قبل الإجابة.',
    icon: Icons.phone_rounded,
    color: Color(0xFF34D399),
    coinTiers: <_Tier>[_Tier(1, 3000), _Tier(3, 7500), _Tier(5, 11000)],
    gemTiers: <_Tier>[_Tier(1, 30), _Tier(3, 75), _Tier(5, 110)],
  ),
];

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  Map<String, int> _inventory = <String, int>{};
  bool _loadingInventory = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    try {
      final inventory =
          await context.read<NativeBridgeService>().getInventory();
      if (!mounted) return;
      setState(() {
        _inventory = inventory;
        _loadingInventory = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingInventory = false);
    }
  }

  int _count(String type) {
    if (type == '5050') return _inventory['inv5050'] ?? 0;
    if (type == 'audience') return _inventory['invAudience'] ?? 0;
    return _inventory['invCall'] ?? 0;
  }

  Future<void> _watchRewardedAd() async {
    final adService = context.read<AdService>();
    if (!adService.canWatchAd) {
      _showSnack(
        adService.watchesLeft == 0
            ? 'وصلت إلى الحد اليومي للإعلانات المكافأة.'
            : 'الإعلان التالي غير متاح بعد. حاول لاحقاً.',
        isError: true,
      );
      return;
    }

    final reward = await adService.showRewardedAd();
    if (reward == null || !mounted) {
      _showSnack('تعذر تشغيل الإعلان أو تم إغلاقه قبل اكتماله.', isError: true);
      return;
    }

    await context.read<NativeBridgeService>().grantCurrency(
          coins: reward['coins']!,
          gems: reward['gems']!,
        );
    if (!mounted) return;
    await context.read<AppState>().loadCurrency();
    if (!mounted) return;
    showCurrencyRewardOverlay(
      context,
      coins: reward['coins']!,
      gems: reward['gems']!,
    );
  }

  Future<void> _claimDailyReward() async {
    final adService = context.read<AdService>();
    if (!adService.canClaimDailyPowerUp) {
      _showSnack('أكمل 5 إعلانات خلال اليوم أولاً.', isError: true);
      return;
    }
    final selected = await _showRewardPicker();
    if (selected == null || !mounted) return;

    final claimed = await adService.claimDailyPowerUp();
    if (!claimed || !mounted) {
      _showSnack('تم صرف مكافأة اليوم مسبقاً.', isError: true);
      return;
    }

    final granted = await context.read<NativeBridgeService>().grantPowerUp(
          type: selected,
          quantity: 1,
        );
    if (!mounted) return;
    if (!granted) {
      _showSnack('تعذر منح الوسيلة المجانية الآن.', isError: true);
      return;
    }
    await _loadInventory();
    _showSnack('تمت إضافة الوسيلة المجانية إلى مخزونك.');
  }

  Future<void> _buyCoins(_CoinItem item) async {
    final appState = context.read<AppState>();
    if (appState.gems < item.gemCost) {
      _showSnack('رصيد الجواهر غير كافٍ لهذه الحزمة.', isError: true);
      return;
    }
    final ok = await _confirm(
        'تحويل ${item.gemCostLabel} جوهرة إلى ${item.label} كوين؟');
    if (!ok || !mounted) return;
    final success = await context.read<NativeBridgeService>().buyCurrency(
          coinAmount: item.coinAmount,
          gemCost: item.gemCost,
        );
    if (!mounted) return;
    if (!success) {
      _showSnack('فشلت عملية التحويل.', isError: true);
      return;
    }
    await context.read<AppState>().loadCurrency();
    _showSnack('تمت إضافة ${item.label} كوين.');
  }

  Future<void> _buyPowerUp(_PowerupDef def, _Tier tier, String payWith) async {
    final appState = context.read<AppState>();
    final balance = payWith == 'coins' ? appState.coins : appState.gems;
    final label = payWith == 'coins' ? 'كوينز' : 'جواهر';
    if (balance < tier.cost) {
      _showSnack('رصيد $label غير كافٍ.', isError: true);
      return;
    }
    final ok = await _confirm(
        'شراء ${def.name} ×${tier.qty} مقابل ${tier.cost} $label؟');
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    final success = await context.read<NativeBridgeService>().buyPowerUp(
          type: def.type,
          quantity: tier.qty,
          payWith: payWith,
          cost: tier.cost,
        );
    if (!mounted) return;
    setState(() => _busy = false);

    if (!success) {
      _showSnack('فشلت عملية الشراء.', isError: true);
      return;
    }
    await context.read<AppState>().loadCurrency();
    await _loadInventory();
    _showSnack('تم شراء ${def.name} بنجاح.');
  }

  Future<bool> _confirm(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            backgroundColor: const Color(0xFF152055),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text(
              'تأكيد العملية',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
            content: Text(
              message,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75), height: 1.5),
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('إلغاء')),
              ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('تأكيد')),
            ],
          ),
        ) ??
        false;
  }

  Future<String?> _showRewardPicker() async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: const Color(0xFF152055),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'اختر الوسيلة المجانية',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _kPowerups.map((_PowerupDef def) {
            return ListTile(
              onTap: () => Navigator.of(ctx).pop(def.type),
              leading: Icon(def.icon, color: def.color),
              title:
                  Text(def.name, style: const TextStyle(color: Colors.white)),
              subtitle:
                  Text(def.desc, style: const TextStyle(color: Colors.white70)),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFB91C1C) : const Color(0xFF166534),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final adService = context.watch<AdService>();
    final progress =
        (adService.watchesToday / AdService.dailyPowerUpGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B4B),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: <Widget>[
                  _chip(Icons.monetization_on_rounded, const Color(0xFFFACC15),
                      appState.coins.toString()),
                  const SizedBox(width: 6),
                  _chip(Icons.diamond_rounded, const Color(0xFF38BDF8),
                      appState.gems.toString()),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          const Icon(Icons.home_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                children: <Widget>[
                  _card(
                    title: 'المتجر',
                    subtitle:
                        'كل العناصر هنا تعتمد على العملات داخل اللعبة فقط. لا توجد أي مشتريات نقدية داخل هذا المتجر.',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _badge(
                            '50:50 ×${_loadingInventory ? '...' : _count('5050')}',
                            const Color(0xFF60A5FA)),
                        _badge(
                            'الجمهور ×${_loadingInventory ? '...' : _count('audience')}',
                            const Color(0xFFC084FC)),
                        _badge(
                            'صديق ×${_loadingInventory ? '...' : _count('call')}',
                            const Color(0xFF34D399)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    title: 'مهمة الإعلانات اليومية',
                    subtitle: adService.canClaimDailyPowerUp
                        ? 'أكملت المهمة اليومية. اختر الآن وسيلة مجانية واحدة.'
                        : adService.hasClaimedDailyPowerUp
                            ? 'تم استلام مكافأة اليوم. تعود المهمة غداً.'
                            : 'شاهد 5 إعلانات مكافأة خلال اليوم لتحصل على وسيلة مجانية من اختيارك.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.08),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF4ADE80)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${adService.watchesToday}/${AdService.dailyPowerUpGoal} إعلانات مكتملة اليوم',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.68)),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            _action('شاهد إعلاناً الآن',
                                const Color(0xFF166534), _watchRewardedAd),
                            _action(
                              adService.canClaimDailyPowerUp
                                  ? 'اختر الوسيلة المجانية'
                                  : 'المكافأة غير جاهزة',
                              adService.canClaimDailyPowerUp
                                  ? const Color(0xFF7C3AED)
                                  : const Color(0xFF374151),
                              adService.canClaimDailyPowerUp
                                  ? _claimDailyReward
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    title: 'تحويل الجواهر إلى كوينز',
                    subtitle:
                        'استثمر الجواهر التي تجمعها من اللعب أو الإعلانات للحصول على كوينز إضافية.',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _kCoinItems.map((_CoinItem item) {
                        return GestureDetector(
                          onTap: _busy ? null : () => _buyCoins(item),
                          child: Container(
                            width: 160,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2557),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Icon(Icons.currency_exchange_rounded,
                                    color: Color(0xFFFACC15)),
                                const SizedBox(height: 10),
                                Text('${item.label} كوين',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text('مقابل ${item.gemCostLabel} جوهرة',
                                    style:
                                        const TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    title: 'القدرات والوسائل',
                    subtitle:
                        'اشترِ ما تحتاجه من وسائل المساعدة باستخدام الكوينز أو الجواهر التي تجمعها داخل اللعبة.',
                    child: Column(
                      children: _kPowerups.map((_PowerupDef def) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: def.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: def.color.withValues(alpha: 0.35)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Icon(def.icon, color: def.color),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text(def.name,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 17))),
                                  Text('المخزون: ${_count(def.type)}',
                                      style: const TextStyle(
                                          color: Colors.white70)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(def.desc,
                                  style: const TextStyle(
                                      color: Colors.white70, height: 1.45)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  ...def.coinTiers.map((_Tier tier) => _action(
                                      '${tier.qty} × • ${tier.cost} كوينز',
                                      const Color(0xFFF59E0B),
                                      _busy
                                          ? null
                                          : () =>
                                              _buyPowerUp(def, tier, 'coins'))),
                                  ...def.gemTiers.map((_Tier tier) => _action(
                                      '${tier.qty} × • ${tier.cost} جوهرة',
                                      const Color(0xFF0EA5E9),
                                      _busy
                                          ? null
                                          : () =>
                                              _buyPowerUp(def, tier, 'gems'))),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(growable: false),
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

  Widget _chip(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800)),
    );
  }

  Widget _action(String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(12)),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }

  Widget _card(
      {required String title,
      required String subtitle,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF10183D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72), height: 1.5)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
