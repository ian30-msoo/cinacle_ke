import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/cenacle_app_bar.dart';
import '../widgets/toggle_switch.dart';
import '../widgets/avatar_widget.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _helpUrl = 'https://yourapp.com/help';
  static const _privacyUrl = 'https://yourapp.com/privacy';

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
                    onTap: () => _showEditProfileSheet(context, state),
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
                // Language row — placeholder, wired up later
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
                  onTap: () => _launchUrl(context, _helpUrl),
                ),
                const SizedBox(height: 8),
                _buildRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textMuted, size: 16),
                  onTap: () => _launchUrl(context, _privacyUrl),
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

  // ────────────────────────────────────────────
  // Edit Profile bottom sheet
  // ────────────────────────────────────────────

  void _showEditProfileSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(state: state),
    );
  }

  // ────────────────────────────────────────────
  // URL launcher
  // ────────────────────────────────────────────

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  // ────────────────────────────────────────────
  // Avatar picker + upload
  // ────────────────────────────────────────────

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

  // ────────────────────────────────────────────
  // Profile card
  // ────────────────────────────────────────────

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
                      child: const Icon(Icons.camera_alt,
                          size: 12, color: AppColors.primaryDark),
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
                                strokeWidth: 2, color: Colors.white),
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
                  Text(user.name,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white)),
                  const SizedBox(height: 2),
                  Text(user.email,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xBBFFFFFF))),
                  if (user.phone != null) ...[
                    const SizedBox(height: 1),
                    Text(user.phone!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0x99FFFFFF))),
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
              child: const Text('Member',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark)),
            ),
          ],
        ),
      );
    }

    // Guest card
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
                  color: AppColors.surfaceLight, shape: BoxShape.circle),
              child: const Icon(Icons.person_outline,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Guest User',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  SizedBox(height: 2),
                  Text('Tap to sign in or create account',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textMuted)),
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

  // ────────────────────────────────────────────
  // Sign out button
  // ────────────────────────────────────────────

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

  // ────────────────────────────────────────────
  // Shared helpers
  // ────────────────────────────────────────────

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
                  color: AppColors.surfaceLight, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.gold, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark)),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
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

// ════════════════════════════════════════════════
// Edit Profile bottom sheet
// ════════════════════════════════════════════════

class _EditProfileSheet extends StatefulWidget {
  final AppState state;
  const _EditProfileSheet({required this.state});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  int _tab = 0; // 0 = name, 1 = password

  late final TextEditingController _nameCtrl;
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.state.currentUser?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Edit Profile',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            // Tab switcher
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _tabBtn(0, 'Display Name', Icons.person_outline),
                  _tabBtn(1, 'Password', Icons.lock_outline),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_tab == 0) _buildNameTab() else _buildPasswordTab(),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(int index, String label, IconData icon) {
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16, color: active ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.textMuted,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Display Name',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Your full name',
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _submitBtn(
          label: 'Save Name',
          onTap: () async {
            final ok = await widget.state.updateDisplayName(_nameCtrl.text);
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Display name updated!'
                      : widget.state.authError ?? 'Update failed.'),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPasswordTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pwField(
          ctrl: _currentPwCtrl,
          label: 'Current Password',
          show: _showCurrent,
          onToggle: () => setState(() => _showCurrent = !_showCurrent),
        ),
        const SizedBox(height: 12),
        _pwField(
          ctrl: _newPwCtrl,
          label: 'New Password',
          show: _showNew,
          onToggle: () => setState(() => _showNew = !_showNew),
        ),
        const SizedBox(height: 12),
        _pwField(
          ctrl: _confirmPwCtrl,
          label: 'Confirm New Password',
          show: _showConfirm,
          onToggle: () => setState(() => _showConfirm = !_showConfirm),
        ),
        const SizedBox(height: 20),
        _submitBtn(
          label: 'Update Password',
          onTap: () async {
            if (_newPwCtrl.text != _confirmPwCtrl.text) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New passwords do not match.')),
              );
              return;
            }
            final ok = await widget.state.updatePassword(
              currentPassword: _currentPwCtrl.text,
              newPassword: _newPwCtrl.text,
            );
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Password updated successfully!'
                      : widget.state.authError ?? 'Update failed.'),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _pwField({
    required TextEditingController ctrl,
    required String label,
    required bool show,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: !show,
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: AppColors.surfaceLight,
            suffixIcon: IconButton(
              icon: Icon(show ? Icons.visibility_off : Icons.visibility,
                  size: 18, color: AppColors.textMuted),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _submitBtn({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: widget.state.isAuthLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: widget.state.isAuthLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
        ),
      ),
    );
  }
}
