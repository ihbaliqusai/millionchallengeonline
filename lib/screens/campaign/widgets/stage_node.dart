import 'package:flutter/material.dart';

import '../../../models/campaign_stage.dart';
import '../../../models/stage_progress.dart';
import 'star_rating_view.dart';

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

  static const double hitWidth = 84;

  static double centerOffsetFor(CampaignStage stage) {
    return stage.type == CampaignStageType.boss ? 39 : 33;
  }

  @override
  Widget build(BuildContext context) {
    final boss = stage.type == CampaignStageType.boss;
    final nodeSize = boss ? 66.0 : 54.0;
    final sideOffset = boss ? 8.0 : 6.0;
    final faceColor = locked
        ? const Color(0xFF9A7564)
        : boss
            ? const Color(0xFFFFB340)
            : current
                ? const Color(0xFF42F36D)
                : const Color(0xFF30D95F);
    final sideColor = locked
        ? const Color(0xFF4C312C)
        : boss
            ? const Color(0xFFB75C13)
            : const Color(0xFF0A9A38);
    final topHighlight = locked
        ? const Color(0xFFC2A193)
        : boss
            ? const Color(0xFFFFDD83)
            : const Color(0xFF8CFFAB);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final pulse = current ? 0.50 + animation.value * 0.40 : 0.0;
        return Transform.scale(
          scale: current ? 1 + animation.value * 0.045 : 1,
          child: Container(
            width: hitWidth,
            height: boss ? 108 : (completed ? 92 : 78),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                if (current)
                  BoxShadow(
                    color: const Color(0xFFFFF1A8).withValues(alpha: pulse),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                if (current)
                  BoxShadow(
                    color:
                        const Color(0xFF35F46B).withValues(alpha: pulse * 0.5),
                    blurRadius: 30,
                    spreadRadius: 6,
                  ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: locked ? 0.38 : 0.32),
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
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (boss)
                    Positioned(
                      top: -7,
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const SweepGradient(
                            colors: [
                              Color(0xFFFFF0A4),
                              Color(0xFFE73D55),
                              Color(0xFF7C2DFF),
                              Color(0xFFFFF0A4),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD15A)
                                  .withValues(alpha: 0.38),
                              blurRadius: 16,
                              spreadRadius: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: sideOffset + 8,
                    child: Container(
                      width: nodeSize + 8,
                      height: nodeSize + 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(nodeSize * 0.33),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 7,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: sideOffset,
                    child: Container(
                      width: nodeSize + 3,
                      height: nodeSize + 3,
                      decoration: BoxDecoration(
                        color: sideColor,
                        borderRadius: BorderRadius.circular(nodeSize * 0.31),
                      ),
                    ),
                  ),
                  Container(
                    width: nodeSize,
                    height: nodeSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: locked ? 0.15 : 0.32),
                          topHighlight,
                          faceColor,
                          sideColor,
                        ],
                        stops: const [0, 0.22, 0.66, 1],
                      ),
                      borderRadius: BorderRadius.circular(nodeSize * 0.30),
                      border: Border.all(
                        color: Colors.white
                            .withValues(alpha: locked ? 0.65 : 0.96),
                        width: boss ? 3 : 2.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 8,
                          offset: const Offset(0, 5),
                        ),
                        BoxShadow(
                          color: Colors.white
                              .withValues(alpha: locked ? 0.05 : 0.25),
                          blurRadius: 6,
                          offset: const Offset(-2, -3),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: boss ? 8 : 7,
                          left: boss ? 12 : 10,
                          child: Container(
                            width: boss ? 18 : 15,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white
                                  .withValues(alpha: locked ? 0.45 : 0.72),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        Positioned(
                          right: boss ? 11 : 9,
                          top: boss ? 16 : 14,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white
                                  .withValues(alpha: locked ? 0.2 : 0.38),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Text(
                          '${stage.order}',
                          style: TextStyle(
                            color: locked
                                ? Colors.white.withValues(alpha: 0.82)
                                : Colors.white,
                            fontSize: boss ? 25 : 21,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.26),
                                blurRadius: 2,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        if (locked)
                          Positioned(
                            bottom: -4,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A2725),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFE7B0),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.lock_rounded,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 13,
                              ),
                            ),
                          ),
                        if (boss)
                          Positioned(
                            top: -13,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7F1D1D),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFF0A4),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: Color(0xFFFFF2A7),
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (completed) ...[
                const SizedBox(height: 0),
                StarRatingView(stars: progress.stars, size: boss ? 18 : 15),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
