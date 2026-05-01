import 'package:flutter/material.dart';

import '../services/native_bridge_service.dart';

class AppSettings extends ChangeNotifier {
  AppSettings(this._nativeBridgeService);

  final NativeBridgeService _nativeBridgeService;

  bool loading = true;
  bool sfx = true;
  bool music = true;
  bool haptic = true;
  bool notifications = true;
  bool systemNotifications = true;
  bool dialogs = true;
  String languageCode = 'ar';

  Locale get locale => Locale(languageCode);
  bool get isArabic => languageCode == 'ar';

  Future<void> load() async {
    try {
      final settings = await _nativeBridgeService.getSettings();
      sfx = settings['sfx'] as bool? ?? true;
      music = settings['music'] as bool? ?? true;
      haptic = settings['haptic'] as bool? ?? true;
      notifications = settings['notifications'] as bool? ?? true;
      systemNotifications = settings['systemNotifications'] as bool? ?? true;
      dialogs = settings['dialogs'] as bool? ?? true;
      languageCode = _normalizeLanguage(settings['language'] as String?);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> setSfx(bool value) async {
    sfx = value;
    notifyListeners();
    await _nativeBridgeService.setSoundEnabled(value);
  }

  Future<void> setMusic(bool value) async {
    music = value;
    notifyListeners();
    await _nativeBridgeService.setMusicEnabled(value);
  }

  Future<void> setHaptic(bool value) async {
    haptic = value;
    notifyListeners();
    await _nativeBridgeService.setHapticEnabled(value);
  }

  Future<void> setNotifications(bool value) async {
    notifications = value;
    notifyListeners();
    await _nativeBridgeService.setNotificationsEnabled(value);
    final refreshed = await _nativeBridgeService.getSettings();
    systemNotifications =
        refreshed['systemNotifications'] as bool? ?? systemNotifications;
    notifyListeners();
  }

  Future<void> setDialogs(bool value) async {
    dialogs = value;
    notifyListeners();
    await _nativeBridgeService.setDialogsEnabled(value);
  }

  Future<void> setLanguage(String value) async {
    final normalized = _normalizeLanguage(value);
    languageCode = normalized;
    notifyListeners();
    await _nativeBridgeService.setLanguage(normalized);
  }

  Future<void> openNotificationSettings() {
    return _nativeBridgeService.openNotificationSettings();
  }

  String _normalizeLanguage(String? value) {
    return value == 'en' ? 'en' : 'ar';
  }
}
