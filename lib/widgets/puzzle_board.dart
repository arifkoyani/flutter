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
  static const double _maxPitch = 1.42;

  int? _shakingArrowId;
  int? _exitingArrowId;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  late final AnimationController _exitController;
  late Animation<double> _exitAnimation;
  CanvasArrow? _animatingArrow;

  double _yaw = _restYaw;
  double _pitch = _restPitch;
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
      _yaw = _restYaw;
      _pitch = _restPitch;
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
      _yaw = _wrapAngle(_yaw + _yawVelocity * dt);
      final nextPitch = _pitch + _pitchVelocity * dt;
      if (nextPitch > _maxPitch || nextPitch < -_maxPitch) {
        _pitch = nextPitch.clamp(-_maxPitch, _maxPitch).toDouble();
        _pitchVelocity = 0;
      } else {
        _pitch = nextPitch;
      }
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
        _yaw = _wrapAngle(_yaw - delta.dx * 0.012);
        _pitch = (_pitch - delta.dy * 0.010).clamp(-_maxPitch, _maxPitch).toDouble();
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
    final hit = _raycastFace(tap, size);
    if (hit == null) return null;

    CanvasArrow? tapped;
    var closest = double.infinity;
    for (final arrow in widget.arrows) {
      if (arrow.isExited || arrow.placedOn != hit.face) continue;
      for (var i = 0; i < arrow.points.length - 1; i++) {
        final dist = _distanceToSegment(hit.grid, arrow.points[i], arrow.points[i + 1]);
        if (dist < 0.7 && dist < closest) {
          closest = dist;
          tapped = arrow;
        }
      }
    }
    return tapped;
  }

  _FaceHit? _raycastFace(Offset tap, Size size) {
    final cubeScale = size.shortestSide * _CubeMath.fill;
    final ndcX = (tap.dx - size.width / 2) / cubeScale;
    final ndcY = (size.height / 2 - tap.dy) / cubeScale;
    final dir = _Vec3(ndcX / _CubeMath.focal, ndcY / _CubeMath.focal, -1);
    const origin = _Vec3(0, 0, _CubeMath.cameraZ);

    CubeFace? bestFace;
    Offset? bestGrid;
    var bestT = double.infinity;

    for (final face in CubeFace.values) {
      final frame = _FaceFrame.of(face);
      final normal = _CubeMath.rotate(frame.normal, _yaw, _pitch);
      if (normal.z <= 0.02) continue;

      final center = _CubeMath.rotate(
        frame.origin + frame.axisU * 0.5 + frame.axisV * 0.5,
        _yaw,
        _pitch,
      );
      final denom = normal.dot(dir);
      if (denom.abs() < 1e-5) continue;
      final t = normal.dot(center - origin) / denom;
      if (t <= 0 || t >= bestT) continue;

      final hitView = origin + dir * t;
      final hitWorld = _CubeMath.unrotate(hitView, _yaw, _pitch);
      final rel = hitWorld - frame.origin;
      final u = rel.dot(frame.axisU) / frame.axisU.dot(frame.axisU);
      final v = rel.dot(frame.axisV) / frame.axisV.dot(frame.axisV);
      if (u < -0.04 || u > 1.04 || v < -0.04 || v > 1.04) continue;

      bestT = t;
      bestFace = face;
      bestGrid = Offset(u * widget.gridCols, v * widget.gridRows);
    }

    if (bestFace == null || bestGrid == null) return null;
    return _FaceHit(bestFace, bestGrid);
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

  double _wrapAngle(double angle) {
    const twoPi = math.pi * 2;
    var wrapped = angle % twoPi;
    if (wrapped > math.pi) wrapped -= twoPi;
    if (wrapped < -math.pi) wrapped += twoPi;
    return wrapped;
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
                        yaw: _yaw,
                        pitch: _pitch,
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

class _FaceHit {
  final CubeFace face;
  final Offset grid;
  const _FaceHit(this.face, this.grid);
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

  static _Vec3 rotate(_Vec3 p, double yaw, double pitch) {
    final cy = math.cos(yaw);
    final sy = math.sin(yaw);
    final x1 = p.x * cy + p.z * sy;
    final z1 = -p.x * sy + p.z * cy;
    final cx = math.cos(pitch);
    final sx = math.sin(pitch);
    return _Vec3(x1, p.y * cx - z1 * sx, p.y * sx + z1 * cx);
  }

  static _Vec3 unrotate(_Vec3 p, double yaw, double pitch) {
    final cx = math.cos(pitch);
    final sx = math.sin(pitch);
    final y1 = p.y * cx + p.z * sx;
    final z1 = -p.y * sx + p.z * cx;
    final cy = math.cos(yaw);
    final sy = math.sin(yaw);
    return _Vec3(p.x * cy - z1 * sy, y1, p.x * sy + z1 * cy);
  }

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
  final double yaw;
  final double pitch;
  final int? shakingArrowId;
  final double shakeOffset;

  static const Color primaryOrange = Color(0xFFFF550D);
  static const _Vec3 _light = _Vec3(0.28, 0.86, 0.42);

  _ArrowCubePainter({
    required this.gridCols,
    required this.gridRows,
    required this.arrows,
    required this.walls,
    required this.yaw,
    required this.pitch,
    required this.shakingArrowId,
    required this.shakeOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintShadow(canvas, size);

    final faces = <CubeFace>[];
    for (final face in CubeFace.values) {
      final normal = _CubeMath.rotate(_FaceFrame.of(face).normal, yaw, pitch);
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
    return _CubeMath.rotate(
      frame.origin + frame.axisU * 0.5 + frame.axisV * 0.5,
      yaw,
      pitch,
    );
  }

  void _paintShadow(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.80),
        width: size.width * 0.42,
        height: size.height * 0.065,
      ),
      Paint()..color = const Color(0x14000000),
    );
  }

  void _paintFace(Canvas canvas, Size size, CubeFace face) {
    final frame = _FaceFrame.of(face);
    final normal = _CubeMath.rotate(frame.normal, yaw, pitch);
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
        .map((corner) => _CubeMath.project(_CubeMath.rotate(corner, yaw, pitch), size))
        .toList();

    final path = Path()..moveTo(projected.first.dx, projected.first.dy);
    for (var i = 1; i < projected.length; i++) {
      path.lineTo(projected[i].dx, projected[i].dy);
    }
    path.close();

    final fill = Color.lerp(const Color(0xFFD7DDE6), _baseColor(face), shade)!;
    canvas.drawPath(path, Paint()..color = fill);

    final originPx = projected.first;
    final unit = (projected[1] - originPx).distance / gridCols;
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF9AA3B2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (unit * 0.09).clamp(1.4, 2.8).toDouble()
        ..strokeJoin = StrokeJoin.round,
    );

    if (face == CubeFace.front && walls.isNotEmpty) {
      final wallPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = (unit * 0.16).clamp(2.5, 6).toDouble()
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (final wall in walls) {
        canvas.drawLine(
          _projectGrid(frame, wall.from, size),
          _projectGrid(frame, wall.to, size),
          wallPaint,
        );
      }
    }

    for (final arrow in arrows) {
      if (arrow.placedOn != face || arrow.isExited) continue;
      _paintArrow(canvas, size, frame, arrow, unit);
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

  Offset _projectGrid(_FaceFrame frame, Offset grid, Size size) {
    final world = frame.gridToWorld(grid, gridCols, gridRows);
    return _CubeMath.project(_CubeMath.rotate(world, yaw, pitch), size);
  }

  void _paintArrow(
    Canvas canvas,
    Size size,
    _FaceFrame frame,
    CanvasArrow arrow,
    double unit,
  ) {
    final isShaking = arrow.id == shakingArrowId;
    final arrowColor = isShaking ? const Color(0xFFFF3B30) : primaryOrange;

    final activeGrid = arrow.exitDistance > 0
        ? arrow.getSnakePathPoints(arrow.exitDistance)
        : List<Offset>.from(arrow.points);
    if (activeGrid.length < 2) return;

    final pixelPoints =
        activeGrid.map((point) => _projectGrid(frame, point, size)).toList();

    final tip = pixelPoints.last;
    final prev = pixelPoints[pixelPoints.length - 2];
    final angle = math.atan2(tip.dy - prev.dy, tip.dx - prev.dx);
    final shift = isShaking
        ? Offset(-math.sin(angle), math.cos(angle)) * shakeOffset
        : Offset.zero;
    if (shift != Offset.zero) {
      for (var i = 0; i < pixelPoints.length; i++) {
        pixelPoints[i] = pixelPoints[i] + shift;
      }
    }

    final shaft = Path()..moveTo(pixelPoints.first.dx, pixelPoints.first.dy);
    for (var i = 1; i < pixelPoints.length; i++) {
      shaft.lineTo(pixelPoints[i].dx, pixelPoints[i].dy);
    }

    canvas.drawPath(
      shaft,
      Paint()
        ..color = arrowColor
        ..strokeWidth = (unit * 0.22).clamp(3.4, 8.0).toDouble()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    final headTip = pixelPoints.last;
    final headPrev = pixelPoints[pixelPoints.length - 2];
    final headAngle = math.atan2(headTip.dy - headPrev.dy, headTip.dx - headPrev.dx);
    final headLength = (unit * 0.52).clamp(9.0, 18.0).toDouble();
    final headWidth = (unit * 0.42).clamp(8.0, 15.0).toDouble();

    final head = Path()
      ..moveTo(headTip.dx, headTip.dy)
      ..lineTo(
        headTip.dx - headLength * math.cos(headAngle) + (headWidth / 2) * math.sin(headAngle),
        headTip.dy - headLength * math.sin(headAngle) - (headWidth / 2) * math.cos(headAngle),
      )
      ..lineTo(
        headTip.dx - headLength * math.cos(headAngle) - (headWidth / 2) * math.sin(headAngle),
        headTip.dy - headLength * math.sin(headAngle) + (headWidth / 2) * math.cos(headAngle),
      )
      ..close();

    canvas.drawPath(head, Paint()..color = arrowColor);
    canvas.drawPath(
      head,
      Paint()
        ..color = isShaking ? const Color(0xFFFF3B30) : const Color(0xFFD63031)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ArrowCubePainter oldDelegate) => true;
}
