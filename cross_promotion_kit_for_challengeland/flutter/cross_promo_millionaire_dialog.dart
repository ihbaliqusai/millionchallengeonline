import 'dart:math' as math;
import 'package:flutter/material.dart';

class CrossPromoMillionaireDialog extends StatefulWidget {
  const CrossPromoMillionaireDialog({
    super.key,
    this.onLaunch,
  });

  final Future<void> Function()? onLaunch;

  static const String millionairePackageName = 'net.androidgaming.millionaire2024';
  static const String millionairePlayStoreUrl =
      'https://play.google.com/store/apps/details?id=net.androidgaming.millionaire2024';

  static Future<void> show(
    BuildContext context, {
    Future<void> Function()? onLaunch,
    bool isInstalled = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (dialogCtx) => CrossPromoMillionaireDialog(
        onLaunch: onLaunch,
      ),
    );
  }

  @override
  State<CrossPromoMillionaireDialog> createState() =>
      _CrossPromoMillionaireDialogState();
}

class _CrossPromoMillionaireDialogState
    extends State<CrossPromoMillionaireDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 380;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: math.min(size.width * 0.88, 700.0),
          height: math.min(size.height * 0.90, 420.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E1435),
                Color(0xFF0A0618),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD97706).withValues(alpha: 0.35),
                blurRadius: 32,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Glowing golden ambient light
                Positioned(
                  top: -60,
                  right: -60,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: -80,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                    ),
                  ),
                ),

                // Dialog Content
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    isCompact ? 10 : 14,
                    18,
                    isCompact ? 10 : 14,
                  ),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(context, isCompact),
                      SizedBox(height: isCompact ? 8 : 12),

                      // Features Showcase
                      Expanded(
                        child: _buildFeaturesGrid(isCompact),
                      ),
                      SizedBox(height: isCompact ? 8 : 12),

                      // Action Button
                      _buildActionButton(context, isCompact),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isCompact) {
    return Row(
      children: [
        Container(
          width: isCompact ? 44 : 52,
          height: isCompact ? 44 : 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFACC15), Color(0xFFD97706)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFACC15).withValues(alpha: 0.4),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFF3E1F00),
              size: 30,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Flexible(
                    child: Text(
                      'تحدي المليونير - أونلاين 🏆',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 14),
                        SizedBox(width: 2),
                        Text(
                          '4.8',
                          style: TextStyle(
                            color: Color(0xFFFACC15),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'أضخم لعبة معلومات عربية! أكثر من 50,000 سؤال ومباريات جماعية حية',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(bool isCompact) {
    final features = [
      _PromoItem(
        title: '50,000+ سؤال 📚',
        desc: 'موسوعة أسئلة ضخمة ومتجددة باستمرار',
        color: const Color(0xFFFACC15),
        icon: Icons.auto_stories_rounded,
      ),
      _PromoItem(
        title: 'تحدي المليون 💰',
        desc: 'تسلق شجرة الجوائز وصولاً للمليون',
        color: const Color(0xFF34D399),
        icon: Icons.monetization_on_rounded,
      ),
      _PromoItem(
        title: 'معارك غرف أونلاين 🌐',
        desc: 'أنشئ غرفتك وتحدى أصدقاءك في أي مكان',
        color: const Color(0xFF60A5FA),
        icon: Icons.hub_rounded,
      ),
      _PromoItem(
        title: 'رحلة الحملة والمراحل 🗺️',
        desc: 'عشرات العوالم والمراحل المتدرجة',
        color: const Color(0xFFA78BFA),
        icon: Icons.explore_rounded,
      ),
      _PromoItem(
        title: 'وسائل مساعدة ذكية 💡',
        desc: 'حذف إجابتين، مساعدة الجمهور، واتصال بصديق',
        color: const Color(0xFFF472B6),
        icon: Icons.lightbulb_rounded,
      ),
      _PromoItem(
        title: 'لعب أوفلاين كامل 🚀',
        desc: 'العب واستمتع حتى بدون اتصال بالإنترنت',
        color: const Color(0xFFFB923C),
        icon: Icons.offline_bolt_rounded,
      ),
    ];

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: features.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: isCompact ? 6 : 10,
        mainAxisSpacing: isCompact ? 6 : 8,
        childAspectRatio: isCompact ? 2.4 : 2.2,
      ),
      itemBuilder: (context, index) {
        final item = features[index];
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 10,
            vertical: isCompact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.color.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isCompact ? 28 : 34,
                height: isCompact ? 28 : 34,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: isCompact ? 16 : 19),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 11 : 12,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.desc,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: isCompact ? 9 : 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, bool isCompact) {
    final glow = 0.4 + _animCtrl.value * 0.45;

    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, _) {
        return GestureDetector(
          onTap: () async {
            if (widget.onLaunch != null) {
              await widget.onLaunch!();
            }
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Container(
            width: double.infinity,
            height: isCompact ? 42 : 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
              ),
              border: Border.all(
                color: const Color(0xFFFDE68A),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: glow),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: isCompact ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'تثبيت لعبة تحدي المليونير مجاناً 🚀',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PromoItem {
  _PromoItem({
    required this.title,
    required this.desc,
    required this.color,
    required this.icon,
  });

  final String title;
  final String desc;
  final Color color;
  final IconData icon;
}
