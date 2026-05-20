import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/cenacle_app_bar.dart';
import '../widgets/devotion_tabs.dart';

class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({super.key});

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
            activeTab: 'articles',
            onTabChanged: (tab) {
              if (tab == 'daily') {
                Navigator.pop(context);
              }
            },
          ),
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back,
                      color: AppColors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'GOSPEL CENTERED',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFBF360C),
                          Color(0xFF6D2C00),
                          Color(0xFF3E1400),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_stories,
                      color: Color(0x33FFFFFF),
                      size: 90,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GOSPEL CENTERED',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Elisha Mwangi',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Published 2 months ago',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.only(left: 12),
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                  color: AppColors.primary, width: 3),
                            ),
                          ),
                          child: const Text(
                            'Living a Gospel centered life',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'We must pay much closer attention to what we have heard, lest we drift away from it. (Hebrews 2:1)',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textDark,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Gospel-centrality is not as popular as it once was. As an early adherent of the gospel-centered, "young, restless, and Reformed" whatchamacallit, I have watched many of my fellow tribesmen gradually undergo a shift in their ministry emphases and spiritual priorities over the last decade.',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textDark,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'In the gospel-centered heyday, many young ministers abandoned the seeker-sensitive church movement. Burned out by ever-demanding needs of innovative methodology, we were drawn to a focus on the cross, on grace, on the real substance of what it means to be a Christian.',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textDark,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 20),
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
}
