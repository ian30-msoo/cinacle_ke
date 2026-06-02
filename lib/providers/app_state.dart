import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

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

  bool _notificationsEnabled = false;
  bool _darkMode = false;
  PostModel? _selectedPost;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkMode => _darkMode;
  PostModel? get selectedPost => _selectedPost;

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

      await credential.user?.updateDisplayName(name.trim());
      await _auth.currentUser?.reload();

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

  Future<void> signOut() async {
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

  // ── Avatar upload ──
  Future<bool> updateAvatar(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _setLoading(true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('${user.uid}.jpg');

      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      await user.updatePhotoURL(downloadUrl);
      await _auth.currentUser?.reload();

      await _db.collection('users').doc(user.uid).update({
        'photoURL': downloadUrl,
      });

      notifyListeners();
      return true;
    } catch (e) {
      _authError = 'Failed to update avatar. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

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
