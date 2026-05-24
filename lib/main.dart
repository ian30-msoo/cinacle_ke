import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/app_state.dart';
import 'screens/splash_screen.dart';
import 'screens/main_shell.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage msg) async {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.primaryDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const CenacleApp());
}

class CenacleApp extends StatelessWidget {
  const CenacleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Cenacle Link',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/splash',
        builder: (context, child) {
          final width = MediaQuery.of(context).size.width;
          if (width >= 700 && child != null) {
            return Container(
              color: const Color(0xFFD6D2CA),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: child,
                ),
              ),
            );
          }
          return child ?? const SizedBox.shrink();
        },
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/home': (context) => const MainShell(),
          '/signin': (context) => const SignInScreen(),
          '/signup': (context) => const SignUpScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/tab') {
            final tab = settings.arguments as int? ?? 0;
            return MaterialPageRoute(
                builder: (_) => MainShell(initialTab: tab));
          }
          return null;
        },
      ),
    );
  }
}
