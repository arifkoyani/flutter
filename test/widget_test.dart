import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_android_app/data/levels_data.dart';
import 'package:my_android_app/main.dart';
import 'package:my_android_app/models/puzzle_level.dart';
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

  testWidgets('Pinch and scroll wheel zoom work without triggering false taps',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GamePlayScreen(levelId: 1),
      ),
    );

    final boardFinder = find.byType(PuzzleBoard);
    final center = tester.getCenter(boardFinder);

    // Scroll wheel zoom out and back in, then tap center arrow (Arrow 1)
    final pointer = TestPointer(99, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(center));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 200)));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, -250)));
    await tester.pumpAndSettle();

    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));

    // Two-finger pinch out + drag + twist to zoom and rotate simultaneously
    final p1 = await tester.startGesture(center - const Offset(20, 0));
    final p2 = await tester.startGesture(center + const Offset(20, 0));
    await p1.moveBy(const Offset(-30, 18));
    await p2.moveBy(const Offset(50, 12));
    await tester.pump();
    await p1.moveBy(const Offset(-10, -15));
    await p2.moveBy(const Offset(-10, -15));
    await tester.pump();
    await p1.up();
    await p2.up();
    await tester.pumpAndSettle();

    // Pinching/rotating should not trigger a false tap or mistake
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));
  });

  test('Stage 1 cube arrows do not overlap and every face is solvable', () {
    double distToSeg(Offset p, Offset a, Offset b) {
      final ab = b - a;
      final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
      if (lenSq == 0) return (p - a).distance;
      final t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / lenSq;
      final clamped = t.clamp(0.0, 1.0);
      return (p - Offset(a.dx + clamped * ab.dx, a.dy + clamped * ab.dy))
          .distance;
    }

    double segToSegDist(Offset a1, Offset a2, Offset b1, Offset b2) {
      double best = double.infinity;
      for (int s = 0; s <= 10; s++) {
        final f = s / 10.0;
        final pa = Offset(a1.dx + (a2.dx - a1.dx) * f, a1.dy + (a2.dy - a1.dy) * f);
        final pb = Offset(b1.dx + (b2.dx - b1.dx) * f, b1.dy + (b2.dy - b1.dy) * f);
        best = math.min(best, distToSeg(pa, b1, b2));
        best = math.min(best, distToSeg(pb, a1, a2));
      }
      return best;
    }

    final level1 = LevelsData.getLevel(1);
    expect(level1.arrows.length, greaterThanOrEqualTo(80));

    for (final face in CubeFace.values) {
      final faceArrows = level1.arrows
          .where((a) => a.placedOn == face)
          .map((a) => a.clone())
          .toList();
      expect(faceArrows.length, greaterThanOrEqualTo(13),
          reason: '$face should be densely packed');

      // Verify bounds and zero overlap across all arrows on this face
      for (int i = 0; i < faceArrows.length; i++) {
        final a = faceArrows[i];
        for (final pt in a.points) {
          expect(pt.dx, inInclusiveRange(0.3, 5.7));
          expect(pt.dy, inInclusiveRange(0.3, 5.7));
        }
        for (int j = i + 1; j < faceArrows.length; j++) {
          final b = faceArrows[j];
          for (int sa = 0; sa < a.points.length - 1; sa++) {
            for (int sb = 0; sb < b.points.length - 1; sb++) {
              final d = segToSegDist(
                a.points[sa],
                a.points[sa + 1],
                b.points[sb],
                b.points[sb + 1],
              );
              expect(d, greaterThanOrEqualTo(0.50),
                  reason: 'Arrows ${a.id} and ${b.id} on $face too close ($d)');
            }
          }
        }
      }

      // Verify 100% solvability using PuzzleBoard's exact _isPathClear logic
      final remaining = List<CanvasArrow>.from(faceArrows);
      while (remaining.isNotEmpty) {
        final clearArrow = remaining.where((arrow) {
          final tip = arrow.tip;
          final dir = arrow.exitDirection.unitVector;
          for (double step = 0.4; step <= 8.0; step += 0.3) {
            final probe = Offset(tip.dx + dir.dx * step, tip.dy + dir.dy * step);
            for (final other in remaining) {
              if (other.id == arrow.id) continue;
              for (int i = 0; i < other.points.length - 1; i++) {
                if (distToSeg(probe, other.points[i], other.points[i + 1]) <
                    0.45) {
                  return false;
                }
              }
            }
          }
          return true;
        }).toList();
        expect(clearArrow, isNotEmpty,
            reason: 'Deadlock on $face with ${remaining.map((e) => e.id).toList()}');
        remaining.remove(clearArrow.first);
      }
    }
  });
}
