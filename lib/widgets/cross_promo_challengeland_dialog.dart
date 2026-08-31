import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/cross_promo_service.dart';

class CrossPromoChallengeLandDialog extends StatefulWidget {
  const CrossPromoChallengeLandDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (dialogCtx) => const CrossPromoChallengeLandDialog(),
    );
  }

  @override
  State<CrossPromoChallengeLandDialog> createState() =>
      _CrossPromoChallengeLandDialogState();
}

class _CrossPromoChallengeLandDialogState
    extends State<CrossPromoChallengeLandDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CrossPromoService>().checkInstallation();
      context.read<CrossPromoService>().recordImpression();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promoService = context.watch<CrossPromoService>();
    final isInstalled = promoService.isInstalled;
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
                Color(0xFF0D1B3E),
                Color(0xFF060D20),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.35),
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
                // Glowing background ambient light
                Positioned(
                  top: -60,
                  right: -60,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0284C7).withValues(alpha: 0.22),
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
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
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
                      // Header: Game Title, Rating, Badges & Close Button
                      _buildHeader(context, isCompact),
                      SizedBox(height: isCompact ? 8 : 12),

                      // Modes & Features Showcase
                      Expanded(
                        child: _buildModesGrid(isCompact),
                      ),
                      SizedBox(height: isCompact ? 8 : 12),

                      // Action CTA Button
                      _buildActionButton(context, promoService, isInstalled, isCompact),
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
        // Game Icon Emblem
        Container(
          width: isCompact ? 44 : 52,
          height: isCompact ? 44 : 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.sports_kabaddi_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Title and description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Flexible(
                    child: Text(
                      'أرض التحدي - أونلاين ⚔️',
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
                          '4.9',
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
                'لعبة المسابقات والتحديات الحية الأقوى! 6 أطوار لعب تنافسية ومكافآت يومية',
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

        // Close Button
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

  Widget _buildModesGrid(bool isCompact) {
    final modes = [
      _GameModeInfo(
        title: 'وضع البرق ⚡',
        desc: 'أجب بأقصى سرعة قبل نفاد الثواني',
        color: const Color(0xFF38BDF8),
        icon: Icons.bolt_rounded,
      ),
      _GameModeInfo(
        title: 'وضع البقاء 💪',
        desc: 'صمود بدون أي خطأ لأطول فترة',
        color: const Color(0xFF10B981),
        icon: Icons.shield_rounded,
      ),
      _GameModeInfo(
        title: 'وضع المعركة ⚔️',
        desc: 'مواجهة مباشرة 1v1 في الوقت الحقيقي',
        color: const Color(0xFFF59E0B),
        icon: Icons.sports_martial_arts_rounded,
      ),
      _GameModeInfo(
        title: 'فريق المعركة 🤝',
        desc: 'تعاون جماعي 2v2 وسحق المنافسين',
        color: const Color(0xFFA855F7),
        icon: Icons.group_rounded,
      ),
      _GameModeInfo(
        title: 'وضع السلسلة 🔗',
        desc: 'جولات متتالية لحسم بطل التحدي',
        color: const Color(0xFFEC4899),
        icon: Icons.military_tech_rounded,
      ),
      _GameModeInfo(
        title: 'وضع الإقصاء 🏆',
        desc: 'خطأ واحد يُخرجك والرابح الأخير يفوز',
        color: const Color(0xFFEF4444),
        icon: Icons.emoji_events_rounded,
      ),
    ];

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: modes.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: isCompact ? 6 : 10,
        mainAxisSpacing: isCompact ? 6 : 8,
        childAspectRatio: isCompact ? 2.4 : 2.2,
      ),
      itemBuilder: (context, index) {
        final mode = modes[index];
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 10,
            vertical: isCompact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: mode.color.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isCompact ? 28 : 34,
                height: isCompact ? 28 : 34,
                decoration: BoxDecoration(
                  color: mode.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(mode.icon, color: mode.color, size: isCompact ? 16 : 19),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mode.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 11 : 12,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      mode.desc,
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

  Widget _buildActionButton(
    BuildContext context,
    CrossPromoService promoService,
    bool isInstalled,
    bool isCompact,
  ) {
    final glow = 0.4 + _animCtrl.value * 0.45;
    final label = isInstalled ? 'فتح اللعبة واللعب الآن 🎮' : 'تثبيت مجاناً من Google Play 🚀';
    final colors = isInstalled
        ? const [Color(0xFF10B981), Color(0xFF059669)]
        : const [Color(0xFF0284C7), Color(0xFF2563EB), Color(0xFF7C3AED)];
    final glowColor = isInstalled ? const Color(0xFF10B981) : const Color(0xFF38BDF8);

    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, _) {
        return GestureDetector(
          onTap: () async {
            await promoService.launchChallengeLand();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Container(
            width: double.infinity,
            height: isCompact ? 42 : 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: colors,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: glow),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isInstalled ? Icons.play_arrow_rounded : Icons.download_rounded,
                  color: Colors.white,
                  size: isCompact ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
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

class _GameModeInfo {
  _GameModeInfo({
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
