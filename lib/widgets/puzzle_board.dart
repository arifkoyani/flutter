import 'dart:math' as math;
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import '../models/puzzle_level.dart';

/// Six-faced arrow cube. Reuses the flat board's path test, shake, and
/// snake-exit animation, and draws every face in perspective.
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
  static const double _restYaw = -0.72;
  static const double _restPitch = 0.50;

  int? _shakingArrowId;
  int? _exitingArrowId;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  late final AnimationController _exitController;
  late Animation<double> _exitAnimation;
  CanvasArrow? _animatingArrow;

  late _Quat _orientation = _Quat.axisAngle(const _Vec3(1, 0, 0), _restPitch)
      .multiplied(_Quat.axisAngle(const _Vec3(0, 1, 0), _restYaw));
  double _yawVelocity = 0;
  double _pitchVelocity = 0;
  late final Ticker _spinTicker;
  Duration? _spinLast;

  int? _activePointer;
  Offset _downPos = Offset.zero;
  Offset _lastPos = Offset.zero;
  DateTime _lastMoveTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _dragged = false;

  @override
  void initState() {
    super.initState();

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

    _spinTicker = createTicker(_onSpinTick);
  }

  @override
  void didUpdateWidget(PuzzleBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final levelChanged = oldWidget.levelId != widget.levelId;
    final arrowsReplaced = !identical(oldWidget.arrows, widget.arrows);
    if (!levelChanged && !arrowsReplaced) return;

    _animatingArrow = null;
    _exitingArrowId = null;
    _shakingArrowId = null;
    _exitController.stop();
    _shakeController.stop();

    if (levelChanged) {
      _orientation = _Quat.axisAngle(const _Vec3(1, 0, 0), _restPitch)
          .multiplied(_Quat.axisAngle(const _Vec3(0, 1, 0), _restYaw));
      _yawVelocity = 0;
      _pitchVelocity = 0;
      _spinTicker.stop();
      _spinLast = null;
    }
  }

  @override
  void dispose() {
    _spinTicker.dispose();
    _shakeController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _onSpinTick(Duration elapsed) {
    final previous = _spinLast;
    _spinLast = elapsed;
    if (previous == null) return;

    final dt = (elapsed - previous).inMicroseconds / 1e6;
    if (dt <= 0 || dt > 0.05) return;

    _yawVelocity *= math.exp(-3.6 * dt);
    _pitchVelocity *= math.exp(-3.6 * dt);

    if (_yawVelocity.abs() < 0.02 && _pitchVelocity.abs() < 0.02) {
      _yawVelocity = 0;
      _pitchVelocity = 0;
      _spinTicker.stop();
      _spinLast = null;
      return;
    }

    setState(() {
      _spinBy(_yawVelocity * dt, _pitchVelocity * dt);
    });
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_activePointer != null) return;
    _activePointer = event.pointer;
    _downPos = event.localPosition;
    _lastPos = event.localPosition;
    _lastMoveTime = DateTime.now();
    _dragged = false;
    _yawVelocity = 0;
    _pitchVelocity = 0;
    _spinTicker.stop();
    _spinLast = null;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer) return;

    final now = DateTime.now();
    final delta = event.localPosition - _lastPos;
    if (!_dragged && (event.localPosition - _downPos).distance > 8) {
      _dragged = true;
    }

    if (_dragged) {
      final dt = now.difference(_lastMoveTime).inMicroseconds / 1e6;
      setState(() {
        _spinBy(-delta.dx * 0.012, -delta.dy * 0.010);
      });
      if (dt > 0.001 && dt < 0.05) {
        final yawInst = (-delta.dx * 0.012 / dt).clamp(-4.0, 4.0).toDouble();
        final pitchInst = (-delta.dy * 0.010 / dt).clamp(-3.4, 3.4).toDouble();
        _yawVelocity = _yawVelocity * 0.45 + yawInst * 0.55;
        _pitchVelocity = _pitchVelocity * 0.45 + pitchInst * 0.55;
      }
    }

    _lastPos = event.localPosition;
    _lastMoveTime = now;
  }

  void _onPointerUp(PointerUpEvent event, Size size) {
    if (event.pointer != _activePointer) return;
    _activePointer = null;
    if (!_dragged) {
      _handleTap(_downPos, size);
      return;
    }
    if (_yawVelocity.abs() > 0.18 || _pitchVelocity.abs() > 0.18) {
      _spinLast = null;
      _spinTicker.start();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) return;
    _activePointer = null;
    _yawVelocity = 0;
    _pitchVelocity = 0;
  }

  /// Same corridor test as the flat board, limited to arrows on this face.
  bool _isPathClear(CanvasArrow arrow) {
    final tip = arrow.tip;
    final dir = arrow.exitDirection.unitVector;

    for (double step = 0.4; step <= 8.0; step += 0.3) {
      final probe = Offset(tip.dx + dir.dx * step, tip.dy + dir.dy * step);

      for (final other in widget.arrows) {
        if (other.id == arrow.id || other.isExited || other.placedOn != arrow.placedOn) {
          continue;
        }

        for (int i = 0; i < other.points.length - 1; i++) {
          final pA = other.points[i];
          final pB = other.points[i + 1];
          if (_distanceToSegment(probe, pA, pB) < 0.45) {
            return false;
          }
        }
      }
    }
    return true;
  }

  void _handleTap(Offset local, Size size) {
    if (_exitingArrowId != null) return;

    final tapped = _pickArrow(local, size);
    if (tapped == null) return;

    final isClear = _isPathClear(tapped);

    if (isClear) {
      _animatingArrow = tapped;
      _exitingArrowId = tapped.id;

      final totalTravelDistance = tapped.totalLength + 25.0;
      _exitAnimation = Tween<double>(
        begin: 0.0,
        end: totalTravelDistance,
      ).animate(CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInOutQuad,
      ));

      _exitController.forward(from: 0.0);
      widget.onArrowTap(tapped, true);
    } else {
      setState(() {
        _shakingArrowId = tapped.id;
      });
      _shakeController.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _shakingArrowId = null;
          });
        }
      });
      widget.onArrowTap(tapped, false);
    }
  }

  CanvasArrow? _pickArrow(Offset tap, Size size) {
    CanvasArrow? tapped;
    var bestRank = double.infinity;

    for (final face in CubeFace.values) {
      final frame = _FaceFrame.of(face);
      final normal = _orientation.rotate(frame.normal);
      if (normal.z <= 0.05) continue;

      final screen = _buildFaceScreen(
        frame: frame,
        size: size,
        orientation: _orientation,
        gridCols: widget.gridCols,
        gridRows: widget.gridRows,
      );
      final slop = screen.unit * 0.72;
      final depthBias = (1.15 - normal.z) * 18;

      for (final arrow in widget.arrows) {
        if (arrow.isExited || arrow.placedOn != face) continue;
        for (var i = 0; i < arrow.points.length - 1; i++) {
          final dist = _distanceToSegment(
            tap,
            screen.map(arrow.points[i]),
            screen.map(arrow.points[i + 1]),
          );
          if (dist > slop) continue;
          final rank = dist + depthBias;
          if (rank < bestRank) {
            bestRank = rank;
            tapped = arrow;
          }
        }
      }
    }
    return tapped;
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

  /// Screen-axis spin. Keeps going on both axes with no stop.
  void _spinBy(double yawDelta, double pitchDelta) {
    final turn = _Quat.axisAngle(const _Vec3(1, 0, 0), pitchDelta)
        .multiplied(_Quat.axisAngle(const _Vec3(0, 1, 0), yawDelta));
    _orientation = turn.multiplied(_orientation).normalized();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var side = constraints.maxWidth;
        if (!side.isFinite || side <= 0) side = 360;
        final size = math.min(side, 460.0);
        final canvas = Size(size, size);
        final effectiveWalls =
            widget.levelId == 1 ? const <MazeWall>[] : widget.walls;

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (_) {},
              onHorizontalDragUpdate: (_) {},
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: (event) => _onPointerUp(event, canvas),
                onPointerCancel: _onPointerCancel,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_shakeAnimation, _exitController]),
                  builder: (context, child) {
                    return CustomPaint(
                      size: canvas,
                      isComplex: true,
                      willChange: true,
                      painter: _ArrowCubePainter(
                        gridCols: widget.gridCols,
                        gridRows: widget.gridRows,
                        arrows: widget.arrows,
                        walls: effectiveWalls,
                        orientation: _orientation,
                        shakingArrowId: _shakingArrowId,
                        shakeOffset: _shakeAnimation.value,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Vec3 {
  final double x;
  final double y;
  final double z;

  const _Vec3(this.x, this.y, this.z);

  _Vec3 operator +(_Vec3 other) => _Vec3(x + other.x, y + other.y, z + other.z);
  _Vec3 operator -(_Vec3 other) => _Vec3(x - other.x, y - other.y, z - other.z);
  _Vec3 operator *(double scale) => _Vec3(x * scale, y * scale, z * scale);

  double dot(_Vec3 other) => x * other.x + y * other.y + z * other.z;
}

class _Quat {
  final double x;
  final double y;
  final double z;
  final double w;

  const _Quat(this.x, this.y, this.z, this.w);

  static _Quat axisAngle(_Vec3 axis, double radians) {
    final half = radians * 0.5;
    final s = math.sin(half);
    final len = math.sqrt(axis.x * axis.x + axis.y * axis.y + axis.z * axis.z);
    if (len == 0) return const _Quat(0, 0, 0, 1);
    final scale = s / len;
    return _Quat(axis.x * scale, axis.y * scale, axis.z * scale, math.cos(half));
  }

  _Quat multiplied(_Quat other) {
    return _Quat(
      w * other.x + x * other.w + y * other.z - z * other.y,
      w * other.y - x * other.z + y * other.w + z * other.x,
      w * other.z + x * other.y - y * other.x + z * other.w,
      w * other.w - x * other.x - y * other.y - z * other.z,
    );
  }

  _Quat normalized() {
    final len = math.sqrt(x * x + y * y + z * z + w * w);
    if (len == 0) return const _Quat(0, 0, 0, 1);
    return _Quat(x / len, y / len, z / len, w / len);
  }

  _Vec3 rotate(_Vec3 v) {
    final tx = 2 * (y * v.z - z * v.y);
    final ty = 2 * (z * v.x - x * v.z);
    final tz = 2 * (x * v.y - y * v.x);
    return _Vec3(
      v.x + w * tx + (y * tz - z * ty),
      v.y + w * ty + (z * tx - x * tz),
      v.z + w * tz + (x * ty - y * tx),
    );
  }
}

class _FaceFrame {
  final _Vec3 origin;
  final _Vec3 axisU;
  final _Vec3 axisV;
  final _Vec3 normal;

  const _FaceFrame(this.origin, this.axisU, this.axisV, this.normal);

  static const double _s = 1;

  static _FaceFrame of(CubeFace face) {
    switch (face) {
      case CubeFace.front:
        return const _FaceFrame(
          _Vec3(-_s, _s, _s),
          _Vec3(2 * _s, 0, 0),
          _Vec3(0, -2 * _s, 0),
          _Vec3(0, 0, 1),
        );
      case CubeFace.back:
        return const _FaceFrame(
          _Vec3(_s, _s, -_s),
          _Vec3(-2 * _s, 0, 0),
          _Vec3(0, -2 * _s, 0),
          _Vec3(0, 0, -1),
        );
      case CubeFace.left:
        return const _FaceFrame(
          _Vec3(-_s, _s, -_s),
          _Vec3(0, 0, 2 * _s),
          _Vec3(0, -2 * _s, 0),
          _Vec3(-1, 0, 0),
        );
      case CubeFace.right:
        return const _FaceFrame(
          _Vec3(_s, _s, _s),
          _Vec3(0, 0, -2 * _s),
          _Vec3(0, -2 * _s, 0),
          _Vec3(1, 0, 0),
        );
      case CubeFace.top:
        return const _FaceFrame(
          _Vec3(-_s, _s, -_s),
          _Vec3(2 * _s, 0, 0),
          _Vec3(0, 0, 2 * _s),
          _Vec3(0, 1, 0),
        );
      case CubeFace.bottom:
        return const _FaceFrame(
          _Vec3(-_s, -_s, _s),
          _Vec3(2 * _s, 0, 0),
          _Vec3(0, 0, -2 * _s),
          _Vec3(0, -1, 0),
        );
    }
  }

  _Vec3 gridToWorld(Offset grid, int cols, int rows) {
    final u = grid.dx / cols;
    final v = grid.dy / rows;
    return origin + axisU * u + axisV * v;
  }
}

class _CubeMath {
  static const double cameraZ = 3.45;
  static const double focal = 2.65;
  static const double fill = 0.30;

  static Offset project(_Vec3 view, Size size) {
    final depth = math.max(0.35, cameraZ - view.z);
    final scale = focal / depth;
    final cubeScale = size.shortestSide * fill;
    return Offset(
      size.width / 2 + view.x * scale * cubeScale,
      size.height / 2 - view.y * scale * cubeScale,
    );
  }
}

class _ArrowCubePainter extends CustomPainter {
  final int gridCols;
  final int gridRows;
  final List<CanvasArrow> arrows;
  final List<MazeWall> walls;
  final _Quat orientation;
  final int? shakingArrowId;
  final double shakeOffset;

  static const Color primaryOrange = Color(0xFFFF550D);
  static const _Vec3 _light = _Vec3(0.28, 0.86, 0.42);

  _ArrowCubePainter({
    required this.gridCols,
    required this.gridRows,
    required this.arrows,
    required this.walls,
    required this.orientation,
    required this.shakingArrowId,
    required this.shakeOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final faces = <CubeFace>[];
    for (final face in CubeFace.values) {
      final normal = orientation.rotate(_FaceFrame.of(face).normal);
      if (normal.z > 0.015) faces.add(face);
    }
    faces.sort((a, b) {
      final za = _faceCenter(a).z;
      final zb = _faceCenter(b).z;
      return za.compareTo(zb);
    });

    for (final face in faces) {
      _paintFace(canvas, size, face);
    }
  }

  _Vec3 _faceCenter(CubeFace face) {
    final frame = _FaceFrame.of(face);
    return orientation.rotate(
      frame.origin + frame.axisU * 0.5 + frame.axisV * 0.5,
    );
  }

  void _paintFace(Canvas canvas, Size size, CubeFace face) {
    final frame = _FaceFrame.of(face);
    final normal = orientation.rotate(frame.normal);
    final lightLen = math.sqrt(
      _light.x * _light.x + _light.y * _light.y + _light.z * _light.z,
    );
    final light = _light * (1 / lightLen);
    final shade = (0.42 + 0.58 * normal.dot(light).clamp(0.0, 1.0)).clamp(0.0, 1.0).toDouble();

    final corners = [
      frame.origin,
      frame.origin + frame.axisU,
      frame.origin + frame.axisU + frame.axisV,
      frame.origin + frame.axisV,
    ];
    final projected = corners
        .map((corner) => _CubeMath.project(orientation.rotate(corner), size))
        .toList();

    final path = Path()..moveTo(projected.first.dx, projected.first.dy);
    for (var i = 1; i < projected.length; i++) {
      path.lineTo(projected[i].dx, projected[i].dy);
    }
    path.close();

    final fill = Color.lerp(const Color(0xFFD7DDE6), _baseColor(face), shade)!
        .withValues(alpha: 0.95);
    canvas.drawPath(path, Paint()..color = fill);

    final screen = _buildFaceScreen(
      frame: frame,
      size: size,
      orientation: orientation,
      gridCols: gridCols,
      gridRows: gridRows,
    );
    final edge = math.max(
          (projected[1] - projected[0]).distance,
          (projected[3] - projected[0]).distance,
        ) /
        gridCols;
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF8B95A3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (edge * 0.16).clamp(0.5, 0.5).toDouble()
        ..strokeJoin = StrokeJoin.round,
    );

    if (face == CubeFace.front && walls.isNotEmpty) {
      final wallPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = (screen.unit * 0.16).clamp(2.5, 6).toDouble()
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (final wall in walls) {
        canvas.drawLine(
          screen.map(wall.from),
          screen.map(wall.to),
          wallPaint,
        );
      }
    }

    for (final arrow in arrows) {
      if (arrow.placedOn != face || arrow.isExited) continue;
      _paintArrow(canvas, screen, arrow);
    }
  }

  Color _baseColor(CubeFace face) {
    switch (face) {
      case CubeFace.front:
        return const Color(0xFFFFFFFF);
      case CubeFace.back:
        return const Color(0xFFF3F4F6);
      case CubeFace.left:
        return const Color(0xFFF5F6F8);
      case CubeFace.right:
        return const Color(0xFFF7F8FA);
      case CubeFace.top:
        return const Color(0xFFFFFFFF);
      case CubeFace.bottom:
        return const Color(0xFFEEF0F3);
    }
  }

  void _paintArrow(Canvas canvas, _FaceScreen screen, CanvasArrow arrow) {
    final isShaking = arrow.id == shakingArrowId;
    final arrowColor = isShaking ? const Color(0xFFFF3B30) : primaryOrange;

    final activeGrid = arrow.exitDistance > 0
        ? arrow.getSnakePathPoints(arrow.exitDistance)
        : List<Offset>.from(arrow.points);
    if (activeGrid.length < 2) return;

    final tip = activeGrid.last;
    final prev = activeGrid[activeGrid.length - 2];
    final delta = tip - prev;
    final deltaLen = delta.distance;
    if (deltaLen < 0.001) return;
    final dir = delta / deltaLen;

    var points = activeGrid;
    if (isShaking && screen.unit > 0.001) {
      final perp = Offset(-dir.dy, dir.dx);
      final gridShake = shakeOffset / screen.unit * 0.35;
      points = activeGrid.map((point) => point + perp * gridShake).toList();
    }

    const shaftHalf = 0.15;
    const headLen = 0.5;
    const headHalf = 0.30;

    final headBase = points.last - dir * math.min(headLen, deltaLen * 0.7);
    final shaft = List<Offset>.from(points);
    shaft[shaft.length - 1] = headBase;

    final fill = Paint()..color = arrowColor;
    for (var i = 0; i < shaft.length - 1; i++) {
      _fillGridQuad(canvas, screen, shaft[i], shaft[i + 1], shaftHalf, fill);
    }

    final side = Offset(-dir.dy, dir.dx) * headHalf;
    _fillGridPolygon(
      canvas,
      screen,
      [points.last, headBase + side, headBase - side],
      fill,
    );
  }

  void _fillGridQuad(
    Canvas canvas,
    _FaceScreen screen,
    Offset a,
    Offset b,
    double half,
    Paint paint,
  ) {
    final delta = b - a;
    final len = delta.distance;
    if (len < 0.001) return;
    final side = Offset(-delta.dy, delta.dx) / len * half;
    _fillGridPolygon(canvas, screen, [a + side, b + side, b - side, a - side], paint);
  }

  void _fillGridPolygon(
    Canvas canvas,
    _FaceScreen screen,
    List<Offset> gridPoints,
    Paint paint,
  ) {
    if (gridPoints.length < 3) return;
    final path = Path()..moveTo(screen.map(gridPoints.first).dx, screen.map(gridPoints.first).dy);
    for (var i = 1; i < gridPoints.length; i++) {
      final pixel = screen.map(gridPoints[i]);
      path.lineTo(pixel.dx, pixel.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowCubePainter oldDelegate) => true;
}

class _FaceScreen {
  final double unit;
  final Offset Function(Offset grid) map;

  const _FaceScreen({required this.unit, required this.map});
}

/// Projects each 2D arrow point onto its cube face so the arrow stays
/// fixed to that surface while the cube turns.
_FaceScreen _buildFaceScreen({
  required _FaceFrame frame,
  required Size size,
  required _Quat orientation,
  required int gridCols,
  required int gridRows,
}) {
  Offset projectGrid(Offset grid) {
    final world = frame.gridToWorld(grid, gridCols, gridRows);
    return _CubeMath.project(orientation.rotate(world), size);
  }

  final mid = Offset(gridCols / 2, gridRows / 2);
  final center = projectGrid(mid);
  final stepU = (projectGrid(mid + const Offset(1, 0)) - center).distance;
  final stepV = (projectGrid(mid + const Offset(0, 1)) - center).distance;

  return _FaceScreen(unit: math.min(stepU, stepV), map: projectGrid);
}
