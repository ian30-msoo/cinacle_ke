import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';
import '../models/post_model.dart';
import '../services/lets_talk_service.dart';
import '../widgets/avatar_widget.dart';

class PostCardLT extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final String currentUserName;
  final String? currentUserAvatar;
  final LetsTalkService service;
  final VoidCallback onLike;

  const PostCardLT({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserAvatar,
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
          // Header
          Row(
            children: [
              AvatarWidget(
                initials: post.initials,
                avatarUrl: post.isAnonymous ? null : post.avatarUrl,
                isAnonymous: post.isAnonymous,
                size: 32,
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

          // Title
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),

          // Body
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

          // Media (image or video)
          if (post.mediaUrl != null && post.mediaType != null) ...[
            const SizedBox(height: 10),
            _MediaPreview(url: post.mediaUrl!, type: post.mediaType!),
          ],

          if (post.isRepost) ...[
            const SizedBox(height: 4),
            const Text(
              '↺ Reposted',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 10),

          // Actions
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

          // Reply thread
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

// ─────────────────────────────────────────────
// Media Preview (image or video) in feed
// ─────────────────────────────────────────────

class _MediaPreview extends StatefulWidget {
  final String url;
  final String type;

  const _MediaPreview({required this.url, required this.type});

  @override
  State<_MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<_MediaPreview> {
  VideoPlayerController? _ctrl;
  bool _imageError = false;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'video') {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _ctrl!.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _retryImage() {
    setState(() {
      _imageError = false;
      _imageLoaded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == 'image') {
      return _buildImage();
    }
    return _buildVideo();
  }

  // ── IMAGE ──────────────────────────────────

  Widget _buildImage() {
    // Show retry UI if image failed
    if (_imageError) {
      return GestureDetector(
        onTap: _retryImage,
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded,
                    color: AppColors.textMuted, size: 28),
                SizedBox(height: 6),
                Text(
                  'Image failed to load\nTap to retry',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          // Shimmer placeholder while loading
          if (!_imageLoaded)
            Container(
              height: 200,
              width: double.infinity,
              color: AppColors.background,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),

          // Actual image
          Image.network(
            widget.url,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            // Force fresh load — avoids stale cache issues
            headers: const {'Cache-Control': 'no-cache'},
            frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                // Image is ready — mark loaded after next frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_imageLoaded) {
                    setState(() => _imageLoaded = true);
                  }
                });
                return child;
              }
              return const SizedBox.shrink();
            },
            errorBuilder: (_, error, __) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_imageError) {
                  setState(() => _imageError = true);
                }
              });
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // ── VIDEO ──────────────────────────────────

  Widget _buildVideo() {
    // Still initializing
    if (_ctrl == null || !_ctrl!.value.isInitialized) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
              SizedBox(height: 10),
              Text(
                'Loading video…',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    // Video ready
    return GestureDetector(
      onTap: () => setState(
          () => _ctrl!.value.isPlaying ? _ctrl!.pause() : _ctrl!.play()),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _ctrl!.value.aspectRatio,
              child: VideoPlayer(_ctrl!),
            ),
            // Play/pause overlay
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _ctrl!.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            // Progress bar at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _ctrl!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: AppColors.primary,
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.black26,
                ),
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Action button
// ─────────────────────────────────────────────

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

// ─────────────────────────────────────────────
// Reply tile
// ─────────────────────────────────────────────

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
          AvatarWidget(
            initials: reply.authorInitials,
            avatarUrl: reply.authorAvatarUrl,
            size: 24,
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

// ─────────────────────────────────────────────
// Reply input
// ─────────────────────────────────────────────

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
