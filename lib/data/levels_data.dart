import '../models/puzzle_level.dart';

class LevelsData {
  static final List<PuzzleLevel> levels = [
    // Level 1: First Steps (10 Arrows on a 4x4 grid)
    PuzzleLevel(
      id: 1,
      name: 'First Steps',
      subtitle: 'Learn the arrow mechanics',
      gridSize: 4,
      maxMistakes: 3,
      initialArrows: [
        // 10 carefully positioned arrows
        ArrowItem(id: 1, row: 0, col: 3, direction: ArrowDirection.right),
        ArrowItem(id: 2, row: 0, col: 2, direction: ArrowDirection.right),
        ArrowItem(id: 3, row: 0, col: 1, direction: ArrowDirection.up),
        ArrowItem(id: 4, row: 1, col: 1, direction: ArrowDirection.up),
        ArrowItem(id: 5, row: 3, col: 0, direction: ArrowDirection.left),
        ArrowItem(id: 6, row: 3, col: 1, direction: ArrowDirection.down),
        ArrowItem(id: 7, row: 2, col: 1, direction: ArrowDirection.down),
        ArrowItem(id: 8, row: 1, col: 3, direction: ArrowDirection.right),
        ArrowItem(id: 9, row: 3, col: 2, direction: ArrowDirection.down),
        ArrowItem(id: 10, row: 2, col: 2, direction: ArrowDirection.down),
      ],
    ),

    // Level 2: Arrow Forest (12 Arrows on a 4x4 grid)
    PuzzleLevel(
      id: 2,
      name: 'Arrow Forest',
      subtitle: 'Navigate the dense woods',
      gridSize: 4,
      maxMistakes: 3,
      initialArrows: [
        ArrowItem(id: 1, row: 0, col: 0, direction: ArrowDirection.up),
        ArrowItem(id: 2, row: 1, col: 0, direction: ArrowDirection.up),
        ArrowItem(id: 3, row: 0, col: 3, direction: ArrowDirection.right),
        ArrowItem(id: 4, row: 0, col: 2, direction: ArrowDirection.right),
        ArrowItem(id: 5, row: 1, col: 3, direction: ArrowDirection.right),
        ArrowItem(id: 6, row: 1, col: 2, direction: ArrowDirection.right),
        ArrowItem(id: 7, row: 3, col: 0, direction: ArrowDirection.left),
        ArrowItem(id: 8, row: 3, col: 1, direction: ArrowDirection.down),
        ArrowItem(id: 9, row: 2, col: 1, direction: ArrowDirection.down),
        ArrowItem(id: 10, row: 3, col: 3, direction: ArrowDirection.down),
        ArrowItem(id: 11, row: 2, col: 3, direction: ArrowDirection.down),
        ArrowItem(id: 12, row: 2, col: 0, direction: ArrowDirection.left),
      ],
    ),

    // Level 3: Mystery Maze
    PuzzleLevel(
      id: 3,
      name: 'Mystery Maze',
      subtitle: 'Twisted paths & tricky turns',
      gridSize: 4,
      maxMistakes: 3,
      initialArrows: [
        ArrowItem(id: 1, row: 0, col: 0, direction: ArrowDirection.left),
        ArrowItem(id: 2, row: 0, col: 3, direction: ArrowDirection.up),
        ArrowItem(id: 3, row: 3, col: 3, direction: ArrowDirection.right),
        ArrowItem(id: 4, row: 3, col: 0, direction: ArrowDirection.down),
        ArrowItem(id: 5, row: 1, col: 1, direction: ArrowDirection.up),
        ArrowItem(id: 6, row: 1, col: 2, direction: ArrowDirection.right),
        ArrowItem(id: 7, row: 2, col: 2, direction: ArrowDirection.down),
        ArrowItem(id: 8, row: 2, col: 1, direction: ArrowDirection.left),
        ArrowItem(id: 9, row: 0, col: 1, direction: ArrowDirection.up),
        ArrowItem(id: 10, row: 3, col: 2, direction: ArrowDirection.down),
      ],
    ),

    // Level 4: Desert Escape
    PuzzleLevel(
      id: 4,
      name: 'Desert Escape',
      subtitle: 'Find your way through the dunes',
      gridSize: 4,
      maxMistakes: 3,
      initialArrows: [
        ArrowItem(id: 1, row: 0, col: 1, direction: ArrowDirection.up),
        ArrowItem(id: 2, row: 0, col: 2, direction: ArrowDirection.up),
        ArrowItem(id: 3, row: 1, col: 3, direction: ArrowDirection.right),
        ArrowItem(id: 4, row: 2, col: 3, direction: ArrowDirection.right),
        ArrowItem(id: 5, row: 3, col: 2, direction: ArrowDirection.down),
        ArrowItem(id: 6, row: 3, col: 1, direction: ArrowDirection.down),
        ArrowItem(id: 7, row: 2, col: 0, direction: ArrowDirection.left),
        ArrowItem(id: 8, row: 1, col: 0, direction: ArrowDirection.left),
        ArrowItem(id: 9, row: 1, col: 1, direction: ArrowDirection.up),
        ArrowItem(id: 10, row: 2, col: 2, direction: ArrowDirection.down),
      ],
    ),

    // Level 5: Final Challenge
    PuzzleLevel(
      id: 5,
      name: 'Final Challenge',
      subtitle: 'The ultimate arrow puzzle',
      gridSize: 4,
      maxMistakes: 3,
      initialArrows: [
        ArrowItem(id: 1, row: 0, col: 0, direction: ArrowDirection.up),
        ArrowItem(id: 2, row: 0, col: 3, direction: ArrowDirection.right),
        ArrowItem(id: 3, row: 3, col: 3, direction: ArrowDirection.down),
        ArrowItem(id: 4, row: 3, col: 0, direction: ArrowDirection.left),
        ArrowItem(id: 5, row: 1, col: 0, direction: ArrowDirection.left),
        ArrowItem(id: 6, row: 0, col: 2, direction: ArrowDirection.up),
        ArrowItem(id: 7, row: 2, col: 3, direction: ArrowDirection.right),
        ArrowItem(id: 8, row: 3, col: 1, direction: ArrowDirection.down),
        ArrowItem(id: 9, row: 1, col: 2, direction: ArrowDirection.right),
        ArrowItem(id: 10, row: 2, col: 1, direction: ArrowDirection.left),
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
