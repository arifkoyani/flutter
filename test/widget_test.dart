import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_android_app/main.dart';
import 'package:my_android_app/screens/game_play_screen.dart';
import 'package:my_android_app/widgets/puzzle_board.dart';
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
    expect(find.text('LIVES'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));
    expect(find.textContaining('ARROWS LEFT'), findsNothing);

    // Verify Settings button is present on top right of GamePlayScreen
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);

    // Verify reset buttons and mistake counter are removed
    expect(find.text('Reset Puzzle'), findsNothing);
    expect(find.text('MISTAKES: '), findsNothing);

    // Tap unblocked Arrow 1 on the canvas at center
    await tester.tap(find.byType(PuzzleBoard));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify lives still remain intact (3 hearts)
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));

    // Press back to Adventure Map
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pump(const Duration(milliseconds: 400));
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

    // Tap Music toggle to test ON/OFF
    await tester.tap(find.text('Music'));
    await tester.pumpAndSettle();

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

  testWidgets('Wrong arrow attempt shows instant red edge Gaussian blur flash',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GamePlayScreen(levelId: 1),
      ),
    );

    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));
    expect(find.byKey(const ValueKey('mistake_edge_blur_overlay')), findsNothing);

    final board = tester.widget<PuzzleBoard>(find.byType(PuzzleBoard));
    board.onArrowTap(board.arrows.first, false);

    // First pump starts the ticker; second pump advances into the flash
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.byKey(const ValueKey('mistake_edge_blur_overlay')), findsOneWidget);

    // After the brief flash finishes, the overlay clears and 2 live hearts remain
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(2));
    expect(find.byKey(const ValueKey('mistake_edge_blur_overlay')), findsNothing);
  });
}
