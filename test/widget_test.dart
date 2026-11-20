import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_android_app/main.dart';
import 'package:my_android_app/screens/settings/setting.dart';
import 'package:my_android_app/screens/settings/privacy_policy.dart';
import 'package:my_android_app/screens/settings/terms_of_service.dart';

void main() {
  testWidgets('Full flow to Adventure Map with 3D Z-axis and Pan/Zoom',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // 1. Splash screen displays "Weconnect Games"
    expect(find.text('Weconnect Games'), findsOneWidget);

    // 2. Advance through Splash to AmazeScreen
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();
    expect(find.text('---Amaze GO!'), findsOneWidget);

    // 3. Advance through Amaze to Dashboard (Adventure Map)
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Adventure Map upward flow markers and 5 levels
    expect(find.text('THE SUMMIT • STAGE 5'), findsOneWidget);
    expect(find.text('First Steps'), findsOneWidget);
    expect(find.text('Arrow Forest'), findsOneWidget);
    expect(find.text('Mystery Maze'), findsOneWidget);
    expect(find.text('Desert Escape'), findsOneWidget);
    expect(find.text('Final Challenge'), findsOneWidget);
    expect(find.text('STARTING BASE • STAGE 1'), findsOneWidget);

    // Verify InteractiveViewer is present for pan & zoom
    expect(find.byType(InteractiveViewer), findsOneWidget);

    // Verify prominent Play button defaults to Stage 1 (at bottom)
    expect(find.text('PLAY • STAGE 1'), findsOneWidget);

    // Ensure Level 1 (First Steps) is visible and tap it
    await tester.ensureVisible(find.text('First Steps'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('First Steps'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('PLAY • STAGE 1'), findsOneWidget);

    // Ensure Arrow Forest (Stage 2, upward) is visible and tap it
    await tester.ensureVisible(find.text('Arrow Forest'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Arrow Forest'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('PLAY • STAGE 2'), findsOneWidget);

    // Verify settings icon navigates to SettingScreen
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(SettingScreen), findsOneWidget);
  });

  testWidgets('Settings screen UI and navigation test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingScreen(),
      ),
    );

    // Verify Setting toggles and labels
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Vibration'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);

    // Tap Privacy Policy and verify navigation
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyPolicyScreen), findsOneWidget);

    // Tap AppBar Back button
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(SettingScreen), findsOneWidget);

    // Tap Terms of Service and verify navigation
    await tester.tap(find.text('Terms of Service'));
    await tester.pumpAndSettle();
    expect(find.byType(TermsOfServiceScreen), findsOneWidget);

    // Tap AppBar Back button
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(SettingScreen), findsOneWidget);
  });
}
