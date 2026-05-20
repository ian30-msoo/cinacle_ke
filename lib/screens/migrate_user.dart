import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> migrateCurrentUserProfile() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

  final data = doc.data() ?? {};
  final hasName = (data['displayName'] as String?)?.isNotEmpty == true;

  // Only write if displayName is missing or empty
  if (!hasName) {
    final name = user.displayName ?? user.email?.split('@').first ?? 'User';
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'displayName': name,
      'email': user.email,
      'photoURL': user.photoURL,
      'online': true,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
