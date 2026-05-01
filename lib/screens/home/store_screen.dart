import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_settings.dart';
import '../../core/app_state.dart';
import '../../services/ad_service.dart';
import '../../services/native_bridge_service.dart';
import '../../widgets/currency_reward_overlay.dart';

class _CoinItem {
  const _CoinItem({
    required this.label,
    required this.coinAmount,
    required this.gemCost,
    required this.tag,
  });

  final String label;
  final int coinAmount;
  final int gemCost;
  final String tag;
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
    required this.shortName,
    required this.desc,
    required this.icon,
    required this.color,
    required this.coinTiers,
    required this.gemTiers,
  });

  final String type;
  final String name;
  final String shortName;
  final String desc;
  final IconData icon;
  final Color color;
  final List<_Tier> coinTiers;
  final List<_Tier> gemTiers;
}

const List<_CoinItem> _kCoinItems = <_CoinItem>[
  _CoinItem(label: '5,000', coinAmount: 5000, gemCost: 50, tag: 'بداية'),
  _CoinItem(label: '22,000', coinAmount: 22000, gemCost: 200, tag: 'شائع'),
  _CoinItem(label: '96,000', coinAmount: 96000, gemCost: 800, tag: 'قيمة'),
  _CoinItem(label: '345,000', coinAmount: 345000, gemCost: 3000, tag: 'كبير'),
  _CoinItem(
    label: '1,200,000',
    coinAmount: 1200000,
    gemCost: 10000,
    tag: 'الأفضل',
  ),
];

const List<_PowerupDef> _kPowerups = <_PowerupDef>[
  _PowerupDef(
    type: '5050',
    name: '50:50',
    shortName: '50:50',
    desc: 'يحذف إجابتين خاطئتين ويترك خيارين فقط.',
    icon: Icons.filter_2_rounded,
    color: Color(0xFF60A5FA),
    coinTiers: <_Tier>[_Tier(1, 2000), _Tier(3, 5000), _Tier(5, 7500)],
    gemTiers: <_Tier>[_Tier(1, 20), _Tier(3, 50), _Tier(5, 75)],
  ),
  _PowerupDef(
    type: 'audience',
    name: 'استشارة الجمهور',
    shortName: 'الجمهور',
    desc: 'يعرض ترجيحات الجمهور لمساعدتك في القرار.',
    icon: Icons.groups_rounded,
    color: Color(0xFFC084FC),
    coinTiers: <_Tier>[_Tier(1, 3000), _Tier(3, 7500), _Tier(5, 11000)],
    gemTiers: <_Tier>[_Tier(1, 30), _Tier(3, 75), _Tier(5, 110)],
  ),
  _PowerupDef(
    type: 'call',
    name: 'اتصال بصديق',
    shortName: 'صديق',
    desc: 'اتصل بالخبير للحصول على تلميح قبل الإجابة.',
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

  Future<void> _haptic() async {
    if (context.read<AppSettings>().haptic) {
      await HapticFeedback.lightImpact();
    }
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

  int get _inventoryTotal =>
      (_inventory['inv5050'] ?? 0) +
      (_inventory['invAudience'] ?? 0) +
      (_inventory['invCall'] ?? 0);

  Future<void> _watchRewardedAd() async {
    if (_busy) return;
    final adService = context.read<AdService>();
    final native = context.read<NativeBridgeService>();
    final appState = context.read<AppState>();
    await _haptic();

    if (!adService.canWatchAd) {
      final remaining = adService.cooldownRemaining;
      _showSnack(
        adService.watchesLeft == 0
            ? 'وصلت إلى الحد اليومي للإعلانات المكافأة.'
            : 'الإعلان التالي بعد ${_formatDuration(remaining)}.',
        isError: true,
      );
      return;
    }

    setState(() => _busy = true);
    final reward = await adService.showRewardedAd();
    if (!mounted) return;
    setState(() => _busy = false);

    if (reward == null) {
      _showSnack('تعذر تشغيل الإعلان أو تم إغلاقه قبل اكتماله.', isError: true);
      return;
    }

    try {
      await native.grantCurrency(
        coins: reward['coins'] ?? 0,
        gems: reward['gems'] ?? 0,
      );
      await appState.loadCurrency();
    } catch (_) {
      if (!mounted) return;
      _showSnack('اكتمل الإعلان، لكن تعذر تسليم المكافأة الآن.', isError: true);
      return;
    }

    if (!mounted) return;
    showCurrencyRewardOverlay(
      context,
      coins: reward['coins'] ?? 0,
      gems: reward['gems'] ?? 0,
    );
  }

  Future<void> _claimDailyReward() async {
    if (_busy) return;
    final adService = context.read<AdService>();
    final native = context.read<NativeBridgeService>();
    await _haptic();

    if (!adService.canClaimDailyPowerUp) {
      _showSnack('أكمل 5 إعلانات خلال اليوم أولاً.', isError: true);
      return;
    }

    final selected = await _showRewardPicker();
    if (selected == null || !mounted) return;

    setState(() => _busy = true);
    final claimed = await adService.claimDailyPowerUp();
    if (!mounted) return;
    if (!claimed) {
      setState(() => _busy = false);
      _showSnack('تم صرف مكافأة اليوم مسبقاً.', isError: true);
      return;
    }

    final granted = await native.grantPowerUp(type: selected, quantity: 1);
    if (!mounted) return;
    setState(() => _busy = false);

    if (!granted) {
      _showSnack('تعذر منح الوسيلة المجانية الآن.', isError: true);
      return;
    }
    await _loadInventory();
    _showSnack('تمت إضافة الوسيلة المجانية إلى مخزونك.');
  }

  Future<void> _buyCoins(_CoinItem item) async {
    if (_busy) return;
    final appState = context.read<AppState>();
    final native = context.read<NativeBridgeService>();
    await _haptic();

    if (appState.gems < item.gemCost) {
      _showSnack('رصيد الجواهر غير كاف لهذه الحزمة.', isError: true);
      return;
    }

    final ok = await _confirm(
      'تأكيد التحويل',
      'تحويل ${_compactNumber(item.gemCost)} جوهرة إلى ${item.label} كوين؟',
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    final success = await native.buyCurrency(
      coinAmount: item.coinAmount,
      gemCost: item.gemCost,
    );
    if (!mounted) return;
    if (success) {
      await appState.loadCurrency();
    }
    if (!mounted) return;
    setState(() => _busy = false);

    if (!success) {
      _showSnack('فشلت عملية التحويل.', isError: true);
      return;
    }
    _showSnack('تمت إضافة ${item.label} كوين.');
  }

  Future<void> _buyPowerUp(
    _PowerupDef def,
    _Tier tier,
    String payWith,
  ) async {
    if (_busy) return;
    final appState = context.read<AppState>();
    final native = context.read<NativeBridgeService>();
    await _haptic();

    final balance = payWith == 'coins' ? appState.coins : appState.gems;
    final label = payWith == 'coins' ? 'كوين' : 'جوهرة';
    if (balance < tier.cost) {
      _showSnack('رصيد $label غير كاف.', isError: true);
      return;
    }

    final ok = await _confirm(
      'تأكيد الشراء',
      'شراء ${def.name} ×${tier.qty} مقابل ${_compactNumber(tier.cost)} $label؟',
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    final success = await native.buyPowerUp(
      type: def.type,
      quantity: tier.qty,
      payWith: payWith,
      cost: tier.cost,
    );
    if (!mounted) return;
    if (success) {
      await appState.loadCurrency();
      await _loadInventory();
    }
    if (!mounted) return;
    setState(() => _busy = false);

    if (!success) {
      _showSnack('فشلت عملية الشراء.', isError: true);
      return;
    }
    _showSnack('تم شراء ${def.name} بنجاح.');
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: const Color(0xFF081328),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              content: Text(
                message,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFACC15),
                    foregroundColor: const Color(0xFF111827),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'تأكيد',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  Future<String?> _showRewardPicker() async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF081328),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text(
            'اختر الوسيلة المجانية',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _kPowerups.map((_PowerupDef def) {
              return _RewardPickerTile(
                def: def,
                onTap: () => Navigator.of(ctx).pop(def.type),
              );
            }).toList(growable: false),
          ),
        ),
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor:
            isError ? const Color(0xFFB91C1C) : const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final adService = context.watch<AdService>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF071126),
        resizeToAvoidBottomInset: false,
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
                      const Color(0xFF030712).withValues(alpha: 0.56),
                      const Color(0xFF071126).withValues(alpha: 0.95),
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
                    child: _StoreDashboard(
                      coins: appState.coins,
                      gems: appState.gems,
                      adService: adService,
                      loadingInventory: _loadingInventory,
                      inventoryTotal: _inventoryTotal,
                      inventoryCount: _count,
                      busy: _busy,
                      onWatchAd: _watchRewardedAd,
                      onClaimDaily: _claimDailyReward,
                      onBuyCoins: _buyCoins,
                      onBuyPowerUp: _buyPowerUp,
                    ),
                  ),
                ],
              ),
            ),
            if (_busy)
              Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.16),
                    child: const Center(
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFFFACC15),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StoreDashboard extends StatelessWidget {
  const _StoreDashboard({
    required this.coins,
    required this.gems,
    required this.adService,
    required this.loadingInventory,
    required this.inventoryTotal,
    required this.inventoryCount,
    required this.busy,
    required this.onWatchAd,
    required this.onClaimDaily,
    required this.onBuyCoins,
    required this.onBuyPowerUp,
  });

  final int coins;
  final int gems;
  final AdService adService;
  final bool loadingInventory;
  final int inventoryTotal;
  final int Function(String type) inventoryCount;
  final bool busy;
  final VoidCallback onWatchAd;
  final VoidCallback onClaimDaily;
  final void Function(_CoinItem item) onBuyCoins;
  final void Function(_PowerupDef def, _Tier tier, String payWith) onBuyPowerUp;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 760 ? 12.0 : 16.0;
        final gap = constraints.maxWidth < 760 ? 10.0 : 12.0;
        final coinColumns = constraints.maxWidth >= 1120
            ? 5
            : constraints.maxWidth >= 820
                ? 3
                : constraints.maxWidth >= 560
                    ? 2
                    : 1;
        final powerupColumns = constraints.maxWidth >= 1060
            ? 3
            : constraints.maxWidth >= 700
                ? 2
                : 1;

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
                child: _StoreOverview(
                  coins: coins,
                  gems: gems,
                  adService: adService,
                  loadingInventory: loadingInventory,
                  inventoryTotal: inventoryTotal,
                  inventoryCount: inventoryCount,
                  busy: busy,
                  onWatchAd: onWatchAd,
                  onClaimDaily: onClaimDaily,
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                10,
              ),
              sliver: const SliverToBoxAdapter(
                child: _SectionHeader(
                  icon: Icons.currency_exchange_rounded,
                  title: 'تحويل الجواهر',
                  subtitle:
                      'حوّل الجواهر إلى كوين لاستخدامها في وسائل المساعدة',
                  color: Color(0xFF38BDF8),
                ),
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
                  crossAxisCount: coinColumns,
                  crossAxisSpacing: gap,
                  mainAxisSpacing: gap,
                  mainAxisExtent: 168,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _kCoinItems[index];
                    return _CoinPackCard(
                      item: item,
                      affordable: gems >= item.gemCost,
                      busy: busy,
                      onTap: () => onBuyCoins(item),
                    );
                  },
                  childCount: _kCoinItems.length,
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                10,
              ),
              sliver: const SliverToBoxAdapter(
                child: _SectionHeader(
                  icon: Icons.handyman_rounded,
                  title: 'وسائل المساعدة',
                  subtitle: 'اشترِ مخزونك قبل الجولات الصعبة',
                  color: Color(0xFFFACC15),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                22,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: powerupColumns,
                  crossAxisSpacing: gap,
                  mainAxisSpacing: gap,
                  mainAxisExtent: 288,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final def = _kPowerups[index];
                    return _PowerupCard(
                      def: def,
                      count: loadingInventory ? null : inventoryCount(def.type),
                      coins: coins,
                      gems: gems,
                      busy: busy,
                      onBuy: onBuyPowerUp,
                    );
                  },
                  childCount: _kPowerups.length,
                ),
              ),
            ),
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
                  'المتجر',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'المكافآت، تحويل الجواهر، ووسائل المساعدة',
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

class _StoreOverview extends StatelessWidget {
  const _StoreOverview({
    required this.coins,
    required this.gems,
    required this.adService,
    required this.loadingInventory,
    required this.inventoryTotal,
    required this.inventoryCount,
    required this.busy,
    required this.onWatchAd,
    required this.onClaimDaily,
  });

  final int coins;
  final int gems;
  final AdService adService;
  final bool loadingInventory;
  final int inventoryTotal;
  final int Function(String type) inventoryCount;
  final bool busy;
  final VoidCallback onWatchAd;
  final VoidCallback onClaimDaily;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final hero = _WalletPanel(
          coins: coins,
          gems: gems,
          loadingInventory: loadingInventory,
          inventoryTotal: inventoryTotal,
          inventoryCount: inventoryCount,
        );
        final mission = _AdMissionPanel(
          adService: adService,
          busy: busy,
          onWatchAd: onWatchAd,
          onClaimDaily: onClaimDaily,
        );

        if (!wide) {
          return Column(
            children: <Widget>[
              hero,
              const SizedBox(height: 10),
              mission,
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(flex: 7, child: hero),
              const SizedBox(width: 12),
              Expanded(flex: 5, child: mission),
            ],
          ),
        );
      },
    );
  }
}

class _WalletPanel extends StatelessWidget {
  const _WalletPanel({
    required this.coins,
    required this.gems,
    required this.loadingInventory,
    required this.inventoryTotal,
    required this.inventoryCount,
  });

  final int coins;
  final int gems;
  final bool loadingInventory;
  final int inventoryTotal;
  final int Function(String type) inventoryCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(accent: const Color(0xFFFACC15)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC15).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFACC15).withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFFFACC15),
                  size: 29,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'رصيدك ومخزونك',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'كل عملية شراء تحدّث الرصيد والمخزون مباشرة',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _BalanceCard(
                  icon: Icons.monetization_on_rounded,
                  color: const Color(0xFFFACC15),
                  value: _compactNumber(coins),
                  label: 'كوين',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BalanceCard(
                  icon: Icons.diamond_rounded,
                  color: const Color(0xFF38BDF8),
                  value: _compactNumber(gems),
                  label: 'جوهرة',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BalanceCard(
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFF34D399),
                  value:
                      loadingInventory ? '...' : _compactNumber(inventoryTotal),
                  label: 'وسيلة',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kPowerups.map((_PowerupDef def) {
              return _InventoryChip(
                def: def,
                count: loadingInventory ? null : inventoryCount(def.type),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _AdMissionPanel extends StatelessWidget {
  const _AdMissionPanel({
    required this.adService,
    required this.busy,
    required this.onWatchAd,
    required this.onClaimDaily,
  });

  final AdService adService;
  final bool busy;
  final VoidCallback onWatchAd;
  final VoidCallback onClaimDaily;

  @override
  Widget build(BuildContext context) {
    final progress =
        (adService.watchesToday / AdService.dailyPowerUpGoal).clamp(0.0, 1.0);
    final canWatch = adService.canWatchAd && !busy;
    final canClaim = adService.canClaimDailyPowerUp && !busy;
    final status = canClaim
        ? 'المكافأة اليومية جاهزة'
        : adService.hasClaimedDailyPowerUp
            ? 'تم استلام مكافأة اليوم'
            : adService.cooldownRemaining > Duration.zero &&
                    adService.watchesLeft > 0
                ? 'الإعلان التالي بعد ${_formatDuration(adService.cooldownRemaining)}'
                : '${adService.watchesToday}/${AdService.dailyPowerUpGoal} إعلانات اليوم';

    return Container(
      decoration: _panelDecoration(accent: const Color(0xFF34D399)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF34D399).withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.ondemand_video_rounded,
                  color: Color(0xFF34D399),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'مهمة الإعلان اليومية',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        color: canClaim
                            ? const Color(0xFF34D399)
                            : Colors.white.withValues(alpha: 0.58),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.09),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF34D399),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _ActionButton(
                  icon: Icons.play_circle_fill_rounded,
                  label: 'شاهد إعلاناً',
                  color: const Color(0xFF166534),
                  onTap: canWatch ? onWatchAd : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.card_giftcard_rounded,
                  label: canClaim ? 'اختر المكافأة' : 'غير جاهزة',
                  color: canClaim
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF374151),
                  onTap: canClaim ? onClaimDaily : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.52),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          height: 2,
          width: 76,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}

class _CoinPackCard extends StatelessWidget {
  const _CoinPackCard({
    required this.item,
    required this.affordable,
    required this.busy,
    required this.onTap,
  });

  final _CoinItem item;
  final bool affordable;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = affordable && !busy;
    final rate = (item.coinAmount / item.gemCost).round();

    return Opacity(
      opacity: enabled ? 1 : 0.58,
      child: Container(
        decoration: _panelDecoration(
          accent:
              affordable ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFACC15).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFACC15).withValues(alpha: 0.30),
                    ),
                  ),
                  child: const Icon(
                    Icons.monetization_on_rounded,
                    color: Color(0xFFFACC15),
                    size: 24,
                  ),
                ),
                const Spacer(),
                _TagPill(text: item.tag, color: const Color(0xFF38BDF8)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${item.label} كوين',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              '${_compactNumber(item.gemCost)} جوهرة  •  $rate كوين لكل جوهرة',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            _ActionButton(
              icon: enabled ? Icons.add_rounded : Icons.lock_rounded,
              label: enabled ? 'تحويل الآن' : 'جواهر غير كافية',
              color:
                  enabled ? const Color(0xFF0369A1) : const Color(0xFF374151),
              onTap: enabled ? onTap : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PowerupCard extends StatelessWidget {
  const _PowerupCard({
    required this.def,
    required this.count,
    required this.coins,
    required this.gems,
    required this.busy,
    required this.onBuy,
  });

  final _PowerupDef def;
  final int? count;
  final int coins;
  final int gems;
  final bool busy;
  final void Function(_PowerupDef def, _Tier tier, String payWith) onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(accent: def.color),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: def.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: def.color.withValues(alpha: 0.34)),
                ),
                child: Icon(def.icon, color: def.color, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      def.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'في المخزون: ${count == null ? '...' : count.toString()}',
                      style: TextStyle(
                        color: def.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            def.desc,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          _TierRow(
            title: 'بالكوين',
            icon: Icons.monetization_on_rounded,
            color: const Color(0xFFFACC15),
            tiers: def.coinTiers,
            balance: coins,
            busy: busy,
            onBuy: (tier) => onBuy(def, tier, 'coins'),
          ),
          const SizedBox(height: 9),
          _TierRow(
            title: 'بالجواهر',
            icon: Icons.diamond_rounded,
            color: const Color(0xFF38BDF8),
            tiers: def.gemTiers,
            balance: gems,
            busy: busy,
            onBuy: (tier) => onBuy(def, tier, 'gems'),
          ),
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.title,
    required this.icon,
    required this.color,
    required this.tiers,
    required this.balance,
    required this.busy,
    required this.onBuy,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<_Tier> tiers;
  final int balance;
  final bool busy;
  final void Function(_Tier tier) onBuy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: tiers.map((_Tier tier) {
            final enabled = !busy && balance >= tier.cost;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _MiniBuyButton(
                  quantity: tier.qty,
                  price: _compactNumber(tier.cost),
                  icon: icon,
                  color: color,
                  enabled: enabled,
                  onTap: () => onBuy(tier),
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.27)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.54),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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

class _InventoryChip extends StatelessWidget {
  const _InventoryChip({
    required this.def,
    required this.count,
  });

  final _PowerupDef def;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: def.color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: def.color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(def.icon, color: def.color, size: 16),
          const SizedBox(width: 6),
          Text(
            def.shortName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            count == null ? '...' : 'x$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniBuyButton extends StatelessWidget {
  const _MiniBuyButton({
    required this.quantity,
    required this.price,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final int quantity;
  final String price;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.46,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.32)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'x$quantity',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(icon, color: color, size: 15),
                const SizedBox(width: 3),
                Text(
                  price,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.48 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: Colors.white, size: 17),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardPickerTile extends StatelessWidget {
  const _RewardPickerTile({
    required this.def,
    required this.onTap,
  });

  final _PowerupDef def;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: def.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: def.color.withValues(alpha: 0.26)),
          ),
          child: Row(
            children: <Widget>[
              Icon(def.icon, color: def.color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      def.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      def.desc,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration({required Color accent}) {
  return BoxDecoration(
    color: const Color(0xFF081328).withValues(alpha: 0.84),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: accent.withValues(alpha: 0.27)),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.20),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

String _compactNumber(int value) {
  final sign = value < 0 ? '-' : '';
  final abs = value.abs();
  if (abs >= 1000000) {
    final number = abs / 1000000;
    return '$sign${number.toStringAsFixed(number >= 10 ? 0 : 1)}M';
  }
  if (abs >= 1000) {
    final number = abs / 1000;
    return '$sign${number.toStringAsFixed(number >= 10 ? 0 : 1)}K';
  }
  return value.toString();
}

String _formatDuration(Duration duration) {
  if (duration <= Duration.zero) return 'الآن';
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (duration.inHours > 0) {
    return '${duration.inHours}:$minutes';
  }
  return '$minutes:$seconds';
}
