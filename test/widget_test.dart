import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_android_app/database/game_database.dart';
import 'package:my_android_app/data/levels_data.dart';
import 'package:my_android_app/main.dart';
import 'package:my_android_app/models/puzzle_level.dart';
import 'package:my_android_app/screens/adventure_map.dart';
import 'package:my_android_app/screens/game_play_screen.dart';
import 'package:my_android_app/widgets/gameplay_background.dart';
import 'package:my_android_app/widgets/puzzle_board.dart';
import 'package:my_android_app/screens/settings/setting.dart';
import 'package:my_android_app/screens/settings/privacy_policy.dart';
import 'package:my_android_app/screens/settings/terms_of_service.dart';

void main() {
  testWidgets('Full flow: Splash -> Map -> Play Level 1',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // 1. Splash screen displays "Weconnect Games"
    expect(find.text('Weconnect Games'), findsOneWidget);

    // 2. Advance directly from Splash to Dashboard (Adventure Map)
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('---Amaze GO!'), findsNothing);

    // Verify Adventure Map upward flow markers, 10 levels, and no Reset View button
    expect(find.text('RESET VIEW'), findsNothing);
    expect(find.text('THE SUMMIT • STAGE 10'), findsNothing);
    expect(find.text('First Steps'), findsOneWidget);
    expect(find.text('PLAY • STAGE 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('stage_1_3d_illustration')), findsOneWidget);
    expect(find.byKey(const ValueKey('stage_2_3d_illustration')), findsOneWidget);
    expect(find.byKey(const ValueKey('stage_3_3d_illustration')), findsOneWidget);
    expect(find.byKey(const ValueKey('stage_4_3d_illustration')), findsOneWidget);
    expect(find.byKey(const ValueKey('stage_5_3d_illustration')), findsOneWidget);
    expect(find.byKey(const ValueKey('stage_6_3d_illustration')), findsOneWidget);
    expect(find.byKey(const ValueKey('stage_7_3d_illustration')), findsOneWidget);
    expect(find.byKey(const ValueKey('stage_8_3d_illustration')), findsOneWidget);
    expect(find.byKey(const ValueKey('stage_9_3d_illustration')), findsOneWidget);
    expect(find.byKey(const ValueKey('stage_10_3d_illustration')), findsOneWidget);
    expect(find.byKey(const ValueKey('flexible_stage_threads')), findsOneWidget);

    // Verify Adventure Map supports vertical drag on background via InteractiveViewer
    final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    final initialMatrix = viewer.transformationController!.value.clone();
    await tester.dragFrom(const Offset(100, 320), const Offset(0, 140));
    await tester.pump(const Duration(milliseconds: 400));
    expect(viewer.transformationController!.value, isNot(equals(initialMatrix)));

    // Tap PLAY • STAGE 1 to open GamePlayScreen for Level 1
    await tester.tap(find.text('PLAY • STAGE 1'));
    await tester.pumpAndSettle();

    // Verify Level 1 GamePlayScreen loaded
    expect(find.byType(GamePlayScreen), findsOneWidget);
    expect(find.text('Stage 1: First Steps'), findsOneWidget);
    expect(find.byKey(const ValueKey('gameplay_background')), findsOneWidget);
    expect(find.text('Tap to Rotate'), findsNothing);
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

  test('All 10 JSON levels load, do not overlap, and every face is solvable', () async {
    await LevelsData.load();
    expect(LevelsData.isLoaded, isTrue);
    expect(LevelsData.levelSummaries.length, 10);

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

    final expectedCounts = {
      1: 24,
      2: 34,
      3: 47,
      4: 68,
      5: 92,
      6: 110,
      7: 128,
      8: 152,
      9: 176,
      10: 204,
    };
    final expectedDurations = {
      1: 30,
      2: 45,
      3: 60,
      4: 75,
      5: 90,
      6: 80,
      7: 95,
      8: 105,
      9: 120,
      10: 120,
    };

    for (final stageId in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) {
      final level = LevelsData.getLevel(stageId);
      expect(level.arrows.length, expectedCounts[stageId],
          reason: 'Stage $stageId arrow count mismatch');
      expect(level.durationSeconds, expectedDurations[stageId]);

      final maxCoord = level.gridCols - 0.3;
      final rayReach = level.gridCols + 2.0;

      for (final face in CubeFace.values) {
        final faceArrows = level.arrows
            .where((a) => a.placedOn == face)
            .map((a) => a.clone())
            .toList();
        expect(faceArrows, isNotEmpty, reason: 'Stage $stageId $face should have arrows');

        // Verify bounds and zero overlap across all arrows on this face
        for (int i = 0; i < faceArrows.length; i++) {
          final a = faceArrows[i];
          for (final pt in a.points) {
            expect(pt.dx, inInclusiveRange(0.3, maxCoord));
            expect(pt.dy, inInclusiveRange(0.3, maxCoord));
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
                    reason:
                        'Stage $stageId Arrows ${a.id} and ${b.id} on $face too close ($d)');
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
            for (double step = 0.4; step <= rayReach; step += 0.3) {
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
              reason:
                  'Deadlock on Stage $stageId $face with ${remaining.map((e) => e.id).toList()}');
          remaining.remove(clearArrow.first);
        }
      }
    }
  });

  testWidgets('Level 1 syncs from levels.json, renders timer & remaining arrows below Lives',
      (WidgetTester tester) async {
    await LevelsData.load();
    expect(LevelsData.isLoaded, isTrue);

    final jsonLevel1 = LevelsData.getLevel(1);
    expect(jsonLevel1.name, 'First Steps');
    expect(jsonLevel1.durationSeconds, 30);
    expect(jsonLevel1.arrows.length, 24);

    await tester.pumpWidget(
      const MaterialApp(
        home: GamePlayScreen(levelId: 1),
      ),
    );

    expect(find.text('Stage 1: First Steps'), findsOneWidget);
    expect(find.byKey(const ValueKey('gameplay_background')), findsOneWidget);
    expect(find.text('Tap to Rotate'), findsNothing);
    expect(find.text('LIVES'), findsOneWidget);
    expect(find.byKey(const ValueKey('level_countdown_timer')), findsOneWidget);
    expect(find.text('TIME'), findsOneWidget);
    expect(find.text('00:30'), findsOneWidget);
    expect(find.byKey(const ValueKey('remaining_arrows_counter')), findsOneWidget);
    expect(find.text('ARROWS'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);

    // Timer sits strictly below LIVES, and remaining arrows sits strictly below TIME
    final livesBottom = tester.getBottomLeft(find.text('LIVES')).dy;
    final timerTop = tester.getTopLeft(find.byKey(const ValueKey('level_countdown_timer'))).dy;
    final timerBottom = tester.getBottomLeft(find.byKey(const ValueKey('level_countdown_timer'))).dy;
    final arrowsTop = tester.getTopLeft(find.byKey(const ValueKey('remaining_arrows_counter'))).dy;
    expect(timerTop, greaterThan(livesBottom));
    expect(arrowsTop, greaterThan(timerBottom));

    // Tapping a clear arrow decrements remaining arrows from 24 to 23
    final board = tester.widget<PuzzleBoard>(find.byType(PuzzleBoard));
    board.onArrowTap(board.arrows.first, true);
    await tester.pump();
    expect(find.text('23'), findsOneWidget);

    // Advance 1 second and verify countdown updates
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:29'), findsOneWidget);

    // Advance remaining 29 seconds to trigger time-up Stage Failed dialog
    await tester.pump(const Duration(seconds: 29));
    await tester.pumpAndSettle();
    expect(find.text('Stage Failed'), findsOneWidget);
  });

  testWidgets('Multiple clear arrows exit simultaneously in parallel',
      (WidgetTester tester) async {
    await LevelsData.load();

    await tester.pumpWidget(
      const MaterialApp(
        home: GamePlayScreen(levelId: 1),
      ),
    );

    final boardFinder = find.byType(PuzzleBoard);
    final board = tester.widget<PuzzleBoard>(boardFinder);
    final center = tester.getCenter(boardFinder);

    // Tap first clear arrow (Arrow 1 on front face, at default 0.65x zoom)
    await tester.tapAt(center + const Offset(-66, 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final exitingAfterFirst =
        board.arrows.where((a) => a.exitDistance > 0 && !a.isExited).toList();
    expect(exitingAfterFirst.length, 1);
    expect(find.text('23'), findsOneWidget);

    // Immediately tap a second clear arrow (Arrow 102 on right face, at 0.65x zoom)
    await tester.tapAt(center + const Offset(57, 31));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final exitingInParallel =
        board.arrows.where((a) => a.exitDistance > 0 && !a.isExited).toList();
    expect(exitingInParallel.length, 2);
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));
    expect(find.text('22'), findsOneWidget);

    // After ~600ms (20% faster than 700ms), both have finished exiting
    await tester.pump(const Duration(milliseconds: 600));
    expect(exitingInParallel.every((a) => a.isExited), isTrue);
  });

  testWidgets('Pressed clear arrow scales to 1.05x on hold and flies immediately on release',
      (WidgetTester tester) async {
    await LevelsData.load();

    await tester.pumpWidget(
      const MaterialApp(
        home: GamePlayScreen(levelId: 1),
      ),
    );

    final boardFinder = find.byType(PuzzleBoard);
    final board = tester.widget<PuzzleBoard>(boardFinder);
    final center = tester.getCenter(boardFinder);

    // Press down on Arrow 1 and hold for 110ms -> scales to 1.05x without exiting yet
    final press = await tester.startGesture(center + const Offset(-66, 3));
    await tester.pump(const Duration(milliseconds: 110));

    final arrow1 = board.arrows.firstWhere((a) => a.id == 1);
    expect(arrow1.exitDistance, 0.0);
    expect(arrow1.isExited, isFalse);
    expect(find.text('24'), findsOneWidget);

    // Release -> clear arrow flies immediately without waiting to shrink back
    await press.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));

    expect(find.text('23'), findsOneWidget);
    expect(arrow1.exitDistance, greaterThan(0.0));
  });

  testWidgets('4-way rotate tutorial (0-30%), slow rotate icon below cube (30-50%), and pinch zoom (50%+) never overlap',
      (WidgetTester tester) async {
    await LevelsData.load();

    await tester.pumpWidget(
      const MaterialApp(
        home: GamePlayScreen(levelId: 1),
      ),
    );

    // 0% to 30% (0s..8s): 4-way Rotate Tutorial + "Shift any side" text only
    expect(find.byKey(const ValueKey('cube_rotate_tutorial')), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_left_rounded), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_right_rounded), findsOneWidget);
    expect(find.text('Shift any side'), findsOneWidget);
    expect(find.byKey(const ValueKey('tap_to_rotate_hint_bar')), findsNothing);
    expect(find.text('rotate any angle'), findsNothing);
    expect(find.byKey(const ValueKey('cube_zoom_tutorial')), findsNothing);
    expect(find.text('Tap to Rotate'), findsNothing);

    // At 9s (30% elapsed): Rotate Tutorial ends, slow rotate icon + "rotate any angle" appears below cube center
    await tester.pump(const Duration(seconds: 9));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('cube_rotate_tutorial')), findsNothing);
    expect(find.text('Shift any side'), findsNothing);
    expect(find.byKey(const ValueKey('tap_to_rotate_hint_bar')), findsOneWidget);
    expect(find.byIcon(Icons.rotate_right_rounded), findsOneWidget);
    expect(find.text('rotate any angle'), findsOneWidget);
    expect(find.text('Tap to Rotate'), findsNothing);
    expect(find.byKey(const ValueKey('cube_zoom_tutorial')), findsNothing);
    final boardCenterY = tester.getCenter(find.byType(PuzzleBoard)).dy;
    final rotateIconY = tester.getCenter(find.byKey(const ValueKey('tap_to_rotate_hint_bar'))).dy;
    expect(rotateIconY, greaterThan(boardCenterY + 60));

    // At 15s (50% elapsed): Rotate icon hides and Two-thumb Pinch Zoom + "zoom in & out" appears
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('tap_to_rotate_hint_bar')), findsNothing);
    expect(find.text('rotate any angle'), findsNothing);
    expect(find.byKey(const ValueKey('cube_zoom_tutorial')), findsOneWidget);
    expect(find.text('zoom in & out'), findsOneWidget);
    expect(find.text('Pinch to Zoom'), findsNothing);

    // At 23s (> 75% elapsed): Pinch tutorial & label fade away cleanly
    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('cube_zoom_tutorial')), findsNothing);
    expect(find.text('zoom in & out'), findsNothing);

    // Stage 2 also shows the tutorials
    await tester.pumpWidget(
      const MaterialApp(
        home: GamePlayScreen(key: ValueKey('stage_2'), levelId: 2),
      ),
    );
    expect(find.byKey(const ValueKey('cube_rotate_tutorial')), findsOneWidget);
    expect(find.text('Shift any side'), findsOneWidget);

    // Stages 3, 4, and 5 must not show any tutorial overlays or hints
    for (final stageId in [3, 4, 5]) {
      await tester.pumpWidget(
        MaterialApp(
          home: GamePlayScreen(key: ValueKey('stage_$stageId'), levelId: stageId),
        ),
      );
      expect(find.byKey(const ValueKey('cube_rotate_tutorial')), findsNothing);
      expect(find.byKey(const ValueKey('cube_zoom_tutorial')), findsNothing);
      expect(find.byKey(const ValueKey('tap_to_rotate_hint_bar')), findsNothing);
      expect(find.text('Shift any side'), findsNothing);
      expect(find.text('rotate any angle'), findsNothing);
      expect(find.text('zoom in & out'), findsNothing);
    }
  });

  testWidgets('Adventure Map stage cards slide-drag with flexible threads',
      (WidgetTester tester) async {
    await LevelsData.load();

    await tester.pumpWidget(
      const MaterialApp(
        home: AdventureMapScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final stage2CardFinder = find.byKey(const ValueKey('draggable_stage_card_2'));
    final beforeDrag = tester.getTopLeft(stage2CardFinder);
    final cardDrag = await tester.startGesture(tester.getCenter(stage2CardFinder));
    await cardDrag.moveBy(const Offset(-24, 18));
    await tester.pump();
    await cardDrag.moveBy(const Offset(-24, 18));
    await tester.pump();
    await cardDrag.up();
    await tester.pump(const Duration(milliseconds: 200));
    final afterDrag = tester.getTopLeft(stage2CardFinder);
    expect(afterDrag.dx, lessThan(beforeDrag.dx));
    expect(afterDrag.dy, greaterThan(beforeDrag.dy));
    expect(find.text('PLAY • STAGE 2'), findsOneWidget);
  });

  testWidgets('Completing Stage 5 unlocks Stage 6 and opens Frozen Peaks from levels.json',
      (WidgetTester tester) async {
    await LevelsData.load();
    final tempDir = Directory.systemTemp.createTempSync('gamia_stage5_test_');
    addTearDown(() {
      GameDatabase.instance.resetInMemory();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });
    await GameDatabase.instance.init(storageDir: tempDir, forceReload: true);
    await GameDatabase.instance.recordLevelCompletion(
      levelId: 5,
      stars: 3,
      mistakes: 0,
    );
    expect(GameDatabase.instance.isLevelUnlocked(6), isTrue);

    await tester.pumpWidget(
      const MaterialApp(
        home: GamePlayScreen(levelId: 6),
      ),
    );
    expect(find.text('Stage 6: Frozen Peaks'), findsOneWidget);
    expect(find.text('110'), findsOneWidget);
    expect(find.text('01:20'), findsOneWidget);
  });

  test('GameDatabase persists completed stages and unlocks across app restarts',
      () async {
    final tempDir = await Directory.systemTemp.createTemp('gamia_progress_test_');
    try {
      GameDatabase.instance.resetInMemory();
      await GameDatabase.instance.init(storageDir: tempDir, forceReload: true);
      expect(GameDatabase.instance.isLevelUnlocked(1), isTrue);
      expect(GameDatabase.instance.isLevelUnlocked(2), isFalse);

      await GameDatabase.instance.recordLevelCompletion(
        levelId: 1,
        stars: 3,
        mistakes: 0,
      );

      // Simulate killing and reopening the app from scratch
      GameDatabase.instance.resetInMemory();
      expect(GameDatabase.instance.getRecord(1).isCompleted, isFalse);
      expect(GameDatabase.instance.isLevelUnlocked(2), isFalse);

      await GameDatabase.instance.init(storageDir: tempDir, forceReload: true);
      expect(GameDatabase.instance.getRecord(1).isCompleted, isTrue);
      expect(GameDatabase.instance.getRecord(1).stars, 3);
      expect(GameDatabase.instance.isLevelUnlocked(2), isTrue);
    } finally {
      GameDatabase.instance.resetInMemory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });

  testWidgets('Minimizing app pauses gameplay timer and resumes cleanly on return',
      (WidgetTester tester) async {
    await LevelsData.load();

    await tester.pumpWidget(
      const MaterialApp(
        home: GamePlayScreen(levelId: 1),
      ),
    );
    expect(find.text('00:30'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('00:27'), findsOneWidget);

    // Minimize / background app: timer must stop and not trigger Stage Failed
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump(const Duration(seconds: 40));
    expect(find.text('00:27'), findsOneWidget);
    expect(find.text('Stage Failed'), findsNothing);

    // Return to app: timer resumes from 00:27
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('00:25'), findsOneWidget);
  });

  testWidgets(
      'Adventure Map defaults to 0.65 zoom (0.20-0.65), locks Stage 1, and clamps card drag bounds',
      (WidgetTester tester) async {
    await LevelsData.load();

    await tester.pumpWidget(
      const MaterialApp(
        home: AdventureMapScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final viewer =
        tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    expect(viewer.minScale, 0.20);
    expect(viewer.maxScale, 0.65);
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      closeTo(0.65, 0.001),
    );
    // Centered horizontally on 800px width: Stage 10 (center column) sits at x = 400
    final stage10Finder = find.byKey(const ValueKey('draggable_stage_card_10'));
    expect(tester.getCenter(stage10Finder).dx, closeTo(400.0, 0.5));

    // Stage 1 is static and starts at bottom just above the CTA bar
    final stage1Finder = find.byKey(const ValueKey('draggable_stage_card_1'));
    final ctaFinder = find.text('PLAY • STAGE 1');
    final stage1BottomAtLaunch = tester.getBottomLeft(stage1Finder).dy;
    final ctaTop = tester.getTopLeft(ctaFinder).dy;
    expect(stage1BottomAtLaunch, lessThan(ctaTop));
    expect(stage1BottomAtLaunch, greaterThan(ctaTop - 90.0));

    final stage1PositionedBefore = tester.widget<Positioned>(
      find.ancestor(of: stage1Finder, matching: find.byType(Positioned)).first,
    );
    final drag1 = await tester.startGesture(tester.getCenter(stage1Finder));
    await drag1.moveBy(const Offset(100, -100));
    await tester.pump();
    await drag1.up();
    await tester.pump(const Duration(milliseconds: 100));

    final stage1PositionedAfter = tester.widget<Positioned>(
      find.ancestor(of: stage1Finder, matching: find.byType(Positioned)).first,
    );
    expect(stage1PositionedAfter.left, stage1PositionedBefore.left);
    expect(stage1PositionedAfter.top, stage1PositionedBefore.top);

    // At 0.65 zoom: Stage 2 drags left/right until 50% reaches screen edges & ±300 px vertically
    final stage2Finder = find.byKey(const ValueKey('draggable_stage_card_2'));
    final stage2PositionedBefore = tester.widget<Positioned>(
      find.ancestor(of: stage2Finder, matching: find.byType(Positioned)).first,
    );
    final drag2Left = await tester.startGesture(tester.getCenter(stage2Finder));
    await drag2Left.moveBy(const Offset(-2000, 0));
    await tester.pump();
    await drag2Left.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getCenter(stage2Finder).dx, closeTo(0.0, 0.5));

    final drag2Right = await tester.startGesture(
      Offset(20, tester.getCenter(stage2Finder).dy),
    );
    await drag2Right.moveBy(const Offset(2000, 0));
    await tester.pump();
    await drag2Right.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getCenter(stage2Finder).dx, closeTo(800.0, 0.5));

    final drag2Up = await tester.startGesture(
      Offset(770, tester.getCenter(stage2Finder).dy),
    );
    await drag2Up.moveBy(const Offset(0, -1200));
    await tester.pump();
    await drag2Up.up();
    await tester.pump(const Duration(milliseconds: 100));
    final stage2PositionedAfterUp = tester.widget<Positioned>(
      find.ancestor(of: stage2Finder, matching: find.byType(Positioned)).first,
    );
    expect(
      stage2PositionedAfterUp.top! - stage2PositionedBefore.top!,
      closeTo(-300.0, 0.01),
    );

    final drag2Down = await tester.startGesture(
      Offset(770, tester.getCenter(stage2Finder).dy),
    );
    await drag2Down.moveBy(const Offset(0, 1200));
    await tester.pump();
    await drag2Down.up();
    await tester.pump(const Duration(milliseconds: 100));
    final stage2PositionedAfterDown = tester.widget<Positioned>(
      find.ancestor(of: stage2Finder, matching: find.byType(Positioned)).first,
    );
    expect(
      stage2PositionedAfterDown.top! - stage2PositionedBefore.top!,
      closeTo(300.0, 0.01),
    );

    // Zoom out to 0.20: stays centered horizontally (Stage 10 at x = 400)
    // and keeps Stage 1 anchored just above the CTA bar
    viewer.transformationController!.value = Matrix4.identity()
      ..scaleByDouble(0.20, 0.20, 0.20, 1.0);
    await tester.pump();
    expect(tester.getCenter(stage10Finder).dx, closeTo(400.0, 0.5));
    final stage1BottomAtMinZoom = tester.getBottomLeft(stage1Finder).dy;
    expect(stage1BottomAtMinZoom, lessThan(ctaTop));
    expect(stage1BottomAtMinZoom, greaterThan(ctaTop - 60.0));

    // At 0.20 zoom: Stage 10 drags to 50% off right & left screen edges and +300 px vertically
    final stage10PositionedBefore = tester.widget<Positioned>(
      find.ancestor(of: stage10Finder, matching: find.byType(Positioned)).first,
    );
    final drag10Right = await tester.startGesture(tester.getCenter(stage10Finder));
    await drag10Right.moveBy(const Offset(2000, 500));
    await tester.pump();
    await drag10Right.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getCenter(stage10Finder).dx, closeTo(800.0, 0.5));
    final stage10PositionedAfter = tester.widget<Positioned>(
      find.ancestor(of: stage10Finder, matching: find.byType(Positioned)).first,
    );
    expect(
      stage10PositionedAfter.top! - stage10PositionedBefore.top!,
      closeTo(300.0, 0.01),
    );

    final drag10Left = await tester.startGesture(
      Offset(790, tester.getCenter(stage10Finder).dy),
    );
    await drag10Left.moveBy(const Offset(-2000, 0));
    await tester.pump();
    await drag10Left.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getCenter(stage10Finder).dx, closeTo(0.0, 0.5));

    // Zooming back in to 0.65 keeps Stage 10 >= 50% inside the screen (never lost off-screen)
    viewer.transformationController!.value = Matrix4.identity()
      ..scaleByDouble(0.65, 0.65, 0.65, 1.0);
    await tester.pump();
    expect(tester.getCenter(stage10Finder).dx, greaterThanOrEqualTo(-0.5));
  });

  testWidgets(
      'Gameplay gyroscope parallax shifts HUD and background while keeping PuzzleBoard stable',
      (WidgetTester tester) async {
    await LevelsData.load();

    await tester.pumpWidget(
      const MaterialApp(
        home: GamePlayScreen(levelId: 1),
      ),
    );
    await tester.pump();

    final state = tester.state(find.byType(GamePlayScreen)) as dynamic;
    final boardBefore = tester.getCenter(find.byType(PuzzleBoard));
    final hudBefore =
        tester.getCenter(find.byKey(const ValueKey('remaining_arrows_counter')));

    // Feed gyroscope + accelerometer tilt samples
    state.parallaxController.addAccelerometerSample(0.0, 6.0, 7.8);
    state.parallaxController.addAccelerometerSample(-3.0, 7.2, 6.2);
    state.parallaxController.addGyroSample(1.2, 2.0, dt: 0.05);
    await tester.pump();

    final tilt = state.parallaxController.value as Offset;
    expect(tilt.dx, greaterThan(0.0));
    expect(tilt.dy, greaterThan(0.0));

    // PuzzleBoard stays anchored in its original center while HUD & background shift
    final boardAfter = tester.getCenter(find.byType(PuzzleBoard));
    final hudAfter =
        tester.getCenter(find.byKey(const ValueKey('remaining_arrows_counter')));
    expect(boardAfter, boardBefore);
    expect(hudAfter.dx, greaterThan(hudBefore.dx));
    expect(hudAfter.dy, greaterThan(hudBefore.dy));

    final bgWidget = tester.widget<GameplayBackground>(
      find.byType(GameplayBackground),
    );
    expect(bgWidget.parallax, tilt);
  });
}
