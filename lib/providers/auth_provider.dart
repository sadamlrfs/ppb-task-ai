import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  UserModel? _user;
  bool _loading = false;
  String? _error;
  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  Future<void> loadCurrentUser() async {
    _user = await _service.fetchCurrentUser();
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.signInWithEmail(email, password);
      _loading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = _friendlyError(e.toString());
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.registerWithEmail(
          email: email, password: password, name: name);
      _loading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = _friendlyError(e.toString());
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.signInWithGoogle();
      _loading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = _friendlyError(e.toString());
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found') ||
        raw.contains('wrong-password') ||
        raw.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }
    if (raw.contains('email-already-in-use')) return 'Email already in use.';
    if (raw.contains('weak-password')) return 'Password is too weak.';
    if (raw.contains('network-request-failed'))
      return 'No internet connection.';
    if (raw.contains('google-sign-in-failed'))
      return 'Google sign-in failed. Make sure your device is connected and try again.';
    if (raw.contains('sign_in_failed'))
      return 'Google sign-in failed. Please try again.';
    return 'Something went wrong. Please try again.';
  }
}
