import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/player_profile.dart';

class ProfileService {
  ProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<PlayerProfile?> fetchProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return PlayerProfile.fromMap(doc.data() ?? const <String, dynamic>{});
  }

  Stream<PlayerProfile> watchProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
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

    return _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: uniqueIds)
        .snapshots()
        .map((snapshot) {
      final profiles = <String, PlayerProfile>{};
      for (final doc in snapshot.docs) {
        profiles[doc.id] = PlayerProfile.fromMap(doc.data());
      }
      return profiles;
    });
  }
}
