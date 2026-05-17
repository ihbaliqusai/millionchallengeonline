import 'package:flutter/material.dart';

import '../../../models/campaign_stage.dart';
import '../../../models/stage_progress.dart';

class StageNode extends StatelessWidget {
  const StageNode({
    super.key,
    required this.stage,
    required this.progress,
    required this.locked,
    required this.completed,
    required this.current,
    required this.onTap,
    required this.animation,
  });

  final CampaignStage stage;
  final StageProgress progress;
  final bool locked;
  final bool completed;
  final bool current;
  final VoidCallback onTap;
  final Animation<double> animation;

  static const double hitWidth = 88;

  static double centerOffsetFor(CampaignStage stage) {
    return _isBossStage(stage) ? 59 : 55;
  }

  static bool _isBossStage(CampaignStage stage) {
    return stage.campaignMode == CampaignMode.bossBattle ||
        stage.order % 10 == 0;
  }

  @override
  Widget build(BuildContext context) {
    final boss = _isBossStage(stage);
    final buttonSize = boss ? 62.0 : 56.0;
    final buttonTop = boss ? 23.0 : 22.0;
    final starCount = completed ? progress.stars.clamp(0, 3) : 0;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final pulse = current ? 0.42 + animation.value * 0.36 : 0.0;
        return Transform.scale(
          scale: current ? 1 + animation.value * 0.045 : 1,
          child: Container(
            width: hitWidth,
            height: boss ? 98 : 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                if (current)
                  BoxShadow(
                    color: const Color(0xFFFFF1A8).withValues(alpha: pulse),
                    blurRadius: 22,
                    spreadRadius: 3,
                  ),
                if (current)
                  BoxShadow(
                    color:
                        const Color(0xFF38BDF8).withValues(alpha: pulse * 0.5),
                    blurRadius: 26,
                    spreadRadius: 5,
                  ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: locked ? 0.38 : 0.30),
                  blurRadius: 11,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(34),
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              if (starCount > 0)
                Positioned(
                  top: 0,
                  child: _StageStarImage(stars: starCount, boss: boss),
                ),
              Positioned(
                top: buttonTop,
                child: _StageButtonImage(
                  stage: stage,
                  boss: boss,
                  locked: locked,
                  size: buttonSize,
                ),
              ),
              if (locked)
                Positioned(
                  top: buttonTop + buttonSize * 0.66,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF24313F),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE0F2FE),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: Colors.white.withValues(alpha: 0.92),
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageButtonImage extends StatelessWidget {
  const _StageButtonImage({
    required this.stage,
    required this.boss,
    required this.locked,
    required this.size,
  });

  final CampaignStage stage;
  final bool boss;
  final bool locked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = boss
        ? 'assets/images/campaign/ui/stage_button_green.png'
        : 'assets/images/campaign/ui/stage_button_blue.png';
    final button = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: locked ? 0.56 : 1,
          child: locked
              ? ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: button,
                )
              : button,
        ),
        SizedBox(
          width: size * 0.56,
          height: size * 0.38,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${stage.order}',
                  style: TextStyle(
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 3.8
                      ..color = Colors.black.withValues(alpha: 0.34),
                  ),
                ),
                Text(
                  '${stage.order}',
                  style: TextStyle(
                    color: locked
                        ? Colors.white.withValues(alpha: 0.78)
                        : Colors.white,
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StageStarImage extends StatelessWidget {
  const _StageStarImage({
    required this.stars,
    required this.boss,
  });

  final int stars;
  final bool boss;

  @override
  Widget build(BuildContext context) {
    final safeStars = stars.clamp(1, 3);
    return Image.asset(
      'assets/images/campaign/ui/star_$safeStars.png',
      width: boss ? 66 : 60,
      height: boss ? 31 : 28,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
