import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_android_app/main.dart';

void main() {
  testWidgets('Game Dev Welcome Screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger frames for entrance animation
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 1500));

    // Verify key texts and icons are present
    expect(find.text('Welcome to the'), findsOneWidget);
    expect(find.text('Start Development'), findsOneWidget);
    expect(find.byIcon(Icons.gamepad_rounded), findsOneWidget);
  });
}
