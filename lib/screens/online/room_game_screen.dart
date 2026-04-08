import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/player_profile.dart';
import '../../models/room.dart';
import '../../services/profile_service.dart';
import '../../services/room_service.dart';
import '../../widgets/game_shell.dart';

class RoomGameScreen extends StatefulWidget {
  const RoomGameScreen({
    super.key,
    required this.roomId,
  });

  final String roomId;

  @override
  State<RoomGameScreen> createState() => _RoomGameScreenState();
}

class _RoomGameScreenState extends State<RoomGameScreen> {
  bool _loadingQuestions = true;
  bool _submittingScore = false;
  bool _leaving = false;
  bool _submittedFinalScore = false;
  bool _seededBotScores = false;
  List<_RoomQuestion> _questions = <_RoomQuestion>[];
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final raw = await rootBundle.loadString('assets/questions.json');
      final decodedList = (jsonDecode(raw) as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
      final questions = _buildQuestionsForRoom(decodedList, widget.roomId);
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loadingQuestions = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load questions: $e')),
      );
      setState(() => _loadingQuestions = false);
    }
  }

  Future<void> _answerQuestion(int answerIndex) async {
    if (_selectedAnswerIndex != null || _currentIndex >= _questions.length) {
      return;
    }

    final question = _questions[_currentIndex];
    final isCorrect = answerIndex == question.correctIndex;

    setState(() {
      _selectedAnswerIndex = answerIndex;
      if (isCorrect) {
        _score += 1;
      }
    });

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    if (_currentIndex >= _questions.length - 1) {
      setState(() {
        _currentIndex = _questions.length;
        _selectedAnswerIndex = null;
      });
      await _submitFinalScoreIfNeeded();
      return;
    }

    setState(() {
      _currentIndex += 1;
      _selectedAnswerIndex = null;
    });
  }

  Future<void> _submitFinalScoreIfNeeded() async {
    if (_submittedFinalScore || _submittingScore) return;
    final userId = context.read<AppState>().user?.uid;
    if (userId == null) return;

    setState(() => _submittingScore = true);
    try {
      await context.read<RoomService>().submitFinalScore(
            roomId: widget.roomId,
            userId: userId,
            score: _score,
            answeredCount: _questions.length,
          );
      if (!mounted) return;
      setState(() => _submittedFinalScore = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _submittingScore = false);
      }
    }
  }

  Future<void> _seedBotScoresIfNeeded({
    required Room room,
    required String currentUserId,
  }) async {
    if (_seededBotScores ||
        _loadingQuestions ||
        _questions.isEmpty ||
        currentUserId != room.hostId ||
        !room.playerIds.any(Room.isBotUserId)) {
      return;
    }

    _seededBotScores = true;
    try {
      await context.read<RoomService>().seedBotScores(
            roomId: widget.roomId,
            totalQuestions: _questions.length,
          );
    } catch (_) {
      _seededBotScores = false;
    }
  }

  Future<void> _leaveRoom() async {
    if (_leaving) return;
    final userId = context.read<AppState>().user?.uid;
    if (userId == null) return;

    setState(() => _leaving = true);
    try {
      await context.read<RoomService>().leaveRoom(
            roomId: widget.roomId,
            userId: userId,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _leaving = false);
      }
    }
  }

  Future<bool> _confirmLeave() async {
    final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Match?'),
            content: const Text('Leaving now removes you from the room.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldLeave) {
      unawaited(_leaveRoom());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AppState>().user?.uid ?? '';

    return WillPopScope(
      onWillPop: _confirmLeave,
      child: StreamBuilder<Room?>(
        stream: context.read<RoomService>().watchRoom(widget.roomId),
        builder: (context, roomSnapshot) {
          if (roomSnapshot.connectionState == ConnectionState.waiting &&
              !roomSnapshot.hasData) {
            return const _RoomGameLoadingState();
          }

          final room = roomSnapshot.data;
          if (room == null) {
            return GameShell(
              title: 'Room Match',
              subtitle: 'This room is no longer available.',
              action: IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
              child: Center(
                child: GlassPanel(
                  radius: 28,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Room Closed',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'The room was deleted while the match was open.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.74)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final playerIds = room.playerIds;

          if (!_loadingQuestions &&
              _questions.isNotEmpty &&
              currentUserId.isNotEmpty &&
              !_seededBotScores) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              unawaited(
                _seedBotScoresIfNeeded(
                  room: room,
                  currentUserId: currentUserId,
                ),
              );
            });
          }

          return GameShell(
            title: 'Room Match',
            subtitle:
                'Everyone is using the same question set for this room. Final scores update in real time.',
            action: IconButton.filledTonal(
              onPressed: _leaving ? null : _confirmLeave,
              icon: const Icon(Icons.exit_to_app_rounded),
            ),
            child: StreamBuilder<Map<String, PlayerProfile>>(
              stream: context.read<ProfileService>().watchProfiles(playerIds),
              builder: (context, profileSnapshot) {
                final profiles =
                    profileSnapshot.data ?? const <String, PlayerProfile>{};
                final ranking = _buildRanking(room, profiles);
                final myPlacement = ranking
                        .indexWhere((entry) => entry.userId == currentUserId) +
                    1;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1220),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 7,
                          child: GlassPanel(
                            radius: 28,
                            child: _loadingQuestions
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : _questions.isEmpty
                                    ? _EmptyQuestionsState(onLeave: _leaveRoom)
                                    : _currentIndex >= _questions.length
                                        ? _CompletedState(
                                            score: _score,
                                            totalQuestions: _questions.length,
                                            placement: myPlacement <= 0
                                                ? ranking.length
                                                : myPlacement,
                                            isSubmitting: _submittingScore,
                                          )
                                        : _QuestionStage(
                                            question: _questions[_currentIndex],
                                            questionNumber: _currentIndex + 1,
                                            totalQuestions: _questions.length,
                                            score: _score,
                                            selectedAnswerIndex:
                                                _selectedAnswerIndex,
                                            onAnswer: _answerQuestion,
                                          ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 4,
                          child: GlassPanel(
                            radius: 28,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Ranking',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Players are ordered by final score, then by who finished earlier.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.72),
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: ranking.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final entry = ranking[index];
                                      return _RankingTile(
                                        rank: index + 1,
                                        username: entry.username,
                                        photoUrl: entry.photoUrl,
                                        score: entry.player.score,
                                        answeredCount:
                                            entry.player.answeredCount,
                                        isCurrentUser:
                                            entry.userId == currentUserId,
                                        isCompleted:
                                            entry.player.completedAt != null,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: NeonButton(
                                    label:
                                        _leaving ? 'Leaving...' : 'Leave Room',
                                    icon: Icons.logout_rounded,
                                    compact: true,
                                    onPressed: _leaving ? null : _leaveRoom,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  static List<_RankingEntry> _buildRanking(
    Room room,
    Map<String, PlayerProfile> profiles,
  ) {
    final entries = room.players.entries.map((entry) {
      final profile = profiles[entry.key];
      return _RankingEntry(
        userId: entry.key,
        username: profile?.username ?? _fallbackName(entry.key),
        photoUrl: profile?.photoUrl,
        player: entry.value,
      );
    }).toList(growable: false);

    entries.sort((a, b) {
      final scoreCompare = b.player.score.compareTo(a.player.score);
      if (scoreCompare != 0) return scoreCompare;

      final completedA = a.player.completedAt;
      final completedB = b.player.completedAt;
      if (completedA != null && completedB != null) {
        return completedA.compareTo(completedB);
      }
      if (completedA != null) return -1;
      if (completedB != null) return 1;
      return a.username.compareTo(b.username);
    });

    return entries;
  }

  static List<_RoomQuestion> _buildQuestionsForRoom(
    List<Map<String, dynamic>> rawQuestions,
    String roomId,
  ) {
    final buckets = <String, List<Map<String, dynamic>>>{
      '0': <Map<String, dynamic>>[],
      '1': <Map<String, dynamic>>[],
      '2': <Map<String, dynamic>>[],
      '3': <Map<String, dynamic>>[],
    };

    for (final item in rawQuestions) {
      final level = (item['Level'] ?? '').toString();
      buckets.putIfAbsent(level, () => <Map<String, dynamic>>[]).add(item);
    }

    final seed = _stableHash(roomId);
    final results = <_RoomQuestion>[];
    final plan = <String, int>{
      '0': 3,
      '1': 3,
      '2': 5,
      '3': 4,
    };

    for (final entry in plan.entries) {
      final bucket = List<Map<String, dynamic>>.from(
        buckets[entry.key] ?? const <Map<String, dynamic>>[],
      );
      if (bucket.isEmpty) continue;
      _shuffleInPlace(bucket, Random(seed + entry.key.codeUnitAt(0)));
      for (final item in bucket.take(entry.value)) {
        results.add(_RoomQuestion.fromMap(item, seed + results.length));
      }
    }

    return results;
  }

  static void _shuffleInPlace<T>(List<T> items, Random random) {
    for (var i = items.length - 1; i > 0; i--) {
      final swapIndex = random.nextInt(i + 1);
      final tmp = items[i];
      items[i] = items[swapIndex];
      items[swapIndex] = tmp;
    }
  }

  static int _stableHash(String value) {
    var hash = 5381;
    for (final unit in value.codeUnits) {
      hash = ((hash << 5) + hash) ^ unit;
    }
    return hash & 0x7fffffff;
  }

  static String _fallbackName(String value) {
    if (Room.isBotUserId(value)) return Room.botDisplayName(value);
    if (value.length <= 8) return value;
    return '${value.substring(0, 8)}...';
  }
}

class _RoomGameLoadingState extends StatelessWidget {
  const _RoomGameLoadingState();

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Room Match',
      subtitle: 'Syncing your match with the room...',
      action: IconButton.filledTonal(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _QuestionStage extends StatelessWidget {
  const _QuestionStage({
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.score,
    required this.selectedAnswerIndex,
    required this.onAnswer,
  });

  final _RoomQuestion question;
  final int questionNumber;
  final int totalQuestions;
  final int score;
  final int? selectedAnswerIndex;
  final ValueChanged<int> onAnswer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            HudChip(
              icon: Icons.help_outline_rounded,
              label: 'Question $questionNumber/$totalQuestions',
            ),
            HudChip(
              icon: Icons.stars_rounded,
              label: '$score pts',
              iconColor: const Color(0xFFFACC15),
            ),
            HudChip(
              icon: Icons.auto_awesome_rounded,
              label: 'Level ${question.level}',
              iconColor: const Color(0xFF7DD3FC),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ProgressStrip(
          value: questionNumber / totalQuestions,
          label: 'Match progress',
        ),
        const SizedBox(height: 24),
        Text(
          question.prompt,
          style: const TextStyle(
              fontSize: 30, fontWeight: FontWeight.w900, height: 1.2),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.builder(
            itemCount: question.answers.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 2.4,
            ),
            itemBuilder: (context, index) {
              final isSelected = selectedAnswerIndex == index;
              final isCorrect = index == question.correctIndex;
              final reveal = selectedAnswerIndex != null;

              var borderColor = Colors.white.withOpacity(0.12);
              var background = Colors.white.withOpacity(0.06);

              if (reveal && isCorrect) {
                borderColor = const Color(0xFF34D399);
                background = const Color(0xFF34D399).withOpacity(0.14);
              } else if (reveal && isSelected && !isCorrect) {
                borderColor = const Color(0xFFFB7185);
                background = const Color(0xFFFB7185).withOpacity(0.14);
              } else if (isSelected) {
                borderColor = const Color(0xFFFACC15);
                background = const Color(0xFFFACC15).withOpacity(0.12);
              }

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: selectedAnswerIndex != null
                      ? null
                      : () => onAnswer(index),
                  child: Ink(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: background,
                      border: Border.all(color: borderColor, width: 1.7),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            question.answers[index],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CompletedState extends StatelessWidget {
  const _CompletedState({
    required this.score,
    required this.totalQuestions,
    required this.placement,
    required this.isSubmitting,
  });

  final int score;
  final int totalQuestions;
  final int placement;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFF59E0B), Color(0xFFFACC15)],
              ),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: Colors.white, size: 44),
          ),
          const SizedBox(height: 18),
          const Text(
            'Match Finished',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'You scored $score / $totalQuestions and you are currently #$placement.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              fontSize: 17,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          if (isSubmitting) const CircularProgressIndicator(),
        ],
      ),
    );
  }
}

class _EmptyQuestionsState extends StatelessWidget {
  const _EmptyQuestionsState({required this.onLeave});

  final Future<void> Function() onLeave;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'No Questions Available',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            'The shared question bank could not prepare a room match.',
            style: TextStyle(color: Colors.white.withOpacity(0.74)),
          ),
          const SizedBox(height: 16),
          NeonButton(
            label: 'Leave Room',
            icon: Icons.logout_rounded,
            compact: true,
            onPressed: () => onLeave(),
          ),
        ],
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({
    required this.rank,
    required this.username,
    required this.photoUrl,
    required this.score,
    required this.answeredCount,
    required this.isCurrentUser,
    required this.isCompleted,
  });

  final int rank;
  final String username;
  final String? photoUrl;
  final int score;
  final int answeredCount;
  final bool isCurrentUser;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isCurrentUser
            ? const Color(0xFFFACC15).withOpacity(0.12)
            : Colors.white.withOpacity(0.06),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFFFCD34D)
              : Colors.white.withOpacity(0.10),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF0F172A),
            backgroundImage:
                photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
            child: photoUrl?.isNotEmpty == true
                ? null
                : const Icon(Icons.person_rounded,
                    color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isCurrentUser ? '$username (You)' : username,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  isCompleted ? 'Finished' : 'Still playing',
                  style: TextStyle(
                    color:
                        isCompleted ? const Color(0xFF34D399) : Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '$score pts',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '$answeredCount answered',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomQuestion {
  const _RoomQuestion({
    required this.prompt,
    required this.answers,
    required this.correctIndex,
    required this.level,
  });

  final String prompt;
  final List<String> answers;
  final int correctIndex;
  final String level;

  factory _RoomQuestion.fromMap(Map<String, dynamic> map, int seed) {
    final entries = <_AnswerEntry>[
      _AnswerEntry(text: (map['R'] ?? '').toString(), correct: true),
      _AnswerEntry(text: (map['W1'] ?? '').toString(), correct: false),
      _AnswerEntry(text: (map['W2'] ?? '').toString(), correct: false),
      _AnswerEntry(text: (map['W3'] ?? '').toString(), correct: false),
    ]..removeWhere((entry) => entry.text.trim().isEmpty);

    _RoomGameScreenState._shuffleInPlace(entries, Random(seed));
    final correctIndex = entries.indexWhere((entry) => entry.correct);

    return _RoomQuestion(
      prompt: (map['Q'] ?? '').toString(),
      answers: entries.map((entry) => entry.text).toList(growable: false),
      correctIndex: correctIndex,
      level: (map['Level'] ?? '').toString(),
    );
  }
}

class _AnswerEntry {
  const _AnswerEntry({
    required this.text,
    required this.correct,
  });

  final String text;
  final bool correct;
}

class _RankingEntry {
  const _RankingEntry({
    required this.userId,
    required this.username,
    required this.photoUrl,
    required this.player,
  });

  final String userId;
  final String username;
  final String? photoUrl;
  final RoomPlayer player;
}
