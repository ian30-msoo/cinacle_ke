import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../models/post_model.dart';

class LetsTalkService {
  LetsTalkService._();
  static final LetsTalkService instance = LetsTalkService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _posts => _db.collection('lets_talk_posts');
  CollectionReference get _rooms => _db.collection('private_rooms');

  // ─── POSTS ───────────────────────────────────────────────────────────────

  Stream<List<PostModel>> streamPosts({
    String? topic,
    String sort = 'recent',
  }) {
    Query q = _posts;
    if (topic != null && topic != 'All Topics') {
      q = q.where('topic', isEqualTo: topic);
    }
    q = sort == 'trending'
        ? q.orderBy('likeCount', descending: true)
        : q.orderBy('createdAt', descending: true);
    return q.snapshots().map(
          (snap) => snap.docs.map(PostModel.fromDoc).toList(),
        );
  }

  Future<void> createPost(PostModel post) => _posts.add(post.toFirestore());

  Future<void> toggleLike(String postId, String userId) async {
    final ref = _posts.doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final liked = List<String>.from(
          (snap.data() as Map<String, dynamic>)['likedBy'] as List? ?? []);
      if (liked.contains(userId)) {
        liked.remove(userId);
      } else {
        liked.add(userId);
      }
      tx.update(ref, {'likedBy': liked, 'likeCount': liked.length});
    });
  }

  // ─── REPLIES ─────────────────────────────────────────────────────────────

  Stream<List<ReplyModel>> streamReplies(String postId) => _posts
      .doc(postId)
      .collection('replies')
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map(ReplyModel.fromDoc).toList());

  Future<void> addReply(String postId, ReplyModel reply) async {
    final batch = _db.batch();
    final replyRef = _posts.doc(postId).collection('replies').doc();
    batch.set(replyRef, reply.toFirestore());
    batch.update(_posts.doc(postId), {
      'replyCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  /// Toggle like on a reply.
  Future<void> toggleReplyLike(
      String postId, String replyId, String userId) async {
    final ref = _posts.doc(postId).collection('replies').doc(replyId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final liked = List<String>.from(
          (snap.data() as Map<String, dynamic>)['likedBy'] as List? ?? []);
      if (liked.contains(userId)) {
        liked.remove(userId);
      } else {
        liked.add(userId);
      }
      tx.update(ref, {'likedBy': liked, 'likeCount': liked.length});
    });
  }

  // ─── PRIVATE ROOMS ────────────────────────────────────────────────────────

  String _hash(String input) => sha256.convert(utf8.encode(input)).toString();

  Stream<List<PrivateRoom>> streamMyRooms(String userId) => _rooms
      .where('memberIds', arrayContains: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(PrivateRoom.fromDoc).toList());

  Future<void> createRoom({
    required String name,
    required String description,
    required String passcode,
    required String createdById,
    required String createdByName,
  }) =>
      _rooms.add({
        'name': name.trim(),
        'description': description.trim(),
        'createdById': createdById,
        'createdByName': createdByName,
        'passcodeHash': _hash(passcode.trim()),
        'memberIds': [createdById],
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<bool> joinRoom({
    required String roomId,
    required String userId,
    required String passcode,
  }) async {
    final snap = await _rooms.doc(roomId).get();
    if (!snap.exists) return false;
    final stored =
        (snap.data() as Map<String, dynamic>)['passcodeHash'] as String? ?? '';
    if (_hash(passcode.trim()) != stored) return false;
    await _rooms.doc(roomId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
    return true;
  }

  // ─── ROOM MESSAGES ────────────────────────────────────────────────────────

  Stream<List<ReplyModel>> streamRoomMessages(String roomId) => _rooms
      .doc(roomId)
      .collection('messages')
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map(ReplyModel.fromDoc).toList());

  Future<void> sendRoomMessage(String roomId, ReplyModel message) =>
      _rooms.doc(roomId).collection('messages').add(message.toFirestore());
}
