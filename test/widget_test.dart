import 'package:flutter_test/flutter_test.dart';
import 'package:my_android_app/main.dart';

void main() {
  testWidgets('Navigation smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify Main Screen elements
    expect(find.text('Select a Screen'), findsOneWidget);
    expect(find.text('Screen 1'), findsOneWidget);
    expect(find.text('Screen 2'), findsOneWidget);

    // Tap Screen 1 and verify navigation
    await tester.tap(find.text('Screen 1'));
    await tester.pumpAndSettle();
    expect(find.text('welcome to screen 1'), findsOneWidget);

    // Tap Go to Screen 2 and verify navigation
    await tester.tap(find.text('Go to Screen 2'));
    await tester.pumpAndSettle();
    expect(find.text('welcome to screen 2'), findsOneWidget);

    // Tap Back to Main Screen and verify navigation
    await tester.tap(find.text('Back to Main Screen'));
    await tester.pumpAndSettle();
    expect(find.text('Select a Screen'), findsOneWidget);
  });
}
