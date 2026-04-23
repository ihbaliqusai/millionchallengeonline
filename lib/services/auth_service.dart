import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    final credential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
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
      final fallbackName = _resolveUsername(const <String, dynamic>{}, username, email);
      if (_auth.currentUser != null && (_auth.currentUser!.displayName ?? '').trim() != fallbackName) {
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

    if (_auth.currentUser != null && (_auth.currentUser!.displayName ?? '').trim() != resolvedUsername) {
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
}
