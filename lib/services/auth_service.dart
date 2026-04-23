import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserFacingError implements Exception {
  const UserFacingError(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    await _tryUpsertProfile(
      uid: credential.user!.uid,
      email: credential.user?.email ?? email.trim(),
      username: credential.user?.displayName,
      photoUrl: credential.user?.photoURL,
    );
    return credential;
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(username.trim());
    await _tryUpsertProfile(
      uid: credential.user!.uid,
      email: email.trim(),
      username: username.trim(),
      photoUrl: credential.user?.photoURL,
    );
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw FirebaseAuthException(
        code: 'cancelled',
        message: 'تم إلغاء تسجيل الدخول عبر Google',
      );
    }
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    await _tryUpsertProfile(
      uid: result.user!.uid,
      email: result.user?.email ?? '',
      username: result.user?.displayName,
      photoUrl: result.user?.photoURL,
    );
    return result;
  }

  Future<void> updateUsername(String username) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final normalizedUsername = username.trim();
    await user.updateDisplayName(normalizedUsername);
    try {
      final privateRef = _firestore.collection('users').doc(user.uid);
      final publicRef = _firestore.collection('public_profiles').doc(user.uid);
      final payload = <String, dynamic>{
        'username': normalizedUsername,
        'lastSeenAt': FieldValue.serverTimestamp(),
      };
      await privateRef.set(
        payload,
        SetOptions(merge: true),
      );
      await publicRef.set(
        <String, dynamic>{
          'uid': user.uid,
          'username': normalizedUsername,
          'photoUrl': user.photoURL?.trim().isNotEmpty == true
              ? user.photoURL!.trim()
              : null,
          'lastSeenAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Firebase Auth remains the source of truth when Firestore is unavailable.
    }
  }

  Future<void> _tryUpsertProfile({
    required String uid,
    required String email,
    String? username,
    String? photoUrl,
  }) async {
    try {
      await _upsertProfile(
        uid: uid,
        email: email,
        username: username,
        photoUrl: photoUrl,
      );
    } catch (_) {
      final fallbackName =
          _resolveUsername(const <String, dynamic>{}, username, email);
      if (_auth.currentUser != null &&
          (_auth.currentUser!.displayName ?? '').trim() != fallbackName) {
        await _auth.currentUser!.updateDisplayName(fallbackName);
      }
    }
  }

  Future<void> _upsertProfile({
    required String uid,
    required String email,
    String? username,
    String? photoUrl,
  }) async {
    final ref = _firestore.collection('users').doc(uid);
    final publicRef = _firestore.collection('public_profiles').doc(uid);
    final snapshot = await ref.get();
    final existing = snapshot.data() ?? const <String, dynamic>{};
    final resolvedUsername = _resolveUsername(existing, username, email);
    final resolvedPhotoUrl = _resolvePhotoUrl(existing, photoUrl);
    final publicTrophies = (existing['trophies'] as num?)?.toInt() ?? 0;
    final publicLevel = (existing['level'] as num?)?.toInt() ?? 1;

    if (_auth.currentUser != null &&
        (_auth.currentUser!.displayName ?? '').trim() != resolvedUsername) {
      await _auth.currentUser!.updateDisplayName(resolvedUsername);
    }

    await ref.set(
      <String, dynamic>{
        'uid': uid,
        'email': email,
        'username': resolvedUsername,
        'photoUrl': resolvedPhotoUrl,
        if (!snapshot.exists) 'wins': 0,
        if (!snapshot.exists) 'losses': 0,
        if (!snapshot.exists) 'totalMatches': 0,
        if (!snapshot.exists) 'totalScore': 0,
        if (!snapshot.exists) 'rating': 1000,
        if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await publicRef.set(
      <String, dynamic>{
        'uid': uid,
        'username': resolvedUsername,
        'photoUrl': resolvedPhotoUrl,
        'rating': (existing['rating'] as num?)?.toInt() ?? 1000,
        'trophies': publicTrophies,
        'level': publicLevel,
        if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> deleteCurrentAccount({String? password}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const UserFacingError('لا يوجد حساب مسجل لحذفه حالياً.');
    }

    try {
      await _reauthenticateForDeletion(currentUser, password: password);
      await _deleteStoredUserData(currentUser.uid);
      await currentUser.delete();
      await _googleSignIn.signOut();
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw _mapDeletionError(error);
    } on UserFacingError {
      rethrow;
    } catch (_) {
      throw const UserFacingError(
        'تعذر حذف الحساب الآن. حاول مرة أخرى بعد قليل.',
      );
    }
  }

  String _resolveUsername(
    Map<String, dynamic> existing,
    String? candidate,
    String email,
  ) {
    final options = <String?>[
      existing['username']?.toString(),
      existing['playerName']?.toString(),
      existing['displayName']?.toString(),
      existing['name']?.toString(),
      candidate,
      email.split('@').first,
    ];

    for (final option in options) {
      final normalized = option?.trim() ?? '';
      if (normalized.isEmpty) continue;
      final lowered = normalized.toLowerCase();
      if (lowered == 'guest' || lowered == 'player') continue;
      return normalized;
    }

    return 'لاعب';
  }

  String? _resolvePhotoUrl(Map<String, dynamic> existing, String? candidate) {
    final existingPhoto = existing['photoUrl']?.toString().trim();
    if (existingPhoto != null && existingPhoto.isNotEmpty) {
      return existingPhoto;
    }

    final nextPhoto = candidate?.trim();
    if (nextPhoto != null && nextPhoto.isNotEmpty) {
      return nextPhoto;
    }

    return null;
  }

  Future<void> _reauthenticateForDeletion(
    User user, {
    String? password,
  }) async {
    final providers = user.providerData
        .map((UserInfo info) => info.providerId)
        .whereType<String>()
        .toSet();

    if (providers.contains('password')) {
      final email = user.email?.trim() ?? '';
      final normalizedPassword = password?.trim() ?? '';
      if (email.isEmpty || normalizedPassword.isEmpty) {
        throw const UserFacingError(
          'أدخل كلمة المرور الحالية لتأكيد حذف الحساب.',
        );
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: normalizedPassword,
      );
      await user.reauthenticateWithCredential(credential);
      return;
    }

    if (providers.contains('google.com')) {
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();
      if (account == null) {
        throw const UserFacingError(
          'تعذر تأكيد هويتك عبر Google. أعد المحاولة ثم وافق على تسجيل الدخول.',
        );
      }
      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  Future<void> _deleteStoredUserData(String uid) async {
    await _deleteSubcollection(
      _firestore.collection('users').doc(uid).collection('friends'),
    );
    await _deleteSubcollection(
      _firestore.collection('users').doc(uid).collection('match_history'),
    );
    await _deleteMatchingDocs(
      _firestore.collection('invitations').where('fromUid', isEqualTo: uid),
    );
    await _deleteMatchingDocs(
      _firestore.collection('invitations').where('toUid', isEqualTo: uid),
    );
    await _deleteMatchingDocs(
      _firestore.collection('rooms').where('hostId', isEqualTo: uid),
    );

    final batch = _firestore.batch();
    batch.delete(_firestore.collection('matchmaking_queue').doc(uid));
    batch.delete(_firestore.collection('public_profiles').doc(uid));
    batch.delete(_firestore.collection('users').doc(uid));
    await batch.commit();
  }

  Future<void> _deleteSubcollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _deleteMatchingDocs(
    Query<Map<String, dynamic>> query,
  ) async {
    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  UserFacingError _mapDeletionError(FirebaseAuthException error) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return const UserFacingError('كلمة المرور غير صحيحة.');
      case 'network-request-failed':
        return const UserFacingError(
          'تعذر الاتصال بالخادم أثناء حذف الحساب. تحقق من الإنترنت ثم حاول مرة أخرى.',
        );
      case 'requires-recent-login':
        return const UserFacingError(
          'لأسباب أمنية، أعد تسجيل الدخول ثم حاول حذف الحساب مرة أخرى.',
        );
      default:
        return UserFacingError(
          error.message?.trim().isNotEmpty == true
              ? error.message!.trim()
              : 'تعذر حذف الحساب الآن. حاول مرة أخرى بعد قليل.',
        );
    }
  }
}
