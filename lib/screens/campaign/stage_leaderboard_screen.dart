import 'package:flutter/material.dart';

import '../../models/campaign_stage.dart';
import '../../models/stage_leaderboard_entry.dart';
import '../../services/campaign_service.dart';
import 'widgets/stage_leaderboard_row.dart';

class StageLeaderboardScreen extends StatefulWidget {
  const StageLeaderboardScreen({
    super.key,
    required this.stage,
  });

  final CampaignStage stage;

  @override
  State<StageLeaderboardScreen> createState() => _StageLeaderboardScreenState();
}

class _StageLeaderboardScreenState extends State<StageLeaderboardScreen> {
  final CampaignService _campaignService = CampaignService();
  bool _pureOnly = false;
  late Future<List<StageLeaderboardEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<StageLeaderboardEntry>> _load() {
    return _campaignService.loadStageLeaderboard(
      campaignId: widget.stage.campaignId,
      stageId: widget.stage.id,
      pureOnly: _pureOnly,
      limit: 50,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  void _setPureOnly(bool value) {
    if (value == _pureOnly) return;
    setState(() {
      _pureOnly = value;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'ترتيب المرحلة',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF111827), Color(0xFF172554), Color(0xFF030712)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                  child: _Header(
                    stage: widget.stage,
                    pureOnly: _pureOnly,
                    onChanged: _setPureOnly,
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<StageLeaderboardEntry>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFACC15),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return const _ErrorState();
                      }
                      final entries =
                          snapshot.data ?? const <StageLeaderboardEntry>[];
                      if (entries.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              _EmptyState(),
                            ],
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                          itemBuilder: (context, index) => StageLeaderboardRow(
                            entry: entries[index],
                            rank: index + 1,
                          ),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemCount: entries.length,
                        ),
                      );
                    },
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

class _Header extends StatelessWidget {
  const _Header({
    required this.stage,
    required this.pureOnly,
    required this.onChanged,
  });

  final CampaignStage stage;
  final bool pureOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF075985), Color(0xFF312E81), Color(0xFF111827)],
        ),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            stage.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'أفضل النتائج في هذه المرحلة',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                label: Text('الكل'),
                icon: Icon(Icons.leaderboard_rounded),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text('بدون مساعدات'),
                icon: Icon(Icons.verified_rounded),
              ),
            ],
            selected: <bool>{pureOnly},
            onSelectionChanged: (values) => onChanged(values.first),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'لا توجد نتائج بعد. كن أول من يتصدر هذه المرحلة!',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'تعذر تحميل الترتيب.',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
