import 'package:material_ui/material_ui.dart';
import '../models/puzzle_level.dart';

class LevelsData {
  static final List<PuzzleLevel> levels = [
    // Level 1: First Steps (10 Canvas Arrows, clean open screen without boxed borders)
    PuzzleLevel(
      id: 1,
      name: 'First Steps',
      subtitle: 'Escape the Arrows',
      gridCols: 6,
      gridRows: 6,
      maxMistakes: 3,
      walls: const [],
      exits: const [],
      arrows: [
        // 1. Straight Up (Exit top center) -> Clear immediately
        CanvasArrow(
          id: 1,
          points: const [Offset(3.0, 3.8), Offset(3.0, 0.2)],
          exitDirection: ArrowDirection.up,
        ),
        // 2. Straight Up (Behind Arrow 1) -> Blocked by Arrow 1
        CanvasArrow(
          id: 2,
          points: const [Offset(3.0, 5.5), Offset(3.0, 4.0)],
          exitDirection: ArrowDirection.up,
        ),
        // 3. L-shape: Right then Down (Exit bottom) -> Clear immediately
        CanvasArrow(
          id: 3,
          points: const [Offset(1.2, 5.2), Offset(2.2, 5.2), Offset(2.2, 5.8)],
          exitDirection: ArrowDirection.down,
        ),
        // 4. Straight Right (Behind Arrow 3) -> Blocked by Arrow 3
        CanvasArrow(
          id: 4,
          points: const [Offset(0.3, 5.2), Offset(1.0, 5.2)],
          exitDirection: ArrowDirection.right,
        ),
        // 5. L-shape: Up then Right (Exit right) -> Clear immediately
        CanvasArrow(
          id: 5,
          points: const [Offset(4.2, 3.0), Offset(4.2, 1.0), Offset(5.8, 1.0)],
          exitDirection: ArrowDirection.right,
        ),
        // 6. Straight Up (Behind Arrow 5) -> Blocked by Arrow 5
        CanvasArrow(
          id: 6,
          points: const [Offset(4.2, 5.2), Offset(4.2, 3.3)],
          exitDirection: ArrowDirection.up,
        ),
        // 7. Straight Down (Exit bottom-right) -> Clear immediately
        CanvasArrow(
          id: 7,
          points: const [Offset(5.4, 2.0), Offset(5.4, 5.8)],
          exitDirection: ArrowDirection.down,
        ),
        // 8. Straight Left (Exit top-left) -> Clear immediately
        CanvasArrow(
          id: 8,
          points: const [Offset(1.8, 0.5), Offset(0.2, 0.5)],
          exitDirection: ArrowDirection.left,
        ),
        // 9. L-shape: Down then Left (Exit mid-left) -> Clear immediately
        CanvasArrow(
          id: 9,
          points: const [Offset(1.5, 1.5), Offset(1.5, 3.0), Offset(0.2, 3.0)],
          exitDirection: ArrowDirection.left,
        ),
        // 10. Straight Down (Behind Arrow 9) -> Blocked by Arrow 9
        CanvasArrow(
          id: 10,
          points: const [Offset(1.5, 0.4), Offset(1.5, 1.3)],
          exitDirection: ArrowDirection.down,
        ),
      ],
    ),

    // Level 2: Arrow Forest (More L-bends)
    PuzzleLevel(
      id: 2,
      name: 'Arrow Forest',
      subtitle: 'Navigate the winding woods',
      gridCols: 6,
      gridRows: 6,
      maxMistakes: 3,
      arrows: [
        CanvasArrow(
          id: 1,
          points: const [Offset(1, 4), Offset(1, 1), Offset(5, 1)],
          exitDirection: ArrowDirection.right,
        ),
        CanvasArrow(
          id: 2,
          points: const [Offset(3, 5), Offset(3, 2)],
          exitDirection: ArrowDirection.up,
        ),
        CanvasArrow(
          id: 3,
          points: const [Offset(5, 3), Offset(5, 5)],
          exitDirection: ArrowDirection.down,
        ),
      ],
    ),

    // Level 3: Mystery Maze
    PuzzleLevel(
      id: 3,
      name: 'Mystery Maze',
      subtitle: 'Twisted corridors & tight turns',
      gridCols: 6,
      gridRows: 6,
      maxMistakes: 3,
      arrows: [
        CanvasArrow(
          id: 1,
          points: const [Offset(2, 5), Offset(2, 1)],
          exitDirection: ArrowDirection.up,
        ),
        CanvasArrow(
          id: 2,
          points: const [Offset(4, 1), Offset(4, 5)],
          exitDirection: ArrowDirection.down,
        ),
      ],
    ),

    // Level 4: Desert Escape
    PuzzleLevel(
      id: 4,
      name: 'Desert Escape',
      subtitle: 'Sun-baked dunes',
      gridCols: 6,
      gridRows: 6,
      maxMistakes: 3,
      arrows: [
        CanvasArrow(
          id: 1,
          points: const [Offset(1, 1), Offset(5, 1)],
          exitDirection: ArrowDirection.right,
        ),
      ],
    ),

    // Level 5: Final Challenge
    PuzzleLevel(
      id: 5,
      name: 'Final Challenge',
      subtitle: 'Master the Labyrinth',
      gridCols: 6,
      gridRows: 6,
      maxMistakes: 3,
      arrows: [
        CanvasArrow(
          id: 1,
          points: const [Offset(3, 5), Offset(3, 0.5)],
          exitDirection: ArrowDirection.up,
        ),
      ],
    ),
  ];

  static PuzzleLevel getLevel(int id) {
    return levels.firstWhere(
      (lvl) => lvl.id == id,
      orElse: () => levels.first,
    );
  }
}
