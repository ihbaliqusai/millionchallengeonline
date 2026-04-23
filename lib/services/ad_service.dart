import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService extends ChangeNotifier {
  // ── Test IDs (replace with real IDs before publishing) ──────────────────────
  static const String _rewardedId = 'ca-app-pub-2427194500639575/4290411051';
  static const String _interstitialId =
      'ca-app-pub-2427194500639575/3315194558';

  // ── Reward config ────────────────────────────────────────────────────────────
  static const int rewardCoins = 100;
  static const int rewardGems = 5;
  static const int maxDailyWatches = 5;
  static const int dailyPowerUpGoal = 5;
  static const Duration cooldown = Duration(hours: 1);
  static const String _prefsWatchesToday = 'ads.watchesToday';
  static const String _prefsLastWatchAt = 'ads.lastWatchAtMillis';
  static const String _prefsNextAvailableAt = 'ads.nextAvailableAtMillis';
  static const String _prefsBonusClaimedAt = 'ads.bonusClaimedAtMillis';

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;

  bool _rewardedLoading = false;
  bool _interstitialLoading = false;
  SharedPreferences? _prefs;
  bool _privacyOptionsRequired = false;

  int _watchesToday = 0;
  DateTime? _lastWatchDate;
  DateTime? _nextAvailableAt;
  DateTime? _bonusClaimedAt;

  bool get canWatchAd {
    _resetIfNewDay();
    if (_watchesToday >= maxDailyWatches) {
      return false;
    }
    if (_nextAvailableAt != null &&
        DateTime.now().isBefore(_nextAvailableAt!)) {
      return false;
    }
    return true;
  }

  bool get privacyOptionsRequired => _privacyOptionsRequired;

  int get watchesLeft {
    _resetIfNewDay();
    return (maxDailyWatches - _watchesToday).clamp(0, maxDailyWatches);
  }

  int get watchesToday {
    _resetIfNewDay();
    return _watchesToday;
  }

  bool get hasClaimedDailyPowerUp {
    _resetIfNewDay();
    return _isSameDay(_bonusClaimedAt, DateTime.now());
  }

  bool get canClaimDailyPowerUp {
    _resetIfNewDay();
    return _watchesToday >= dailyPowerUpGoal && !hasClaimedDailyPowerUp;
  }

  Duration get cooldownRemaining {
    if (_nextAvailableAt == null) return Duration.zero;
    final remaining = _nextAvailableAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<bool> claimDailyPowerUp() async {
    _resetIfNewDay();
    if (!canClaimDailyPowerUp) {
      return false;
    }
    _bonusClaimedAt = DateTime.now();
    await _persistState();
    notifyListeners();
    return true;
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _restoreState();
    await MobileAds.instance.initialize();
    await _refreshConsent();
    await _loadAdsIfAllowed();
  }

  Future<FormError?> showPrivacyOptionsForm() async {
    final completer = Completer<FormError?>();
    await ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (!completer.isCompleted) {
        completer.complete(error);
      }
    });
    _privacyOptionsRequired = await _resolvePrivacyOptionsRequirement();
    await _loadAdsIfAllowed();
    notifyListeners();
    return completer.future;
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

  Future<void> _refreshConsent() async {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((FormError? _) {});
        _privacyOptionsRequired = await _resolvePrivacyOptionsRequirement();
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      (FormError _) async {
        _privacyOptionsRequired = await _resolvePrivacyOptionsRequirement();
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );
    await completer.future;
    notifyListeners();
  }

  Future<void> _loadAdsIfAllowed() async {
    if (await ConsentInformation.instance.canRequestAds()) {
      _loadRewarded();
      _loadInterstitial();
    }
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
    unawaited(_persistState());
    notifyListeners();
  }

  void _resetIfNewDay() {
    final now = DateTime.now();
    var shouldPersist = false;
    if (_lastWatchDate != null) {
      final last = _lastWatchDate!;
      if (last.year != now.year ||
          last.month != now.month ||
          last.day != now.day) {
        final hadState = _watchesToday != 0 || _nextAvailableAt != null;
        _watchesToday = 0;
        _nextAvailableAt = null;
        shouldPersist = shouldPersist || hadState;
      }
    }
    if (_bonusClaimedAt != null && !_isSameDay(_bonusClaimedAt, now)) {
      _bonusClaimedAt = null;
      shouldPersist = true;
    }
    if (shouldPersist) {
      unawaited(_persistState());
    }
  }

  void _restoreState() {
    final prefs = _prefs;
    if (prefs == null) return;

    _watchesToday = prefs.getInt(_prefsWatchesToday) ?? 0;
    final lastWatchAtMillis = prefs.getInt(_prefsLastWatchAt);
    final nextAvailableAtMillis = prefs.getInt(_prefsNextAvailableAt);
    final bonusClaimedAtMillis = prefs.getInt(_prefsBonusClaimedAt);

    if (lastWatchAtMillis != null && lastWatchAtMillis > 0) {
      _lastWatchDate = DateTime.fromMillisecondsSinceEpoch(lastWatchAtMillis);
    }
    if (nextAvailableAtMillis != null && nextAvailableAtMillis > 0) {
      _nextAvailableAt =
          DateTime.fromMillisecondsSinceEpoch(nextAvailableAtMillis);
    }
    if (bonusClaimedAtMillis != null && bonusClaimedAtMillis > 0) {
      _bonusClaimedAt =
          DateTime.fromMillisecondsSinceEpoch(bonusClaimedAtMillis);
    }

    _resetIfNewDay();
    notifyListeners();
  }

  Future<void> _persistState() async {
    final prefs = _prefs;
    if (prefs == null) return;

    await prefs.setInt(_prefsWatchesToday, _watchesToday);
    if (_lastWatchDate == null) {
      await prefs.remove(_prefsLastWatchAt);
    } else {
      await prefs.setInt(
        _prefsLastWatchAt,
        _lastWatchDate!.millisecondsSinceEpoch,
      );
    }

    if (_nextAvailableAt == null) {
      await prefs.remove(_prefsNextAvailableAt);
    } else {
      await prefs.setInt(
        _prefsNextAvailableAt,
        _nextAvailableAt!.millisecondsSinceEpoch,
      );
    }

    if (_bonusClaimedAt == null) {
      await prefs.remove(_prefsBonusClaimedAt);
    } else {
      await prefs.setInt(
        _prefsBonusClaimedAt,
        _bonusClaimedAt!.millisecondsSinceEpoch,
      );
    }
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime? left, DateTime? right) {
    if (left == null || right == null) {
      return false;
    }
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  Future<bool> _resolvePrivacyOptionsRequirement() async {
    final status =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }
}
