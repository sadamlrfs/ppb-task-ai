import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _googleSignIn = kIsWeb ? null : GoogleSignIn();
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  Future<UserModel?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return _fetchUser(cred.user!.uid);
  }

  Future<UserModel?> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user!.updateDisplayName(name);
    final user = UserModel(
      uid: cred.user!.uid,
      name: name,
      email: email,
      role: 'student',
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(user.uid).set(user.toFirestore());
    return user;
  }

  Future<UserModel?> signInWithGoogle() async {
    UserCredential result;
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      result = await _auth.signInWithPopup(provider);
    } else {
      try {
        final googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) return null;
        final googleAuth = await googleUser.authentication;
        final cred = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        result = await _auth.signInWithCredential(cred);
      } on PlatformException catch (e) {
        if (e.code == 'sign_in_cancelled') return null;
        throw FirebaseAuthException(
          code: 'google-sign-in-failed',
          message: e.message ?? e.code,
        );
      }
    }
    final uid = result.user!.uid;
    final existing = await _fetchUser(uid);
    if (existing != null) return existing;
    final user = UserModel(
      uid: uid,
      name: result.user!.displayName ?? result.user!.email ?? uid,
      email: result.user!.email ?? '',
      role: 'student',
      photoURL: result.user!.photoURL,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(uid).set(user.toFirestore());
    return user;
  }

  Future<void> signOut() async {
    if (!kIsWeb) await _googleSignIn?.signOut();
    await _auth.signOut();
  }

  Future<UserModel?> _fetchUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel?> fetchCurrentUser() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    return _fetchUser(uid);
  }
}
