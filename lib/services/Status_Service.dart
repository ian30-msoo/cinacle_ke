import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum StatusType { text, image }

class StatusItem {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String text;
  final StatusType type;
  final String? imageUrl;
  final String?
      backgroundColor; // hex string, e.g. '#1F6F54', for text statuses
  final DateTime createdAt;
  final DateTime expiresAt;
  final Map<String, DateTime> viewedBy;

  const StatusItem({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.text,
    required this.type,
    this.imageUrl,
    this.backgroundColor,
    required this.createdAt,
    required this.expiresAt,
    required this.viewedBy,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool viewedByMe(String myUid) => viewedBy.containsKey(myUid);

  factory StatusItem.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawViewed = d['viewedBy'] as Map<String, dynamic>? ?? {};
    return StatusItem(
      id: doc.id,
      userId: d['userId'] as String,
      userName: d['userName'] as String? ?? 'Unknown',
      userAvatar: d['userAvatar'] as String?,
      text: d['text'] as String? ?? '',
      type: (d['type'] as String?) == 'image'
          ? StatusType.image
          : StatusType.text,
      imageUrl: d['imageUrl'] as String?,
      backgroundColor: d['backgroundColor'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 24)),
      viewedBy: rawViewed.map(
        (k, v) => MapEntry(k, (v as Timestamp).toDate()),
      ),
    );
  }
}

/// Groups all of one user's active statuses together — this is the unit
/// the status list/ring UI actually works with (one ring per user, not per status).
class UserStatusGroup {
  final String userId;
  final String userName;
  final String? userAvatar;
  final List<StatusItem> items; // sorted oldest -> newest

  const UserStatusGroup({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.items,
  });

  bool hasUnviewedFor(String myUid) => items.any((s) => !s.viewedByMe(myUid));

  DateTime get latestAt => items.last.createdAt;
}

class StatusService {
  static final StatusService _instance = StatusService._();
  factory StatusService() => _instance;
  StatusService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _myUid => _auth.currentUser?.uid;

  /// Returns the set of uids this user has an existing conversation with.
  /// Status visibility is scoped to this set, reusing the same
  /// `conversations` collection ChatService already maintains.
  Future<Set<String>> _conversationContactIds() async {
    final uid = _myUid;
    if (uid == null) return {};
    final snap = await _db
        .collection('conversations')
        .where('participantIds', arrayContains: uid)
        .get();

    final contacts = <String>{};
    for (final doc in snap.docs) {
      final ids = List<String>.from(doc['participantIds'] ?? []);
      contacts.addAll(ids.where((id) => id != uid));
    }
    return contacts;
  }

  /// Stream of active (non-expired) status groups for everyone the
  /// current user has an existing conversation with, plus their own.
  /// Firestore can't query "userId in [dynamic large set]" reliably past
  /// 30 ids, so for very large contact lists this chunks the `whereIn`
  /// query; most users will have far fewer than 30 conversations.
  Stream<List<UserStatusGroup>> contactStatusesStream() {
    final uid = _myUid;
    if (uid == null) return const Stream.empty();

    return Stream.fromFuture(_conversationContactIds()).asyncExpand((
      contactIds,
    ) {
      if (contactIds.isEmpty) return const Stream.empty();

      final chunks = <List<String>>[];
      final list = contactIds.toList();
      for (var i = 0; i < list.length; i += 30) {
        chunks
            .add(list.sublist(i, i + 30 > list.length ? list.length : i + 30));
      }

      final controller = StreamController<List<UserStatusGroup>>.broadcast();
      final latestByChunk = <int, List<StatusItem>>{};
      final subs = <StreamSubscription>[];

      for (var c = 0; c < chunks.length; c++) {
        final sub = _db
            .collection('statuses')
            .where('userId', whereIn: chunks[c])
            .where('expiresAt', isGreaterThan: Timestamp.now())
            .orderBy('expiresAt')
            .orderBy('createdAt')
            .snapshots()
            .listen((snap) {
          latestByChunk[c] = snap.docs.map(StatusItem.fromDoc).toList();
          controller.add(_groupAndEmit(latestByChunk));
        });
        subs.add(sub);
      }

      controller.onCancel = () {
        for (final s in subs) {
          s.cancel();
        }
      };

      return controller.stream;
    });
  }

  List<UserStatusGroup> _groupAndEmit(Map<int, List<StatusItem>> byChunk) {
    final all = byChunk.values.expand((l) => l).toList();
    final byUser = <String, List<StatusItem>>{};
    for (final s in all) {
      byUser.putIfAbsent(s.userId, () => []).add(s);
    }

    // userName/userAvatar are denormalized onto each status doc at write
    // time (see _postStatus), so we can build groups without a join.
    final groups = byUser.entries.map((e) {
      e.value.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final first = e.value.first;
      return UserStatusGroup(
        userId: e.key,
        userName: first.userName,
        userAvatar: first.userAvatar,
        items: e.value,
      );
    }).toList();

    groups.sort((a, b) => b.latestAt.compareTo(a.latestAt));
    return groups;
  }

  /// My own active statuses (no expiry filter needed beyond standard query
  /// since this is just for "My Status" preview at the top of the screen).
  Stream<List<StatusItem>> myStatusesStream() {
    final uid = _myUid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('statuses')
        .where('userId', isEqualTo: uid)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(StatusItem.fromDoc).toList());
  }

  Future<void> postTextStatus(String text,
      {required String backgroundColor}) async {
    final uid = _myUid;
    if (uid == null || text.trim().isEmpty) return;
    await _postStatus(
      type: StatusType.text,
      text: text.trim(),
      backgroundColor: backgroundColor,
    );
  }

  Future<void> postImageStatus(String imageUrl, {String caption = ''}) async {
    final uid = _myUid;
    if (uid == null || imageUrl.isEmpty) return;
    await _postStatus(
      type: StatusType.image,
      text: caption.trim(),
      imageUrl: imageUrl,
    );
  }

  Future<void> _postStatus({
    required StatusType type,
    required String text,
    String? imageUrl,
    String? backgroundColor,
  }) async {
    final uid = _myUid!;
    final user = _auth.currentUser!;
    final name = user.displayName ?? user.email?.split('@').first ?? 'User';
    final now = DateTime.now();

    await _db.collection('statuses').add({
      'userId': uid,
      'userName': name,
      'userAvatar': user.photoURL,
      'type': type == StatusType.image ? 'image' : 'text',
      'text': text,
      'imageUrl': imageUrl,
      'backgroundColor': backgroundColor,
      'createdAt': Timestamp.fromDate(now),
      // Stored explicitly (not serverTimestamp-derived) so it can be used
      // directly in range queries immediately after write, and so a
      // Firestore TTL policy on this field can auto-delete the doc.
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
      'viewedBy': <String, dynamic>{},
    });
  }

  Future<void> markViewed(String statusId) async {
    final uid = _myUid;
    if (uid == null) return;
    await _db.collection('statuses').doc(statusId).update({
      'viewedBy.$uid': Timestamp.now(),
    });
  }

  Future<void> deleteStatus(String statusId) async {
    await _db.collection('statuses').doc(statusId).delete();
  }

  /// Viewer list for a single status, newest-first — used on your own
  /// status to show "who's viewed this".
  Future<List<MapEntry<String, DateTime>>> viewersOf(String statusId) async {
    final doc = await _db.collection('statuses').doc(statusId).get();
    final raw = doc.data()?['viewedBy'] as Map<String, dynamic>? ?? {};
    final entries = raw.entries
        .map((e) => MapEntry(e.key, (e.value as Timestamp).toDate()))
        .toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}
