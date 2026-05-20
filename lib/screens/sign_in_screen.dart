import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Basic client-side validation before hitting Firebase
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }

    final state = context.read<AppState>();
    state.clearAuthError();

    final ok = await state.signIn(_emailCtrl.text, _passCtrl.text);
    if (!mounted) return;

    if (ok) {
      // Pop back to wherever the user came from.
      // If we were the root (opened fresh), go home.
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true); // pass true = success
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Enter your email above first, then tap Forgot Password.'),
        ),
      );
      return;
    }

    final state = context.read<AppState>();
    final ok = await state.sendPasswordReset(email);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Password reset email sent to $email.'
              : state.authError ?? 'Failed to send reset email.',
        ),
        backgroundColor: ok ? AppColors.primary : Colors.red[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppState>(
        builder: (context, state, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Teal header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 36),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Back button if we can pop
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
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 2),
                        ),
                        child: const Icon(Icons.workspace_premium,
                            color: AppColors.gold, size: 44),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'CENACLE LINK',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Welcome back!',
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
                      // Error banner
                      if (state.authError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF9A9A)),
                          ),
                          child: Text(
                            state.authError!,
                            style: const TextStyle(
                                color: Color(0xFFC62828), fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Text(
                        'Email Address',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildInputContainer(
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 13),
                              child: Icon(Icons.email_outlined,
                                  color: AppColors.textMuted, size: 18),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(
                                    fontSize: 14, color: AppColors.textDark),
                                decoration: const InputDecoration(
                                  hintText: 'Enter your email',
                                  hintStyle: TextStyle(
                                      color: Color(0xFF9AA8AD), fontSize: 14),
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildInputContainer(
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 13),
                              child: Icon(Icons.lock_outline,
                                  color: AppColors.textMuted, size: 18),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _passCtrl,
                                obscureText: !_showPass,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                                style: const TextStyle(
                                    fontSize: 14, color: AppColors.textDark),
                                decoration: const InputDecoration(
                                  hintText: 'Enter your password',
                                  hintStyle: TextStyle(
                                      color: Color(0xFF9AA8AD), fontSize: 14),
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 13),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _showPass = !_showPass),
                              icon: Icon(
                                _showPass
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

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
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
                                  'Sign In',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/signup'),
                          child: RichText(
                            text: const TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(
                                  fontSize: 14, color: AppColors.textMuted),
                              children: [
                                TextSpan(
                                  text: 'Sign Up',
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

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
