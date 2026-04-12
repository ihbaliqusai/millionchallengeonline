import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../services/native_bridge_service.dart';

// ─── Currency section models ──────────────────────────────────────────────────

enum _PriceType { free, jod, gems }

class _Item {
  const _Item({
    required this.amount,
    required this.priceLabel,
    required this.priceType,
    this.isMega = false,
    this.leftToday,
  });
  final String amount;
  final String priceLabel;
  final _PriceType priceType;
  final bool isMega;
  final int? leftToday;
}

class _SectionData {
  const _SectionData({
    required this.title,
    required this.headerColor,
    required this.cardGradient,
    required this.icon,
    required this.iconColor,
    required this.items,
  });
  final String title;
  final Color headerColor;
  final List<Color> cardGradient;
  final IconData icon;
  final Color iconColor;
  final List<_Item> items;
}

const _kSections = [
  _SectionData(
    title: 'Gems',
    headerColor: Color(0xFF1D4ED8),
    cardGradient: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
    icon: Icons.diamond_rounded,
    iconColor: Color(0xFF93C5FD),
    items: [
      _Item(amount: '10',     priceLabel: 'FREE',       priceType: _PriceType.free, leftToday: 3),
      _Item(amount: '80',     priceLabel: 'JOD 0.300',  priceType: _PriceType.jod),
      _Item(amount: '500',    priceLabel: 'JOD 1.550',  priceType: _PriceType.jod),
      _Item(amount: '1,200',  priceLabel: 'JOD 3.100',  priceType: _PriceType.jod),
      _Item(amount: '2,500',  priceLabel: 'JOD 6.200',  priceType: _PriceType.jod),
      _Item(amount: '6,500',  priceLabel: 'JOD 15.550', priceType: _PriceType.jod),
      _Item(amount: '14,000', priceLabel: 'JOD 31.000', priceType: _PriceType.jod, isMega: true),
    ],
  ),
  _SectionData(
    title: 'Wild Cards',
    headerColor: Color(0xFF6D28D9),
    cardGradient: [Color(0xFF8B5CF6), Color(0xFF5B21B6)],
    icon: Icons.person_rounded,
    iconColor: Color(0xFFC4B5FD),
    items: [
      _Item(amount: '10',    priceLabel: 'FREE',       priceType: _PriceType.free, leftToday: 3),
      _Item(amount: '50',    priceLabel: 'JOD 0.300',  priceType: _PriceType.jod),
      _Item(amount: '400',   priceLabel: 'JOD 1.550',  priceType: _PriceType.jod),
      _Item(amount: '950',   priceLabel: 'JOD 3.100',  priceType: _PriceType.jod),
      _Item(amount: '2,100', priceLabel: 'JOD 6.200',  priceType: _PriceType.jod),
      _Item(amount: '5,500', priceLabel: 'JOD 15.550', priceType: _PriceType.jod),
    ],
  ),
  _SectionData(
    title: 'Coins',
    headerColor: Color(0xFFB45309),
    cardGradient: [Color(0xFFF59E0B), Color(0xFFB45309)],
    icon: Icons.monetization_on_rounded,
    iconColor: Color(0xFFFDE68A),
    items: [
      _Item(amount: '100',     priceLabel: 'FREE',   priceType: _PriceType.free, leftToday: 3),
      _Item(amount: '500',     priceLabel: '50',     priceType: _PriceType.gems),
      _Item(amount: '2,200',   priceLabel: '200',    priceType: _PriceType.gems),
      _Item(amount: '9,600',   priceLabel: '800',    priceType: _PriceType.gems),
      _Item(amount: '34,500',  priceLabel: '3,000',  priceType: _PriceType.gems),
      _Item(amount: '120,000', priceLabel: '10,000', priceType: _PriceType.gems),
    ],
  ),
];

// ─── Powerup models ───────────────────────────────────────────────────────────

class _Tier {
  final int qty;
  final int cost;
  const _Tier(this.qty, this.cost);
}

class _PowerupDef {
  final String type;       // "5050" | "audience" | "call"
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
    coinTiers: [_Tier(1, 200), _Tier(3, 500), _Tier(5, 750)],
    gemTiers:  [_Tier(1, 3),   _Tier(3, 7),   _Tier(5, 10)],
  ),
  _PowerupDef(
    type: 'audience',
    nameAr: 'استشارة الجمهور',
    descAr: 'يستطلع رأي الجمهور ويُظهر نسب التصويت',
    icon: Icons.groups_rounded,
    color: Color(0xFFA855F7),
    bgColor: Color(0xFF4C1D95),
    coinTiers: [_Tier(1, 300), _Tier(3, 750),  _Tier(5, 1100)],
    gemTiers:  [_Tier(1, 5),   _Tier(3, 12),   _Tier(5, 18)],
  ),
  _PowerupDef(
    type: 'call',
    nameAr: 'اتصال بصديق',
    descAr: 'يتصل بخبير يعطيك تلميحاً للإجابة الصحيحة',
    icon: Icons.phone_rounded,
    color: Color(0xFF10B981),
    bgColor: Color(0xFF064E3B),
    coinTiers: [_Tier(1, 400), _Tier(3, 1000), _Tier(5, 1500)],
    gemTiers:  [_Tier(1, 7),   _Tier(3, 18),   _Tier(5, 25)],
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
    _tabCtrl = TabController(length: 4, vsync: this, initialIndex: 1);
    _tabCtrl.addListener(() => setState(() {}));
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
                  _PlaceholderTab(label: 'OFFERS'),
                  _CurrencyTab(),
                  _PowerupsTab(),
                  _PlaceholderTab(label: 'UNITS'),
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
          _Chip(icon: Icons.monetization_on_rounded, color: const Color(0xFFFACC15), label: appState.coins.toString()),
          const SizedBox(width: 6),
          _Chip(icon: Icons.diamond_rounded,         color: const Color(0xFF38BDF8), label: appState.gems.toString()),
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
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Bottom tab bar ───────────────────────────────────────────────────────────

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({required this.controller});
  final TabController controller;

  static const _labels = ['OFFERS', 'CURRENCY', 'POWERUPS', 'UNITS'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF091030),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final sel = controller.index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFFFACC15) : const Color(0xFF1E3A8A).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? const Color(0xFFFDE68A) : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  _labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: sel ? const Color(0xFF1F2937) : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Placeholder tab ──────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.3), letterSpacing: 2),
      ),
    );
  }
}

// ─── Currency tab ─────────────────────────────────────────────────────────────

class _CurrencyTab extends StatelessWidget {
  const _CurrencyTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < _kSections.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _SectionColumn(data: _kSections[i]),
          ],
        ],
      ),
    );
  }
}

class _SectionColumn extends StatelessWidget {
  const _SectionColumn({required this.data});
  final _SectionData data;

  static const _cardW = 86.0;
  static const _cardH = 116.0;
  static const _gap   = 6.0;

  @override
  Widget build(BuildContext context) {
    final regular = data.items.where((i) => !i.isMega).toList();
    final megaList = data.items.where((i) => i.isMega).toList();
    final row1 = regular.take(3).toList();
    final row2 = regular.skip(3).take(3).toList();
    final hasMega = megaList.isNotEmpty;
    const gridHeight = _cardH * 2 + _gap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionHeader(title: data.title, color: data.headerColor),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CardRow(items: row1, data: data),
                if (row2.isNotEmpty) ...[
                  const SizedBox(height: _gap),
                  _CardRow(items: row2, data: data),
                ],
              ],
            ),
            if (hasMega) ...[
              const SizedBox(width: _gap),
              _MegaCard(item: megaList.first, data: data, height: gridHeight, width: _cardW + 28),
            ],
          ],
        ),
      ],
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.items, required this.data});
  final List<_Item> items;
  final _SectionData data;

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
          _ItemCard(item: items[i], data: data, width: _cardW, height: _cardH),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.data, required this.width, required this.height});
  final _Item item;
  final _SectionData data;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: data.cardGradient),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Column(
          children: [
            Expanded(child: Center(child: Icon(data.icon, color: data.iconColor, size: 32))),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(item.amount, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            if (item.leftToday != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('Left today: ${item.leftToday}', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w700)),
              ),
            _PriceBar(item: item),
          ],
        ),
      ),
    );
  }
}

class _MegaCard extends StatelessWidget {
  const _MegaCard({required this.item, required this.data, required this.height, required this.width});
  final _Item item;
  final _SectionData data;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [data.cardGradient[0].withValues(alpha: 0.9), data.cardGradient[1]],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
              boxShadow: [BoxShadow(color: data.cardGradient[0].withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(data.icon, color: data.iconColor, size: 48),
                const SizedBox(height: 8),
                Text(item.amount, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 4),
                _PriceBar(item: item),
              ],
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2))],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('MEGA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                  Text('PACK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBar extends StatelessWidget {
  const _PriceBar({required this.item});
  final _Item item;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Widget content;

    switch (item.priceType) {
      case _PriceType.free:
        bg = const Color(0xFF16A34A);
        content = const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.diamond_rounded, size: 11, color: Colors.white),
            SizedBox(width: 3),
            Text('FREE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        );
      case _PriceType.jod:
        bg = const Color(0xFF0369A1);
        content = Text(item.priceLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white));
      case _PriceType.gems:
        bg = const Color(0xFF0369A1);
        content = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.diamond_rounded, size: 11, color: Colors.white),
            const SizedBox(width: 3),
            Text(item.priceLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
      ),
      child: Center(child: content),
    );
  }
}

// ─── Powerups tab ─────────────────────────────────────────────────────────────

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
      final inv = await context.read<NativeBridgeService>().getInventory();
      if (mounted) setState(() { _inventory = inv; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _count(String type) {
    if (type == '5050')     return _inventory['inv5050']    ?? 0;
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

    // Balance check before showing dialog
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
      type: def.type, quantity: qty, payWith: payWith, cost: cost,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('فشلت عملية الشراء، حاول مرة أخرى'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  Future<bool> _showConfirmDialog(
    _PowerupDef def, int qty, String payWith, int cost,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF152055),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: def.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: def.color.withValues(alpha: 0.5)),
              ),
              child: Icon(def.icon, color: def.color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(def.nameAr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل تريد شراء ×$qty من ${def.nameAr}؟',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (payWith == 'coins') ...[
                    const Icon(Icons.monetization_on_rounded, color: Color(0xFFFACC15), size: 22),
                    const SizedBox(width: 6),
                    Text('$cost', style: const TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.w900, fontSize: 22)),
                    const SizedBox(width: 4),
                    const Text('كوين', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ] else ...[
                    const Icon(Icons.diamond_rounded, color: Color(0xFF38BDF8), size: 22),
                    const SizedBox(width: 6),
                    Text('$cost', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w900, fontSize: 22)),
                    const SizedBox(width: 4),
                    const Text('جوهرة', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: def.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('شراء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showInsufficientDialog(String currency, int have, int need) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF152055),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFBBF24), size: 24),
            SizedBox(width: 8),
            Text('رصيد غير كافٍ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: Text(
          'تحتاج $need $currency ولديك $have فقط.\nاشحن رصيدك من تبويب CURRENCY.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)));
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
        boxShadow: [BoxShadow(color: def.color.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: def.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: def.color.withValues(alpha: 0.5)),
                  ),
                  child: Icon(def.icon, color: def.color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(def.nameAr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: def.color)),
                      const SizedBox(height: 3),
                      Text(def.descAr, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.55))),
                    ],
                  ),
                ),
                // Inventory badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                          fontSize: 18, fontWeight: FontWeight.w900,
                          color: count > 0 ? def.color : Colors.white38,
                        ),
                      ),
                      Text(
                        'مخزون',
                        style: TextStyle(fontSize: 8, color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Divider ────────────────────────────────────────────────────────
          Divider(color: def.color.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 10),

          // ── Buy with Coins ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.monetization_on_rounded, color: Color(0xFFFACC15), size: 14),
                    SizedBox(width: 5),
                    Text('شراء بالكوينز', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFFACC15))),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: def.coinTiers.map((t) => Expanded(
                    child: _BuyButton(
                      qty: t.qty,
                      cost: t.cost,
                      payWith: 'coins',
                      color: const Color(0xFFFACC15),
                      icon: Icons.monetization_on_rounded,
                      onTap: () => onBuy(def, t.qty, 'coins', t.cost),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 10),

                // ── Buy with Gems ─────────────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.diamond_rounded, color: Color(0xFF38BDF8), size: 14),
                    const SizedBox(width: 5),
                    const Text('شراء بالجواهر', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF38BDF8))),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: def.gemTiers.map((t) => Expanded(
                    child: _BuyButton(
                      qty: t.qty,
                      cost: t.cost,
                      payWith: 'gems',
                      color: const Color(0xFF38BDF8),
                      icon: Icons.diamond_rounded,
                      onTap: () => onBuy(def, t.qty, 'gems', t.cost),
                    ),
                  )).toList(),
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
            Text('×$qty', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 11, color: color.withValues(alpha: 0.8)),
                const SizedBox(width: 2),
                Text('$cost', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.8))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
