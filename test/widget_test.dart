import 'package:flutter_test/flutter_test.dart';
import 'package:my_android_app/main.dart';

void main() {
  testWidgets('Full automatic flow: Splash -> Amaze -> Dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // 1. Splash screen displays "Weconnect Games"
    expect(find.text('Weconnect Games'), findsOneWidget);

    // 2. Splash finishes loading (2.2s) and navigates to AmazeScreen
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    // Verify AmazeScreen texts
    expect(
      find.text('one rouhd is all it take, cool!\nyour mood right down.'),
      findsOneWidget,
    );
    expect(find.text('---Amaze GO!'), findsOneWidget);

    // 3. AmazeScreen finishes timer (2.5s) and navigates to DashboardScreen
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    // Verify DashboardScreen text
    expect(find.text('welcome to go arrow game '), findsOneWidget);
  });
}
