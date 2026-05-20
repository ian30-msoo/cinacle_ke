import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false;
  bool _showConfirm = false;
  String? _localError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _localError = null);

    // Client-side validation
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _localError = 'Please enter your full name.');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _localError = 'Please enter your email address.');
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _localError = 'Password must be at least 6 characters.');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _localError = 'Passwords do not match.');
      return;
    }

    final state = context.read<AppState>();
    state.clearAuthError();

    final ok = await state.signUp(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      // Clear the entire auth stack, land on home
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppState>(
        builder: (context, state, _) {
          final error = _localError ?? state.authError;
          return SingleChildScrollView(
            child: Column(
              children: [
                // Teal header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                  ),
                  child: Column(
                    children: [
                      if (Navigator.canPop(context))
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back,
                                  color: AppColors.white, size: 18),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 2),
                        ),
                        child: const Icon(Icons.workspace_premium,
                            color: AppColors.gold, size: 40),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Join the Cenacle community',
                        style:
                            TextStyle(color: Color(0xBBFFFFFF), fontSize: 13),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF9A9A)),
                          ),
                          child: Text(
                            error,
                            style: const TextStyle(
                                color: Color(0xFFC62828), fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildField(
                        label: 'Full Name *',
                        controller: _nameCtrl,
                        hint: 'Enter your full name',
                        icon: Icons.person_outline,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        label: 'Email Address *',
                        controller: _emailCtrl,
                        hint: 'Enter your email',
                        icon: Icons.email_outlined,
                        type: TextInputType.emailAddress,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        label: 'Phone Number (optional)',
                        controller: _phoneCtrl,
                        hint: 'e.g. +254 700 000 000',
                        icon: Icons.phone_outlined,
                        type: TextInputType.phone,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      _buildPasswordField(
                        label: 'Password *',
                        controller: _passCtrl,
                        hint: 'Min. 6 characters',
                        show: _showPass,
                        onToggle: () => setState(() => _showPass = !_showPass),
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      _buildPasswordField(
                        label: 'Confirm Password *',
                        controller: _confirmCtrl,
                        hint: 'Re-enter your password',
                        show: _showConfirm,
                        onToggle: () =>
                            setState(() => _showConfirm = !_showConfirm),
                        action: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state.isAuthLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 0,
                          ),
                          child: state.isAuthLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor:
                                        AlwaysStoppedAnimation(AppColors.white),
                                  ),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: RichText(
                            text: const TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(
                                  fontSize: 14, color: AppColors.textMuted),
                              children: [
                                TextSpan(
                                  text: 'Sign In',
                                  style: TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    TextInputAction action = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Icon(icon, color: AppColors.textMuted, size: 18),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: type,
                  textInputAction: action,
                  autocorrect: false,
                  style:
                      const TextStyle(fontSize: 14, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle:
                        const TextStyle(color: Color(0xFF9AA8AD), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool show,
    required VoidCallback onToggle,
    TextInputAction action = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 13),
                child: Icon(Icons.lock_outline,
                    color: AppColors.textMuted, size: 18),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: !show,
                  textInputAction: action,
                  onSubmitted: onSubmitted,
                  style:
                      const TextStyle(fontSize: 14, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle:
                        const TextStyle(color: Color(0xFF9AA8AD), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              IconButton(
                onPressed: onToggle,
                icon: Icon(
                  show
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textMuted,
                  size: 18,
                ),
                splashRadius: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
