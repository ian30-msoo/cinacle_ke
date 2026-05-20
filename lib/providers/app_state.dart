import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

// Wraps Firebase User for clean access across the app.
class AppUser {
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;

  const AppUser({
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  factory AppUser.fromFirebase(User user) {
    return AppUser(
      name: user.displayName ?? user.email?.split('@')[0] ?? 'User',
      email: user.email ?? '',
      avatarUrl: user.photoURL,
    );
  }
}

class AppState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Non-auth state
  bool _notificationsEnabled = false;
  bool _darkMode = false;

  PostModel? _selectedPost;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkMode => _darkMode;
  PostModel? get selectedPost => _selectedPost;

  // Auth state
  bool _isAuthLoading = false;
  String? _authError;

  bool get isAuthLoading => _isAuthLoading;
  String? get authError => _authError;

  bool get isLoggedIn {
    try {
      return _auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  AppUser? get currentUser {
    try {
      final u = _auth.currentUser;
      return u != null ? AppUser.fromFirebase(u) : null;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  AppState() {
    _auth.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  void clearAuthError() {
    _authError = null;
    notifyListeners();
  }

  //  Firestore profile write
  // Called after every sign-in and sign-up so the users collection
  Future<void> _syncUserProfile(User user) async {
    final name = user.displayName ?? user.email?.split('@').first ?? 'User';
    await _db.collection('users').doc(user.uid).set({
      'displayName': name,
      'email': user.email,
      'photoURL': user.photoURL,
      'online': true,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  //  Sign Up

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    if (name.trim().isEmpty) {
      _authError = 'Please enter your full name.';
      notifyListeners();
      return false;
    }
    if (email.trim().isEmpty) {
      _authError = 'Please enter your email address.';
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      _authError = 'Password must be at least 6 characters.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Set the display name on the Firebase Auth profile first
      await credential.user?.updateDisplayName(name.trim());
      await _auth.currentUser?.reload();

      // Now write the full profile to Firestore so the user appears
      final user = _auth.currentUser;
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'displayName': name.trim(),
          'email': user.email,
          'photoURL': user.photoURL,
          'phone': phone,
          'online': true,
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      _authError = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _authError = _friendlyError(e.code);
      return false;
    } catch (_) {
      _authError = 'An unexpected error occurred. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  //  Sign In

  Future<bool> signIn(String email, String password) async {
    if (email.trim().isEmpty) {
      _authError = 'Please enter your email address.';
      notifyListeners();
      return false;
    }
    if (password.isEmpty) {
      _authError = 'Please enter your password.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Sync profile on every sign-in — fixes existing users who signed up
      final user = _auth.currentUser;
      if (user != null) await _syncUserProfile(user);

      _authError = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _authError = _friendlyError(e.code);
      return false;
    } catch (_) {
      _authError = 'An unexpected error occurred. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  //  Sign Out

  Future<void> signOut() async {
    // Mark offline before signing out
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).update({
        'online': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
    await _auth.signOut();
    _authError = null;
  }

  //  Password Reset

  Future<bool> sendPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      _authError = 'Please enter your email address.';
      notifyListeners();
      return false;
    }
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _authError = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _authError = _friendlyError(e.code);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  //  Non-auth actions

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
  }

  void toggleDarkMode() {
    _darkMode = !_darkMode;
    notifyListeners();
  }

  void setSelectedPost(PostModel? post) {
    _selectedPost = post;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isAuthLoading = v;
    notifyListeners();
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Check your network.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
