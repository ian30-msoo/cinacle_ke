import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/cenacle_app_bar.dart';
import '../models/post_model.dart';
import '../services/lets_talk_service.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _service = LetsTalkService.instance;
  final _replyController = TextEditingController();
  bool _sendingReply = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  IconData _tagIcon(String icon) {
    switch (icon) {
      case 'tv':
        return Icons.tv;
      case 'mountain':
        return Icons.landscape;
      case 'church':
        return Icons.church;
      case 'bank':
        return Icons.account_balance;
      case 'school':
        return Icons.school;
      default:
        return Icons.label_outline;
    }
  }

  Future<void> _sendReply(String postId) async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _sendingReply || _user == null) return;
    setState(() => _sendingReply = true);
    try {
      await _service.addReply(
        postId,
        ReplyModel.create(
          uid: _user!.uid,
          displayName: _user!.displayName ?? _user!.email ?? 'Anonymous',
          avatarUrl: _user!.photoURL,
          body: text,
        ),
      );
      _replyController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reply: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingReply = false);
    }
  }

  Future<void> _toggleLike(PostModel post) async {
    if (_user == null) return;
    await _service.toggleLike(post.id, _user!.uid);
  }

  Future<void> _toggleReplyLike(String postId, ReplyModel reply) async {
    if (_user == null) return;
    await _service.toggleReplyLike(postId, reply.id, _user!.uid);
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final post = state.selectedPost;

    if (post == null) {
      return const Scaffold(body: Center(child: Text('No post selected')));
    }

    final uid = _user?.uid ?? '';
    final isLiked = post.isLikedBy(uid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CenacleAppBar(
        title: "Let's Talk",
        titleIcon: Icons.chat_bubble_outline,
        action: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back,
                size: 14, color: AppColors.primaryDark),
            label: const Text(
              'Back',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.gold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          //  Post + replies (scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //  Post card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AvatarWidget(
                              initials: post.initials,
                              avatarUrl: post.avatarUrl,
                              isAnonymous: post.isAnonymous,
                              size: 44,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.isAnonymous
                                        ? 'Anonymous'
                                        : post.author,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    timeago.format(post.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Topic badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_tagIcon(post.tagIcon),
                                  size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                post.tag,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Body
                        Text(
                          post.body,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                            height: 1.8,
                          ),
                        ),

                        if (post.isRepost) ...[
                          const SizedBox(height: 6),
                          const Text(
                            '↺ Reposted',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 14),

                        // Actions row — like + reply count
                        Row(
                          children: [
                            // Like button (real-time)
                            GestureDetector(
                              onTap: () => _toggleLike(post),
                              child: Row(
                                children: [
                                  Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 16,
                                    color: isLiked
                                        ? Colors.redAccent
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${post.likeCount} ${post.likeCount == 1 ? "Like" : "Likes"}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isLiked
                                          ? Colors.redAccent
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            const Icon(Icons.chat_bubble_outline,
                                size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 5),
                            Text(
                              '${post.replyCount} ${post.replyCount == 1 ? "Reply" : "Replies"}',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  //  Replies section
                  const Text(
                    'REPLIES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),

                  StreamBuilder<List<ReplyModel>>(
                    stream: _service.streamReplies(post.id),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final replies = snap.data ?? [];
                      if (replies.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          alignment: Alignment.center,
                          child: const Text(
                            'No replies yet. Be the first to respond!',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textMuted),
                          ),
                        );
                      }
                      return Column(
                        children: replies
                            .map((r) => _ReplyCard(
                                  reply: r,
                                  currentUid: uid,
                                  onLike: () => _toggleReplyLike(post.id, r),
                                ))
                            .toList(),
                      );
                    },
                  ),

                  // Space so FAB doesn't cover last reply
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          //  Reply input bar (pinned to bottom)
          SafeArea(
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: (_) => _sendReply(post.id),
                      decoration: InputDecoration(
                        hintText: 'Write a reply…',
                        hintStyle: const TextStyle(
                            color: AppColors.textMuted, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendingReply ? null : () => _sendReply(post.id),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDark,
                        shape: BoxShape.circle,
                      ),
                      child: _sendingReply
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//
// Reply card widget
//

class _ReplyCard extends StatelessWidget {
  final ReplyModel reply;
  final String currentUid;
  final VoidCallback onLike;

  const _ReplyCard({
    required this.reply,
    required this.currentUid,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final isLiked = reply.isLikedBy(currentUid);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE8EEF9),
            backgroundImage: reply.authorAvatarUrl != null
                ? NetworkImage(reply.authorAvatarUrl!)
                : null,
            child: reply.authorAvatarUrl == null
                ? Text(
                    reply.authorInitials,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2A3F72)),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + time
                Row(
                  children: [
                    Text(
                      reply.authorName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeago.format(reply.createdAt),
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Body
                Text(
                  reply.body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                // Like reply
                GestureDetector(
                  onTap: onLike,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 13,
                        color: isLiked ? Colors.redAccent : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reply.likeCount > 0 ? '${reply.likeCount}' : 'Like',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isLiked ? Colors.redAccent : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
