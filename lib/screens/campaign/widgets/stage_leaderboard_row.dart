import 'package:flutter/material.dart';

import '../../../models/stage_leaderboard_entry.dart';

class StageLeaderboardRow extends StatelessWidget {
  const StageLeaderboardRow({
    super.key,
    required this.entry,
    required this.rank,
    this.compact = false,
  });

  final StageLeaderboardEntry entry;
  final int rank;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final medalColor = switch (rank) {
      1 => const Color(0xFFFACC15),
      2 => const Color(0xFFE5E7EB),
      3 => const Color(0xFFF97316),
      _ => const Color(0xFF7DD3FC),
    };
    final displayName =
        entry.displayName.trim().isEmpty ? 'لاعب' : entry.displayName.trim();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0B173F).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: medalColor.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: compact ? 28 : 34,
            child: Text(
              '#$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: medalColor,
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _Avatar(entry: entry, size: compact ? 30 : 38),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!compact)
                  Text(
                    '${entry.correctAnswers} صحيحة • ${_formatTime(entry.timeMs)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          if (entry.assisted)
            Container(
              margin: const EdgeInsetsDirectional.only(end: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFFF97316).withValues(alpha: 0.42),
                ),
              ),
              child: const Text(
                'مساعدة',
                style: TextStyle(
                  color: Color(0xFFF97316),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${entry.score}',
                style: TextStyle(
                  color: const Color(0xFFFACC15),
                  fontSize: compact ? 14 : 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  return Icon(
                    index < entry.stars
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: compact ? 13 : 15,
                    color: index < entry.stars
                        ? const Color(0xFFFACC15)
                        : Colors.white.withValues(alpha: 0.35),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.entry, required this.size});

  final StageLeaderboardEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final photoUrl = entry.photoUrl?.trim() ?? '';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1D4ED8),
        border: Border.all(color: const Color(0xFFFACC15), width: 1.4),
      ),
      child: ClipOval(
        child: photoUrl.isEmpty
            ? const Icon(Icons.person_rounded, color: Colors.white)
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

String _formatTime(int timeMs) {
  final seconds = (timeMs / 1000).round().clamp(0, 24 * 60 * 60);
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final rest = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$rest';
}
