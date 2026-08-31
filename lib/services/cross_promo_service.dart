import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'native_bridge_service.dart';

class CrossPromoService extends ChangeNotifier {
  CrossPromoService({NativeBridgeService? nativeBridge})
      : _native = nativeBridge ?? NativeBridgeService();

  final NativeBridgeService _native;

  static const String challengeLandPackageName =
      'com.qi7bali.landchallengeonline';
  static const String challengeLandPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.qi7bali.landchallengeonline';

  static const String _prefLastShownKey = 'cross_promo_challengeland_last_shown';
  static const String _prefImpressionsKey =
      'cross_promo_challengeland_impressions';

  bool _isInstalled = false;
  bool _checked = false;

  bool get isInstalled => _isInstalled;
  bool get hasChecked => _checked;

  /// فحص هل لعبة أرض التحدي مثبتة على جهاز المستخدم
  Future<bool> checkInstallation() async {
    try {
      _isInstalled = await _native.isAppInstalled(challengeLandPackageName);
      _checked = true;
      notifyListeners();
      return _isInstalled;
    } catch (_) {
      _isInstalled = false;
      _checked = true;
      notifyListeners();
      return false;
    }
  }

  /// فتح اللعبة إذا كانت مثبتة أو التوجيه لصفحتها على Google Play
  Future<bool> launchChallengeLand() async {
    final success = await _native.launchAppOrPlayStore(
      packageName: challengeLandPackageName,
      url: challengeLandPlayStoreUrl,
    );
    return success;
  }

  /// تسجيل عرض النافذة المنبثقة للتحكم بالتردد
  Future<void> recordImpression() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_prefImpressionsKey) ?? 0;
      await prefs.setInt(_prefImpressionsKey, current + 1);
      await prefs.setInt(
        _prefLastShownKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  /// فحص هل حان وقت العرض التلقائي دون إزعاج
  Future<bool> shouldAutoShow({Duration minInterval = const Duration(hours: 4)}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getInt(_prefLastShownKey) ?? 0;
      if (lastShown == 0) return true;
      final diff = DateTime.now().millisecondsSinceEpoch - lastShown;
      return diff >= minInterval.inMilliseconds;
    } catch (_) {
      return false;
    }
  }
}
