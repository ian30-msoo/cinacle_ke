import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

/// Call this before any action that requires authentication.
/// Shows a bottom sheet prompting the user to sign in if not logged in.
/// Returns true if the user is (or becomes) authenticated.
Future<bool> requireAuth(BuildContext context) async {
  final state = context.read<AppState>();
  if (state.isLoggedIn) return true;

  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _AuthPromptSheet(),
  );
  return result == true;
}

class _AuthPromptSheet extends StatelessWidget {
  const _AuthPromptSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8F9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1A6370), width: 1.5),
            ),
            child: const Icon(Icons.lock_outline,
                color: Color(0xFF1A6370), size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sign in Required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A3A40),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You need to be signed in to do that.\nJoin the Cenacle community — it\'s free!',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: Color(0xFF6B8A90), height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final result = await Navigator.pushNamed(context, '/signin');
                // Signal auth success back to caller
                if (context.mounted) {
                  final isNowLoggedIn = context.read<AppState>().isLoggedIn;
                  if (isNowLoggedIn) {
                    Navigator.pop(context, true);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6370),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: const Text('Sign In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                Navigator.pop(context);
                await Navigator.pushNamed(context, '/signup');
                if (context.mounted) {
                  final isNowLoggedIn = context.read<AppState>().isLoggedIn;
                  if (isNowLoggedIn) Navigator.pop(context, true);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A6370),
                side: const BorderSide(color: Color(0xFF1A6370)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Create Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Maybe later',
                style: TextStyle(color: Color(0xFF6B8A90), fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
