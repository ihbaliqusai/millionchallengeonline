import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/campaign_stage.dart';
import '../../models/stage_progress.dart';
import '../../services/campaign_result_handler.dart';
import '../../services/campaign_service.dart';
import 'stage_intro_screen.dart';
import 'widgets/campaign_map_background.dart';
import 'widgets/campaign_path_painter.dart';
import 'widgets/stage_node.dart';

class CampaignMapScreen extends StatefulWidget {
  const CampaignMapScreen({super.key});

  @override
  State<CampaignMapScreen> createState() => _CampaignMapScreenState();
}

class _CampaignMapScreenState extends State<CampaignMapScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final CampaignService _campaignService = CampaignService();
  late final AnimationController _pulseController;
  late Future<_CampaignMapData> _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _future = _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingCampaignResult();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _consumePendingCampaignResult();
    }
  }

  Future<void> _consumePendingCampaignResult() async {
    if (!mounted) return;
    await CampaignResultHandler.consumeAndHandlePendingCampaignResult(
      context: context,
    );
    if (mounted) {
      await _reload();
    }
  }

  Future<_CampaignMapData> _load() async {
    final uid = context.read<AppState>().currentUser?.uid.trim();
    final stages = await _campaignService.loadStages();
    final savedProgress = uid == null || uid.isEmpty
        ? const <String, StageProgress>{}
        : await _campaignService.loadUserProgress(uid: uid);
    final progress = _campaignService.resolveProgressForStages(
      stages: stages,
      savedProgress: savedProgress,
    );
    return _CampaignMapData(stages: stages, progress: progress);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: FutureBuilder<_CampaignMapData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _MapScaffoldBackground(child: _LoadingState());
            }
            if (snapshot.hasError) {
              return _MapScaffoldBackground(
                  child: _ErrorState(onRetry: _reload));
            }
            final data = snapshot.data;
            if (data == null || data.stages.isEmpty) {
              return _MapScaffoldBackground(
                  child: _EmptyState(onRetry: _reload));
            }
            return _CampaignMapContent(
              data: data,
              campaignService: _campaignService,
              pulseAnimation: _pulseController,
              onRefresh: _reload,
              onLockedTap: _showLockedMessage,
              onStageTap: _openStageIntro,
            );
          },
        ),
      ),
    );
  }

  void _showLockedMessage(CampaignStage stage) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'أكمل المراحل السابقة أو اجمع المزيد من النجوم لفتح هذه المرحلة.',
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
  }

  void _openStageIntro(CampaignStage stage, StageProgress progress) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StageIntroScreen(stage: stage, progress: progress),
      ),
    );
  }
}

class _CampaignMapContent extends StatefulWidget {
  const _CampaignMapContent({
    required this.data,
    required this.campaignService,
    required this.pulseAnimation,
    required this.onRefresh,
    required this.onLockedTap,
    required this.onStageTap,
  });

  final _CampaignMapData data;
  final CampaignService campaignService;
  final Animation<double> pulseAnimation;
  final Future<void> Function() onRefresh;
  final void Function(CampaignStage stage) onLockedTap;
  final void Function(CampaignStage stage, StageProgress progress) onStageTap;

  @override
  State<_CampaignMapContent> createState() => _CampaignMapContentState();
}

class _CampaignMapContentState extends State<_CampaignMapContent> {
  final ScrollController _scrollController = ScrollController();
  bool _didAutoScroll = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalStars = widget.campaignService.totalStars(widget.data.progress);
    final completedStages = widget.data.progress
        .where(widget.campaignService.isStageCompleted)
        .length;
    final nextPlayableIndex = widget.data.progress.indexWhere(
      (progress) =>
          progress.status == StageProgressStatus.unlocked &&
          !widget.campaignService.isStageCompleted(progress),
    );
    final currentIndex = nextPlayableIndex >= 0
        ? nextPlayableIndex
        : math.max(0, completedStages - 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final viewportHeight = constraints.maxHeight;
        final mapHeight =
            _mapHeightFor(widget.data.stages.length, viewportHeight);
        final centers = _stageCenters(
          width: width,
          height: mapHeight,
          stages: widget.data.stages,
        );

        _scheduleAutoScroll(
          centers: centers,
          currentIndex: currentIndex,
          mapHeight: mapHeight,
          viewportHeight: viewportHeight,
        );

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: widget.onRefresh,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: SizedBox(
                  width: width,
                  height: mapHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CampaignMapBackground(
                          height: mapHeight,
                          stageCount: widget.data.stages.length,
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: CampaignPathPainter(points: centers),
                        ),
                      ),
                      for (var index = 0;
                          index < widget.data.stages.length;
                          index += 1)
                        Positioned(
                          left: centers[index].dx - StageNode.hitWidth / 2,
                          top: centers[index].dy -
                              StageNode.centerOffsetFor(
                                widget.data.stages[index],
                              ),
                          child: StageNode(
                            stage: widget.data.stages[index],
                            progress: widget.data.progress[index],
                            locked: widget.data.progress[index].status ==
                                StageProgressStatus.locked,
                            completed: widget.campaignService
                                .isStageCompleted(widget.data.progress[index]),
                            current: index == currentIndex &&
                                widget.data.progress[index].status !=
                                    StageProgressStatus.locked,
                            animation: widget.pulseAnimation,
                            onTap: () {
                              final progress = widget.data.progress[index];
                              if (progress.status ==
                                  StageProgressStatus.locked) {
                                widget.onLockedTap(widget.data.stages[index]);
                              } else {
                                widget.onStageTap(
                                    widget.data.stages[index], progress);
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _MapTopOverlay(
                totalStars: totalStars,
                completedStages: completedStages,
                totalStages: widget.data.stages.length,
              ),
            ),
          ],
        );
      },
    );
  }

  void _scheduleAutoScroll({
    required List<Offset> centers,
    required int currentIndex,
    required double mapHeight,
    required double viewportHeight,
  }) {
    if (_didAutoScroll || centers.isEmpty) return;
    _didAutoScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final targetY = centers[currentIndex.clamp(0, centers.length - 1)].dy;
      final maxOffset = math.max(0.0, mapHeight - viewportHeight);
      final desired = (targetY - viewportHeight * 0.78).clamp(0.0, maxOffset);
      _scrollController.jumpTo(desired);
    });
  }

  double _mapHeightFor(int stageCount, double viewportHeight) {
    final count = stageCount.clamp(1, 30);
    return math.max(viewportHeight + 120, 210 + count * 76.0);
  }

  List<Offset> _stageCenters({
    required double width,
    required double height,
    required List<CampaignStage> stages,
  }) {
    const pattern = <double>[0.50, 0.25, 0.72, 0.34, 0.78, 0.56, 0.28, 0.68];
    final horizontalInset = width < 360 ? 44.0 : 52.0;
    final usableWidth = width - horizontalInset * 2;
    final step = _stageStepFor(height, stages.length);
    return List.generate(stages.length, (index) {
      final boss = stages[index].type == CampaignStageType.boss;
      final ratio = boss ? 0.50 : pattern[index % pattern.length];
      final x = horizontalInset + usableWidth * ratio;
      final y = height - 86 - index * step;
      return Offset(x.clamp(42.0, width - 42.0), y);
    });
  }

  double _stageStepFor(double mapHeight, int stageCount) {
    if (stageCount <= 1) return 82;
    final usableHeight = math.max(0.0, mapHeight - 190);
    return (usableHeight / (stageCount - 1)).clamp(70.0, 88.0);
  }
}

class _MapScaffoldBackground extends StatelessWidget {
  const _MapScaffoldBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8CF04A), Color(0xFF25B62A), Color(0xFF087A27)],
        ),
      ),
      child: SizedBox.expand(child: child),
    );
  }
}

class _MapTopOverlay extends StatelessWidget {
  const _MapTopOverlay({
    required this.totalStars,
    required this.completedStages,
    required this.totalStages,
  });

  final int totalStars;
  final int completedStages;
  final int totalStages;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
        child: Row(
          children: [
            _OverlayIconButton(
              icon: Icons.arrow_forward_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const Spacer(),
            _OverlayChip(
              icon: Icons.flag_rounded,
              label: '$completedStages/$totalStages',
              color: const Color(0xFF55F07A),
            ),
            const SizedBox(width: 7),
            _OverlayChip(
              icon: Icons.star_rounded,
              label: '$totalStars',
              color: const Color(0xFFFFD84D),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF0C3B25).withValues(alpha: 0.50),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({
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
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0C3B25).withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignMapData {
  const _CampaignMapData({
    required this.stages,
    required this.progress,
  });

  final List<CampaignStage> stages;
  final List<StageProgress> progress;
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFFFACC15)),
          SizedBox(height: 12),
          Text(
            'جاري تحميل رحلة المليون...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Color(0x88000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFF87171),
            size: 42,
          ),
          const SizedBox(height: 10),
          const Text(
            'تعذر تحميل الخريطة الآن.',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, color: Color(0xFF7DD3FC), size: 42),
          const SizedBox(height: 10),
          const Text(
            'لا توجد مراحل متاحة',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              'تعذر تحميل المراحل. حاول مرة أخرى.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
