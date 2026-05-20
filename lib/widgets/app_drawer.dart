import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';

class AppDrawer extends StatelessWidget {
  final ValueChanged<String> onNavigate;

  const AppDrawer({super.key, required this.onNavigate});

  Future<void> _handleSignOut(BuildContext context) async {
    Navigator.pop(context); // Close drawer first

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<AppState>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        const navItems = [
          {'label': 'Home', 'icon': Icons.home_outlined, 'route': 'home'},
          {
            'label': "Let's Talk",
            'icon': Icons.chat_bubble_outline,
            'route': 'letstalk'
          },
          {
            'label': 'Messages',
            'icon': Icons.mail_outline,
            'route': 'messages'
          },
          {
            'label': 'Devotion',
            'icon': Icons.menu_book_outlined,
            'route': 'devotion_daily'
          },
          {
            'label': 'Articles',
            'icon': Icons.auto_stories_outlined,
            'route': 'devotion_articles'
          },
          {
            'label': 'Media Library',
            'icon': Icons.play_circle_outline,
            'route': 'home'
          },
          {
            'label': 'Settings',
            'icon': Icons.settings_outlined,
            'route': 'settings'
          },
        ];

        return Drawer(
          backgroundColor: AppColors.background,
          child: Column(
            children: [
              //  Header
              Container(
                width: double.infinity,
                color: AppColors.primaryDark,
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + 16,
                  16,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium,
                            color: AppColors.gold, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'CENACLE LINK',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close,
                              color: Colors.white60, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // User section
                    if (state.isLoggedIn && state.currentUser != null) ...[
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: AppColors.gold, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                state.currentUser!.initials,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.currentUser!.name,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  state.currentUser!.email,
                                  style: const TextStyle(
                                    color: Color(0x99FFFFFF),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/signin');
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white30, width: 1.5),
                              ),
                              child: const Icon(Icons.person_outline,
                                  color: Colors.white70, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Guest User',
                                  style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Tap to sign in',
                                  style: TextStyle(
                                      color: Color(0x88FFFFFF), fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              //  Nav items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ...navItems.map((item) => ListTile(
                          leading: Icon(item['icon'] as IconData,
                              color: AppColors.gold, size: 22),
                          title: Text(
                            item['label'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: AppColors.textMuted, size: 16),
                          onTap: () {
                            Navigator.pop(context);
                            onNavigate(item['route'] as String);
                          },
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 2),
                        )),
                    const Divider(height: 1, color: AppColors.border),
                    if (state.isLoggedIn)
                      ListTile(
                        leading: const Icon(Icons.logout,
                            color: Color(0xFFC62828), size: 22),
                        title: const Text(
                          'Sign Out',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFC62828)),
                        ),
                        onTap: () => _handleSignOut(context),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 2),
                      )
                    else
                      ListTile(
                        leading: const Icon(Icons.login,
                            color: AppColors.primary, size: 22),
                        title: const Text(
                          'Sign In / Register',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/signin');
                        },
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 2),
                      ),
                  ],
                ),
              ),

              //  Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Text(
                  'Cenacle Link v1.0.0\nA Sure Foundation',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted.withOpacity(0.6),
                      height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
