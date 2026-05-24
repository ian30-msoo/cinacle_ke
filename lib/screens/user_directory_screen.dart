import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/chat_service.dart';
import 'message_detail_screen.dart';

class UserDirectoryScreen extends StatefulWidget {
  const UserDirectoryScreen({super.key});

  @override
  State<UserDirectoryScreen> createState() => _UserDirectoryScreenState();
}

class _UserDirectoryScreenState extends State<UserDirectoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _loadingUid;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () => setState(() => _query = _searchCtrl.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openChat(AppUser user) async {
    if (_loadingUid != null) return;
    setState(() => _loadingUid = user.uid);
    try {
      final convId = await ChatService().getOrCreateConversation(user.uid);
      if (!mounted) return;

      // FIX: pop the directory first, then push the chat.
      // This means back from chat → MessagesScreen (not directory).
      Navigator.pop(context);
      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (_) => MessageDetailScreen(
            conversationId: convId,
            otherUserId: user.uid,
            name: user.displayName,
            avatarUrl: user.avatarUrl,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open chat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingUid = null);
    }
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
        title: const Text(
          'New Message',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          //  Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13),
                    child: Icon(Icons.search,
                        color: AppColors.textMuted, size: 18),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search people…',
                        hintStyle:
                            TextStyle(color: AppColors.textMuted, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: AppColors.textMuted),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                      splashRadius: 16,
                    ),
                ],
              ),
            ),
          ),

          //  User list
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: ChatService().usersStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text('Error: ${snap.error}',
                        style: const TextStyle(color: AppColors.textMuted)),
                  );
                }

                final all = snap.data ?? [];
                final filtered = _query.isEmpty
                    ? all
                    : all
                        .where(
                            (u) => u.displayName.toLowerCase().contains(_query))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_search,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            _query.isEmpty
                                ? 'No members found'
                                : 'No results for "$_query"',
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final online = filtered.where((u) => u.isOnline).toList();
                final offline = filtered.where((u) => !u.isOnline).toList();

                return ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    if (online.isNotEmpty) ...[
                      _SectionHeader(label: 'Online now', count: online.length),
                      ...online.map((u) => _UserTile(
                            user: u,
                            isLoading: _loadingUid == u.uid,
                            onTap: () => _openChat(u),
                          )),
                    ],
                    if (offline.isNotEmpty) ...[
                      _SectionHeader(label: 'Members', count: offline.length),
                      ...offline.map((u) => _UserTile(
                            user: u,
                            isLoading: _loadingUid == u.uid,
                            onTap: () => _openChat(u),
                          )),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;
  final bool isLoading;
  final VoidCallback onTap;

  const _UserTile({
    required this.user,
    required this.isLoading,
    required this.onTap,
  });

  String _lastSeenLabel() {
    final ls = user.lastSeen;
    if (ls == null) return 'Seen recently';
    final diff = DateTime.now().difference(ls);
    if (diff.inMinutes < 1) return 'Seen just now';
    if (diff.inMinutes < 60) return 'Seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) {
      return 'Seen today at ${DateFormat.jm().format(ls)}';
    }
    if (diff.inDays == 1) return 'Seen yesterday';
    return 'Seen ${DateFormat.MMMd().format(ls)}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: isLoading ? null : onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          _AvatarWidget(
              name: user.displayName, avatarUrl: user.avatarUrl, size: 46),
          if (user.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      subtitle: Text(
        user.isOnline ? 'Online' : _lastSeenLabel(),
        style: TextStyle(
          fontSize: 12,
          color: user.isOnline ? Colors.green : AppColors.textMuted,
        ),
      ),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right,
              color: AppColors.textMuted, size: 20),
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;

  const _AvatarWidget({required this.name, this.avatarUrl, this.size = 40});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
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
            color: AppColors.primaryDark, shape: BoxShape.circle),
        child: Center(
          child: Text(
            _initials,
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.36,
            ),
          ),
        ),
      );
}
