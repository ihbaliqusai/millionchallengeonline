import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/native_bridge_service.dart';
import 'player_rank.dart';
import 'trophy_league.dart';

class AppState extends ChangeNotifier {
  AppState({
    required AuthService authService,
    required NativeBridgeService nativeBridgeService,
  })  : _authService = authService,
        _nativeBridgeService = nativeBridgeService {
    _authSubscription = _authService.authStateChanges().listen(_onAuthChanged);
  }

  final AuthService _authService;
  final NativeBridgeService _nativeBridgeService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;

  User? user;
  bool isBusy = false;
  String? error;
  int coins = 0;
  int gems = 0;
  int trophies = 0;
  int streakDay = 0;
  bool claimedToday = false;
  bool _claimingStreak = false;

  static const List<Map<String, int>> _kStreakRewards = [
    {'coins': 100, 'gems': 0},
    {'coins': 150, 'gems': 0},
    {'coins': 200, 'gems': 1},
    {'coins': 250, 'gems': 0},
    {'coins': 300, 'gems': 1},
    {'coins': 400, 'gems': 2},
    {'coins': 500, 'gems': 3},
    {'coins': 300, 'gems': 1},
    {'coins': 350, 'gems': 1},
    {'coins': 400, 'gems': 2},
    {'coins': 450, 'gems': 2},
    {'coins': 500, 'gems': 3},
    {'coins': 600, 'gems': 3},
    {'coins': 800, 'gems': 5},
    {'coins': 400, 'gems': 2},
    {'coins': 450, 'gems': 2},
    {'coins': 500, 'gems': 3},
    {'coins': 550, 'gems': 3},
    {'coins': 600, 'gems': 4},
    {'coins': 700, 'gems': 4},
    {'coins': 1000, 'gems': 7},
    {'coins': 600, 'gems': 3},
    {'coins': 650, 'gems': 4},
    {'coins': 700, 'gems': 4},
    {'coins': 750, 'gems': 5},
    {'coins': 800, 'gems': 5},
    {'coins': 900, 'gems': 6},
    {'coins': 1000, 'gems': 7},
    {'coins': 1200, 'gems': 8},
    {'coins': 2000, 'gems': 15},
  ];

  /// Returns the reward {coins, gems} if claimed, or null if already claimed / error.
  Future<Map<String, int>?> claimDailyStreak() async {
    if (claimedToday || _claimingStreak) return null;
    _claimingStreak = true;
    notifyListeners();

    final uid = user?.uid;
    if (uid == null) {
      _claimingStreak = false;
      notifyListeners();
      return null;
    }

    final day = streakDay > 0 ? streakDay : 1;
    final reward =
        _kStreakRewards[(day - 1).clamp(0, _kStreakRewards.length - 1)];
    final rewardCoins = reward['coins'] ?? 0;
    final rewardGems = reward['gems'] ?? 0;

    try {
      await _firestore.collection('users').doc(uid).set(
        {
          'streakDay': day,
          'lastStreakClaimDate': Timestamp.fromDate(DateTime.now()),
        },
        SetOptions(merge: true),
      );

      final balances = await _nativeBridgeService.grantCurrency(
        coins: rewardCoins,
        gems: rewardGems,
      );

      coins = balances['coins'] ?? (coins + rewardCoins);
      gems = balances['gems'] ?? (gems + rewardGems);
      claimedToday = true;
      streakDay = day;
    } catch (_) {
      _claimingStreak = false;
      notifyListeners();
      return null;
    }

    _claimingStreak = false;
    notifyListeners();
    return reward;
  }

  // ── Level / XP ──────────────────────────────────────────────────────────────
  int level = 1;
  int xp = 0;
  int xpInCurrentLevel = 0;
  int xpNeededForLevel = 100;
  int _lastKnownGamesPlayed = -1;
  int _lastKnownWins = -1;
  bool _checkingXp = false;

  static int _computeLevel(int totalXp) {
    return PlayerRank.levelForXp(totalXp);
  }

  static int _computeXpInLevel(int totalXp) {
    return PlayerRank.xpIntoLevel(totalXp);
  }

  Future<void> loadLevelData() async {
    final uid = user?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      xp = (data['xp'] as num?)?.toInt() ?? 0;
      _lastKnownGamesPlayed =
          (data['lastKnownGamesPlayed'] as num?)?.toInt() ?? -1;
      _lastKnownWins = (data['lastKnownWins'] as num?)?.toInt() ?? -1;
      level = _computeLevel(xp);
      xpInCurrentLevel = _computeXpInLevel(xp);
      xpNeededForLevel = PlayerRank.xpNeededForLevel(level);
      trophies = (data['trophies'] as num?)?.toInt() ?? 0;

      // Streak data
      final lastClaimTs = data['lastStreakClaimDate'] as Timestamp?;
      final savedStreakDay = (data['streakDay'] as num?)?.toInt() ?? 0;
      if (lastClaimTs == null) {
        streakDay = 1;
        claimedToday = false;
      } else {
        final lastClaim = lastClaimTs.toDate();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final lastDay =
            DateTime(lastClaim.year, lastClaim.month, lastClaim.day);
        final diff = today.difference(lastDay).inDays;
        if (diff == 0) {
          streakDay = savedStreakDay.clamp(1, 30);
          claimedToday = true;
        } else if (diff == 1) {
          streakDay =
              savedStreakDay >= 30 ? 1 : (savedStreakDay + 1).clamp(1, 30);
          claimedToday = false;
        } else {
          // Streak broken — reset to day 1
          streakDay = 1;
          claimedToday = false;
        }
      }
      notifyListeners();
    } catch (e) {
      // Firestore read failed (offline/network). Retain defaults and notify
      // so UI shows day 1 rather than an endless spinner.
      streakDay = streakDay > 0 ? streakDay : 1;
      notifyListeners();
    }
    unawaited(checkAndAwardXpForGames());
  }

  Future<void> checkAndAwardXpForGames() async {
    if (_checkingXp) return;
    _checkingXp = true;
    final uid = user?.uid;
    if (uid == null) {
      _checkingXp = false;
      return;
    }
    try {
      final stats = await _nativeBridgeService.getPlayerStats();
      final gamesPlayed = stats['gamesPlayed'] ?? 0;
      final wins = stats['wins'] ?? 0;
      final nativeXp = stats['xp'] ?? xp;
      final effectiveXp = nativeXp > xp ? nativeXp : xp;
      final computedLevel = _computeLevel(effectiveXp);
      final computedTrophies = TrophyProgression.computeTrophies(stats);
      final statsChanged =
          gamesPlayed != _lastKnownGamesPlayed || wins != _lastKnownWins;
      final xpChanged = xp != effectiveXp;
      final levelChanged = level != computedLevel;
      final trophiesChanged = trophies != computedTrophies;

      _lastKnownGamesPlayed = gamesPlayed;
      _lastKnownWins = wins;
      xp = effectiveXp;
      level = computedLevel;
      xpInCurrentLevel = _computeXpInLevel(effectiveXp);
      xpNeededForLevel = PlayerRank.xpNeededForLevel(level);
      trophies = computedTrophies;

      if (xpChanged || levelChanged || trophiesChanged) {
        notifyListeners();
      }

      if (statsChanged || xpChanged || levelChanged || trophiesChanged) {
        await _firestore.collection('users').doc(uid).set(
          {
            'xp': xp,
            'level': level,
            'trophies': trophies,
            'lastKnownGamesPlayed': gamesPlayed,
            'lastKnownWins': wins,
          },
          SetOptions(merge: true),
        );
        await _syncPublicProfile(
          level: level,
          trophies: trophies,
        );
      }
    } catch (_) {
    } finally {
      _checkingXp = false;
    }
  }

  Future<void> _onAuthChanged(User? nextUser) async {
    user = nextUser;

    if (nextUser != null) {
      unawaited(_syncPublicProfile());
      unawaited(_syncLegacyUser());
      unawaited(loadCurrency());
      unawaited(loadLevelData());
    } else {
      _resetSessionState();
      unawaited(_nativeBridgeService.resetLegacyUser());
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _runBusy(
        () => _authService.signInWithEmail(email: email, password: password));
  }

  Future<void> register(String email, String password, String username) async {
    await _runBusy(
      () => _authService.registerWithEmail(
        email: email,
        password: password,
        username: username,
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    await _runBusy(_authService.signInWithGoogle);
  }

  Future<void> updateUsername(String username) async {
    await _authService.updateUsername(username);
    await _syncLegacyUser();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _runBusy(_authService.signOut);
    await _nativeBridgeService.resetLegacyUser();
  }

  Future<void> deleteAccount({String? password}) async {
    await _runBusy(
      () => _authService.deleteCurrentAccount(password: password),
    );
    try {
      await _nativeBridgeService.resetLocalProgress();
    } catch (_) {
      // Account deletion already succeeded remotely; local cleanup is best-effort.
    }
    _resetSessionState();
    notifyListeners();
  }

  Future<void> openAuthenticatedLanding() async {
    final currentUser = user;
    if (currentUser == null) return;
    await _syncLegacyUser();
    await _nativeBridgeService.launchLegacyGame();
  }

  Future<void> openOfflineGame() async {
    await _syncLegacyUser();
    await _nativeBridgeService.launchOfflineGame();
  }

  Future<void> openStats() async {
    await _syncLegacyUser();
    await _nativeBridgeService.launchStats();
  }

  Future<void> openAchievements() async {
    await _syncLegacyUser();
    await _nativeBridgeService.launchAchievements();
  }

  Future<void> openStore() async {
    await _syncLegacyUser();
    await _nativeBridgeService.launchStore();
  }

  Future<void> openNativeSettings() async {
    await _nativeBridgeService.launchNativeSettings();
  }

  Future<void> openSpeedBattle() async {
    await _syncLegacyUser();
    await _nativeBridgeService.launchSpeedBattle();
  }

  Future<void> loadCurrency() async {
    try {
      final data = await _nativeBridgeService.getUserCurrency();
      coins = data['coins'] ?? 0;
      gems = data['gems'] ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _syncLegacyUser() async {
    final currentUser = user;
    if (currentUser == null) return;

    await _nativeBridgeService.syncLegacyUser(
      uid: currentUser.uid,
      username: _resolvedUsername(currentUser),
      photoUrl: _resolvedPhotoUrl(currentUser),
    );
  }

  Future<void> _syncPublicProfile({
    int? level,
    int? trophies,
  }) async {
    final currentUser = user;
    if (currentUser == null) return;

    try {
      await _firestore.collection('public_profiles').doc(currentUser.uid).set(
        <String, dynamic>{
          'uid': currentUser.uid,
          'username': _resolvedUsername(currentUser),
          'photoUrl': _resolvedPhotoUrl(currentUser),
          'level': level ?? this.level,
          'trophies': trophies ?? this.trophies,
          'lastSeenAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Keep gameplay responsive if Firestore is temporarily unavailable.
    }
  }

  Future<void> _runBusy(Future<dynamic> Function() action) async {
    try {
      isBusy = true;
      error = null;
      notifyListeners();
      await action();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  String _resolvedUsername(User user) {
    final candidates = <String?>[
      user.displayName,
      user.email?.split('@').first,
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

  String? _resolvedPhotoUrl(User user) {
    final authPhoto = user.photoURL?.trim();
    if (authPhoto != null && authPhoto.isNotEmpty) {
      return authPhoto;
    }
    return null;
  }

  void _resetSessionState() {
    coins = 0;
    gems = 0;
    trophies = 0;
    streakDay = 0;
    claimedToday = false;
    level = 1;
    xp = 0;
    xpInCurrentLevel = 0;
    xpNeededForLevel = PlayerRank.xpNeededForLevel(1);
    _lastKnownGamesPlayed = -1;
    _lastKnownWins = -1;
  }
}
