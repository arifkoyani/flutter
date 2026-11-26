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
    final base = levels.firstWhere(
      (lvl) => lvl.id == id,
      orElse: () => levels.first,
    );
    return PuzzleLevel(
      id: base.id,
      name: base.name,
      subtitle: base.subtitle,
      gridCols: base.gridCols,
      gridRows: base.gridRows,
      maxMistakes: base.maxMistakes,
      walls: base.walls,
      exits: base.exits,
      arrows: [
        ...base.arrows,
        ..._sideFaceArrows(),
      ],
    );
  }

  /// Denser solvable sets for the five faces around the front puzzle.
  static List<CanvasArrow> _sideFaceArrows() {
    return [
      // Right: three free columns, six arrows waiting behind them.
      CanvasArrow(
        id: 101,
        face: CubeFace.right,
        points: const [Offset(0.5, 0.4), Offset(0.5, 5.6)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 102,
        face: CubeFace.right,
        points: const [Offset(3.0, 0.4), Offset(3.0, 5.6)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 103,
        face: CubeFace.right,
        points: const [Offset(5.5, 0.4), Offset(5.5, 5.6)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 104,
        face: CubeFace.right,
        points: const [Offset(1.1, 1.1), Offset(2.3, 1.1)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 105,
        face: CubeFace.right,
        points: const [Offset(1.1, 2.7), Offset(2.3, 2.7)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 106,
        face: CubeFace.right,
        points: const [Offset(1.1, 4.3), Offset(2.3, 4.3)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 107,
        face: CubeFace.right,
        points: const [Offset(3.6, 1.6), Offset(4.85, 1.6)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 108,
        face: CubeFace.right,
        points: const [Offset(3.6, 3.3), Offset(4.85, 3.3)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 109,
        face: CubeFace.right,
        points: const [Offset(3.6, 5.0), Offset(4.85, 5.0)],
        exitDirection: ArrowDirection.right,
      ),

      // Left: three free rows, six arrows waiting above them.
      CanvasArrow(
        id: 201,
        face: CubeFace.left,
        points: const [Offset(0.4, 0.5), Offset(5.6, 0.5)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 202,
        face: CubeFace.left,
        points: const [Offset(0.4, 3.0), Offset(5.6, 3.0)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 203,
        face: CubeFace.left,
        points: const [Offset(0.4, 5.5), Offset(5.6, 5.5)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 204,
        face: CubeFace.left,
        points: const [Offset(1.2, 1.1), Offset(1.2, 2.4)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 205,
        face: CubeFace.left,
        points: const [Offset(3.0, 1.1), Offset(3.0, 2.4)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 206,
        face: CubeFace.left,
        points: const [Offset(4.8, 1.1), Offset(4.8, 2.4)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 207,
        face: CubeFace.left,
        points: const [Offset(1.2, 3.6), Offset(1.2, 4.9)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 208,
        face: CubeFace.left,
        points: const [Offset(3.0, 3.6), Offset(3.0, 4.9)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 209,
        face: CubeFace.left,
        points: const [Offset(4.8, 3.6), Offset(4.8, 4.9)],
        exitDirection: ArrowDirection.down,
      ),

      // Back
      CanvasArrow(
        id: 301,
        face: CubeFace.back,
        points: const [Offset(1.2, 0.4), Offset(1.2, 5.6)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 302,
        face: CubeFace.back,
        points: const [Offset(4.6, 0.4), Offset(4.6, 5.6)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 303,
        face: CubeFace.back,
        points: const [Offset(0.4, 1.2), Offset(0.4, 5.2)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 304,
        face: CubeFace.back,
        points: const [Offset(5.2, 1.0), Offset(5.2, 5.2)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 305,
        face: CubeFace.back,
        points: const [Offset(1.8, 1.1), Offset(4.0, 1.1)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 306,
        face: CubeFace.back,
        points: const [Offset(1.8, 2.5), Offset(4.0, 2.5)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 307,
        face: CubeFace.back,
        points: const [Offset(1.8, 3.9), Offset(4.0, 3.9)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 308,
        face: CubeFace.back,
        points: const [Offset(1.8, 5.2), Offset(4.0, 5.2)],
        exitDirection: ArrowDirection.right,
      ),

      // Top
      CanvasArrow(
        id: 401,
        face: CubeFace.top,
        points: const [Offset(0.4, 1.5), Offset(5.6, 1.5)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 402,
        face: CubeFace.top,
        points: const [Offset(0.4, 4.5), Offset(5.6, 4.5)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 403,
        face: CubeFace.top,
        points: const [Offset(0.6, 0.4), Offset(5.4, 0.4)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 404,
        face: CubeFace.top,
        points: const [Offset(1.2, 5.05), Offset(4.6, 5.05)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 405,
        face: CubeFace.top,
        points: const [Offset(1.3, 2.1), Offset(1.3, 3.9)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 406,
        face: CubeFace.top,
        points: const [Offset(2.9, 2.1), Offset(2.9, 3.9)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 407,
        face: CubeFace.top,
        points: const [Offset(4.5, 2.1), Offset(4.5, 3.9)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 408,
        face: CubeFace.top,
        points: const [Offset(5.3, 2.2), Offset(5.3, 3.9)],
        exitDirection: ArrowDirection.down,
      ),

      // Bottom
      CanvasArrow(
        id: 501,
        face: CubeFace.bottom,
        points: const [Offset(1.5, 0.4), Offset(1.5, 5.6)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 502,
        face: CubeFace.bottom,
        points: const [Offset(4.5, 0.4), Offset(4.5, 5.6)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 503,
        face: CubeFace.bottom,
        points: const [Offset(0.45, 0.8), Offset(0.45, 5.2)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 504,
        face: CubeFace.bottom,
        points: const [Offset(5.2, 0.8), Offset(5.2, 5.2)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 505,
        face: CubeFace.bottom,
        points: const [Offset(2.1, 1.1), Offset(3.9, 1.1)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 506,
        face: CubeFace.bottom,
        points: const [Offset(2.1, 2.5), Offset(3.9, 2.5)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 507,
        face: CubeFace.bottom,
        points: const [Offset(2.1, 4.0), Offset(3.9, 4.0)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 508,
        face: CubeFace.bottom,
        points: const [Offset(2.1, 5.3), Offset(3.9, 5.3)],
        exitDirection: ArrowDirection.right,
      ),
    ];
  }
}
