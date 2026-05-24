import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    hide PlayerState;
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../theme/app_data.dart';

class MediaLibraryScreen extends StatefulWidget {
  const MediaLibraryScreen({super.key});

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchCtrl.addListener(
      () =>
          setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
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
          'Media Library',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          indicatorWeight: 3,
          labelColor: AppColors.gold,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          tabs: const [
            Tab(
                icon: Icon(Icons.play_circle_outline, size: 18),
                text: 'Videos'),
            Tab(icon: Icon(Icons.headphones_outlined, size: 18), text: 'Audio'),
            Tab(icon: Icon(Icons.menu_book_outlined, size: 18), text: 'Books'),
          ],
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
                      decoration: const InputDecoration(
                        hintText: 'Search media…',
                        hintStyle:
                            TextStyle(color: AppColors.textMuted, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: AppColors.textMuted),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                      splashRadius: 16,
                    ),
                ],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _VideosTab(searchQuery: _searchQuery),
                _AudioTab(searchQuery: _searchQuery),
                _BooksTab(searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//  Videos tab

class _VideosTab extends StatelessWidget {
  final String searchQuery;
  const _VideosTab({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final items = AppData.videos
        .where((v) =>
            searchQuery.isEmpty ||
            v['title']!.toLowerCase().contains(searchQuery) ||
            v['speaker']!.toLowerCase().contains(searchQuery) ||
            v['category']!.toLowerCase().contains(searchQuery))
        .toList();

    if (items.isEmpty) {
      return const _EmptyState(
          icon: Icons.play_circle_outline, label: 'No videos yet');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: items.length,
      itemBuilder: (_, i) => _VideoCard(item: items[i]),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final Map<String, String> item;
  const _VideoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _YouTubePlayerScreen(
            videoId: item['youtubeId']!,
            title: item['title']!,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: item['thumb']!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 180,
                      color: AppColors.primaryDark,
                      child: const Center(
                        child: Icon(Icons.play_circle_outline,
                            color: Colors.white38, size: 48),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 180,
                      color: AppColors.primaryDark,
                      child: const Center(
                        child: Icon(Icons.play_circle_outline,
                            color: Colors.white38, size: 48),
                      ),
                    ),
                  ),
                  // Play overlay
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 34),
                      ),
                    ),
                  ),
                  // Duration
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['duration']!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  // Category
                  Positioned(
                    top: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item['category']!,
                        style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(item['speaker']!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                      const Spacer(),
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(item['date']!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  YouTube full-screen player

class _YouTubePlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  const _YouTubePlayerScreen({required this.videoId, required this.title});

  @override
  State<_YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<_YouTubePlayerScreen> {
  late YoutubePlayerController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _ctrl,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.gold,
      ),
      builder: (context, player) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back, color: AppColors.white, size: 22),
            onPressed: () => Navigator.pop(context),
            splashRadius: 20,
          ),
          title: Text(
            widget.title,
            style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Column(
          children: [
            player,
            Expanded(
              child: Container(
                color: Colors.black,
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  Audio tab

class _AudioTab extends StatelessWidget {
  final String searchQuery;
  const _AudioTab({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final items = AppData.audio
        .where((a) =>
            searchQuery.isEmpty ||
            a['title']!.toLowerCase().contains(searchQuery) ||
            a['speaker']!.toLowerCase().contains(searchQuery) ||
            a['category']!.toLowerCase().contains(searchQuery))
        .toList();

    if (items.isEmpty) {
      return const _EmptyState(
          icon: Icons.headphones_outlined, label: 'No audio yet');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: items.length,
      itemBuilder: (_, i) => _AudioCard(item: items[i]),
    );
  }
}

class _AudioCard extends StatelessWidget {
  final Map<String, String> item;

  const _AudioCard({required this.item});

  static const _catColors = <String, Color>{
    'Sermon': Color(0xFF1A6370),
    'Worship': Color(0xFF7A2AB0),
    'Prayer': Color(0xFF1A7A44),
    'Bible Study': Color(0xFF2A3F72),
    'Youth': Color(0xFFB8761A),
    'Ministries': Color(0xFFB01A3A),
  };

  @override
  Widget build(BuildContext context) {
    final color = _catColors[item['category']] ?? AppColors.primary;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _AudioPlayerScreen(
            url: item['url']!,
            title: item['title']!,
            speaker: item['speaker']!,
            category: item['category']!,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.headphones_rounded, color: color, size: 22),
          ),
          title: Text(
            item['title']!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item['category']!,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    item['speaker']!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      item['duration']!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item['date']!,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//  Audio player screen

class _AudioPlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  final String speaker;
  final String category;

  const _AudioPlayerScreen({
    required this.url,
    required this.title,
    required this.speaker,
    required this.category,
  });

  @override
  State<_AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<_AudioPlayerScreen> {
  final _player = AudioPlayer();
  bool _loading = true;
  bool _hasError = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setUrl(widget.url);
      _player.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d ?? Duration.zero);
      });
      _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white, size: 22),
          onPressed: () => Navigator.pop(context),
          splashRadius: 20,
        ),
        title: const Text(
          'Now Playing',
          style: TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Album art placeholder
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.headphones_rounded,
                  color: AppColors.gold, size: 80),
            ),
            const SizedBox(height: 40),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.speaker,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 32),

            if (_hasError)
              const Text('Could not load audio.',
                  style: TextStyle(color: Colors.redAccent))
            else if (_loading)
              const CircularProgressIndicator(color: AppColors.gold)
            else ...[
              // Progress slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.gold,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppColors.gold,
                  overlayColor: AppColors.gold.withOpacity(0.2),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: _position.inSeconds
                      .clamp(0, _duration.inSeconds)
                      .toDouble(),
                  max: _duration.inSeconds.toDouble().clamp(1, double.infinity),
                  onChanged: (v) => _player.seek(Duration(seconds: v.toInt())),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(_position),
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12)),
                    Text(_fmt(_duration),
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10,
                        color: Colors.white70, size: 32),
                    onPressed: () =>
                        _player.seek(_position - const Duration(seconds: 10)),
                  ),
                  const SizedBox(width: 16),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snap) {
                      final playing = snap.data?.playing ?? false;
                      return GestureDetector(
                        onTap: () => playing ? _player.pause() : _player.play(),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: AppColors.primaryDark,
                            size: 38,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.forward_30,
                        color: Colors.white70, size: 32),
                    onPressed: () =>
                        _player.seek(_position + const Duration(seconds: 30)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

//  Books tab

class _BooksTab extends StatelessWidget {
  final String searchQuery;
  const _BooksTab({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final items = AppData.books
        .where((b) =>
            searchQuery.isEmpty ||
            b['title']!.toLowerCase().contains(searchQuery) ||
            b['author']!.toLowerCase().contains(searchQuery) ||
            b['category']!.toLowerCase().contains(searchQuery))
        .toList();

    if (items.isEmpty) {
      return const _EmptyState(
          icon: Icons.menu_book_outlined, label: 'No books yet');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: items.length,
      itemBuilder: (_, i) => _BookCard(item: items[i]),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Map<String, String> item;
  const _BookCard({required this.item});

  static const _catColors = <String, Color>{
    'Study Notes': Color(0xFF2A3F72),
    'Prayer': Color(0xFF1A7A44),
    'Discipleship': Color(0xFF1A6370),
    'Youth': Color(0xFFB8761A),
  };

  Future<void> _openPdf(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PDF.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _catColors[item['category']] ?? AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item['category']!,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['title']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description']!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(item['author']!,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(width: 10),
                      const Icon(Icons.description_outlined,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(item['pages']!,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _openPdf(context, item['url']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Open',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
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
      ),
    );
  }
}

//  Empty state

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
