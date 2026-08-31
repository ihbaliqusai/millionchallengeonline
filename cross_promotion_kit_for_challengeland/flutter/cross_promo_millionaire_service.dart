import 'package:flutter/services.dart';

class CrossPromoMillionaireService {
  static const MethodChannel _channel = MethodChannel('millionaire/native');

  static const String millionairePackageName = 'net.androidgaming.millionaire2024';
  static const String millionairePlayStoreUrl =
      'https://play.google.com/store/apps/details?id=net.androidgaming.millionaire2024';

  static Future<bool> isInstalled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAppInstalled', {
        'packageName': millionairePackageName,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> launchMillionaire() async {
    try {
      final result = await _channel.invokeMethod<bool>('launchAppOrPlayStore', {
        'packageName': millionairePackageName,
        'url': millionairePlayStoreUrl,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
