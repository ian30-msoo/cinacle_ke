import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../utils/auth_gaurd.dart';
import '../widgets/cenacle_app_bar.dart';
import '../models/post_model.dart';
import '../services/lets_talk_service.dart';
import '../widgets/post_card.dart';
import '../widgets/private_room_sheet.dart';
import '../widgets/new_post_Sheet.dart';

class LetsTalkScreen extends StatefulWidget {
  const LetsTalkScreen({super.key});

  @override
  State<LetsTalkScreen> createState() => _LetsTalkScreenState();
}

class _LetsTalkScreenState extends State<LetsTalkScreen> {
  // FIX 1: Use singleton instance, not LetsTalkService()
  final _service = LetsTalkService.instance;

  String _filter = 'All Topics';
  String _sort = 'recent';

  static const _filterTopics = [
    'All Topics',
    'Government',
    'Education',
    'Media',
    'Religion',
    'Arts & Culture',
  ];

  static const _filterIcons = {
    'Government': Icons.account_balance,
    'Education': Icons.school,
    'Media': Icons.tv,
    'Religion': Icons.church,
    'Arts & Culture': Icons.landscape,
  };

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CenacleAppBar(
        title: "Let's Talk",
        titleIcon: Icons.chat_bubble_outline,
        action: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: ElevatedButton.icon(
            onPressed: () async {
              final authed = await requireAuth(context);
              if (authed && context.mounted) _openNewPost(context);
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              'New Post',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.primaryDark,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SEVEN MOUNTAINS OF INFLUENCE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            _buildFilterChips(),
            const SizedBox(height: 4),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),
            _buildPrivateRoomCard(),
            const SizedBox(height: 16),
            _buildSortToggle(),
            const SizedBox(height: 16),
            _buildPostsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        // FIX 2: Use local _filterTopics, not AppData.filterTopics
        children: _filterTopics.map((topic) {
          final isActive = _filter == topic;
          return GestureDetector(
            onTap: () => setState(() => _filter = topic),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isActive ? AppColors.textDark : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: isActive ? null : Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (topic != 'All Topics' &&
                      _filterIcons.containsKey(topic)) ...[
                    Icon(
                      _filterIcons[topic],
                      size: 13,
                      color: isActive ? AppColors.white : AppColors.textMuted,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    topic,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? AppColors.white : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPrivateRoomCard() {
    return GestureDetector(
      onTap: () async {
        final authed = await requireAuth(context);
        if (authed && context.mounted) _openRoomsSheet(context);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline,
                  color: AppColors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Private Rooms',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Create or join members-only discussions',
                    style: TextStyle(fontSize: 12, color: Color(0xBBFFFFFF)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white60, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSortToggle() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'DISCUSSIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 1,
            ),
          ),
        ),
        GestureDetector(
          onTap: () =>
              setState(() => _sort = _sort == 'recent' ? 'trending' : 'recent'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _sort == 'trending' ? Icons.trending_up : Icons.access_time,
                  size: 13,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  _sort == 'trending' ? 'Trending' : 'Recent',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostsList() {
    return StreamBuilder<List<PostModel>>(
      stream: _service.streamPosts(
        topic: _filter == 'All Topics' ? null : _filter,
        sort: _sort,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final posts = snap.data ?? [];
        if (posts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No posts in this topic yet.\nBe the first to start a discussion!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
            ),
          );
        }
        return Column(
          children: posts.map((post) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PostCardLT(
                post: post,
                currentUserId: _user?.uid ?? '',
                currentUserName: _user?.displayName ?? 'Anonymous',
                currentUserAvatar: _user
                    ?.photoURL, // this is very optional because i have not placed in the setting file
                service: _service,
                onLike: () async {
                  final authed = await requireAuth(context);
                  if (authed && _user != null) {
                    await _service.toggleLike(post.id, _user!.uid);
                  }
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _openNewPost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewPostSheet(service: _service, user: _user!),
    );
  }

  void _openRoomsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PrivateRoomsSheet(service: _service, user: _user!),
    );
  }
}
