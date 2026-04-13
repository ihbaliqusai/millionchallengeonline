import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../services/iap_service.dart';
import '../../services/native_bridge_service.dart';

// ─── Bundle definitions ───────────────────────────────────────────────────────

class _Bundle {
  const _Bundle({
    required this.productId,
    required this.titleAr,
    required this.gems,
    required this.coins,
    this.inv5050 = 0,
    this.invAudience = 0,
    this.invCall = 0,
    required this.savePct,
    required this.fallbackPrice,
    required this.gradient,
    required this.accent,
  });
  final String productId;
  final String titleAr;
  final int gems;
  final int coins;
  final int inv5050;
  final int invAudience;
  final int invCall;
  final int savePct;
  final String fallbackPrice;
  final List<Color> gradient;
  final Color accent;
}

const _kBundles = [
  _Bundle(
    productId: 'pack_starter',
    titleAr: 'حزمة المبتدئ',
    gems: 120, coins: 500, inv5050: 2,
    savePct: 20,
    fallbackPrice: 'JOD 0.550',
    gradient: [Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
    accent: Color(0xFF60A5FA),
  ),
  _Bundle(
    productId: 'pack_value',
    titleAr: 'حزمة القيمة',
    gems: 600, coins: 2000, inv5050: 3, invAudience: 2,
    savePct: 25,
    fallbackPrice: 'JOD 1.750',
    gradient: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
    accent: Color(0xFFA78BFA),
  ),
  _Bundle(
    productId: 'pack_champion',
    titleAr: 'حزمة البطل',
    gems: 1800, coins: 10000, inv5050: 5, invAudience: 3, invCall: 2,
    savePct: 35,
    fallbackPrice: 'JOD 4.500',
    gradient: [Color(0xFFD97706), Color(0xFF92400E)],
    accent: Color(0xFFFBBF24),
  ),
];

// ─── Gem items (IAP products) ─────────────────────────────────────────────────

class _GemItem {
  const _GemItem({
    required this.productId,
    required this.amount,
    required this.fallbackPrice,
    this.isMega = false,
  });
  final String productId;
  final String amount;
  final String fallbackPrice;
  final bool isMega;
}

const _kGemItems = [
  _GemItem(productId: 'gems_80',    amount: '80',     fallbackPrice: 'JOD 0.300'),
  _GemItem(productId: 'gems_500',   amount: '500',    fallbackPrice: 'JOD 1.550'),
  _GemItem(productId: 'gems_1200',  amount: '1,200',  fallbackPrice: 'JOD 3.100'),
  _GemItem(productId: 'gems_2500',  amount: '2,500',  fallbackPrice: 'JOD 6.200'),
  _GemItem(productId: 'gems_6500',  amount: '6,500',  fallbackPrice: 'JOD 15.550'),
  _GemItem(productId: 'gems_14000', amount: '14,000', fallbackPrice: 'JOD 31.000', isMega: true),
];

// ─── Coin items (bought with gems internally) ─────────────────────────────────

class _CoinItem {
  const _CoinItem({
    required this.displayAmount,
    required this.gemCostLabel,
    required this.coinAmt,
    required this.gemCostInt,
  });
  final String displayAmount;
  final String gemCostLabel;
  final int coinAmt;
  final int gemCostInt;
}

const _kCoinItems = [
  _CoinItem(displayAmount: '500',     gemCostLabel: '50',     coinAmt: 500,    gemCostInt: 50),
  _CoinItem(displayAmount: '2,200',   gemCostLabel: '200',    coinAmt: 2200,   gemCostInt: 200),
  _CoinItem(displayAmount: '9,600',   gemCostLabel: '800',    coinAmt: 9600,   gemCostInt: 800),
  _CoinItem(displayAmount: '34,500',  gemCostLabel: '3,000',  coinAmt: 34500,  gemCostInt: 3000),
  _CoinItem(displayAmount: '120,000', gemCostLabel: '10,000', coinAmt: 120000, gemCostInt: 10000),
];

// ─── Powerup models ───────────────────────────────────────────────────────────

class _Tier {
  final int qty;
  final int cost;
  const _Tier(this.qty, this.cost);
}

class _PowerupDef {
  final String type;
  final String nameAr;
  final String descAr;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final List<_Tier> coinTiers;
  final List<_Tier> gemTiers;

  const _PowerupDef({
    required this.type,
    required this.nameAr,
    required this.descAr,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.coinTiers,
    required this.gemTiers,
  });
}

const _kPowerups = [
  _PowerupDef(
    type: '5050',
    nameAr: '50 : 50',
    descAr: 'يخفي إجابتين خاطئتين ويبقي الصحيحة وأخرى',
    icon: Icons.filter_2_rounded,
    color: Color(0xFF3B82F6),
    bgColor: Color(0xFF1E3A8A),
    coinTiers: [_Tier(1, 2000), _Tier(3, 5000), _Tier(5, 7500)],
    gemTiers:  [_Tier(1, 20),   _Tier(3, 50),   _Tier(5, 75)],
  ),
  _PowerupDef(
    type: 'audience',
    nameAr: 'استشارة الجمهور',
    descAr: 'يستطلع رأي الجمهور ويُظهر نسب التصويت',
    icon: Icons.groups_rounded,
    color: Color(0xFFA855F7),
    bgColor: Color(0xFF4C1D95),
    coinTiers: [_Tier(1, 3000), _Tier(3, 7500),  _Tier(5, 11000)],
    gemTiers:  [_Tier(1, 30),   _Tier(3, 75),    _Tier(5, 110)],
  ),
  _PowerupDef(
    type: 'call',
    nameAr: 'اتصال بصديق',
    descAr: 'يتصل بخبير يعطيك تلميحاً للإجابة الصحيحة',
    icon: Icons.phone_rounded,
    color: Color(0xFF10B981),
    bgColor: Color(0xFF064E3B),
    coinTiers: [_Tier(1, 3000), _Tier(3, 7500), _Tier(5, 11000)],
    gemTiers:  [_Tier(1, 30),   _Tier(3, 75),   _Tier(5, 110)],
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _tabCtrl = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabCtrl.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final iap      = context.read<IapService>();
      final appState = context.read<AppState>();

      iap.onItemsDelivered = () {
        appState.loadCurrency();
        if (!mounted) return;
        final id      = iap.lastDeliveredId ?? '';
        final bundle  = kBundleContents[id];
        final gemAmt  = kGemProductAmounts[id];
        String msg    = 'تم الشراء بنجاح ✓';
        if (bundle != null) {
          msg = 'تم استلام ${bundle.titleAr} بنجاح ✓';
        } else if (gemAmt != null) {
          msg = 'تم استلام $gemAmt جوهرة بنجاح ✓';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      };
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B4B),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(appState: appState),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _OffersTab(),
                  _CurrencyTab(),
                  _PowerupsTab(),
                ],
              ),
            ),
            _BottomTabBar(controller: _tabCtrl),
          ],
        ),
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _Chip(
            icon: Icons.monetization_on_rounded,
            color: const Color(0xFFFACC15),
            label: appState.coins.toString(),
          ),
          const SizedBox(width: 6),
          _Chip(
            icon: Icons.diamond_rounded,
            color: const Color(0xFF38BDF8),
            label: appState.gems.toString(),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.color, required this.label});
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom tab bar ───────────────────────────────────────────────────────────

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({required this.controller});
  final TabController controller;

  static const _tabs = [
    (label: 'عروض',  icon: Icons.local_offer_rounded),
    (label: 'عملات', icon: Icons.diamond_rounded),
    (label: 'قدرات', icon: Icons.bolt_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF091030),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final sel = controller.index == i;
          final tab = _tabs[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: sel
                      ? const Color(0xFFFACC15)
                      : const Color(0xFF1E3A8A).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel
                        ? const Color(0xFFFDE68A)
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.icon,
                      size: 15,
                      color: sel
                          ? const Color(0xFF1F2937)
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: sel ? const Color(0xFF1F2937) : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── OFFERS tab ───────────────────────────────────────────────────────────────

class _OffersTab extends StatelessWidget {
  const _OffersTab();

  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IapService>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < _kBundles.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            _BundleCard(bundle: _kBundles[i], iap: iap),
          ],
        ],
      ),
    );
  }
}

class _BundleCard extends StatelessWidget {
  const _BundleCard({required this.bundle, required this.iap});
  final _Bundle bundle;
  final IapService iap;

  static const double _w = 170.0;

  @override
  Widget build(BuildContext context) {
    final priceStr =
        iap.products[bundle.productId]?.price ?? bundle.fallbackPrice;

    return Container(
      width: _w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bundle.gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bundle.accent.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: bundle.accent.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    bundle.titleAr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: bundle.accent,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    'وفّر ${bundle.savePct}%',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Divider(
            color: Colors.white.withValues(alpha: 0.12),
            height: 1,
            indent: 12,
            endIndent: 12,
          ),
          const SizedBox(height: 8),

          // ── Contents ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _BundleRow(
                  icon: Icons.diamond_rounded,
                  color: const Color(0xFF38BDF8),
                  label: '${_fmt(bundle.gems)} جوهرة',
                ),
                _BundleRow(
                  icon: Icons.monetization_on_rounded,
                  color: const Color(0xFFFACC15),
                  label: '${_fmt(bundle.coins)} كوين',
                ),
                if (bundle.inv5050 > 0)
                  _BundleRow(
                    icon: Icons.filter_2_rounded,
                    color: const Color(0xFF3B82F6),
                    label: '×${bundle.inv5050}  50:50',
                  ),
                if (bundle.invAudience > 0)
                  _BundleRow(
                    icon: Icons.groups_rounded,
                    color: const Color(0xFFA855F7),
                    label: '×${bundle.invAudience}  جمهور',
                  ),
                if (bundle.invCall > 0)
                  _BundleRow(
                    icon: Icons.phone_rounded,
                    color: const Color(0xFF10B981),
                    label: '×${bundle.invCall}  صديق',
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Buy button ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            child: GestureDetector(
              onTap: iap.isPurchasing
                  ? null
                  : () => iap.buy(bundle.productId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: iap.isPurchasing
                      ? Colors.white12
                      : bundle.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: iap.isPurchasing
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        priceStr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: bundle.gradient.last.computeLuminance() > 0.3
                              ? const Color(0xFF1F2937)
                              : Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) {
      final s = n.toString();
      final parts = <String>[];
      int remaining = s.length;
      while (remaining > 0) {
        final start = remaining - 3 < 0 ? 0 : remaining - 3;
        parts.insert(0, s.substring(start, remaining));
        remaining = start;
      }
      return parts.join(',');
    }
    return n.toString();
  }
}

class _BundleRow extends StatelessWidget {
  const _BundleRow({
    required this.icon,
    required this.color,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.88),
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 5),
          Icon(icon, color: color, size: 13),
        ],
      ),
    );
  }
}

// ─── CURRENCY tab ─────────────────────────────────────────────────────────────

class _CurrencyTab extends StatefulWidget {
  const _CurrencyTab();

  @override
  State<_CurrencyTab> createState() => _CurrencyTabState();
}

class _CurrencyTabState extends State<_CurrencyTab> {
  // ── Coin purchase ──────────────────────────────────────────────────────────

  Future<void> _buyCoin(_CoinItem item) async {
    final appState = context.read<AppState>();
    if (appState.gems < item.gemCostInt) {
      _showInsufficientDialog(item.gemCostInt, appState.gems);
      return;
    }
    final confirmed = await _showConfirmDialog(item);
    if (!confirmed || !mounted) return;

    final ok = await context.read<NativeBridgeService>().buyCurrency(
      coinAmount: item.coinAmt,
      gemCost: item.gemCostInt,
    );
    if (!mounted) return;

    if (ok) {
      await context.read<AppState>().loadCurrency();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم إضافة ${item.displayAmount} كوين ✓'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('فشلت عملية الشراء، حاول مرة أخرى'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  Future<bool> _showConfirmDialog(_CoinItem item) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF152055),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.monetization_on_rounded,
                    color: Color(0xFFFACC15), size: 22),
                SizedBox(width: 8),
                Text(
                  'تأكيد الشراء',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'هل تريد شراء ${item.displayAmount} كوين؟',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.diamond_rounded,
                          color: Color(0xFF38BDF8), size: 22),
                      const SizedBox(width: 6),
                      Text(
                        item.gemCostLabel,
                        style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.w900,
                            fontSize: 22),
                      ),
                      const SizedBox(width: 4),
                      const Text('جوهرة',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء',
                    style: TextStyle(
                        color: Colors.white54, fontWeight: FontWeight.w700)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFACC15),
                  foregroundColor: const Color(0xFF1F2937),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('شراء',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showInsufficientDialog(int need, int have) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF152055),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFBBF24), size: 24),
            SizedBox(width: 8),
            Text('رصيد غير كافٍ',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
          ],
        ),
        content: Text(
          'تحتاج $need جوهرة ولديك $have فقط.\nاشتر جواهر من تبويب العملات.',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IapService>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GemSection(iap: iap),
          const SizedBox(width: 12),
          _CoinSection(onBuy: _buyCoin),
        ],
      ),
    );
  }
}

// ─── Gem section ──────────────────────────────────────────────────────────────

class _GemSection extends StatelessWidget {
  const _GemSection({required this.iap});
  final IapService iap;

  static const _cardW = 86.0;
  static const _cardH = 116.0;
  static const _gap   = 6.0;

  @override
  Widget build(BuildContext context) {
    final regular = _kGemItems.where((i) => !i.isMega).toList();
    final mega    = _kGemItems.where((i) => i.isMega).toList();
    final row1 = regular.take(3).toList();
    final row2 = regular.skip(3).take(3).toList();
    const gridH = _cardH * 2 + _gap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionHeader(title: 'جواهر', color: const Color(0xFF1D4ED8)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GemRow(items: row1, iap: iap),
                if (row2.isNotEmpty) ...[
                  const SizedBox(height: _gap),
                  _GemRow(items: row2, iap: iap),
                ],
              ],
            ),
            if (mega.isNotEmpty) ...[
              const SizedBox(width: _gap),
              _MegaGemCard(
                item: mega.first,
                iap: iap,
                height: gridH,
                width: _cardW + 28,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _GemRow extends StatelessWidget {
  const _GemRow({required this.items, required this.iap});
  final List<_GemItem> items;
  final IapService iap;

  static const _cardW = 86.0;
  static const _cardH = 116.0;
  static const _gap   = 6.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          _GemCard(item: items[i], iap: iap, width: _cardW, height: _cardH),
        ],
      ],
    );
  }
}

class _GemCard extends StatelessWidget {
  const _GemCard({
    required this.item,
    required this.iap,
    required this.width,
    required this.height,
  });
  final _GemItem item;
  final IapService iap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final priceStr =
        iap.products[item.productId]?.price ?? item.fallbackPrice;

    return GestureDetector(
      onTap: iap.isPurchasing ? null : () => iap.buy(item.productId),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Icon(
                  Icons.diamond_rounded,
                  color: const Color(0xFF93C5FD),
                  size: 32,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                item.amount,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            _IapPriceBar(label: priceStr),
          ],
        ),
      ),
    );
  }
}

class _MegaGemCard extends StatelessWidget {
  const _MegaGemCard({
    required this.item,
    required this.iap,
    required this.height,
    required this.width,
  });
  final _GemItem item;
  final IapService iap;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final priceStr =
        iap.products[item.productId]?.price ?? item.fallbackPrice;

    return GestureDetector(
      onTap: iap.isPurchasing ? null : () => iap.buy(item.productId),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x663B82F6),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.diamond_rounded,
                    color: Color(0xFF93C5FD), size: 48),
                const SizedBox(height: 8),
                Text(
                  item.amount,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                _IapPriceBar(label: priceStr),
              ],
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(1, 2))
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('MEGA',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5)),
                  Text('PACK',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IapPriceBar extends StatelessWidget {
  const _IapPriceBar({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xFF0369A1),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Coin section ─────────────────────────────────────────────────────────────

class _CoinSection extends StatelessWidget {
  const _CoinSection({required this.onBuy});
  final void Function(_CoinItem) onBuy;

  @override
  Widget build(BuildContext context) {
    final row1 = _kCoinItems.take(3).toList();
    final row2 = _kCoinItems.skip(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionHeader(title: 'عملات', color: const Color(0xFFB45309)),
        const SizedBox(height: 6),
        _CoinRow(items: row1, onBuy: onBuy),
        if (row2.isNotEmpty) ...[
          const SizedBox(height: 6),
          _CoinRow(items: row2, onBuy: onBuy),
        ],
      ],
    );
  }
}

class _CoinRow extends StatelessWidget {
  const _CoinRow({required this.items, required this.onBuy});
  final List<_CoinItem> items;
  final void Function(_CoinItem) onBuy;

  static const _cardW = 86.0;
  static const _cardH = 116.0;
  static const _gap   = 6.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          _CoinCard(item: items[i], onBuy: onBuy, width: _cardW, height: _cardH),
        ],
      ],
    );
  }
}

class _CoinCard extends StatelessWidget {
  const _CoinCard({
    required this.item,
    required this.onBuy,
    required this.width,
    required this.height,
  });
  final _CoinItem item;
  final void Function(_CoinItem) onBuy;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onBuy(item),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Icon(
                  Icons.monetization_on_rounded,
                  color: const Color(0xFFFDE68A),
                  size: 32,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                item.displayAmount,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            _GemPriceBar(label: item.gemCostLabel),
          ],
        ),
      ),
    );
  }
}

class _GemPriceBar extends StatelessWidget {
  const _GemPriceBar({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xFF0369A1),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diamond_rounded, size: 11, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared section header ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── POWERUPS tab ─────────────────────────────────────────────────────────────

class _PowerupsTab extends StatefulWidget {
  const _PowerupsTab();

  @override
  State<_PowerupsTab> createState() => _PowerupsTabState();
}

class _PowerupsTabState extends State<_PowerupsTab> {
  Map<String, int> _inventory = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    try {
      final inv =
          await context.read<NativeBridgeService>().getInventory();
      if (mounted) setState(() { _inventory = inv; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _count(String type) {
    if (type == '5050')     return _inventory['inv5050']     ?? 0;
    if (type == 'audience') return _inventory['invAudience'] ?? 0;
    return                         _inventory['invCall']     ?? 0;
  }

  Future<void> _purchase(
    _PowerupDef def,
    int qty,
    String payWith,
    int cost,
  ) async {
    final appState = context.read<AppState>();

    if (payWith == 'coins' && appState.coins < cost) {
      _showInsufficientDialog('كوينز', appState.coins, cost);
      return;
    }
    if (payWith == 'gems' && appState.gems < cost) {
      _showInsufficientDialog('جواهر', appState.gems, cost);
      return;
    }

    final confirmed = await _showConfirmDialog(def, qty, payWith, cost);
    if (!confirmed || !mounted) return;

    final success = await context.read<NativeBridgeService>().buyPowerUp(
      type: def.type,
      quantity: qty,
      payWith: payWith,
      cost: cost,
    );
    if (!mounted) return;

    if (success) {
      await context.read<AppState>().loadCurrency();
      await _loadInventory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم شراء ${def.nameAr} ×$qty بنجاح ✓'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('فشلت عملية الشراء، حاول مرة أخرى'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  Future<bool> _showConfirmDialog(
    _PowerupDef def,
    int qty,
    String payWith,
    int cost,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF152055),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: def.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: def.color.withValues(alpha: 0.5)),
                  ),
                  child: Icon(def.icon, color: def.color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    def.nameAr,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'هل تريد شراء ×$qty من ${def.nameAr}؟',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (payWith == 'coins') ...[
                        const Icon(Icons.monetization_on_rounded,
                            color: Color(0xFFFACC15), size: 22),
                        const SizedBox(width: 6),
                        Text('$cost',
                            style: const TextStyle(
                                color: Color(0xFFFACC15),
                                fontWeight: FontWeight.w900,
                                fontSize: 22)),
                        const SizedBox(width: 4),
                        const Text('كوين',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 13)),
                      ] else ...[
                        const Icon(Icons.diamond_rounded,
                            color: Color(0xFF38BDF8), size: 22),
                        const SizedBox(width: 6),
                        Text('$cost',
                            style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontWeight: FontWeight.w900,
                                fontSize: 22)),
                        const SizedBox(width: 4),
                        const Text('جوهرة',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء',
                    style: TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.w700)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: def.color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('شراء',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showInsufficientDialog(
      String currency, int have, int need) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF152055),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFBBF24), size: 24),
            SizedBox(width: 8),
            Text('رصيد غير كافٍ',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
          ],
        ),
        content: Text(
          'تحتاج $need $currency ولديك $have فقط.\nاشتر المزيد من تبويب العملات.',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFACC15)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      itemCount: _kPowerups.length,
      itemBuilder: (_, i) => _PowerupCard(
        def: _kPowerups[i],
        count: _count(_kPowerups[i].type),
        onBuy: _purchase,
      ),
    );
  }
}

// ─── Powerup card ─────────────────────────────────────────────────────────────

class _PowerupCard extends StatelessWidget {
  const _PowerupCard({
    required this.def,
    required this.count,
    required this.onBuy,
  });
  final _PowerupDef def;
  final int count;
  final Future<void> Function(_PowerupDef, int, String, int) onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: def.bgColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: def.color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: def.color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: def.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: def.color.withValues(alpha: 0.5)),
                  ),
                  child: Icon(def.icon, color: def.color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def.nameAr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: def.color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        def.descAr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: count > 0
                        ? def.color.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: count > 0
                          ? def.color.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: count > 0 ? def.color : Colors.white38,
                        ),
                      ),
                      Text(
                        'مخزون',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: def.color.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 10),

          // Buy with Coins
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: Color(0xFFFACC15), size: 14),
                    const SizedBox(width: 5),
                    const Text(
                      'شراء بالكوينز',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFACC15)),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: def.coinTiers
                      .map((t) => Expanded(
                            child: _BuyButton(
                              qty: t.qty,
                              cost: t.cost,
                              payWith: 'coins',
                              color: const Color(0xFFFACC15),
                              icon: Icons.monetization_on_rounded,
                              onTap: () =>
                                  onBuy(def, t.qty, 'coins', t.cost),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.diamond_rounded,
                        color: Color(0xFF38BDF8), size: 14),
                    const SizedBox(width: 5),
                    const Text(
                      'شراء بالجواهر',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF38BDF8)),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: def.gemTiers
                      .map((t) => Expanded(
                            child: _BuyButton(
                              qty: t.qty,
                              cost: t.cost,
                              payWith: 'gems',
                              color: const Color(0xFF38BDF8),
                              icon: Icons.diamond_rounded,
                              onTap: () =>
                                  onBuy(def, t.qty, 'gems', t.cost),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Buy button ───────────────────────────────────────────────────────────────

class _BuyButton extends StatelessWidget {
  const _BuyButton({
    required this.qty,
    required this.cost,
    required this.payWith,
    required this.color,
    required this.icon,
    required this.onTap,
  });
  final int qty;
  final int cost;
  final String payWith;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(
              '×$qty',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: color),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 11, color: color.withValues(alpha: 0.8)),
                const SizedBox(width: 2),
                Text(
                  '$cost',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
