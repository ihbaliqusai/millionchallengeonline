import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/campaign_stage.dart';

class CampaignQuestionSelector {
  CampaignQuestionSelector({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<List<int>> selectQuestionIds(CampaignStage stage) async {
    final decoded = await _loadQuestions();
    if (decoded.isEmpty) return const <int>[];

    final allowedLevels =
        stage.allowedLevels.map((item) => item.trim()).toSet();
    final exactCandidates = <int>[];
    final fallbackByDistance = <int, List<int>>{};
    final availableLevels = <String>{};
    for (var index = 0; index < decoded.length; index += 1) {
      final item = decoded[index];
      if (item is! Map) continue;
      final level = _readString(item['Level'] ?? item['level']);
      if (level.isNotEmpty) availableLevels.add(level);
      if (allowedLevels.isNotEmpty) {
        if (allowedLevels.contains(level)) {
          exactCandidates.add(index);
        } else {
          final distance = _levelDistance(level, allowedLevels);
          fallbackByDistance.putIfAbsent(distance, () => <int>[]).add(index);
        }
      } else if (_matchesDifficulty(item, stage)) {
        exactCandidates.add(index);
      }
    }

    exactCandidates.shuffle(math.Random());
    final candidates = <int>[...exactCandidates];
    if (allowedLevels.isNotEmpty && candidates.length < stage.questionCount) {
      final fallbackFloor = _fallbackLevelFloor(allowedLevels, availableLevels);
      final distances = fallbackByDistance.keys.toList()..sort();
      for (final distance in distances) {
        final bucket = fallbackByDistance[distance]!..shuffle(math.Random());
        for (final id in bucket) {
          if (candidates.length >= stage.questionCount) break;
          if (!_passesFallbackFloor(decoded[id], fallbackFloor)) continue;
          candidates.add(id);
        }
        if (candidates.length >= stage.questionCount) break;
      }
      if (kDebugMode && exactCandidates.length < stage.questionCount) {
        debugPrint(
          'CampaignQuestionSelector fallback stage=${stage.id} '
          'allowed=${stage.allowedLevels} exact=${exactCandidates.length} '
          'available=$availableLevels selectedLevels=${_levelSummary(decoded, candidates)}',
        );
      }
    }
    final selected = _verifiedSelection(
      decoded: decoded,
      ids: candidates.take(stage.questionCount).toList(growable: false),
      allowedLevels: allowedLevels,
      stage: stage,
      strict: exactCandidates.length >= stage.questionCount,
    );

    if (kDebugMode) {
      debugPrint(
        'CampaignQuestionSelector stage=${stage.id} order=${stage.order} '
        'allowed=${stage.allowedLevels} selected=${selected.length} '
        'levels=${_levelSummary(decoded, selected)} ids=$selected',
      );
    }

    if (selected.length < stage.questionCount) {
      throw StateError(
        'Not enough valid campaign questions for stage ${stage.id}: '
        '${selected.length}/${stage.questionCount} for levels ${stage.allowedLevels}',
      );
    }
    return selected;
  }

  Future<Map<String, int>> levelSummaryForQuestionIds(List<int> ids) async {
    try {
      return _levelSummary(await _loadQuestions(), ids);
    } catch (_) {
      return const <String, int>{};
    }
  }

  Future<List<dynamic>> _loadQuestions() async {
    final jsonText = await _bundle.loadString('assets/questions.json');
    final decoded = jsonDecode(jsonText);
    return decoded is List ? decoded : const <dynamic>[];
  }

  List<int> _verifiedSelection({
    required List<dynamic> decoded,
    required List<int> ids,
    required Set<String> allowedLevels,
    required CampaignStage stage,
    required bool strict,
  }) {
    if (allowedLevels.isEmpty || !strict) return ids;
    final verified = <int>[];
    for (final id in ids) {
      if (id < 0 || id >= decoded.length) continue;
      final item = decoded[id];
      if (item is! Map) continue;
      final level = _readString(item['Level'] ?? item['level']);
      if (allowedLevels.contains(level)) {
        verified.add(id);
      } else if (kDebugMode) {
        debugPrint(
          'CampaignQuestionSelector removed invalid level question: '
          'stage=${stage.order} id=$id level=$level allowed=$allowedLevels',
        );
      }
    }
    return verified;
  }

  int _levelDistance(String level, Set<String> allowedLevels) {
    final value = int.tryParse(level);
    if (value == null) return 999;
    var best = 999;
    for (final allowed in allowedLevels) {
      final allowedValue = int.tryParse(allowed);
      if (allowedValue == null) continue;
      final distance = (value - allowedValue).abs();
      if (distance < best) best = distance;
    }
    return best;
  }

  int? _fallbackLevelFloor(Set<String> allowedLevels, Set<String> available) {
    final allowedNumbers = allowedLevels
        .map(int.tryParse)
        .whereType<int>()
        .toList(growable: false);
    if (allowedNumbers.isEmpty) return null;
    final minAllowed = allowedNumbers.reduce(math.min);
    if (minAllowed < 4) return null;

    final availableNumbers = available
        .map(int.tryParse)
        .whereType<int>()
        .where((level) => level < minAllowed)
        .toList(growable: false);
    if (availableNumbers.isEmpty) return null;
    return availableNumbers.reduce(math.max);
  }

  bool _passesFallbackFloor(dynamic item, int? fallbackFloor) {
    if (fallbackFloor == null) return true;
    if (item is! Map) return false;
    final level = int.tryParse(_readString(item['Level'] ?? item['level']));
    return level != null && level >= fallbackFloor;
  }

  Map<String, int> _levelSummary(List<dynamic> decoded, List<int> ids) {
    final summary = <String, int>{};
    for (final id in ids) {
      if (id < 0 || id >= decoded.length) continue;
      final item = decoded[id];
      if (item is! Map) continue;
      final level = _readString(item['Level'] ?? item['level']);
      summary[level] = (summary[level] ?? 0) + 1;
    }
    return summary;
  }

  bool _matchesDifficulty(Map<dynamic, dynamic> item, CampaignStage stage) {
    final level = _readInt(item['difficulty'] ??
        item['Difficulty'] ??
        item['level'] ??
        item['Level']);
    if (level == null) return true;
    return level >= stage.minDifficulty && level <= stage.maxDifficulty;
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}
