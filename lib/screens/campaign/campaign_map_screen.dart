import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/campaign_stage.dart';
import '../../models/stage_progress.dart';
import '../../models/campaign_world.dart';
import '../../services/campaign_result_handler.dart';
import '../../services/campaign_service.dart';
import 'stage_intro_screen.dart';
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
                child: _ErrorState(onRetry: _reload),
              );
            }
            final data = snapshot.data;
            if (data == null || data.stages.isEmpty) {
              return _MapScaffoldBackground(
                child: _EmptyState(onRetry: _reload),
              );
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
  late final PageController _pageController;
  late int _selectedWorldIndex;

  @override
  void initState() {
    super.initState();
    _selectedWorldIndex = _initialWorldIndex();
    _pageController = PageController(initialPage: _selectedWorldIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheWorld(_selectedWorldIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalStars = widget.campaignService.totalStars(widget.data.progress);
    final completedStages = widget.data.progress
        .where(widget.campaignService.isStageCompleted)
        .length;
    final worlds = _worldStageBundles();
    final selectedWorld =
        campaignWorlds[_selectedWorldIndex.clamp(0, campaignWorlds.length - 1)];

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          itemCount: worlds.length,
          onPageChanged: (index) {
            setState(() {
              _selectedWorldIndex = index;
            });
            _precacheWorld(index);
          },
          itemBuilder: (context, index) {
            return _WorldMapPage(
              bundle: worlds[index],
              campaignService: widget.campaignService,
              pulseAnimation: widget.pulseAnimation,
              onLockedTap: widget.onLockedTap,
              onStageTap: widget.onStageTap,
              onRefresh: widget.onRefresh,
            );
          },
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
        Positioned(
          left: 14,
          right: 14,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: _WorldPagerControls(
              world: selectedWorld,
              selectedIndex: _selectedWorldIndex,
              completedStages: worlds[_selectedWorldIndex].completedStages,
              totalStages: worlds[_selectedWorldIndex].stages.length,
              onPrevious: _selectedWorldIndex == 0
                  ? null
                  : () => _goToWorld(_selectedWorldIndex - 1),
              onNext: _selectedWorldIndex == campaignWorlds.length - 1
                  ? null
                  : () => _goToWorld(_selectedWorldIndex + 1),
              onDotTap: _goToWorld,
            ),
          ),
        ),
      ],
    );
  }

  int _initialWorldIndex() {
    final allUnlocked = widget.data.progress.isNotEmpty &&
        widget.data.progress.every(
          (progress) => progress.status != StageProgressStatus.locked,
        );
    final hasCompleted = widget.data.progress.any(
      widget.campaignService.isStageCompleted,
    );
    if (allUnlocked && !hasCompleted) return 0;

    final nextPlayableIndex = widget.data.progress.indexWhere(
      (progress) =>
          progress.status == StageProgressStatus.unlocked &&
          !widget.campaignService.isStageCompleted(progress),
    );
    final stageIndex = nextPlayableIndex >= 0
        ? nextPlayableIndex
        : math.max(
            0,
            widget.data.progress
                    .where(widget.campaignService.isStageCompleted)
                    .length -
                1,
          );
    if (stageIndex >= widget.data.stages.length) return 0;
    return campaignWorldIndexForStageOrder(
        widget.data.stages[stageIndex].order);
  }

  List<_WorldStageBundle> _worldStageBundles() {
    final progressByStageId = {
      for (final progress in widget.data.progress) progress.stageId: progress,
    };
    return [
      for (final world in campaignWorlds)
        _WorldStageBundle(
          world: world,
          stages: widget.data.stages
              .where((stage) => world.containsStageOrder(stage.order))
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order)),
          progressByStageId: progressByStageId,
          campaignService: widget.campaignService,
        ),
    ];
  }

  void _goToWorld(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _precacheWorld(int index) {
    if (!mounted) return;
    for (final candidate in <int>[index, index - 1, index + 1]) {
      if (candidate < 0 || candidate >= campaignWorlds.length) continue;
      precacheImage(
        AssetImage(campaignWorlds[candidate].backgroundAsset),
        context,
      );
    }
  }
}

class _WorldMapPage extends StatelessWidget {
  const _WorldMapPage({
    required this.bundle,
    required this.campaignService,
    required this.pulseAnimation,
    required this.onLockedTap,
    required this.onStageTap,
    required this.onRefresh,
  });

  final _WorldStageBundle bundle;
  final CampaignService campaignService;
  final Animation<double> pulseAnimation;
  final void Function(CampaignStage stage) onLockedTap;
  final void Function(CampaignStage stage, StageProgress progress) onStageTap;
  final Future<void> Function() onRefresh;

  static const Size _backgroundSourceSize = Size(1672, 941);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      bundle.world.backgroundAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.10),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  for (var index = 0; index < bundle.stages.length; index += 1)
                    _buildStageNode(
                      size: Size(width, height),
                      index: index,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStageNode({
    required Size size,
    required int index,
  }) {
    final stage = bundle.stages[index];
    final progress = bundle.progress[index];
    final position = _coverAlignedPosition(
      bundle.world.nodePositions[index],
      size,
    );

    return Positioned(
      left: position.dx - StageNode.hitWidth / 2,
      top: position.dy - StageNode.centerOffsetFor(stage),
      child: StageNode(
        stage: stage,
        progress: progress,
        locked: progress.status == StageProgressStatus.locked,
        completed: campaignService.isStageCompleted(progress),
        current: bundle.currentStageId == stage.id &&
            progress.status != StageProgressStatus.locked,
        animation: pulseAnimation,
        onTap: () {
          if (progress.status == StageProgressStatus.locked) {
            onLockedTap(stage);
          } else {
            onStageTap(stage, progress);
          }
        },
      ),
    );
  }

  Offset _coverAlignedPosition(Offset imagePosition, Size outputSize) {
    final scale = math.max(
      outputSize.width / _backgroundSourceSize.width,
      outputSize.height / _backgroundSourceSize.height,
    );
    final fittedSize = _backgroundSourceSize * scale;
    final cropOffset = Offset(
      (outputSize.width - fittedSize.width) / 2,
      (outputSize.height - fittedSize.height) / 2,
    );
    return Offset(
      cropOffset.dx + imagePosition.dx * fittedSize.width,
      cropOffset.dy + imagePosition.dy * fittedSize.height,
    );
  }
}

class _WorldStageBundle {
  _WorldStageBundle({
    required this.world,
    required this.stages,
    required Map<String, StageProgress> progressByStageId,
    required CampaignService campaignService,
  })  : progress = [
          for (final stage in stages)
            progressByStageId[stage.id] ??
                StageProgress.empty().copyWith(
                  campaignId: stage.campaignId,
                  stageId: stage.id,
                ),
        ],
        completedStages = stages
            .map((stage) => progressByStageId[stage.id])
            .whereType<StageProgress>()
            .where(campaignService.isStageCompleted)
            .length,
        currentStageId = _currentStageId(
          stages,
          progressByStageId,
          campaignService,
        );

  final CampaignWorld world;
  final List<CampaignStage> stages;
  final List<StageProgress> progress;
  final int completedStages;
  final String? currentStageId;

  static String? _currentStageId(
    List<CampaignStage> stages,
    Map<String, StageProgress> progressByStageId,
    CampaignService campaignService,
  ) {
    for (final stage in stages) {
      final progress = progressByStageId[stage.id];
      if (progress == null) continue;
      if (progress.status == StageProgressStatus.unlocked &&
          !campaignService.isStageCompleted(progress)) {
        return stage.id;
      }
    }
    return null;
  }
}

class _WorldPagerControls extends StatelessWidget {
  const _WorldPagerControls({
    required this.world,
    required this.selectedIndex,
    required this.completedStages,
    required this.totalStages,
    required this.onPrevious,
    required this.onNext,
    required this.onDotTap,
  });

  final CampaignWorld world;
  final int selectedIndex;
  final int completedStages;
  final int totalStages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onDotTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0C3B25).withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              _WorldArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: onPrevious,
              ),
              Expanded(
                child: Text(
                  'العالم ${world.worldIndex + 1}  •  ${world.name}  •  $completedStages/$totalStages',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _WorldArrowButton(
                icon: Icons.chevron_left_rounded,
                onTap: onNext,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < campaignWorlds.length; index += 1)
              GestureDetector(
                onTap: () => onDotTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: index == selectedIndex ? 20 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == selectedIndex
                        ? const Color(0xFFFFD84D)
                        : Colors.white.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _WorldArrowButton extends StatelessWidget {
  const _WorldArrowButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(
        icon,
        color: onTap == null ? Colors.white38 : Colors.white,
        size: 26,
      ),
    );
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
