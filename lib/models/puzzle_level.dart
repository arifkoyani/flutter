import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';

enum ArrowDirection {
  up,
  down,
  left,
  right;

  Offset get unitVector {
    switch (this) {
      case ArrowDirection.up:
        return const Offset(0, -1);
      case ArrowDirection.down:
        return const Offset(0, 1);
      case ArrowDirection.left:
        return const Offset(-1, 0);
      case ArrowDirection.right:
        return const Offset(1, 0);
    }
  }

  double get angle {
    switch (this) {
      case ArrowDirection.right:
        return 0.0;
      case ArrowDirection.down:
        return math.pi / 2;
      case ArrowDirection.left:
        return math.pi;
      case ArrowDirection.up:
        return -math.pi / 2;
    }
  }
}

/// A path-based arrow defined by continuous waypoints (straight or with turns)
class CanvasArrow {
  final int id;

  /// Ordered waypoints in grid coordinates (e.g. (col, row))
  final List<Offset> points;

  /// Direction of the final segment (where arrowhead points)
  final ArrowDirection exitDirection;

  /// Color accent for the arrow
  final Color? color;

  /// Runtime state
  bool isExited;
  double exitOffset; // Distance moved along exit vector
  bool isShaking;

  CanvasArrow({
    required this.id,
    required this.points,
    required this.exitDirection,
    this.color,
    this.isExited = false,
    this.exitOffset = 0.0,
    this.isShaking = false,
  });

  Offset get tip => points.last;
  Offset get start => points.first;

  CanvasArrow clone() {
    return CanvasArrow(
      id: id,
      points: List<Offset>.from(points),
      exitDirection: exitDirection,
      color: color,
      isExited: isExited,
      exitOffset: exitOffset,
      isShaking: isShaking,
    );
  }
}

/// A wall segment in the maze [from -> to] in grid coordinates
class MazeWall {
  final Offset from;
  final Offset to;

  const MazeWall(this.from, this.to);
}

/// Exit gap in outer maze boundary
class MazeExit {
  final Offset position;
  final ArrowDirection direction;

  const MazeExit(this.position, this.direction);
}

class PuzzleLevel {
  final int id;
  final String name;
  final String subtitle;
  final int gridCols;
  final int gridRows;
  final int maxMistakes;
  final List<CanvasArrow> arrows;
  final List<MazeWall> walls;
  final List<MazeExit> exits;

  const PuzzleLevel({
    required this.id,
    required this.name,
    required this.subtitle,
    this.gridCols = 6,
    this.gridRows = 6,
    this.maxMistakes = 3,
    required this.arrows,
    this.walls = const [],
    this.exits = const [],
  });
}
