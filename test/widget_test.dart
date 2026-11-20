import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_android_app/main.dart';
import 'package:my_android_app/screens/game_play_screen.dart';
import 'package:my_android_app/screens/settings/setting.dart';
import 'package:my_android_app/screens/settings/privacy_policy.dart';
import 'package:my_android_app/screens/settings/terms_of_service.dart';

void main() {
  testWidgets('Full flow: Splash -> Amaze -> Map -> Play Level 1',
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
    expect(find.text('PLAY • STAGE 1'), findsOneWidget);

    // Tap PLAY • STAGE 1 to open GamePlayScreen for Level 1
    await tester.tap(find.text('PLAY • STAGE 1'));
    await tester.pumpAndSettle();

    // Verify Level 1 GamePlayScreen loaded
    expect(find.byType(GamePlayScreen), findsOneWidget);
    expect(find.text('Stage 1: First Steps'), findsOneWidget);
    expect(find.text('10 / 10 LEFT'), findsOneWidget);

    // Tap an unblocked arrow on the board (Arrow 1 pointing right with size 32)
    final arrowTile = find.byWidgetPredicate(
      (widget) =>
          widget is Icon &&
          widget.icon == Icons.arrow_forward_rounded &&
          widget.size == 32,
    ).first;
    await tester.tap(arrowTile);
    await tester.pumpAndSettle();

    // Verify count decrements to 9 / 10 LEFT
    expect(find.text('9 / 10 LEFT'), findsOneWidget);

    // Press back to Adventure Map
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
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
