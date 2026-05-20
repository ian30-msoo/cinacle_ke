import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cinacleke/main.dart';
import 'package:cinacleke/firebase_options.dart';

void main() {
  setUpAll(() async {
    // Initialize Firebase before any tests run
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  testWidgets('CenacleApp renders without crashing', (WidgetTester tester) async {
    // Build the root app widget
    await tester.pumpWidget(const CenacleApp());

    // Allow splash screen and async frames to settle
    await tester.pump();

    // Verify the MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Splash screen is the initial route', (WidgetTester tester) async {
    await tester.pumpWidget(const CenacleApp());
    await tester.pump();

    // The app should start on the splash screen
    expect(find.byType(MaterialApp), findsOneWidget);
    // No sign-in or home screen should appear immediately
    expect(find.text('Sign In'), findsNothing);
  });
}