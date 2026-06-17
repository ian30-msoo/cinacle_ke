import 'package:cinacleke/screens/Status_Viewer_Scren.dart';
import 'package:cinacleke/screens/Status_composer_Screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/cenacle_app_bar.dart';
import '../services/status_service.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CenacleAppBar(
        title: 'Status',
        titleIcon: Icons.donut_large_outlined,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 90, top: 4),
        children: [
          _MyStatusRow(myUid: myUid),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Text(
              'Recent updates',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.4,
              ),
            ),
          ),
          StreamBuilder<List<UserStatusGroup>>(
            stream: StatusService().contactStatusesStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final groups = snap.data ?? [];

              if (groups.isEmpty) {
                return const _EmptyContactStatuses();
              }

              return Column(
                children: groups
                    .map((g) => _ContactStatusTile(group: g, myUid: myUid))
                    .toList(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatusComposerScreen()),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 4,
        child:
            const Icon(Icons.edit_outlined, color: AppColors.white, size: 22),
      ),
    );
  }
}

//  My Status row

class _MyStatusRow extends StatelessWidget {
  final String myUid;
  const _MyStatusRow({required this.myUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StatusItem>>(
      stream: StatusService().myStatusesStream(),
      builder: (context, snap) {
        final myStatuses = snap.data ?? [];
        final hasStatus = myStatuses.isNotEmpty;
        final user = FirebaseAuth.instance.currentUser;
        final name =
            user?.displayName ?? user?.email?.split('@').first ?? 'You';

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          onTap: () {
            if (hasStatus) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatusViewerScreen(
                    group: UserStatusGroup(
                      userId: myUid,
                      userName: name,
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
                MaterialPageRoute(builder: (_) => const StatusComposerScreen()),
              );
            }
          },
          leading: Stack(
            children: [
              _StatusRing(
                hasUnviewed: false,
                hasStatus: hasStatus,
                child: _Avatar(name: name, avatarUrl: user?.photoURL, size: 50),
              ),
              if (!hasStatus)
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
                    child:
                        const Icon(Icons.add, color: AppColors.white, size: 12),
                  ),
                ),
            ],
          ),
          title: const Text(
            'My Status',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          subtitle: Text(
            hasStatus
                ? 'Tap to view · ${myStatuses.length} update${myStatuses.length > 1 ? 's' : ''}'
                : 'Tap to add status update',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        );
      },
    );
  }
}

//  Contact status tile

class _ContactStatusTile extends StatelessWidget {
  final UserStatusGroup group;
  final String myUid;

  const _ContactStatusTile({required this.group, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final unviewed = group.hasUnviewedFor(myUid);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StatusViewerScreen(group: group, isMyStatus: false),
        ),
      ),
      leading: _StatusRing(
        hasUnviewed: unviewed,
        hasStatus: true,
        child: _Avatar(
            name: group.userName, avatarUrl: group.userAvatar, size: 50),
      ),
      title: Text(
        group.userName,
        style: TextStyle(
          fontSize: 15,
          fontWeight: unviewed ? FontWeight.w700 : FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      subtitle: Text(
        _formatTime(group.latestAt),
        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return DateFormat.MMMd().add_jm().format(dt);
  }
}

//  Status ring (colored = unviewed, grey = viewed, dashed-ish add state)

class _StatusRing extends StatelessWidget {
  final bool hasUnviewed;
  final bool hasStatus;
  final Widget child;

  const _StatusRing({
    required this.hasUnviewed,
    required this.hasStatus,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasStatus) return child;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: hasUnviewed ? AppColors.primary : AppColors.border,
          width: 2.5,
        ),
      ),
      child: child,
    );
  }
}

//  Empty state

class _EmptyContactStatuses extends StatelessWidget {
  const _EmptyContactStatuses();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.donut_large_outlined,
                color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 14),
          const Text(
            'No recent updates',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Status updates from people you\'ve messaged will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

//  Avatar widget (same pattern as messages_screen / message_detail_screen)

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;
  const _Avatar({required this.name, this.avatarUrl, this.size = 40});

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
          child: Text(_initials,
              style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.32)),
        ),
      );
}
