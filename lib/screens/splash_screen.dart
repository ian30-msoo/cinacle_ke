import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Splash screen: plays the animation then always navigates to /home.
/// Firebase Auth persists login state automatically — the app simply
/// checks AppState.isLoggedIn when a protected action is attempted.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
    _scale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );

    _ctrl.forward();

    // Always go to /home — users can browse freely.
    // Firebase Auth handles session persistence internally.
    // Protected screens/actions will prompt login when needed.
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D3D45),
              AppColors.primaryDark,
              AppColors.primary,
              Color(0xFF2A8A96),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Column(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                            border:
                                Border.all(color: AppColors.gold, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.workspace_premium,
                            color: AppColors.gold,
                            size: 56,
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'CENACLE',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 7,
                          ),
                        ),
                        const Text(
                          'LINK',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _taglineFade,
                  child: Column(
                    children: [
                      const Text(
                        'A Sure Foundation',
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Shaped into Christ\'s Fullness',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
                FadeTransition(
                  opacity: _fade,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.gold.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
