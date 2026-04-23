import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/player_profile.dart';

class ProfileService {
  ProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('public_profiles');

  Future<PlayerProfile?> fetchProfile(String uid) async {
    final doc = await _profiles.doc(uid).get();
    if (!doc.exists) return null;
    return PlayerProfile.fromMap(doc.data() ?? const <String, dynamic>{});
  }

  Stream<PlayerProfile> watchProfile(String uid) {
    return _profiles.doc(uid).snapshots().map(
          (doc) => doc.exists
              ? PlayerProfile.fromMap(doc.data() ?? const <String, dynamic>{})
              : PlayerProfile.empty(),
        );
  }

  Stream<Map<String, PlayerProfile>> watchProfiles(Iterable<String> uids) {
    final uniqueIds = uids
        .where((uid) => uid.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (uniqueIds.isEmpty) {
      return Stream.value(const <String, PlayerProfile>{});
    }

    late final StreamController<Map<String, PlayerProfile>> controller;
    final profiles = <String, PlayerProfile>{};
    final subscriptions = <StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>[];

    void emit() {
      if (!controller.isClosed) {
        controller.add(Map<String, PlayerProfile>.unmodifiable(profiles));
      }
    }

    controller = StreamController<Map<String, PlayerProfile>>(
      onListen: () {
        for (final uid in uniqueIds) {
          final subscription = _profiles.doc(uid).snapshots().listen((doc) {
            if (doc.exists) {
              profiles[uid] =
                  PlayerProfile.fromMap(doc.data() ?? const <String, dynamic>{});
            } else {
              profiles.remove(uid);
            }
            emit();
          }, onError: controller.addError);
          subscriptions.add(subscription);
        }
        emit();
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );

    return controller.stream;
  }
}
