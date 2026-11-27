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

/// Which side of the arrow cube an arrow is attached to.
enum CubeFace { front, back, left, right, top, bottom }

/// A path-based arrow defined by continuous waypoints (straight or with turns)
class CanvasArrow {
  final int id;

  /// Ordered waypoints in grid coordinates (e.g. (col, row))
  final List<Offset> points;

  /// Direction of the final segment (where arrowhead points)
  final ArrowDirection exitDirection;

  /// Cube face this arrow lies on. Null only on instances kept alive across
  /// a hot reload that added the field; [placedOn] treats that as the front.
  final CubeFace? face;

  /// Color accent for the arrow
  final Color? color;

  /// Runtime state
  bool isExited;
  double exitDistance; // Distance traveled along the snake path in grid units
  bool isShaking;

  CanvasArrow({
    required this.id,
    required this.points,
    required this.exitDirection,
    this.face = CubeFace.front,
    this.color,
    this.isExited = false,
    this.exitDistance = 0.0,
    this.isShaking = false,
  });

  Offset get tip => points.last;
  Offset get start => points.first;

  /// Face this arrow is drawn and tested on.
  CubeFace get placedOn => face ?? CubeFace.front;

  /// Total length of the arrow along its path in grid units
  double get totalLength {
    double len = 0;
    for (int i = 0; i < points.length - 1; i++) {
      len += (points[i + 1] - points[i]).distance;
    }
    return len;
  }

  /// Extracts the snake-like path at distance [d].
  /// The head advances along the forward exit vector while the body
  /// and tail follow the exact path waypoints and corners in sequence.
  List<Offset> getSnakePathPoints(double d, {double exitProjection = 30.0}) {
    if (d <= 0.0) {
      return List<Offset>.from(points);
    }

    final length = totalLength;
    final dir = exitDirection.unitVector;

    // Full trajectory: original waypoints + extended exit projection
    final trajectory = <Offset>[
      ...points,
      points.last + dir * exitProjection,
    ];

    // Cumulative distances along trajectory
    final cumulative = <double>[0.0];
    for (int i = 0; i < trajectory.length - 1; i++) {
      final segLen = (trajectory[i + 1] - trajectory[i]).distance;
      cumulative.add(cumulative.last + segLen);
    }

    final totalTrajectoryLength = cumulative.last;
    final sTail = d;
    final sHead = (length + d).clamp(0.0, totalTrajectoryLength);

    if (sTail >= totalTrajectoryLength) {
      return [];
    }

    Offset getPointAtDistance(double s) {
      for (int i = 0; i < cumulative.length - 1; i++) {
        final cStart = cumulative[i];
        final cEnd = cumulative[i + 1];
        if (s >= cStart && s <= cEnd) {
          final segLen = cEnd - cStart;
          if (segLen == 0) return trajectory[i];
          final f = (s - cStart) / segLen;
          return Offset(
            trajectory[i].dx + (trajectory[i + 1].dx - trajectory[i].dx) * f,
            trajectory[i].dy + (trajectory[i + 1].dy - trajectory[i].dy) * f,
          );
        }
      }
      return trajectory.last;
    }

    final result = <Offset>[];
    result.add(getPointAtDistance(sTail));

    // Preserve all corners and intermediate turns between tail and head
    for (int i = 1; i < cumulative.length - 1; i++) {
      final c = cumulative[i];
      if (c > sTail + 0.001 && c < sHead - 0.001) {
        result.add(trajectory[i]);
      }
    }

    result.add(getPointAtDistance(sHead));
    return result;
  }

  CanvasArrow clone() {
    return CanvasArrow(
      id: id,
      points: List<Offset>.from(points),
      exitDirection: exitDirection,
      face: placedOn,
      color: color,
      isExited: isExited,
      exitDistance: exitDistance,
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
  final int durationSeconds;
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
    this.durationSeconds = 60,
    required this.arrows,
    this.walls = const [],
    this.exits = const [],
  });
}
