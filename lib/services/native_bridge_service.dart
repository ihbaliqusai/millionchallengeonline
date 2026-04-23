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
    required String roomId,
    String matchMode = 'battle',
    int seriesTarget = 2,
    int roundDurationSeconds = 30,
    String myTeam = '',
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
            'teamId': (opponent['teamId'] ?? '').toString(),
          },
        )
        .toList(growable: false);

    await _channel.invokeMethod('launchRoomMatch', <String, dynamic>{
      'roomId': roomId,
      'opponentsJson': jsonEncode(safeOpponents),
      'meOwner': meOwner,
      'matchMode': matchMode,
      'seriesTarget': seriesTarget,
      'roundDurationSeconds': roundDurationSeconds,
      'myTeam': myTeam,
    });
  }

  Future<Map<String, dynamic>?> consumePendingRoomMatchResult() async {
    final payload =
        await _channel.invokeMethod<String>('consumePendingRoomMatchResult');
    if (payload == null || payload.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return null;
  }

  Future<Map<String, dynamic>?> getPendingRoomMatchResult() async {
    final payload =
        await _channel.invokeMethod<String>('getPendingRoomMatchResult');
    if (payload == null || payload.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return null;
  }

  Future<void> clearPendingRoomMatchResult() async {
    await _channel.invokeMethod<void>('clearPendingRoomMatchResult');
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
    final result =
        await _channel.invokeMapMethod<String, dynamic>('getPlayerStats');
    if (result == null) return {};
    return result.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  /// يُعيد حالة جميع الإنجازات + عدادات التقدم الحالية.
  /// المفاتيح البوليانية هي مفاتيح الإنجازات (ACH_*)، والمفاتيح الرقمية هي إحصاءات اللاعب.
  Future<Map<String, dynamic>> getAchievements() async {
    final result =
        await _channel.invokeMapMethod<String, dynamic>('getAchievements');
    return result ?? {};
  }

  /// يُعيد {'coins': int, 'gems': int} من SharedPreferences الـ native
  Future<Map<String, int>> getUserCurrency() async {
    final result =
        await _channel.invokeMapMethod<String, int>('getUserCurrency');
    return result ?? {'coins': 0, 'gems': 0};
  }

  Future<Map<String, int>> grantCurrency({
    int coins = 0,
    int gems = 0,
  }) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'grantCurrency',
      <String, dynamic>{
        'coins': coins,
        'gems': gems,
      },
    );
    if (result == null) return {'coins': 0, 'gems': 0};
    return result.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  /// يُعيد قيم الإعدادات المحفوظة من Android SharedPreferences
  Future<Map<String, bool>> getSettings() async {
    final result =
        await _channel.invokeMapMethod<String, dynamic>('getSettings');
    return {
      'sfx': result?['sfx'] as bool? ?? true,
      'music': result?['music'] as bool? ?? true,
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
    final result =
        await _channel.invokeMapMethod<String, dynamic>('getInventory');
    if (result == null) return {};
    return result.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  /// يُسلّم منتج IAP للاعب (يُستدعى بعد نجاح عملية الدفع عبر Google Play).
  Future<bool> deliverPurchase(
    String productId, {
    String? deliveryKey,
  }) async {
    final result = await _channel.invokeMethod<bool>(
      'deliverPurchase',
      {
        'productId': productId,
        'deliveryKey': deliveryKey ?? '',
      },
    );
    return result ?? false;
  }

  /// يشتري عملات (كوينز) بخصم جواهر من الرصيد المحلي.
  Future<bool> buyCurrency(
      {required int coinAmount, required int gemCost}) async {
    final result = await _channel.invokeMethod<bool>(
      'buyCurrency',
      {'coinAmount': coinAmount, 'gemCost': gemCost},
    );
    return result ?? false;
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
