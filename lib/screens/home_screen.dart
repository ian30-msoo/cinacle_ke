import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/profile_dropdown.dart';
import '../theme/app_data.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int> onTabChange;
  final VoidCallback onViewDevotionDetail;
  final VoidCallback onViewLetsTalk;

  const HomeScreen({
    super.key,
    required this.onTabChange,
    required this.onViewDevotionDetail,
    required this.onViewLetsTalk,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showDropdown = false;
  bool _isMuted = true;
  bool _playerReady =
      false; // tracks when controller is safe to call methods on

  YoutubePlayerController? _ytController;

  @override
  void initState() {
    super.initState();
    _ytController = YoutubePlayerController(
      initialVideoId: 'su5q9Fy-9S4',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: true,
        loop: true,
        hideControls: true,
        showLiveFullscreenButton: false,
        disableDragSeek: true,
        enableCaption: false,
      ),
    );

    // Listen for player state — only mark ready when fully initialized
    _ytController!.addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    if (!mounted) return;
    if (_ytController!.value.isReady && !_playerReady) {
      setState(() => _playerReady = true);
    }
  }

  @override
  void dispose() {
    _ytController?.removeListener(_onPlayerStateChange);
    _ytController?.dispose();
    super.dispose();
  }

  void _toggleMute() {
    // Guard: only call methods when player is fully ready
    if (_ytController == null || !_playerReady) return;
    setState(() {
      _isMuted = !_isMuted;
      _isMuted ? _ytController!.mute() : _ytController!.unMute();
    });
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _handleDrawerNavigate(String route) {
    switch (route) {
      case 'home':
        widget.onTabChange(0);
        break;
      case 'letstalk':
        widget.onTabChange(1);
        break;
      case 'messages':
        widget.onTabChange(2);
        break;
      case 'devotion_daily':
      case 'devotion_articles':
        widget.onTabChange(3);
        break;
      case 'settings':
        widget.onTabChange(4);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: AppDrawer(onNavigate: _handleDrawerNavigate),
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          _buildBody(),
          if (_showDropdown)
            Positioned(
              top: 0,
              right: 0,
              left: 0,
              bottom: 0,
              child: ProfileDropdown(
                onClose: () => setState(() => _showDropdown = false),
                onNavigate: (route) {
                  setState(() => _showDropdown = false);
                  if (route == 'settings') widget.onTabChange(4);
                  if (route == 'signin') {
                    Navigator.pushNamed(context, '/signin');
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: AppColors.white, size: 22),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
          splashRadius: 20,
        ),
      ),
      title: Row(
        children: const [
          Icon(Icons.workspace_premium, color: AppColors.gold, size: 20),
          SizedBox(width: 10),
          Text(
            'CENACLE LINK',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle,
              color: AppColors.white, size: 26),
          onPressed: () => setState(() => _showDropdown = !_showDropdown),
          splashRadius: 20,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroBanner(),
          _buildTodaysDevotionSection(),
          _buildUpcomingEventsSection(),
          _buildServiceTimesSection(),
          _buildLetsTalkSection(),
          _buildMediaLibrarySection(),
          _buildMinistriesSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return SizedBox(
      height: 210,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // YouTube player — wrapped so it always stays in the tree once created.
          // Visibility keeps it alive (and buffering) even before _playerReady.
          if (_ytController != null)
            YoutubePlayer(
              controller: _ytController!,
              showVideoProgressIndicator: false,
              onReady: () {
                // onReady is the most reliable signal — mute right away
                if (mounted) {
                  setState(() => _playerReady = true);
                  _ytController!.mute();
                }
              },
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3D0A6E),
                    Color(0xFF6A1B9A),
                    Color(0xFF4A007A),
                  ],
                ),
              ),
            ),

          // Left-to-right gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.transparent, Color(0xCC3D0A6E)],
              ),
            ),
          ),

          // Top-to-bottom gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xBB2D0050)],
              ),
            ),
          ),

          // Mute button — greyed out until player is ready
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: _playerReady ? _toggleMute : null,
              child: AnimatedOpacity(
                opacity: _playerReady ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xBF320046),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        color: AppColors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _playerReady
                            ? (_isMuted ? 'Unmute' : 'Mute')
                            : 'Loading…',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // CENACLE badge top-left
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  Icon(Icons.workspace_premium,
                      color: AppColors.gold, size: 14),
                  SizedBox(width: 5),
                  Text(
                    'CENACLE',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom text and CTA buttons
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Shaped into Christ's fullness",
                  style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'A SURE\nFOUNDATION',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const Text(
                  'Abiding in the Word',
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _launchURL(
                          'https://chat.whatsapp.com/KBR0xaFn4SfLelwMR9zR3s',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.primaryDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Join Us',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _launchURL(
                          'https://www.youtube.com/@thecenacle.',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Watch Live',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysDevotionSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "TODAY'S DEVOTION",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => widget.onTabChange(3),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View All →',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: widget.onViewDevotionDetail,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 66,
                        height: 66,
                        child: CachedNetworkImage(
                          imageUrl:
                              'https://images.unsplash.com/photo-1504052434569-70ad5836ab65?w=200&q=80',
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1565C0),
                                  Color(0xFF0D47A1),
                                ],
                              ),
                            ),
                            child: const Icon(Icons.menu_book,
                                color: Color(0x73FFFFFF), size: 32),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1565C0),
                                  Color(0xFF0D47A1),
                                ],
                              ),
                            ),
                            child: const Icon(Icons.menu_book,
                                color: Color(0x73FFFFFF), size: 32),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KNOWING VS BELIEVE',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'John 17.3 - "For this is eternal life, that they may know You, the one true God."',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Daily Bread',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Mar 5',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_outlined,
                    color: AppColors.gold, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'UPCOMING EVENTS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Text(
                  '0 events',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'No upcoming events scheduled',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTimesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Service Times',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: AppData.serviceTimes.map((s) {
              return Expanded(
                child: Container(
                  margin: AppData.serviceTimes.indexOf(s) <
                          AppData.serviceTimes.length - 1
                      ? const EdgeInsets.only(right: 8)
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEEEEE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.church,
                            color: AppColors.gold, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s['day']!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s['service']!,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textMuted,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s['time']!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLetsTalkSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Let's Talk",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => widget.onTabChange(1),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View All →',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => widget.onTabChange(1),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.thumb_up, color: AppColors.white, size: 14),
                        SizedBox(width: 8),
                        Text(
                          'Trending discussion',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Social media and Christianity',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Social media and Christianity can intersect in various ways. Some Christians use social media as a platform to share their faith, connect with others, and find...',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: const [
                            Icon(Icons.thumb_up_outlined,
                                size: 13, color: AppColors.textMuted),
                            SizedBox(width: 4),
                            Text('6 likes',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textMuted)),
                            SizedBox(width: 16),
                            Icon(Icons.chat_bubble_outline,
                                size: 13, color: AppColors.textMuted),
                            SizedBox(width: 4),
                            Text('2 replies',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
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

  Widget _buildMediaLibrarySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_outline,
                  color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Media Library',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View All →',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
            ),
            itemCount: AppData.mediaItems.length,
            itemBuilder: (_, i) {
              final item = AppData.mediaItems[i];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item['icon'] == 'music'
                            ? Icons.music_note
                            : Icons.description_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['title']!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['type']!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static const List<Map<String, String>> _ministryImages = [
    {
      'name': 'Kingdom Kids',
      'url':
          'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=400&q=80',
    },
    {
      'name': 'Royal daughters',
      'url':
          'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=400&q=80',
    },
    {
      'name': 'The Forge',
      'url':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
    },
    {
      'name': 'YT NATION',
      'url':
          'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=400&q=80',
    },
  ];

  Widget _buildMinistriesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_outlined,
                  color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Our Ministries',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.8,
            ),
            itemCount: _ministryImages.length,
            itemBuilder: (_, i) {
              final ministry = _ministryImages[i];
              return GestureDetector(
                onTap: () {},
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: ministry['url']!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.border),
                        errorWidget: (_, __, ___) =>
                            Container(color: AppColors.primaryDark),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 12,
                        right: 12,
                        child: Text(
                          ministry['name']!,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
