import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../widgets/cenacle_app_bar.dart';
import '../widgets/devotion_tabs.dart';

class DevotionDetailScreen extends StatelessWidget {
  const DevotionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CenacleAppBar(
        title: 'Read',
        titleIcon: Icons.menu_book,
      ),
      body: Column(
        children: [
          DevotionTabs(
            activeTab: 'daily',
            onTabChanged: (tab) {
              if (tab == 'articles') {
                Navigator.pop(context);
              }
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bible hero image — matches design
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: 'https://images.unsplash.com/photo-1533000971552-6a962ff0b9f9?w=800&q=80',
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF1565C0), Color(0xFF1A237E), Color(0xFF0D47A1)],
                          ),
                        ),
                        child: const Icon(Icons.auto_stories, color: Color(0x33FFFFFF), size: 90),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF1565C0), Color(0xFF1A237E), Color(0xFF0D47A1)],
                          ),
                        ),
                        child: const Icon(Icons.auto_stories, color: Color(0x33FFFFFF), size: 90),
                      ),
                    ),
                  ),
                  Padding(
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
                    'The journey of faith starts from believing then it goes to knowing. Believing is the weakest way to demonstrate trust but it is the needed way to start the journey of trust. The believing Christians can always change. It is impossible to change a knowing Christian!! That\'s why God wants us to move from the realm of believing to the realm of knowing.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textDark,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'In the realm of knowing, it\'s not about whether God will do it or not, it\'s that HE IS GOD. In the believing realm, God does it to prove a point. In the knowing realm, God is the point without doing anything!',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textDark,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'For us to stand in this generation full of corruption, we need to move from the realm of believing to the realm of knowing!! Where you don\'t just believe that God can heal, you know that He can heal!!',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textDark,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '📌 SEEK TO KNOW HIM 📌',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Every blessing!',
                    style: TextStyle(fontSize: 15, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '#Bread&Wine\n#LikeChrist',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ActionButton(
                        icon: Icons.play_arrow,
                        label: 'Listen',
                        isPrimary: true,
                        onTap: () {},
                      ),
                      _ActionButton(
                        icon: Icons.bookmark_border,
                        label: 'Save',
                        onTap: () {},
                      ),
                      _ActionButton(
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ActionButton(
                    icon: Icons.download,
                    label: 'Download',
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                  ],   // inner Column children
                  ),   // inner Column
                  ),   // Padding
                ],     // outer Column children
              ),       // outer Column
            ),         // SingleChildScrollView
          ),           // Expanded
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isPrimary ? null : Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isPrimary ? AppColors.primaryDark : AppColors.textDark,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPrimary ? AppColors.primaryDark : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
