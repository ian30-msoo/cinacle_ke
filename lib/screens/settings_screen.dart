import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/cenacle_app_bar.dart';
import '../widgets/toggle_switch.dart';
import '../widgets/avatar_widget.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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

  // ── Profile card ──
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
            // ── Avatar with camera badge ──
            GestureDetector(
              onTap: () => _pickAndUploadAvatar(context, state),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: AvatarWidget(
                      initials: user.initials,
                      avatarUrl: user.avatarUrl,
                      size: 60,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primaryDark, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 12,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  if (state.isAuthLoading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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

    // ── Guest card ──
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

  // ── Avatar picker + upload ──
  Future<void> _pickAndUploadAvatar(
      BuildContext context, AppState state) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !context.mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (picked == null || !context.mounted) return;

    final success = await state.updateAvatar(File(picked.path));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Profile photo updated!'
              : state.authError ?? 'Upload failed.'),
        ),
      );
    }
  }

  // ── Sign out button ──
  Widget _buildSignOutButton(BuildContext context, AppState state) {
    return GestureDetector(
      onTap: () async {
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
