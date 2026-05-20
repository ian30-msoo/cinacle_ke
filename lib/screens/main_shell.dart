import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import 'home_screen.dart';
import 'lets_talk_screen.dart';
import 'messages_screen.dart';
import 'devotion_screen.dart';
import 'settings_screen.dart';
import 'devotion_detail_screen.dart';

class MainShell extends StatefulWidget {
  final int initialTab;

  const MainShell({super.key, this.initialTab = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;

    // Listen to Firebase auth changes so the UI reacts immediately
    // when the user signs in or out from any screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().authStateChanges.listen((_) {
        if (mounted) setState(() {});
      });
    });
  }

  void _handleDevotionDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DevotionDetailScreen()),
    );
  }

  void _setTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Consumer ensures bottom nav and body react to auth state changes
    return Consumer<AppState>(
      builder: (context, state, _) {
        final screens = [
          HomeScreen(
            onTabChange: _setTab,
            onViewDevotionDetail: _handleDevotionDetail,
            onViewLetsTalk: () => _setTab(1),
          ),
          const LetsTalkScreen(),
          const MessagesScreen(),
          const DevotionScreen(),
          const SettingsScreen(),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: _buildBottomNav(state),
        );
      },
    );
  }

  Widget _buildBottomNav(AppState state) {
    const navItems = [
      {
        'label': 'Home',
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home_rounded
      },
      {
        'label': "Let's Talk",
        'icon': Icons.chat_bubble_outline,
        'activeIcon': Icons.chat_bubble_rounded
      },
      {
        'label': 'Messages',
        'icon': Icons.mail_outline,
        'activeIcon': Icons.mail_rounded
      },
      {
        'label': 'Devotion',
        'icon': Icons.menu_book_outlined,
        'activeIcon': Icons.menu_book_rounded
      },
      {
        'label': 'Settings',
        'icon': Icons.settings_outlined,
        'activeIcon': Icons.settings_rounded
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(navItems.length, (i) {
              final item = navItems[i];
              final isActive = _currentIndex == i;
              final color = isActive ? AppColors.gold : const Color(0x8CFFFFFF);

              // Show unread badge on Messages tab when logged in
              final showBadge = i == 2 && state.isLoggedIn;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _setTab(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            isActive
                                ? item['activeIcon'] as IconData
                                : item['icon'] as IconData,
                            color: color,
                            size: 22,
                          ),
                          if (showBadge)
                            Positioned(
                              top: -2,
                              right: -4,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.gold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
