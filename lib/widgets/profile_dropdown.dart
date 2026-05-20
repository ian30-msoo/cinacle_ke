import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';

class ProfileDropdown extends StatelessWidget {
  final VoidCallback onClose;
  final ValueChanged<String> onNavigate;

  const ProfileDropdown({
    super.key,
    required this.onClose,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // Full-screen dimming overlay
              Container(color: Colors.black.withOpacity(0.2)),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  // Prevent taps inside from closing
                  onTap: () {},
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(14),
                    shadowColor: Colors.black26,
                    child: Container(
                      width: 230,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: AppColors.border)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: state.isLoggedIn
                                        ? AppColors.primaryDark
                                        : AppColors.surfaceLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: state.isLoggedIn &&
                                            state.currentUser != null
                                        ? Text(
                                            state.currentUser!.initials,
                                            style: const TextStyle(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          )
                                        : const Icon(Icons.person_outline,
                                            color: AppColors.primary, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.isLoggedIn
                                            ? (state.currentUser?.name ??
                                                'Member')
                                            : 'Guest User',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        state.isLoggedIn
                                            ? (state.currentUser?.email ?? '')
                                            : 'Tap to sign in',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Menu items
                          if (state.isLoggedIn) ...[
                            _item(Icons.person_outline, 'My Profile', () {
                              onClose();
                              onNavigate('settings');
                            }),
                            _item(Icons.bookmark_border, 'Saved Content', () {
                              onClose();
                              onNavigate('home');
                            }),
                            _item(Icons.settings_outlined, 'Settings', () {
                              onClose();
                              onNavigate('settings');
                            }),
                            const Divider(height: 1, color: AppColors.border),
                            _item(
                              Icons.logout,
                              'Sign Out',
                              () async {
                                onClose();
                                // Small delay so dropdown closes first
                                await Future.delayed(
                                    const Duration(milliseconds: 150));
                                if (context.mounted) {
                                  await context.read<AppState>().signOut();
                                  // UI rebuilds reactively — no explicit navigation needed
                                }
                              },
                              color: const Color(0xFFC62828),
                            ),
                          ] else ...[
                            _item(Icons.login, 'Sign In', () {
                              onClose();
                              Navigator.pushNamed(context, '/signin');
                            }),
                            _item(Icons.person_add_outlined, 'Create Account',
                                () {
                              onClose();
                              Navigator.pushNamed(context, '/signup');
                            }),
                            _item(Icons.settings_outlined, 'Settings', () {
                              onClose();
                              onNavigate('settings');
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(icon, size: 18, color: color ?? AppColors.textDark),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color ?? AppColors.textDark,
              fontWeight: color != null ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          visualDensity: const VisualDensity(vertical: -1),
        ),
      ),
    );
  }
}
