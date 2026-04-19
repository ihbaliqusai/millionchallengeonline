import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  // ── Test IDs (replace with real IDs before publishing) ──────────────────────
  static const String _rewardedId =
      'ca-app-pub-2427194500639575/4290411051';
  static const String _interstitialId =
      'ca-app-pub-2427194500639575/3315194558';

  // ── Reward config ────────────────────────────────────────────────────────────
  static const int rewardCoins = 100;
  static const int rewardGems = 5;
  static const int maxDailyWatches = 5;
  static const Duration cooldown = Duration(hours: 1);

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;

  bool _rewardedLoading = false;
  bool _interstitialLoading = false;

  int _watchesToday = 0;
  DateTime? _lastWatchDate;
  DateTime? _nextAvailableAt;

  bool get canWatchAd {
    _resetIfNewDay();
    if (_watchesToday >= maxDailyWatches) { return false; }
    if (_nextAvailableAt != null &&
        DateTime.now().isBefore(_nextAvailableAt!)) { return false; }
    return true;
  }

  int get watchesLeft {
    _resetIfNewDay();
    return (maxDailyWatches - _watchesToday).clamp(0, maxDailyWatches);
  }

  Duration get cooldownRemaining {
    if (_nextAvailableAt == null) return Duration.zero;
    final remaining = _nextAvailableAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadRewarded();
    _loadInterstitial();
  }

  void _loadRewarded() {
    if (_rewardedLoading) return;
    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedLoading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _rewardedLoading = false;
          Future.delayed(const Duration(seconds: 30), _loadRewarded);
        },
      ),
    );
  }

  void _loadInterstitial() {
    if (_interstitialLoading) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _interstitialLoading = false;
          Future.delayed(const Duration(seconds: 30), _loadInterstitial);
        },
      ),
    );
  }

  /// Shows a rewarded ad. Returns {coins, gems} on success, null if cancelled/unavailable.
  Future<Map<String, int>?> showRewardedAd() async {
    if (!canWatchAd) return null;
    final ad = _rewardedAd;
    if (ad == null) return null;

    final completer = Completer<Map<String, int>?>();
    _rewardedAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(null);
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(null);
      },
    );

    ad.show(
      onUserEarnedReward: (_, __) {
        _recordWatch();
        if (!completer.isCompleted) {
          completer.complete({'coins': rewardCoins, 'gems': rewardGems});
        }
      },
    );

    return completer.future;
  }

  /// Shows an interstitial ad (no reward). Fire-and-forget.
  void showInterstitialAd() {
    final ad = _interstitialAd;
    if (ad == null) return;
    _interstitialAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _loadInterstitial();
      },
    );

    ad.show();
  }

  void _recordWatch() {
    _resetIfNewDay();
    _watchesToday++;
    _lastWatchDate = DateTime.now();
    _nextAvailableAt = DateTime.now().add(cooldown);
    notifyListeners();
  }

  void _resetIfNewDay() {
    final now = DateTime.now();
    if (_lastWatchDate != null) {
      final last = _lastWatchDate!;
      if (last.year != now.year ||
          last.month != now.month ||
          last.day != now.day) {
        _watchesToday = 0;
      }
    }
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }
}
