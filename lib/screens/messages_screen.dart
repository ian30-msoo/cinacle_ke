import 'dart:async';
import 'package:cinacleke/screens/Status_Viewer_Scren.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/cenacle_app_bar.dart';
import '../services/chat_service.dart';
import '../services/status_service.dart';
import 'message_detail_screen.dart';
import 'user_directory_screen.dart';
import 'status_screen.dart';
import 'status_composer_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CenacleAppBar(
        title: 'Messages',
        titleIcon: Icons.mail_outline,
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (!state.isLoggedIn) return const _GuestMessagesPlaceholder();
          return const _RealTimeMessagesList();
        },
      ),
    );
  }
}

//  Real-time conversation list

class _RealTimeMessagesList extends StatefulWidget {
  const _RealTimeMessagesList();

  @override
  State<_RealTimeMessagesList> createState() => _RealTimeMessagesListState();
}

class _RealTimeMessagesListState extends State<_RealTimeMessagesList>
    with WidgetsBindingObserver {
  final _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _presenceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ChatService().setOnline();

    // FIX: refresh presence every 2 minutes so lastSeen stays fresh
    // and the 5-min staleness check in ChatService works correctly
    _presenceTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => ChatService().setOnline(),
    );

    _searchCtrl.addListener(
      () => setState(() => _query = _searchCtrl.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presenceTimer?.cancel();
    _searchCtrl.dispose();
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

  void _openDirectory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserDirectoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Stack(
      children: [
        Column(
          children: [
            //  Status strip
            const _StatusStrip(),

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
                        decoration: const InputDecoration(
                          hintText: 'Search messages...',
                          hintStyle:
                              TextStyle(color: Color(0xFF9AA8AD), fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            //  Conversation list
            Expanded(
              child: StreamBuilder<List<Conversation>>(
                stream: ChatService().conversationsStream(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final convos = (snap.data ?? []).where((c) {
                    if (_query.isEmpty) return true;
                    return c
                            .displayName(myUid)
                            .toLowerCase()
                            .contains(_query) ||
                        c.lastMessage.toLowerCase().contains(_query);
                  }).toList();

                  if (convos.isEmpty) {
                    return _EmptyConversations(
                      hasQuery: _query.isNotEmpty,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80, top: 4),
                    itemCount: convos.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, indent: 76, color: AppColors.border),
                    itemBuilder: (context, i) =>
                        _ConvoTile(convo: convos[i], myUid: myUid),
                  );
                },
              ),
            ),
          ],
        ),

        //  FAB — compose button (WhatsApp style)
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _openDirectory,
            backgroundColor: AppColors.primaryDark,
            elevation: 4,
            child: const Icon(Icons.edit_outlined,
                color: AppColors.white, size: 22),
          ),
        ),
      ],
    );
  }
}

//  Status strip — horizontal "My Status" + contacts' rings, entry point
//  into the full StatusScreen. Sits above the search bar on Messages.

class _StatusStrip extends StatelessWidget {
  const _StatusStrip();

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final user = FirebaseAuth.instance.currentUser;
    final myName = user?.displayName ?? user?.email?.split('@').first ?? 'You';

    return Container(
      height: 106,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: StreamBuilder<List<UserStatusGroup>>(
        stream: StatusService().contactStatusesStream(),
        builder: (context, snap) {
          final groups = snap.data ?? [];

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              // My status — always first
              StreamBuilder<List<StatusItem>>(
                stream: StatusService().myStatusesStream(),
                builder: (context, mySnap) {
                  final myStatuses = mySnap.data ?? [];
                  return _StatusBubble(
                    label: 'My Status',
                    name: myName,
                    avatarUrl: user?.photoURL,
                    hasStatus: myStatuses.isNotEmpty,
                    hasUnviewed: false,
                    isMine: true,
                    onTap: () {
                      if (myStatuses.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StatusViewerScreen(
                              group: UserStatusGroup(
                                userId: myUid,
                                userName: myName,
                                userAvatar: user?.photoURL,
                                items: myStatuses,
                              ),
                              isMyStatus: true,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StatusComposerScreen(),
                          ),
                        );
                      }
                    },
                  );
                },
              ),

              // Contacts' statuses
              ...groups.map((g) => _StatusBubble(
                    label: g.userName,
                    name: g.userName,
                    avatarUrl: g.userAvatar,
                    hasStatus: true,
                    hasUnviewed: g.hasUnviewedFor(myUid),
                    isMine: false,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StatusViewerScreen(group: g, isMyStatus: false),
                      ),
                    ),
                  )),

              // "See all" entry into the full StatusScreen
              _SeeAllBubble(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatusScreen()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusBubble extends StatelessWidget {
  final String label;
  final String name;
  final String? avatarUrl;
  final bool hasStatus;
  final bool hasUnviewed;
  final bool isMine;
  final VoidCallback onTap;

  const _StatusBubble({
    required this.label,
    required this.name,
    this.avatarUrl,
    required this.hasStatus,
    required this.hasUnviewed,
    required this.isMine,
    required this.onTap,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: hasStatus
                        ? Border.all(
                            color: hasUnviewed
                                ? AppColors.primary
                                : AppColors.border,
                            width: 2.5,
                          )
                        : null,
                  ),
                  child: ClipOval(
                    child: avatarUrl != null && avatarUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _initial(),
                            errorWidget: (_, __, ___) => _initial(),
                          )
                        : _initial(),
                  ),
                ),
                if (isMine && !hasStatus)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: const Icon(Icons.add,
                          color: AppColors.white, size: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                isMine ? 'My Status' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initial() => Container(
        color: AppColors.primaryDark,
        child: Center(
          child: Text(_initials,
              style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
        ),
      );
}

class _SeeAllBubble extends StatelessWidget {
  final VoidCallback onTap;
  const _SeeAllBubble({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.donut_large_outlined,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 4),
            const SizedBox(
              width: 64,
              child: Text(
                'See all',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  Conversation tile

class _ConvoTile extends StatelessWidget {
  final Conversation convo;
  final String myUid;

  const _ConvoTile({required this.convo, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final name = convo.displayName(myUid);
    final avatar = convo.displayAvatar(myUid);
    final unread = convo.myUnread(myUid);
    final otherId = convo.otherUserId(myUid);

    return ListTile(
      onTap: () {
        // FIX: push MessageDetailScreen directly — no extra back-stack issue
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MessageDetailScreen(
              conversationId: convo.id,
              otherUserId: otherId,
              name: name,
              avatarUrl: avatar,
            ),
          ),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          _AvatarWidget(name: name, avatarUrl: avatar, size: 48),
          StreamBuilder<Map<String, dynamic>?>(
            stream: ChatService().presenceStream(otherId),
            builder: (context, snap) {
              final isOnline = snap.data?['online'] == true;
              if (!isOnline) return const SizedBox.shrink();
              return Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      title: Text(
        name,
        style: TextStyle(
          fontSize: 15,
          fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      subtitle: Text(
        convo.lastMessage.isEmpty ? 'Start a conversation' : convo.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: unread > 0 ? AppColors.textDark : AppColors.textMuted,
          fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(convo.lastMessageAt),
            style: TextStyle(
              fontSize: 11,
              color: unread > 0 ? AppColors.primary : AppColors.textMuted,
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.white,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return DateFormat.jm().format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat.E().format(dt);
    return DateFormat.MMMd().format(dt);
  }
}

//  Empty state

class _EmptyConversations extends StatelessWidget {
  final bool hasQuery;
  const _EmptyConversations({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasQuery ? Icons.search_off : Icons.forum_outlined,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery ? 'No results found' : 'No conversations yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Try a different name or keyword.'
                  : 'Tap the pencil icon to start a conversation.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

//  Guest placeholder

class _GuestMessagesPlaceholder extends StatelessWidget {
  const _GuestMessagesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mail_outline,
                  color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Messages',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to view your conversations and connect with the Cenacle community.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/signin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Sign In',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
              ),
              child: const Text('Create Account',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

//  Avatar widget

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
