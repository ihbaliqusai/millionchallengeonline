import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/native_bridge_service.dart';
import '../services/profile_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required AuthService authService,
    required ProfileService profileService,
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

  // ── Level / XP ──────────────────────────────────────────────────────────────
  int level = 1;
  int xp = 0;
  int xpInCurrentLevel = 0;
  int xpNeededForLevel = 100;
  int _lastKnownGamesPlayed = -1;
  int _lastKnownWins        = -1;
  bool _checkingXp          = false;

  static int _computeLevel(int totalXp) {
    int lv = 1;
    int remaining = totalXp;
    while (remaining >= lv * 100) {
      remaining -= lv * 100;
      lv++;
    }
    return lv;
  }

  static int _computeXpInLevel(int totalXp) {
    int lv = 1;
    int remaining = totalXp;
    while (remaining >= lv * 100) {
      remaining -= lv * 100;
      lv++;
    }
    return remaining;
  }

  Future<void> loadLevelData() async {
    final uid = user?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      xp = (data['xp'] as num?)?.toInt() ?? 0;
      _lastKnownGamesPlayed = (data['lastKnownGamesPlayed'] as num?)?.toInt() ?? -1;
      _lastKnownWins        = (data['lastKnownWins']        as num?)?.toInt() ?? -1;
      level = _computeLevel(xp);
      xpInCurrentLevel = _computeXpInLevel(xp);
      xpNeededForLevel = level * 100;
      notifyListeners();
      // After Firestore data is ready, check for new games immediately
      unawaited(checkAndAwardXpForGames());
    } catch (_) {}
  }

  // XP constants — keep in sync with PlayerProgress.java
  static const int xpPerWin  = 100;
  static const int xpPerLoss = 30;

  Future<void> checkAndAwardXpForGames() async {
    if (_checkingXp) return;
    _checkingXp = true;
    final uid = user?.uid;
    if (uid == null) { _checkingXp = false; return; }
    try {
      final stats = await _nativeBridgeService.getPlayerStats();
      final gamesPlayed = stats['gamesPlayed'] ?? 0;
      final wins       = stats['wins']        ?? 0;

      // First run: just snapshot, no XP awarded yet
      if (_lastKnownGamesPlayed < 0) {
        _lastKnownGamesPlayed = gamesPlayed;
        _lastKnownWins        = wins;
        await _firestore.collection('users').doc(uid).set(
          {'lastKnownGamesPlayed': _lastKnownGamesPlayed, 'lastKnownWins': _lastKnownWins},
          SetOptions(merge: true),
        );
        return;
      }

      final newGames = gamesPlayed - _lastKnownGamesPlayed;
      if (newGames > 0) {
        final newWins   = (wins - _lastKnownWins).clamp(0, newGames);
        final newLosses = newGames - newWins;
        final earned    = newWins * xpPerWin + newLosses * xpPerLoss;

        xp += earned;
        _lastKnownGamesPlayed = gamesPlayed;
        _lastKnownWins        = wins;
        level             = _computeLevel(xp);
        xpInCurrentLevel  = _computeXpInLevel(xp);
        xpNeededForLevel  = level * 100;
        notifyListeners();
        await _firestore.collection('users').doc(uid).set(
          {
            'xp': xp,
            'level': level,
            'trophies': wins * 30,
            'lastKnownGamesPlayed': gamesPlayed,
            'lastKnownWins': wins,
          },
          SetOptions(merge: true),
        );
      }
    } catch (_) {
    } finally {
      _checkingXp = false;
    }
  }

  Future<void> initialize() async {}

  Future<void> _onAuthChanged(User? nextUser) async {
    user = nextUser;

    if (nextUser != null) {
      unawaited(_syncLegacyUser());
      unawaited(loadCurrency());
      unawaited(loadLevelData());
    } else {
      unawaited(_nativeBridgeService.resetLegacyUser());
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _runBusy(() => _authService.signInWithEmail(email: email, password: password));
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
    await _runBusy(() => _authService.updateUsername(username));
    await _syncLegacyUser();
  }

  Future<void> signOut() async {
    await _runBusy(_authService.signOut);
    await _nativeBridgeService.resetLegacyUser();
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

    return 'Guest';
  }

  String? _resolvedPhotoUrl(User user) {
    final authPhoto = user.photoURL?.trim();
    if (authPhoto != null && authPhoto.isNotEmpty) {
      return authPhoto;
    }
    return null;
  }
}
