import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../widgets/cenacle_app_bar.dart';
import '../widgets/devotion_tabs.dart';
import 'devotion_detail_screen.dart';
import 'article_detail_screen.dart';

class DevotionScreen extends StatefulWidget {
  final String initialTab;

  const DevotionScreen({super.key, this.initialTab = 'daily'});

  @override
  State<DevotionScreen> createState() => _DevotionScreenState();
}

class _DevotionScreenState extends State<DevotionScreen> {
  late String _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CenacleAppBar(
        title: 'Read',
        titleIcon: Icons.menu_book,
      ),
      body: Column(
        children: [
          DevotionTabs(
            activeTab: _activeTab,
            onTabChanged: (tab) => setState(() => _activeTab = tab),
          ),
          Expanded(
            child: _activeTab == 'daily'
                ? _buildDailyDevotionContent()
                : _buildArticlesContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyDevotionContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DevotionDetailScreen(),
              ),
            ),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1533000971552-6a962ff0b9f9?w=800&q=80',
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1565C0),
                        Color(0xFF1A237E),
                        Color(0xFF0D47A1)
                      ],
                    ),
                  ),
                  child: const Icon(Icons.auto_stories,
                      color: Color(0x33FFFFFF), size: 90),
                ),
                errorWidget: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1565C0),
                        Color(0xFF1A237E),
                        Color(0xFF0D47A1)
                      ],
                    ),
                  ),
                  child: const Icon(Icons.auto_stories,
                      color: Color(0x33FFFFFF), size: 90),
                ),
              ),
            ),
          ),
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.calendar_today, color: AppColors.gold, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'March 5, 2026',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'KNOWING VS BELIEVE',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '"For this is eternal life, that they may know You, the one true God." - John 17.3',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'The journey of faith starts from believing then it goes to knowing. Believing is the weakest way to demonstrate trust but it is the needed way to start the journey of trust. The believing Christians can always change. It is impossible to change a knowing Christian!!',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textDark,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'In the realm of knowing, it\'s not about whether God will do it or not, it\'s that HE IS GOD. In the believing realm, God does it to prove a point.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textDark,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DevotionDetailScreen(),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Text(
                        'Read more ',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: AppColors.primary, size: 13),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticlesContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ArticleDetailScreen()),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFBF360C), Color(0xFF6D2C00)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    color: Color(0x59FFFFFF),
                    size: 32,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GOSPEL CENTERED',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Living a Gospel centered life',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.person_outline,
                                      size: 11, color: AppColors.textMuted),
                                  SizedBox(width: 4),
                                  Text(
                                    'Elisha Mwangi',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '2 months ago',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.chevron_right,
                      color: AppColors.textMuted, size: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
