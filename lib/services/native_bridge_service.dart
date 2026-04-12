import 'dart:convert';

import 'package:flutter/services.dart';

class NativeBridgeService {
  static const MethodChannel _channel = MethodChannel('millionaire/native');

  Future<void> launchLegacyGame() async {
    await _channel.invokeMethod('launchOriginal');
  }

  Future<void> launchLegacyRoomMatch({
    required List<Map<String, dynamic>> opponents,
    required bool meOwner,
  }) async {
    final safeOpponents = opponents
        .map(
          (opponent) => <String, dynamic>{
            'id': (opponent['id'] ?? '').toString(),
            'name': (opponent['name'] ?? '').toString(),
            'photo': (opponent['photo'] ?? '').toString(),
            'level': (opponent['level'] as num?)?.toInt() ?? 1,
            'intelligence': (opponent['intelligence'] as num?)?.toInt() ?? 0,
            'score': (opponent['score'] as num?)?.toInt() ?? 0,
            'bot': opponent['bot'] == true,
          },
        )
        .toList(growable: false);

    await _channel.invokeMethod('launchRoomMatch', <String, dynamic>{
      'opponentsJson': jsonEncode(safeOpponents),
      'meOwner': meOwner,
    });
  }

  Future<void> syncLegacyUser({
    required String uid,
    required String username,
    String? photoUrl,
  }) async {
    await _channel.invokeMethod('syncLegacyUser', <String, dynamic>{
      'uid': uid,
      'username': username,
      'photoUrl': photoUrl ?? '',
    });
  }

  Future<void> resetLegacyUser() async {
    await _channel.invokeMethod('resetLegacyUser');
  }

  Future<void> launchOfflineGame() async {
    await _channel.invokeMethod('launchOfflineGame');
  }

  Future<void> launchStats() async {
    await _channel.invokeMethod('launchStats');
  }

  Future<void> launchAchievements() async {
    await _channel.invokeMethod('launchAchievements');
  }

  Future<void> launchStore() async {
    await _channel.invokeMethod('launchStore');
  }

  Future<void> launchNativeSettings() async {
    await _channel.invokeMethod('launchSettings');
  }

  Future<void> launchSpeedBattle() async {
    await _channel.invokeMethod('launchSpeedBattle');
  }

  /// يُعيد إحصائيات اللاعب الحقيقية من PlayerStats
  Future<Map<String, int>> getPlayerStats() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('getPlayerStats');
    if (result == null) return {};
    return result.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  /// يُعيد {'coins': int, 'gems': int} من SharedPreferences الـ native
  Future<Map<String, int>> getUserCurrency() async {
    final result = await _channel.invokeMapMethod<String, int>('getUserCurrency');
    return result ?? {'coins': 0, 'gems': 0};
  }

  /// يُعيد قيم الإعدادات المحفوظة من Android SharedPreferences
  Future<Map<String, bool>> getSettings() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('getSettings');
    return {
      'sfx':    result?['sfx']    as bool? ?? true,
      'music':  result?['music']  as bool? ?? true,
      'haptic': result?['haptic'] as bool? ?? true,
    };
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await _channel.invokeMethod<void>('setSoundEnabled', {'enabled': enabled});
  }

  Future<void> setMusicEnabled(bool enabled) async {
    await _channel.invokeMethod<void>('setMusicEnabled', {'enabled': enabled});
  }

  Future<void> setHapticEnabled(bool enabled) async {
    await _channel.invokeMethod<void>('setHapticEnabled', {'enabled': enabled});
  }

  Future<void> openNotificationSettings() async {
    await _channel.invokeMethod<void>('openNotificationSettings');
  }

  Future<bool> restorePurchases() async {
    final result = await _channel.invokeMethod<bool>('restorePurchases');
    return result ?? false;
  }

  /// يُعيد كميات وسائل المساعدة المخزّنة {'inv5050', 'invAudience', 'invCall'}
  Future<Map<String, int>> getInventory() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('getInventory');
    if (result == null) return {};
    return result.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  /// يشتري وسيلة مساعدة ويخصم الثمن من الكوينز أو الجواهر.
  /// يُعيد true عند النجاح.
  Future<bool> buyPowerUp({
    required String type,
    required int quantity,
    required String payWith, // 'coins' | 'gems'
    required int cost,
  }) async {
    final result = await _channel.invokeMethod<bool>('buyPowerUp', {
      'type': type,
      'quantity': quantity,
      'payWith': payWith,
      'cost': cost,
    });
    return result ?? false;
  }
}
