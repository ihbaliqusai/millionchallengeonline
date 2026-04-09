import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

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

// ─── Static data ──────────────────────────────────────────────────────────────

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
                  _PlaceholderTab(label: 'MARKET'),
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

  static const _labels = ['OFFERS', 'CURRENCY', 'MARKET', 'UNITS'];

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

// ─── Placeholder tabs ─────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.white.withValues(alpha: 0.3),
          letterSpacing: 2,
        ),
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

// ─── Section column ───────────────────────────────────────────────────────────

class _SectionColumn extends StatelessWidget {
  const _SectionColumn({required this.data});
  final _SectionData data;

  static const _cardW = 86.0;
  static const _cardH = 116.0;
  static const _gap = 6.0;

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
              _MegaCard(
                item: megaList.first,
                data: data,
                height: gridHeight,
                width: _cardW + 28,
              ),
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
  static const _gap = 6.0;

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

// ─── Section header ───────────────────────────────────────────────────────────

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

// ─── Regular item card ────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.data,
    required this.width,
    required this.height,
  });
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: data.cardGradient,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Icon(data.icon, color: data.iconColor, size: 32),
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
            if (item.leftToday != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'Left today: ${item.leftToday}',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            _PriceBar(item: item),
          ],
        ),
      ),
    );
  }
}

// ─── Mega card ────────────────────────────────────────────────────────────────

class _MegaCard extends StatelessWidget {
  const _MegaCard({
    required this.item,
    required this.data,
    required this.height,
    required this.width,
  });
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
                colors: [
                  data.cardGradient[0].withValues(alpha: 0.9),
                  data.cardGradient[1],
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: data.cardGradient[0].withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(data.icon, color: data.iconColor, size: 48),
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
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2)),
                ],
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

// ─── Price bar ────────────────────────────────────────────────────────────────

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
        content = Text(
          item.priceLabel,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
        );
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
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Center(child: content),
    );
  }
}
