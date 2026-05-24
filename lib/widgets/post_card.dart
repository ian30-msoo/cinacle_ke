import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../theme/app_theme.dart';
import '../models/post_model.dart';
import '../services/lets_talk_service.dart';

class PostCardLT extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final String currentUserName; // ← ADDED: real display name
  final String? currentUserAvatar; // ← ADDED: optional avatar url
  final LetsTalkService service;
  final VoidCallback onLike;

  const PostCardLT({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.currentUserName, // ← ADDED
    this.currentUserAvatar, // ← ADDED
    required this.service,
    required this.onLike,
  });

  @override
  State<PostCardLT> createState() => _PostCardLTState();
}

class _PostCardLTState extends State<PostCardLT> {
  bool _showReplies = false;
  final _replyController = TextEditingController();
  bool _sendingReply = false;

  bool get _liked => widget.post.isLikedBy(widget.currentUserId);

  static const _avatarBgs = [
    Color(0xFFE8EEF9),
    Color(0xFFFFF3E0),
    Color(0xFFE8F5E9),
    Color(0xFFFCE4EC),
    Color(0xFFF3E5F5),
  ];
  static const _avatarFgs = [
    Color(0xFF1A2744),
    Color(0xFFB8761A),
    Color(0xFF1A7A44),
    Color(0xFFB01A3A),
    Color(0xFF7A2AB0),
  ];
  static const _badgeBgs = <String, Color>{
    'Government': Color(0xFFE8EEF9),
    'Education': Color(0xFFE8F5E9),
    'Media': Color(0xFFFCE4EC),
    'Religion': Color(0xFFFFF3E0),
    'Arts & Culture': Color(0xFFF3E5F5),
  };
  static const _badgeFgs = <String, Color>{
    'Government': Color(0xFF2A3F72),
    'Education': Color(0xFF1A7A44),
    'Media': Color(0xFFB01A3A),
    'Religion': Color(0xFFB8761A),
    'Arts & Culture': Color(0xFF7A2AB0),
  };

  Color get _avatarBg {
    final i = widget.post.author.hashCode.abs() % _avatarBgs.length;
    return _avatarBgs[i];
  }

  Color get _avatarFg {
    final i = widget.post.author.hashCode.abs() % _avatarFgs.length;
    return _avatarFgs[i];
  }

  Color get _badgeBg => _badgeBgs[widget.post.tag] ?? const Color(0xFFF1EDE6);
  Color get _badgeFg => _badgeFgs[widget.post.tag] ?? const Color(0xFF1A2744);

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _sendingReply) return;
    setState(() => _sendingReply = true);
    try {
      await widget.service.addReply(
        widget.post.id,
        ReplyModel.create(
          uid: widget.currentUserId,
          displayName: widget.currentUserName.isNotEmpty
              ? widget.currentUserName
              : 'Anonymous',
          avatarUrl: widget.currentUserAvatar,
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

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //  Header
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    post.isAnonymous ? AppColors.surfaceLight : _avatarBg,
                child: post.isAnonymous
                    ? const Icon(Icons.lock, size: 14, color: AppColors.primary)
                    : Text(
                        post.initials,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _avatarFg,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.isAnonymous ? 'Anonymous' : post.author,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      timeago.format(post.createdAt),
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  post.tag,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _badgeFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          //  Content
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            post.body,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          if (post.isRepost) ...[
            const SizedBox(height: 4),
            const Text(
              '↺ Reposted',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 10),

          //  Actions
          Row(
            children: [
              _ActionButton(
                icon: _liked ? Icons.favorite : Icons.favorite_border,
                label: '${post.likeCount}',
                color: _liked ? Colors.redAccent : AppColors.textMuted,
                onTap: widget.onLike,
              ),
              const SizedBox(width: 16),
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: _showReplies
                    ? 'Hide (${post.replyCount})'
                    : 'Replies (${post.replyCount})',
                onTap: () => setState(() => _showReplies = !_showReplies),
              ),
              const Spacer(),
              _ActionButton(
                icon: Icons.share_outlined,
                label: '',
                onTap: () {},
              ),
            ],
          ),

          //  Reply thread
          if (_showReplies) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            StreamBuilder<List<ReplyModel>>(
              stream: widget.service.streamReplies(post.id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Could not load replies: ${snap.error}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.redAccent),
                    ),
                  );
                }
                final replies = snap.data ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (replies.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No replies yet. Be the first!',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                    ...replies.map((r) => _ReplyTile(reply: r)),
                    const SizedBox(height: 8),
                    if (widget.currentUserId.isNotEmpty)
                      _ReplyInput(
                        controller: _replyController,
                        sending: _sendingReply,
                        onSend: _sendReply,
                      )
                    else
                      const Text(
                        'Sign in to reply.',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

//  Action button

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ],
      ),
    );
  }
}

//  Reply tile

class _ReplyTile extends StatelessWidget {
  final ReplyModel reply;
  const _ReplyTile({required this.reply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFFE8EEF9),
            child: Text(
              reply.authorInitials,
              style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2A3F72)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply.authorName,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeago.format(reply.createdAt),
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.textMuted),
                    ),
                  ],
                ),
                Text(
                  reply.body,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//  Reply input

class _ReplyInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _ReplyInput({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 12),
            onSubmitted: (_) => onSend(),
            decoration: InputDecoration(
              hintText: 'Write a reply…',
              hintStyle:
                  const TextStyle(fontSize: 12, color: AppColors.textMuted),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: sending ? null : onSend,
          child: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              shape: BoxShape.circle,
            ),
            child: sending
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}
