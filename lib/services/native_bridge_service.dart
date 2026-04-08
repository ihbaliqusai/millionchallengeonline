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
}
