import 'package:material_ui/material_ui.dart';

enum ArrowDirection {
  up,
  down,
  left,
  right;

  IconData get icon {
    switch (this) {
      case ArrowDirection.up:
        return Icons.arrow_upward_rounded;
      case ArrowDirection.down:
        return Icons.arrow_downward_rounded;
      case ArrowDirection.left:
        return Icons.arrow_back_rounded;
      case ArrowDirection.right:
        return Icons.arrow_forward_rounded;
    }
  }

  // Delta offsets along rows and columns
  int get deltaRow {
    switch (this) {
      case ArrowDirection.up:
        return -1;
      case ArrowDirection.down:
        return 1;
      case ArrowDirection.left:
      case ArrowDirection.right:
        return 0;
    }
  }

  int get deltaCol {
    switch (this) {
      case ArrowDirection.left:
        return -1;
      case ArrowDirection.right:
        return 1;
      case ArrowDirection.up:
      case ArrowDirection.down:
        return 0;
    }
  }
}

class ArrowItem {
  final int id;
  int row;
  int col;
  final ArrowDirection direction;
  bool isExited;
  bool isShaking;

  ArrowItem({
    required this.id,
    required this.row,
    required this.col,
    required this.direction,
    this.isExited = false,
    this.isShaking = false,
  });

  ArrowItem clone() {
    return ArrowItem(
      id: id,
      row: row,
      col: col,
      direction: direction,
      isExited: isExited,
      isShaking: isShaking,
    );
  }
}

class PuzzleLevel {
  final int id;
  final String name;
  final String subtitle;
  final int gridSize;
  final int maxMistakes;
  final List<ArrowItem> initialArrows;

  const PuzzleLevel({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.gridSize,
    this.maxMistakes = 3,
    required this.initialArrows,
  });
}
