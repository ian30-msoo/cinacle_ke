import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/chat_service.dart';

class MessageDetailScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String name;
  final String? avatarUrl;

  const MessageDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.name,
    this.avatarUrl,
  });

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen>
    with WidgetsBindingObserver {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  ChatMessage? _replyTo;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ChatService().setOnline();
    // Mark conversation as read when opened
    ChatService().markAsRead(widget.conversationId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ChatService().setOnline();
    } else if (state == AppLifecycleState.paused) {
      ChatService().setOffline();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    _ctrl.clear();
    final reply = _replyTo;
    setState(() => _replyTo = null);
    await ChatService().sendMessage(
      widget.conversationId,
      text,
      replyTo: reply,
    );
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white, size: 22),
          onPressed: () => Navigator.pop(context),
          splashRadius: 20,
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            _Avatar(name: widget.name, avatarUrl: widget.avatarUrl, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // Real-time presence subtitle
                  StreamBuilder<Map<String, dynamic>?>(
                    stream: ChatService().presenceStream(widget.otherUserId),
                    builder: (context, snap) {
                      final data = snap.data;
                      final isOnline = data?['online'] == true;
                      final lastSeen = data?['lastSeen'] as DateTime?;
                      String subtitle;
                      if (isOnline) {
                        subtitle = 'Online';
                      } else if (lastSeen != null) {
                        subtitle = 'Last seen ${_formatLastSeen(lastSeen)}';
                      } else {
                        subtitle = 'Last seen recently';
                      }
                      return Text(
                        subtitle,
                        style: TextStyle(
                          color: isOnline
                              ? AppColors.gold
                              : Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined,
                color: AppColors.white, size: 22),
            onPressed: () {},
            splashRadius: 20,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.white, size: 22),
            onPressed: () {},
            splashRadius: 20,
          ),
        ],
      ),
      body: Column(
        children: [
          // Real-time message list
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: ChatService().messagesStream(widget.conversationId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snap.data ?? [];
                // Auto-scroll on new messages
                if (messages.isNotEmpty) _scrollToBottom();
                // Mark as read whenever new messages arrive
                ChatService().markAsRead(widget.conversationId);

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hello to ${widget.name} 👋',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 14),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final showDate = i == 0 ||
                        !_sameDay(messages[i - 1].createdAt, msg.createdAt);
                    return Column(
                      children: [
                        if (showDate) _DateDivider(date: msg.createdAt),
                        _buildBubble(msg),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Reply preview bar
          if (_replyTo != null)
            _ReplyPreview(
              message: _replyTo!,
              onCancel: () => setState(() => _replyTo = null),
            ),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    return GestureDetector(
      // Long press to reply
      onLongPress: () => setState(() => _replyTo = msg),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment:
              msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!msg.isMe) ...[
              _Avatar(name: widget.name, avatarUrl: widget.avatarUrl, size: 28),
              const SizedBox(width: 6),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 270),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: msg.isMe ? AppColors.primaryDark : AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
                    bottomRight: Radius.circular(msg.isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: msg.isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Reply quote block
                    if (msg.replyToText != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: msg.isMe
                              ? Colors.white.withOpacity(0.12)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color:
                                  msg.isMe ? AppColors.gold : AppColors.primary,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.replyToSenderName ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: msg.isMe
                                    ? AppColors.gold
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              msg.replyToText!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: msg.isMe
                                    ? Colors.white.withOpacity(0.7)
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Message text
                    Text(
                      msg.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: msg.isMe ? AppColors.white : AppColors.textDark,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.jm().format(msg.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: msg.isMe
                            ? Colors.white.withOpacity(0.6)
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle:
                      TextStyle(color: AppColors.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                ),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSending
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatLastSeen(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'today at ${DateFormat.jm().format(dt)}';
    if (diff.inDays == 1) return 'yesterday';
    return DateFormat.MMMd().format(dt);
  }
}

// ─── Date divider ─────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = 'Today';
    } else if (now.difference(date).inDays == 1) {
      label = 'Yesterday';
    } else {
      label = DateFormat.yMMMd().format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }
}

// ─── Reply preview bar ────────────────────────────────────────────────────────

class _ReplyPreview extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onCancel;

  const _ReplyPreview({required this.message, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surfaceLight,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.isMe ? 'You' : message.senderName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  message.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
            onPressed: onCancel,
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─── Avatar widget ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;
  const _Avatar({required this.name, this.avatarUrl, this.size = 40});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initial(),
          errorWidget: (_, __, ___) => _initial(),
        ),
      );
    }
    return _initial();
  }

  Widget _initial() => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
            color: AppColors.primary, shape: BoxShape.circle),
        child: Center(
          child: Text(_initials,
              style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.36)),
        ),
      );
}
