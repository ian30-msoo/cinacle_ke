import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/cenacle_app_bar.dart';
import '../widgets/toggle_switch.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CenacleAppBar(
        title: 'Settings',
        titleIcon: Icons.settings_outlined,
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(context, state),
                const SizedBox(height: 20),
                _buildSectionLabel('ACCOUNT'),
                const SizedBox(height: 8),
                if (state.isLoggedIn) ...[
                  _buildRow(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    subtitle: state.currentUser?.email ?? '',
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textMuted, size: 16),
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _buildRow(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle:
                        state.notificationsEnabled ? 'Enabled' : 'Disabled',
                    trailing: ToggleSwitch(
                      value: state.notificationsEnabled,
                      onTap: state.toggleNotifications,
                    ),
                  ),
                ] else ...[
                  _buildRow(
                    icon: Icons.login,
                    title: 'Sign In',
                    subtitle: 'Access your profile and messages',
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textMuted, size: 16),
                    onTap: () => Navigator.pushNamed(context, '/signin'),
                  ),
                  const SizedBox(height: 8),
                  _buildRow(
                    icon: Icons.person_add_outlined,
                    title: 'Create Account',
                    subtitle: 'Join the Cenacle community',
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textMuted, size: 16),
                    onTap: () => Navigator.pushNamed(context, '/signup'),
                  ),
                  const SizedBox(height: 8),
                  _buildRow(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle:
                        state.notificationsEnabled ? 'Enabled' : 'Disabled',
                    trailing: ToggleSwitch(
                      value: state.notificationsEnabled,
                      onTap: state.toggleNotifications,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildSectionLabel('APP PREFERENCES'),
                const SizedBox(height: 8),
                _buildRow(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  subtitle: state.darkMode ? 'On' : 'Off',
                  trailing: ToggleSwitch(
                      value: state.darkMode, onTap: state.toggleDarkMode),
                ),
                const SizedBox(height: 8),
                _buildRow(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'English',
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textMuted, size: 16),
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('ABOUT'),
                const SizedBox(height: 8),
                _buildRow(
                  icon: Icons.help_outline,
                  title: 'Help & FAQ',
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textMuted, size: 16),
                ),
                const SizedBox(height: 8),
                _buildRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textMuted, size: 16),
                ),
                const SizedBox(height: 8),
                _buildRow(
                  icon: Icons.info_outline,
                  title: 'App Version',
                  subtitle: '1.0.0',
                ),
                if (state.isLoggedIn) ...[
                  const SizedBox(height: 24),
                  _buildSignOutButton(context, state),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, AppState state) {
    return GestureDetector(
      onTap: () async {
        // Confirm before signing out
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sign Out?'),
            content: const Text(
                'Are you sure you want to sign out of your account?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC62828)),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          await context.read<AppState>().signOut();
          // No navigation needed — Consumer rebuilds the settings card
          // and the rest of the app updates reactively via auth stream
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You have been signed out.')),
            );
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Color(0xFFC62828), size: 18),
            SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFFC62828),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AppState state) {
    if (state.isLoggedIn && state.currentUser != null) {
      final user = state.currentUser!;
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: Center(
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xBBFFFFFF)),
                  ),
                  if (user.phone != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      user.phone!,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0x99FFFFFF)),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Member',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Guest card — tappable to sign in
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/signin'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guest User',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tap to sign in or create account',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.gold, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
