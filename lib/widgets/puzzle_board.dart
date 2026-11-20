import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../models/puzzle_level.dart';

class PuzzleBoard extends StatefulWidget {
  final int levelId;
  final int gridCols;
  final int gridRows;
  final List<CanvasArrow> arrows;
  final List<MazeWall> walls;
  final Function(CanvasArrow arrow, bool isClear) onArrowTap;

  const PuzzleBoard({
    super.key,
    this.levelId = 1,
    required this.gridCols,
    required this.gridRows,
    required this.arrows,
    this.walls = const [],
    required this.onArrowTap,
  });

  @override
  State<PuzzleBoard> createState() => _PuzzleBoardState();
}

class _PuzzleBoardState extends State<PuzzleBoard>
    with TickerProviderStateMixin {
  int? _shakingArrowId;
  int? _exitingArrowId;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  late final AnimationController _exitController;
  late Animation<double> _exitAnimation;
  CanvasArrow? _animatingArrow;

  @override
  void initState() {
    super.initState();

    // Shaking animation for blocked moves
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    // Smooth snake-like exit animation controller (700ms)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _exitAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_exitController);

    _exitController.addListener(() {
      if (_animatingArrow != null) {
        setState(() {
          _animatingArrow!.exitDistance = _exitAnimation.value;
        });
      }
    });

    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _animatingArrow != null) {
        setState(() {
          _animatingArrow!.isExited = true;
          _animatingArrow!.exitDistance = 0.0;
          _animatingArrow = null;
          _exitingArrowId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  // Check if arrow's path is unobstructed to exit
  bool _isPathClear(CanvasArrow arrow) {
    final tip = arrow.tip;
    final dir = arrow.exitDirection.unitVector;

    // Probe forward along the exit corridor
    for (double step = 0.4; step <= 8.0; step += 0.3) {
      final probe = Offset(tip.dx + dir.dx * step, tip.dy + dir.dy * step);

      // Check against all other un-exited arrows
      for (final other in widget.arrows) {
        if (other.id == arrow.id || other.isExited) continue;

        // Check if probe hits any line segment of the other arrow
        for (int i = 0; i < other.points.length - 1; i++) {
          final pA = other.points[i];
          final pB = other.points[i + 1];
          if (_distanceToSegment(probe, pA, pB) < 0.45) {
            return false; // Blocked by another arrow!
          }
        }
      }
    }
    return true; // Path is clear!
  }

  void _onTapDown(TapDownDetails details, Size canvasSize) {
    if (_exitingArrowId != null) return; // Wait during active snake exit

    final padding = 20.0;
    final usableW = canvasSize.width - padding * 2;
    final usableH = canvasSize.height - padding * 2;
    final cellW = usableW / widget.gridCols;
    final cellH = usableH / widget.gridRows;

    final tap = details.localPosition;

    // Convert tap pixel to grid coordinate
    final gridX = (tap.dx - padding) / cellW;
    final gridY = (tap.dy - padding) / cellH;
    final tapGrid = Offset(gridX, gridY);

    // Hit test active arrows (with generous 0.55 grid unit tap tolerance)
    CanvasArrow? tappedArrow;
    double closestDist = double.infinity;

    for (final arrow in widget.arrows) {
      if (arrow.isExited) continue;

      for (int i = 0; i < arrow.points.length - 1; i++) {
        final dist = _distanceToSegment(
          tapGrid,
          arrow.points[i],
          arrow.points[i + 1],
        );
        if (dist < 0.55 && dist < closestDist) {
          closestDist = dist;
          tappedArrow = arrow;
        }
      }
    }

    if (tappedArrow == null) return;

    final isClear = _isPathClear(tappedArrow);

    if (isClear) {
      _animatingArrow = tappedArrow;
      _exitingArrowId = tappedArrow.id;

      // Distance required for the entire arrow (head + body + tail) to exit the whole screen
      final totalTravelDistance = tappedArrow.totalLength + 25.0;

      _exitAnimation = Tween<double>(
        begin: 0.0,
        end: totalTravelDistance,
      ).animate(CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInOutQuad,
      ));

      _exitController.forward(from: 0.0);
      widget.onArrowTap(tappedArrow, true);
    } else {
      setState(() {
        _shakingArrowId = tappedArrow!.id;
      });
      _shakeController.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _shakingArrowId = null;
          });
        }
      });
      widget.onArrowTap(tappedArrow, false);
    }
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final lengthSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lengthSq == 0) return (p - a).distance;

    final t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / lengthSq;
    final clampedT = t.clamp(0.0, 1.0);
    final projection = Offset(a.dx + clampedT * ab.dx, a.dy + clampedT * ab.dy);
    return (p - projection).distance;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 360.0);
        // Stage 1 (First Steps) has no walls, frames, or borders
        final effectiveWalls =
            widget.levelId == 1 ? const <MazeWall>[] : widget.walls;

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _onTapDown(details, Size(size, size)),
              child: AnimatedBuilder(
                animation: Listenable.merge([_shakeAnimation, _exitController]),
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(size, size),
                    painter: _MazeArrowCanvasPainter(
                      gridCols: widget.gridCols,
                      gridRows: widget.gridRows,
                      arrows: widget.arrows,
                      walls: effectiveWalls,
                      shakingArrowId: _shakingArrowId,
                      shakeOffset: _shakeAnimation.value,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Canvas Painter that renders the Snake-Like Arrow Movement & Maze Walls
class _MazeArrowCanvasPainter extends CustomPainter {
  final int gridCols;
  final int gridRows;
  final List<CanvasArrow> arrows;
  final List<MazeWall> walls;
  final int? shakingArrowId;
  final double shakeOffset;

  static const Color primaryOrange = Color(0xFFFF550D);

  _MazeArrowCanvasPainter({
    required this.gridCols,
    required this.gridRows,
    required this.arrows,
    required this.walls,
    this.shakingArrowId,
    required this.shakeOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 20.0;
    final usableW = size.width - padding * 2;
    final usableH = size.height - padding * 2;
    final cellW = usableW / gridCols;
    final cellH = usableH / gridRows;

    Offset toPixel(Offset grid) {
      return Offset(
        padding + grid.dx * cellW,
        padding + grid.dy * cellH,
      );
    }

    // 1. Draw Maze Walls (Only if walls exist, never in Stage 1)
    if (walls.isNotEmpty) {
      final wallPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (final wall in walls) {
        canvas.drawLine(toPixel(wall.from), toPixel(wall.to), wallPaint);
      }
    }

    // 2. Draw Each Arrow with Snake Follower Dynamics
    for (final arrow in arrows) {
      if (arrow.isExited) continue;

      final isShaking = arrow.id == shakingArrowId;
      final arrowColor = isShaking ? const Color(0xFFFF3B30) : primaryOrange;

      // Extract current snake path points (follows exact turns and corners)
      final activeGridPoints = arrow.exitDistance > 0.0
          ? arrow.getSnakePathPoints(arrow.exitDistance)
          : List<Offset>.from(arrow.points);

      // If arrow has completely slithered off the board, nothing to draw
      if (activeGridPoints.length < 2) continue;

      final shakePixelShift = isShaking
          ? (arrow.exitDirection.unitVector.dx != 0
              ? Offset(0, shakeOffset)
              : Offset(shakeOffset, 0))
          : Offset.zero;

      final pixelPoints =
          activeGridPoints.map((p) => toPixel(p) + shakePixelShift).toList();

      // ─── A. Draw Continuous Arrow Shaft ───
      final shaftPath = Path();
      shaftPath.moveTo(pixelPoints.first.dx, pixelPoints.first.dy);
      for (int i = 1; i < pixelPoints.length; i++) {
        shaftPath.lineTo(pixelPoints[i].dx, pixelPoints[i].dy);
      }

      final shaftPaint = Paint()
        ..color = arrowColor
        ..strokeWidth = 7.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(shaftPath, shaftPaint);

      // ─── B. Draw Vector Arrowhead Triangle at the Leading Head ───
      final tip = pixelPoints.last;
      final prev = pixelPoints[pixelPoints.length - 2];
      final angle = math.atan2(tip.dy - prev.dy, tip.dx - prev.dx);

      const headLength = 18.0;
      const headWidth = 15.0;

      final headPath = Path();
      headPath.moveTo(tip.dx, tip.dy); // Arrowhead Tip

      // Left barb
      headPath.lineTo(
        tip.dx - headLength * math.cos(angle) + (headWidth / 2) * math.sin(angle),
        tip.dy - headLength * math.sin(angle) - (headWidth / 2) * math.cos(angle),
      );

      // Right barb
      headPath.lineTo(
        tip.dx - headLength * math.cos(angle) - (headWidth / 2) * math.sin(angle),
        tip.dy - headLength * math.sin(angle) + (headWidth / 2) * math.cos(angle),
      );

      headPath.close();

      final headPaint = Paint()
        ..color = arrowColor
        ..style = PaintingStyle.fill;

      canvas.drawPath(headPath, headPaint);

      // Stroke around arrowhead for sharp contrast
      final headStroke = Paint()
        ..color = isShaking ? Colors.redAccent : const Color(0xFFD63031)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(headPath, headStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _MazeArrowCanvasPainter oldDelegate) {
    return true;
  }
}
