import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A single chat message stored in Firestore.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String text;
  final DateTime createdAt;
  final String? replyToId;
  final String? replyToText;
  final String? replyToSenderName;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.text,
    required this.createdAt,
    this.replyToId,
    this.replyToText,
    this.replyToSenderName,
  });

  bool get isMe => senderId == FirebaseAuth.instance.currentUser?.uid;

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: d['senderId'] as String,
      senderName: d['senderName'] as String? ?? 'Unknown',
      senderAvatar: d['senderAvatar'] as String?,
      text: d['text'] as String,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      replyToId: d['replyToId'] as String?,
      replyToText: d['replyToText'] as String?,
      replyToSenderName: d['replyToSenderName'] as String?,
    );
  }
}

/// Represents a conversation thread between two users.
class Conversation {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantAvatars;
  final String lastMessage;
  final DateTime lastMessageAt;
  final Map<String, int> unreadCount;

  const Conversation({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantAvatars,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory Conversation.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      participantIds: List<String>.from(d['participantIds'] ?? []),
      participantNames: Map<String, String>.from(d['participantNames'] ?? {}),
      participantAvatars:
          Map<String, String?>.from(d['participantAvatars'] ?? {}),
      lastMessage: d['lastMessage'] as String? ?? '',
      lastMessageAt:
          (d['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: Map<String, int>.from(d['unreadCount'] ?? {}),
    );
  }

  /// Returns the other participant's uid (for 1-on-1 chats).
  String otherUserId(String myUid) =>
      participantIds.firstWhere((id) => id != myUid, orElse: () => '');

  /// Display name shown in the conversation list.
  String displayName(String myUid) {
    final otherId = otherUserId(myUid);
    return participantNames[otherId] ?? 'Unknown';
  }

  /// Avatar of the other participant.
  String? displayAvatar(String myUid) {
    final otherId = otherUserId(myUid);
    return participantAvatars[otherId];
  }

  int myUnread(String myUid) => unreadCount[myUid] ?? 0;
}

/// Manages all Firestore chat operations.
class ChatService {
  static final ChatService _instance = ChatService._();
  factory ChatService() => _instance;
  ChatService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _myUid => _auth.currentUser?.uid;

  // ─── Presence ──────────────────────────────────────────────────────────────

  /// Call when the app comes to foreground / user logs in.
  Future<void> setOnline() async {
    final uid = _myUid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({
      'online': true,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Call when the app goes to background / user logs out.
  Future<void> setOffline() async {
    final uid = _myUid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({
      'online': false,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Stream of online/lastSeen status for [userId].
  Stream<Map<String, dynamic>?> presenceStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final d = snap.data()!;
      return {
        'online': d['online'] as bool? ?? false,
        'lastSeen': (d['lastSeen'] as Timestamp?)?.toDate(),
      };
    });
  }

  // ─── Conversations ─────────────────────────────────────────────────────────

  /// Stream of all conversations for the current user, ordered by latest.
  Stream<List<Conversation>> conversationsStream() {
    final uid = _myUid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('conversations')
        .where('participantIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Conversation.fromDoc).toList());
  }

  /// Gets or creates a 1-on-1 conversation between current user and [otherUid].
  Future<String> getOrCreateConversation(String otherUid) async {
    final myUid = _myUid!;
    final myUser = _auth.currentUser!;

    // Check if conversation already exists
    final existing = await _db
        .collection('conversations')
        .where('participantIds', arrayContains: myUid)
        .get();

    for (final doc in existing.docs) {
      final ids = List<String>.from(doc['participantIds'] ?? []);
      if (ids.contains(otherUid) && ids.length == 2) return doc.id;
    }

    // Fetch the other user's profile
    final otherDoc = await _db.collection('users').doc(otherUid).get();
    final otherData = otherDoc.data() ?? {};

    // Create new conversation
    final ref = await _db.collection('conversations').add({
      'participantIds': [myUid, otherUid],
      'participantNames': {
        myUid: myUser.displayName ?? myUser.email ?? 'Me',
        otherUid: otherData['displayName'] ?? otherData['name'] ?? 'Unknown',
      },
      'participantAvatars': {
        myUid: myUser.photoURL,
        otherUid: otherData['photoURL'] ?? otherData['avatarUrl'],
      },
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': {myUid: 0, otherUid: 0},
    });

    return ref.id;
  }

  // ─── Messages ──────────────────────────────────────────────────────────────

  /// Real-time stream of messages for [conversationId].
  Stream<List<ChatMessage>> messagesStream(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  /// Sends a message to [conversationId], optionally replying to [replyTo].
  Future<void> sendMessage(
    String conversationId,
    String text, {
    ChatMessage? replyTo,
  }) async {
    final uid = _myUid;
    if (uid == null || text.trim().isEmpty) return;

    final user = _auth.currentUser!;
    final name = user.displayName ?? user.email ?? 'Me';
    final avatar = user.photoURL;
    final convRef = _db.collection('conversations').doc(conversationId);

    final batch = _db.batch();

    // Add message document
    final msgRef = convRef.collection('messages').doc();
    batch.set(msgRef, {
      'senderId': uid,
      'senderName': name,
      'senderAvatar': avatar,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      if (replyTo != null) ...{
        'replyToId': replyTo.id,
        'replyToText': replyTo.text,
        'replyToSenderName': replyTo.senderName,
      },
    });

    // Update conversation metadata + increment unread for others
    final convSnap = await convRef.get();
    if (convSnap.exists) {
      final data = convSnap.data()!;
      final participants = List<String>.from(data['participantIds'] ?? []);
      final unreadUpdate = <String, dynamic>{};
      for (final pid in participants) {
        if (pid != uid)
          unreadUpdate['unreadCount.$pid'] = FieldValue.increment(1);
      }
      batch.update(convRef, {
        'lastMessage': text.trim().length > 60
            ? '${text.trim().substring(0, 60)}…'
            : text.trim(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        ...unreadUpdate,
      });
    }

    await batch.commit();
  }

  /// Marks all messages in [conversationId] as read for the current user.
  Future<void> markAsRead(String conversationId) async {
    final uid = _myUid;
    if (uid == null) return;
    await _db.collection('conversations').doc(conversationId).update({
      'unreadCount.$uid': 0,
    });
  }
}
