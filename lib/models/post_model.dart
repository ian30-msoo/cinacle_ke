import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String author;
  final String initials;
  final String? avatarUrl;
  final DateTime createdAt;
  final String tag;
  final String tagIcon;
  final String title;
  final String body;
  final bool isAnonymous;
  final bool isRepost;
  final List<String> likedBy;
  final int replyCount;
  final List<ReplyModel> replies; // loaded separately via streamReplies

  const PostModel({
    required this.id,
    required this.authorId,
    required this.author,
    required this.initials,
    this.avatarUrl,
    required this.createdAt,
    required this.tag,
    required this.tagIcon,
    required this.title,
    required this.body,
    this.isAnonymous = false,
    this.isRepost = false,
    this.likedBy = const [],
    this.replyCount = 0,
    this.replies = const [],
  });

  // ── Computed ──

  int get likeCount => likedBy.length;
  bool isLikedBy(String uid) => likedBy.contains(uid);

  // ── copyWith ──

  PostModel copyWith({
    String? id,
    String? authorId,
    String? author,
    String? initials,
    String? avatarUrl,
    DateTime? createdAt,
    String? tag,
    String? tagIcon,
    String? title,
    String? body,
    bool? isAnonymous,
    bool? isRepost,
    List<String>? likedBy,
    int? replyCount,
    List<ReplyModel>? replies,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      author: author ?? this.author,
      initials: initials ?? this.initials,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      tag: tag ?? this.tag,
      tagIcon: tagIcon ?? this.tagIcon,
      title: title ?? this.title,
      body: body ?? this.body,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isRepost: isRepost ?? this.isRepost,
      likedBy: likedBy ?? this.likedBy,
      replyCount: replyCount ?? this.replyCount,
      replies: replies ?? this.replies,
    );
  }

  // Call this on tap for instant UI feedback; real write done in service.

  PostModel toggleLikeLocally(String uid) {
    final updated = List<String>.from(likedBy);
    if (updated.contains(uid)) {
      updated.remove(uid);
    } else {
      updated.add(uid);
    }
    return copyWith(likedBy: updated);
  }

  // Prepend reply so it appears instantly before Firestore confirms.

  PostModel addReplyLocally(ReplyModel reply) {
    return copyWith(
      replies: [reply, ...replies],
      replyCount: replyCount + 1,
    );
  }

  // ── Firestore ─

  factory PostModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: d['authorId'] as String? ?? '',
      author: d['authorName'] as String? ?? 'Anonymous',
      initials: d['authorInitials'] as String? ?? '?',
      avatarUrl: d['authorAvatarUrl'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tag: d['topic'] as String? ?? 'General',
      tagIcon: d['tagIcon'] as String? ?? 'chat',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      isAnonymous: d['isAnonymous'] as bool? ?? false,
      isRepost: d['isRepost'] as bool? ?? false,
      likedBy: List<String>.from(d['likedBy'] as List<dynamic>? ?? []),
      replyCount: d['replyCount'] as int? ?? 0,
      replies: const [],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'authorId': authorId,
        'authorName': isAnonymous ? 'Anonymous' : author,
        'authorInitials': isAnonymous ? 'A' : initials,
        'authorAvatarUrl': isAnonymous ? null : avatarUrl,
        'topic': tag,
        'tagIcon': _tagIconForTopic(tag),
        'title': title,
        'body': body,
        'isAnonymous': isAnonymous,
        'isRepost': isRepost,
        'likedBy': likedBy,
        'likeCount': likedBy.length,
        'replyCount': replyCount,
        'createdAt': FieldValue.serverTimestamp(),
      };

  // Auto-derive tagIcon from topic
  static String _tagIconForTopic(String topic) {
    switch (topic) {
      case 'Government':
        return 'bank';
      case 'Education':
        return 'school';
      case 'Media':
        return 'tv';
      case 'Religion':
        return 'church';
      case 'Arts & Culture':
        return 'mountain';
      default:
        return 'chat';
    }
  }

  //  create new post ─

  factory PostModel.create({
    required String uid,
    required String displayName,
    String? avatarUrl,
    required String topic,
    required String title,
    required String body,
    bool isAnonymous = false,
  }) {
    return PostModel(
      id: '',
      authorId: uid,
      author: displayName,
      initials: _initialsFrom(displayName),
      avatarUrl: avatarUrl,
      createdAt: DateTime.now(),
      tag: topic,
      tagIcon: _tagIconForTopic(topic),
      title: title.trim(),
      body: body.trim(),
      isAnonymous: isAnonymous,
      likedBy: const [],
      replyCount: 0,
      replies: const [],
    );
  }

  static String _initialsFrom(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}

// ReplyModel

class ReplyModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorInitials;
  final String? authorAvatarUrl;
  final String body;
  final DateTime createdAt;
  final List<String> likedBy;

  const ReplyModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorInitials,
    this.authorAvatarUrl,
    required this.body,
    required this.createdAt,
    this.likedBy = const [],
  });

  int get likeCount => likedBy.length;
  bool isLikedBy(String uid) => likedBy.contains(uid);

  // Optimistic like toggle on a reply
  ReplyModel toggleLikeLocally(String uid) {
    final updated = List<String>.from(likedBy);
    if (updated.contains(uid)) {
      updated.remove(uid);
    } else {
      updated.add(uid);
    }
    return ReplyModel(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorInitials: authorInitials,
      authorAvatarUrl: authorAvatarUrl,
      body: body,
      createdAt: createdAt,
      likedBy: updated,
    );
  }

  factory ReplyModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReplyModel(
      id: doc.id,
      authorId: d['authorId'] as String? ?? '',
      authorName: d['authorName'] as String? ?? 'Anonymous',
      authorInitials: d['authorInitials'] as String? ?? '?',
      authorAvatarUrl: d['authorAvatarUrl'] as String?,
      body: d['body'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likedBy: List<String>.from(d['likedBy'] as List<dynamic>? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'authorId': authorId,
        'authorName': authorName,
        'authorInitials': authorInitials,
        'authorAvatarUrl': authorAvatarUrl,
        'body': body,
        'likedBy': likedBy,
        'likeCount': likedBy.length,
        'createdAt': FieldValue.serverTimestamp(),
      };

  //create a reply ready to write
  factory ReplyModel.create({
    required String uid,
    required String displayName,
    String? avatarUrl,
    required String body,
  }) {
    final parts = displayName.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : displayName.isNotEmpty
            ? displayName[0].toUpperCase()
            : 'U';
    return ReplyModel(
      id: '',
      authorId: uid,
      authorName: displayName,
      authorInitials: initials,
      authorAvatarUrl: avatarUrl,
      body: body.trim(),
      createdAt: DateTime.now(),
      likedBy: const [],
    );
  }
}

// PrivateRoom

class PrivateRoom {
  final String id;
  final String name;
  final String description;
  final String createdById;
  final String createdByName;
  final String passcodeHash;
  final List<String> memberIds;
  final DateTime createdAt;

  const PrivateRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.createdById,
    required this.createdByName,
    required this.passcodeHash,
    required this.memberIds,
    required this.createdAt,
  });

  int get memberCount => memberIds.length;
  bool isMember(String uid) => memberIds.contains(uid);

  factory PrivateRoom.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PrivateRoom(
      id: doc.id,
      name: d['name'] as String? ?? '',
      description: d['description'] as String? ?? '',
      createdById: d['createdById'] as String? ?? '',
      createdByName: d['createdByName'] as String? ?? '',
      passcodeHash: d['passcodeHash'] as String? ?? '',
      memberIds: List<String>.from(d['memberIds'] as List<dynamic>? ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'createdById': createdById,
        'createdByName': createdByName,
        'passcodeHash': passcodeHash,
        'memberIds': memberIds,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
