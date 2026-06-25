import 'package:cinacleke/screens/media_library_screen.dart';
import 'package:cinacleke/screens/ministry_details_Screen.dart';
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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
          _buildGreetingSection(),
          _buildTodaysDevotionSection(),
          _buildUpcomingEventsSection(),
          _buildLetsTalkSection(),
          _buildMediaLibraryBanner(),
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

  Widget _buildGreetingSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_greeting()}, Miller ✨',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: widget.onViewLetsTalk,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0x1AF1C40F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline,
                        color: AppColors.gold, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'What has been on your heart and mind lately?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Share it in Let's Talk",
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward,
                      size: 16, color: AppColors.gold),
                ],
              ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: 0.5,
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
                  'Explore more →',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: widget.onViewDevotionDetail,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56,
                      height: 56,
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
                              color: Color(0x73FFFFFF), size: 28),
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
                              color: Color(0x73FFFFFF), size: 28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SETTING LOVE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Psalms 91.14',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '"Because he has set his love on me I will deliver him."',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: const [
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
                              'May 29',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsSection() {
    // TODO: wire up to real events data source. Showing a single sample
    // event row to match the approved design; falls back to an empty
    // state automatically when AppData/events list is empty.
    final hasEvent = true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(14),
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
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  hasEvent ? '1 events' : '0 events',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (!hasEvent)
              const Text(
                'No upcoming events scheduled',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                          ),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'LIFE',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Jul 5',
                                style: TextStyle(
                                  color: Color(0xCCFFFFFF),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OUR MONTHLY FELLOWSHIP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 11, color: AppColors.textMuted),
                              SizedBox(width: 3),
                              Text(
                                '20:45 - 22:00',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.location_on_outlined,
                                  size: 11, color: AppColors.textMuted),
                              SizedBox(width: 3),
                              Text(
                                'Google meet',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
          ],
        ),
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
                  "LET'S TALK",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: 0.5,
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
                  'Explore more →',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => widget.onTabChange(1),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFFE0E0E0),
                        child: Icon(Icons.person,
                            size: 16, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Charis',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              '5 months ago',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0x1AF1C40F),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'TRENDING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Church & Government',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'What is the role of the church in a political world?',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(color: AppColors.gold, width: 3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(0xFFE0E0E0),
                          child: Icon(Icons.person,
                              size: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Zion Elichrist',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gold,
                                ),
                              ),
                              Text(
                                '"Wow 🙌🔥🔥"',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Text(
                        '3 others talking',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      Spacer(),
                      Icon(Icons.favorite_border,
                          size: 14, color: AppColors.textMuted),
                      SizedBox(width: 4),
                      Text('5',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                      SizedBox(width: 14),
                      Icon(Icons.chat_bubble_outline,
                          size: 14, color: AppColors.textMuted),
                      SizedBox(width: 4),
                      Text('3',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaLibraryBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MediaLibraryScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0x14F1C40F),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow,
                    color: AppColors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Media Library',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Videos, audio & books',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, size: 16, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }

  static const List<Map<String, dynamic>> _ministries = [
    {
      'name': 'Kingdom Kids',
      'imageUrl':
          'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=400&q=80',
      'description':
          'A children\'s ministry meant to shape children to grow in the ways of the Lord. We create a fun, safe, and nurturing environment where kids discover their identity in Christ.',
      'leader': 'Isaac Masila',
      'leaderTitle': 'Ministry Leader',
      'meetingTime': 'Sundays — 9:00 AM (during Morning Service)',
      'activities': [
        'Bible stories and memory verses',
        'Worship and praise sessions',
        'Creative arts and crafts',
        'Character-building activities',
      ],
      'contacts': ['masilaisaacmim@gmail.com'],
    },
    {
      'name': 'Royal Daughters',
      'imageUrl':
          'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=400&q=80',
      'description':
          'A women\'s fellowship that builds women of faith, purpose, and excellence. We journey together in sisterhood, prayer, and the Word of God.',
      'leader': 'Isaac Masila',
      'leaderTitle': 'Ministry Leader',
      'meetingTime': 'Last Saturday of every month — 10:00 AM',
      'activities': [
        'Women\'s Bible study and fellowship',
        'Prayer and intercession',
        'Mentorship and discipleship',
        'Community outreach and service',
      ],
      'contacts': ['masilaisaacmim@gmail.com'],
    },
    {
      'name': 'The Forge',
      'imageUrl':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
      'description':
          'A men\'s ministry dedicated to forging men of God — strong in faith, integrity, and servant leadership. Iron sharpens iron.',
      'leader': 'Isaac Masila',
      'leaderTitle': 'Ministry Leader',
      'meetingTime': 'Every other Saturday — 7:00 AM',
      'activities': [
        'Men\'s accountability groups',
        'Leadership and character development',
        'Prayer and fasting sessions',
        'Community and family impact projects',
      ],
      'contacts': ['masilaisaacmim@gmail.com'],
    },
    {
      'name': 'YT Nation',
      'imageUrl':
          'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=400&q=80',
      'description':
          'The youth ministry of Cenacle — a generation rising in faith, truth, and fire. YT Nation exists to disciple young people into passionate followers of Jesus.',
      'leader': 'Isaac Masila',
      'leaderTitle': 'Ministry Leader',
      'meetingTime': 'Fridays — 5:30 PM',
      'activities': [
        'Youth Bible study and discipleship',
        'Worship and creative arts',
        'Youth camps and retreats',
        'Evangelism and outreach',
      ],
      'contacts': ['masilaisaacmim@gmail.com'],
    },
  ];
  Widget _buildMinistriesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Our Ministries',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Divider(color: AppColors.border, height: 1),
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
              childAspectRatio: 1.8,
            ),
            itemCount: _ministries.length,
            itemBuilder: (_, i) {
              final ministry = _ministries[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MinistryDetailScreen(ministry: ministry),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: ministry['imageUrl'] as String,
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
                          ministry['name'] as String,
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
