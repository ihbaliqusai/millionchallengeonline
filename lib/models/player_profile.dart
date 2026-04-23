import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerProfile {
  PlayerProfile({
    required this.uid,
    required this.email,
    required this.username,
    required this.photoUrl,
    required this.wins,
    required this.losses,
    required this.totalMatches,
    required this.totalScore,
    required this.rating,
    required this.createdAt,
    required this.lastSeenAt,
  });

  final String uid;
  final String email;
  final String username;
  final String? photoUrl;
  final int wins;
  final int losses;
  final int totalMatches;
  final int totalScore;
  final int rating;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

  factory PlayerProfile.empty() => PlayerProfile(
        uid: '',
        email: '',
        username: 'لاعب',
        photoUrl: null,
        wins: 0,
        losses: 0,
        totalMatches: 0,
        totalScore: 0,
        rating: 1000,
        createdAt: null,
        lastSeenAt: null,
      );

  factory PlayerProfile.fromMap(Map<String, dynamic> map) => PlayerProfile(
        uid: (map['uid'] ?? '').toString(),
        email: (map['email'] ?? '').toString(),
        username: _resolveUsername(map),
        photoUrl: map['photoUrl']?.toString(),
        wins: (map['wins'] as num?)?.toInt() ?? 0,
        losses: (map['losses'] as num?)?.toInt() ?? 0,
        totalMatches: (map['totalMatches'] as num?)?.toInt() ?? 0,
        totalScore: (map['totalScore'] as num?)?.toInt() ?? 0,
        rating: (map['rating'] as num?)?.toInt() ?? 1000,
        createdAt: _readDate(map['createdAt']),
        lastSeenAt: _readDate(map['lastSeenAt']),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'uid': uid,
        'email': email,
        'username': username,
        'photoUrl': photoUrl,
        'wins': wins,
        'losses': losses,
        'totalMatches': totalMatches,
        'totalScore': totalScore,
        'rating': rating,
        'createdAt': createdAt,
        'lastSeenAt': lastSeenAt,
      };

  PlayerProfile copyWith({
    String? uid,
    String? email,
    String? username,
    String? photoUrl,
    int? wins,
    int? losses,
    int? totalMatches,
    int? totalScore,
    int? rating,
    DateTime? createdAt,
    DateTime? lastSeenAt,
  }) {
    return PlayerProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      totalMatches: totalMatches ?? this.totalMatches,
      totalScore: totalScore ?? this.totalScore,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static String _resolveUsername(Map<String, dynamic> map) {
    final candidates = <String?>[
      map['username']?.toString(),
      map['playerName']?.toString(),
      map['displayName']?.toString(),
      map['name']?.toString(),
      map['email']?.toString().split('@').first,
    ];

    for (final candidate in candidates) {
      final normalized = candidate?.trim() ?? '';
      if (normalized.isEmpty) continue;
      final lowered = normalized.toLowerCase();
      if (lowered == 'guest' || lowered == 'player') continue;
      return normalized;
    }

    return 'لاعب';
  }
}
