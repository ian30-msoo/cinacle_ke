import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      // FIX: graceful fallback — serverTimestamp can be null briefly
      lastMessageAt:
          (d['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: Map<String, int>.from(d['unreadCount'] ?? {}),
    );
  }

  String otherUserId(String myUid) =>
      participantIds.firstWhere((id) => id != myUid, orElse: () => '');

  String displayName(String myUid) {
    final otherId = otherUserId(myUid);
    return participantNames[otherId] ?? 'Unknown';
  }

  String? displayAvatar(String myUid) {
    final otherId = otherUserId(myUid);
    return participantAvatars[otherId];
  }

  int myUnread(String myUid) => unreadCount[myUid] ?? 0;
}

class AppUser {
  final String uid;
  final String displayName;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  const AppUser({
    required this.uid,
    required this.displayName,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final email = d['email'] as String?;
    final name = (d['displayName'] as String?)?.isNotEmpty == true
        ? d['displayName'] as String
        : (d['name'] as String?)?.isNotEmpty == true
            ? d['name'] as String
            : email?.split('@').first ?? 'Unknown';

    final rawOnline = d['online'] as bool? ?? false;
    final lastSeen = (d['lastSeen'] as Timestamp?)?.toDate();
    final isOnline = rawOnline &&
        lastSeen != null &&
        DateTime.now().difference(lastSeen).inMinutes < 5;

    return AppUser(
      uid: doc.id,
      displayName: name,
      avatarUrl: d['photoURL'] as String? ?? d['avatarUrl'] as String?,
      isOnline: isOnline,
      lastSeen: lastSeen,
    );
  }
}

class ChatService {
  static final ChatService _instance = ChatService._();
  factory ChatService() => _instance;
  ChatService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _myUid => _auth.currentUser?.uid;

  //  Presence 

  Future<void> setOnline() async {
    final uid = _myUid;
    if (uid == null) return;
    final user = _auth.currentUser!;
    final name = user.displayName ?? user.email?.split('@').first ?? 'User';
    await _db.collection('users').doc(uid).set({
      'displayName': name,
      'email': user.email,
      'photoURL': user.photoURL,
      'online': true,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setOffline() async {
    final uid = _myUid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({
      'online': false,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> presenceStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final d = snap.data()!;
      final rawOnline = d['online'] as bool? ?? false;
      final lastSeen = (d['lastSeen'] as Timestamp?)?.toDate();
      final isOnline = rawOnline &&
          lastSeen != null &&
          DateTime.now().difference(lastSeen).inMinutes < 5;
      return {
        'online': isOnline,
        'lastSeen': lastSeen,
      };
    });
  }

  //  User Directory 

  Stream<List<AppUser>> usersStream() {
    final uid = _myUid;
    return _db.collection('users').snapshots().map((snap) =>
        snap.docs.map(AppUser.fromDoc).where((u) => u.uid != uid).toList()
          ..sort((a, b) {
            if (a.isOnline && !b.isOnline) return -1;
            if (!a.isOnline && b.isOnline) return 1;
            return a.displayName.compareTo(b.displayName);
          }));
  }

  //  FCM token 

  Future<void> saveFcmToken(String token) async {
    final uid = _myUid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  Future<void> removeFcmToken(String token) async {
    final uid = _myUid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayRemove([token]),
    }, SetOptions(merge: true));
  }

  //  Conversations 
  Stream<List<Conversation>> conversationsStream() {
    final uid = _myUid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('conversations')
        .where('participantIds', arrayContains: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Conversation.fromDoc).toList();
      // Sort by lastMessageAt descending in-memory
      list.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return list;
    });
  }

  Future<String> getOrCreateConversation(String otherUid) async {
    final myUid = _myUid!;
    final myUser = _auth.currentUser!;

    // Check for existing conversation
    final existing = await _db
        .collection('conversations')
        .where('participantIds', arrayContains: myUid)
        .get();

    for (final doc in existing.docs) {
      final ids = List<String>.from(doc['participantIds'] ?? []);
      if (ids.contains(otherUid) && ids.length == 2) return doc.id;
    }

    final otherDoc = await _db.collection('users').doc(otherUid).get();
    final otherData = otherDoc.data() ?? {};

    final otherEmail = otherData['email'] as String?;
    final otherName =
        (otherData['displayName'] as String?)?.isNotEmpty == true
            ? otherData['displayName'] as String
            : (otherData['name'] as String?)?.isNotEmpty == true
                ? otherData['name'] as String
                : otherEmail?.split('@').first ?? 'Unknown';

    final ref = await _db.collection('conversations').add({
      'participantIds': [myUid, otherUid],
      'participantNames': {
        myUid:
            myUser.displayName ?? myUser.email?.split('@').first ?? 'Me',
        otherUid: otherName,
      },
      'participantAvatars': {
        myUid: myUser.photoURL,
        otherUid: otherData['photoURL'] ?? otherData['avatarUrl'],
      },
      'lastMessage': '',
      'lastMessageAt': Timestamp.now(), // ← real timestamp, not serverTimestamp
      'unreadCount': {myUid: 0, otherUid: 0},
    });

    return ref.id;
  }

  //  Messages 

  Stream<List<ChatMessage>> messagesStream(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  Future<void> sendMessage(
    String conversationId,
    String text, {
    ChatMessage? replyTo,
  }) async {
    final uid = _myUid;
    if (uid == null || text.trim().isEmpty) return;

    final user = _auth.currentUser!;
    final name =
        user.displayName ?? user.email?.split('@').first ?? 'Me';
    final avatar = user.photoURL;
    final convRef = _db.collection('conversations').doc(conversationId);

    final batch = _db.batch();

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

    final convSnap = await convRef.get();
    if (convSnap.exists) {
      final data = convSnap.data()!;
      final participants =
          List<String>.from(data['participantIds'] ?? []);
      final unreadUpdate = <String, dynamic>{};
      for (final pid in participants) {
        if (pid != uid) {
          unreadUpdate['unreadCount.$pid'] = FieldValue.increment(1);
        }
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

  Future<void> markAsRead(String conversationId) async {
    final uid = _myUid;
    if (uid == null) return;
    await _db
        .collection('conversations')
        .doc(conversationId)
        .update({'unreadCount.$uid': 0});
  }
}