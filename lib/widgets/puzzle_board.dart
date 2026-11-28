import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
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
  final Offset parallax;

  const PuzzleBoard({
    super.key,
    this.levelId = 1,
    required this.gridCols,
    required this.gridRows,
    required this.arrows,
    this.walls = const [],
    required this.onArrowTap,
    this.parallax = Offset.zero,
  });

  @override
  State<PuzzleBoard> createState() => _PuzzleBoardState();
}

class _ExitingArrow {
  final CanvasArrow arrow;
  final double totalDistance;
  double progress = 0.0;

  _ExitingArrow({
    required this.arrow,
    required this.totalDistance,
  });
}

class _PuzzleBoardState extends State<PuzzleBoard>
    with TickerProviderStateMixin {
  static const double _restYaw = -0.72;
  static const double _restPitch = 0.50;
  static const double _defaultZoomOffset = -0.35;
  static const double _minZoomOffset = -0.50;
  static const double _maxZoomOffset = 1.0;
  // 20% faster than the original 700ms exit duration (700 / 1.2 ≈ 583ms).
  static const double _exitDurationSeconds = 0.700 / 1.20;

  int? _shakingArrowId;
  int? _pressedArrowId;
  CanvasArrow? _pendingOutcomeArrow;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  late final AnimationController _pressController;
  late final Animation<double> _pressAnimation;

  final Map<int, _ExitingArrow> _exitingArrows = {};
  late final Ticker _exitTicker;
  Duration? _exitLast;

  late _Quat _orientation = _Quat.axisAngle(const _Vec3(1, 0, 0), _restPitch)
      .multiplied(_Quat.axisAngle(const _Vec3(0, 1, 0), _restYaw));
  double _yawVelocity = 0;
  double _pitchVelocity = 0;
  double _zoomOffset = _defaultZoomOffset;
  double get _zoom => 1.0 + _zoomOffset;
  late final Ticker _spinTicker;
  Duration? _spinLast;

  int? _activePointer;
  Offset _downPos = Offset.zero;
  Offset _lastPos = Offset.zero;
  DateTime _lastMoveTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _dragged = false;
  final Map<int, Offset> _pointers = {};
  double? _lastPinchDistance;
  Offset? _lastPinchCenter;
  double? _lastPinchAngle;
  bool _pinched = false;

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

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 95),
      reverseDuration: const Duration(milliseconds: 95),
    );

    _pressAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      ),
    );

    _pressController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        final pending = _pendingOutcomeArrow;
        _pendingOutcomeArrow = null;
        if (mounted) {
          setState(() {
            _pressedArrowId = null;
          });
        } else {
          _pressedArrowId = null;
        }
        if (pending != null && mounted) {
          _triggerArrowOutcome(pending);
        }
      }
    });

    _exitTicker = createTicker(_onExitTick);
    _spinTicker = createTicker(_onSpinTick);
  }

  void _onExitTick(Duration elapsed) {
    final previous = _exitLast;
    _exitLast = elapsed;
    if (previous == null || _exitingArrows.isEmpty) return;

    final dt = (elapsed - previous).inMicroseconds / 1e6;
    if (dt <= 0) return;

    final completedIds = <int>[];
    setState(() {
      for (final entry in _exitingArrows.entries) {
        final item = entry.value;
        item.progress = (item.progress + dt / _exitDurationSeconds).clamp(0.0, 1.0);
        if (item.progress >= 1.0) {
          item.arrow.isExited = true;
          item.arrow.exitDistance = 0.0;
          completedIds.add(entry.key);
        } else {
          final eased = Curves.easeInOutQuad.transform(item.progress);
          item.arrow.exitDistance = eased * item.totalDistance;
        }
      }
      for (final id in completedIds) {
        _exitingArrows.remove(id);
      }
      if (_exitingArrows.isEmpty) {
        _exitTicker.stop();
        _exitLast = null;
      }
    });
  }

  @override
  void didUpdateWidget(PuzzleBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final levelChanged = oldWidget.levelId != widget.levelId;
    final arrowsReplaced = !identical(oldWidget.arrows, widget.arrows);
    if (!levelChanged && !arrowsReplaced) return;

    _exitingArrows.clear();
    _exitTicker.stop();
    _exitLast = null;
    _pendingOutcomeArrow = null;
    _pressedArrowId = null;
    _pressController.reset();
    _shakingArrowId = null;
    _shakeController.stop();

    if (levelChanged) {
      _orientation = _Quat.axisAngle(const _Vec3(1, 0, 0), _restPitch)
          .multiplied(_Quat.axisAngle(const _Vec3(0, 1, 0), _restYaw));
      _yawVelocity = 0;
      _pitchVelocity = 0;
      _zoomOffset = _defaultZoomOffset;
      _pointers.clear();
      _lastPinchDistance = null;
      _lastPinchCenter = null;
      _lastPinchAngle = null;
      _pinched = false;
      _spinTicker.stop();
      _spinLast = null;
    }
  }

  @override
  void dispose() {
    _spinTicker.dispose();
    _exitTicker.dispose();
    _pressController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onSpinTick(Duration elapsed) {
    final previous = _spinLast;
    _spinLast = elapsed;
    if (previous == null) return;

    final rawDt = (elapsed - previous).inMicroseconds / 1e6;
    if (rawDt <= 0) return;
    final dt = math.min(rawDt, 0.05);

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

  ({double distance, Offset center, double angle})? _currentPinchState() {
    if (_pointers.length < 2) return null;
    final positions = _pointers.values.take(2).toList();
    final diff = positions[1] - positions[0];
    return (
      distance: diff.distance,
      center: (positions[0] + positions[1]) * 0.5,
      angle: math.atan2(diff.dy, diff.dx),
    );
  }

  double _wrapAngleDelta(double delta) {
    while (delta > math.pi) {
      delta -= 2 * math.pi;
    }
    while (delta < -math.pi) {
      delta += 2 * math.pi;
    }
    return delta;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      GestureBinding.instance.pointerSignalResolver.register(event, (signal) {
        if (signal is PointerScrollEvent && mounted) {
          final factor = math.exp(-signal.scrollDelta.dy * 0.0015);
          setState(() {
            _zoomOffset =
                (_zoom * factor - 1.0).clamp(_minZoomOffset, _maxZoomOffset);
          });
        }
      });
    }
  }

  void _flushPendingPressOutcome() {
    final pending = _pendingOutcomeArrow;
    _pendingOutcomeArrow = null;
    _pressedArrowId = null;
    _pressController.reset();
    if (pending != null) {
      _triggerArrowOutcome(pending);
    }
  }

  void _cancelPressVisual() {
    _pendingOutcomeArrow = null;
    if (_pressController.value > 0.0) {
      _pressController.reverse();
    } else if (_pressedArrowId != null) {
      setState(() {
        _pressedArrowId = null;
      });
    }
  }

  void _onPointerDown(PointerDownEvent event, Size size) {
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length == 1) {
      if (_pendingOutcomeArrow != null) {
        _flushPendingPressOutcome();
      }
      _activePointer = event.pointer;
      _downPos = event.localPosition;
      _lastPos = event.localPosition;
      _lastMoveTime = DateTime.now();
      _dragged = false;
      _pinched = false;
      _yawVelocity = 0;
      _pitchVelocity = 0;
      _spinTicker.stop();
      _spinLast = null;

      final hit = _pickArrow(event.localPosition, size);
      if (hit != null) {
        setState(() {
          _pressedArrowId = hit.id;
        });
        _pressController.forward(from: 0.0);
      }
    } else {
      _cancelPressVisual();
      _activePointer = null;
      _dragged = true;
      _pinched = true;
      _yawVelocity = 0;
      _pitchVelocity = 0;
      _spinTicker.stop();
      _spinLast = null;
      _lastMoveTime = DateTime.now();
      final pinch = _currentPinchState();
      _lastPinchDistance = pinch?.distance;
      _lastPinchCenter = pinch?.center;
      _lastPinchAngle = pinch?.angle;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_pointers.containsKey(event.pointer)) {
      _pointers[event.pointer] = event.localPosition;
    }

    if (_pointers.length >= 2) {
      _cancelPressVisual();
      final pinch = _currentPinchState();
      if (pinch == null) return;

      final now = DateTime.now();
      final dt = now.difference(_lastMoveTime).inMicroseconds / 1e6;

      var newZoomOffset = _zoomOffset;
      if (_lastPinchDistance != null &&
          _lastPinchDistance! > 1.0 &&
          pinch.distance > 1.0) {
        newZoomOffset = (_zoom * (pinch.distance / _lastPinchDistance!) - 1.0)
            .clamp(_minZoomOffset, _maxZoomOffset);
      }

      final centerDelta = _lastPinchCenter != null
          ? pinch.center - _lastPinchCenter!
          : Offset.zero;
      final rollDelta = (_lastPinchAngle != null && pinch.distance > 12.0)
          ? -_wrapAngleDelta(pinch.angle - _lastPinchAngle!)
          : 0.0;

      setState(() {
        _zoomOffset = newZoomOffset;
        if (centerDelta != Offset.zero || rollDelta.abs() > 0.0005) {
          _spinBy(
            centerDelta.dx * 0.012,
            centerDelta.dy * 0.010,
            rollDelta: rollDelta,
          );
        }
      });

      if (dt > 0.001 && dt < 0.05 && centerDelta != Offset.zero) {
        final yawInst =
            (centerDelta.dx * 0.012 / dt).clamp(-4.0, 4.0).toDouble();
        final pitchInst =
            (centerDelta.dy * 0.010 / dt).clamp(-3.4, 3.4).toDouble();
        _yawVelocity = _yawVelocity * 0.45 + yawInst * 0.55;
        _pitchVelocity = _pitchVelocity * 0.45 + pitchInst * 0.55;
      }

      _lastPinchDistance = pinch.distance;
      _lastPinchCenter = pinch.center;
      _lastPinchAngle = pinch.angle;
      _lastMoveTime = now;
      return;
    }

    if (event.pointer != _activePointer) return;

    final now = DateTime.now();
    final delta = event.localPosition - _lastPos;
    if (!_dragged && (event.localPosition - _downPos).distance > 8) {
      _dragged = true;
      _cancelPressVisual();
    }

    if (_dragged) {
      final dt = now.difference(_lastMoveTime).inMicroseconds / 1e6;
      setState(() {
        _spinBy(delta.dx * 0.012, delta.dy * 0.010);
      });
      if (dt > 0.001 && dt < 0.05) {
        final yawInst = (delta.dx * 0.012 / dt).clamp(-4.0, 4.0).toDouble();
        final pitchInst = (delta.dy * 0.010 / dt).clamp(-3.4, 3.4).toDouble();
        _yawVelocity = _yawVelocity * 0.45 + yawInst * 0.55;
        _pitchVelocity = _pitchVelocity * 0.45 + pitchInst * 0.55;
      }
    }

    _lastPos = event.localPosition;
    _lastMoveTime = now;
  }

  void _onPointerUp(PointerUpEvent event, Size size) {
    _pointers.remove(event.pointer);
    if (_pointers.length < 2) {
      _lastPinchDistance = null;
      _lastPinchCenter = null;
      _lastPinchAngle = null;
    }
    if (_pointers.length == 1 && _pinched) {
      // Hand off cleanly to the remaining finger without triggering a false tap.
      final remaining = _pointers.entries.first;
      _activePointer = remaining.key;
      _lastPos = remaining.value;
      _lastMoveTime = DateTime.now();
      return;
    }
    if (_pinched) {
      if (_pointers.isEmpty) {
        _pinched = false;
        if (_yawVelocity.abs() > 0.18 || _pitchVelocity.abs() > 0.18) {
          _spinLast = null;
          _spinTicker.start();
        }
      }
      return;
    }
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
    _cancelPressVisual();
    _pointers.remove(event.pointer);
    if (_pointers.length < 2) {
      _lastPinchDistance = null;
      _lastPinchCenter = null;
      _lastPinchAngle = null;
    }
    if (_pointers.length == 1 && _pinched) {
      final remaining = _pointers.entries.first;
      _activePointer = remaining.key;
      _lastPos = remaining.value;
      _lastMoveTime = DateTime.now();
      return;
    }
    if (_pointers.isEmpty) {
      _pinched = false;
    }
    if (event.pointer != _activePointer) return;
    _activePointer = null;
    _yawVelocity = 0;
    _pitchVelocity = 0;
  }

  /// Same corridor test as the flat board, limited to arrows on this face.
  bool _isPathClear(CanvasArrow arrow) {
    final tip = arrow.tip;
    final dir = arrow.exitDirection.unitVector;
    final maxDist = math.max(widget.gridCols, widget.gridRows) + 2.0;

    for (double step = 0.4; step <= maxDist; step += 0.3) {
      final probe = Offset(tip.dx + dir.dx * step, tip.dy + dir.dy * step);

      for (final other in widget.arrows) {
        if (other.id == arrow.id ||
            other.isExited ||
            _exitingArrows.containsKey(other.id) ||
            other.placedOn != arrow.placedOn) {
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
    final tapped = _pickArrow(local, size);
    if (tapped == null) {
      _cancelPressVisual();
      return;
    }

    final isClear = _isPathClear(tapped);
    if (!isClear && _pressedArrowId == tapped.id && _pressController.value > 0.0) {
      // Blocked arrow returns smoothly from 1.05x to 1.0x first, then triggers mistake feedback.
      _pendingOutcomeArrow = tapped;
      _pressController.reverse();
      return;
    }

    _pendingOutcomeArrow = null;
    _pressedArrowId = null;
    _pressController.reset();
    _triggerArrowOutcome(tapped);
  }

  void _triggerArrowOutcome(CanvasArrow tapped) {
    final isClear = _isPathClear(tapped);

    if (isClear) {
      _exitingArrows[tapped.id] = _ExitingArrow(
        arrow: tapped,
        totalDistance: tapped.totalLength + 25.0,
      );
      if (!_exitTicker.isActive) {
        _exitLast = null;
        _exitTicker.start();
      }
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

  _Quat get _viewOrientation {
    if (widget.parallax == Offset.zero) return _orientation;
    final yaw = widget.parallax.dx * 0.11;
    final pitch = widget.parallax.dy * 0.11;
    final tiltQuat = _Quat.axisAngle(const _Vec3(1, 0, 0), pitch)
        .multiplied(_Quat.axisAngle(const _Vec3(0, 1, 0), yaw));
    return tiltQuat.multiplied(_orientation).normalized();
  }

  CanvasArrow? _pickArrow(Offset tap, Size size) {
    CanvasArrow? tapped;
    var bestRank = double.infinity;
    final activeOrientation = _viewOrientation;

    for (final face in CubeFace.values) {
      final frame = _FaceFrame.of(face);
      final normal = activeOrientation.rotate(frame.normal);
      if (normal.z <= 0.05) continue;

      final screen = _buildFaceScreen(
        frame: frame,
        size: size,
        orientation: activeOrientation,
        gridCols: widget.gridCols,
        gridRows: widget.gridRows,
        zoom: _zoom,
      );
      final slop = screen.unit * 0.72;
      final depthBias = (1.15 - normal.z) * 18;

      for (final arrow in widget.arrows) {
        if (arrow.isExited ||
            _exitingArrows.containsKey(arrow.id) ||
            arrow.placedOn != face) {
          continue;
        }
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
  void _spinBy(double yawDelta, double pitchDelta, {double rollDelta = 0.0}) {
    var turn = _Quat.axisAngle(const _Vec3(1, 0, 0), pitchDelta)
        .multiplied(_Quat.axisAngle(const _Vec3(0, 1, 0), yawDelta));
    if (rollDelta != 0.0) {
      turn = _Quat.axisAngle(const _Vec3(0, 0, 1), rollDelta).multiplied(turn);
    }
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
                onPointerDown: (event) => _onPointerDown(event, canvas),
                onPointerMove: _onPointerMove,
                onPointerUp: (event) => _onPointerUp(event, canvas),
                onPointerCancel: _onPointerCancel,
                onPointerSignal: _onPointerSignal,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_shakeAnimation, _pressAnimation]),
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
                        orientation: _viewOrientation,
                        zoom: _zoom,
                        shakingArrowId: _shakingArrowId,
                        shakeOffset: _shakeAnimation.value,
                        pressedArrowId: _pressedArrowId,
                        pressScale: _pressAnimation.value,
                        parallax: widget.parallax,
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

  static Offset project(_Vec3 view, Size size, {double zoom = 1.0}) {
    final depth = math.max(0.35, cameraZ - view.z);
    final scale = focal / depth;
    final cubeScale = size.shortestSide * fill * zoom;
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
  final double zoom;
  final int? shakingArrowId;
  final double shakeOffset;
  final int? pressedArrowId;
  final double pressScale;
  final Offset parallax;

  static const Color primaryOrange = Color(0xFFFF550D);
  static const _Vec3 _light = _Vec3(0.28, 0.86, 0.42);

  _ArrowCubePainter({
    required this.gridCols,
    required this.gridRows,
    required this.arrows,
    required this.walls,
    required this.orientation,
    required this.zoom,
    required this.shakingArrowId,
    required this.shakeOffset,
    required this.pressedArrowId,
    required this.pressScale,
    this.parallax = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintFloatingShadow(canvas, size);

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

  /// Diffused elliptical floor shadow beneath the floating 3D cube that responds
  /// dynamically to the cube's live orientation and zoom.
  void _paintFloatingShadow(Canvas canvas, Size size) {
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final sx in const [-1.0, 1.0]) {
      for (final sy in const [-1.0, 1.0]) {
        for (final sz in const [-1.0, 1.0]) {
          final projected = _CubeMath.project(
            orientation.rotate(_Vec3(sx, sy, sz)),
            size,
            zoom: zoom,
          );
          if (projected.dx < minX) minX = projected.dx;
          if (projected.dx > maxX) maxX = projected.dx;
          if (projected.dy > maxY) maxY = projected.dy;
        }
      }
    }

    final spanX = math.max(40.0, maxX - minX);
    final shadowCenter = Offset(
      (minX + maxX) * 0.5 - spanX * 0.025 - parallax.dx * 18.0,
      maxY + size.shortestSide * 0.042 * zoom - parallax.dy * 12.0,
    );

    final outerRect = Rect.fromCenter(
      center: shadowCenter,
      width: spanX * 1.06,
      height: spanX * 0.25,
    );
    canvas.drawOval(
      outerRect,
      Paint()
        ..color = const Color(0xFFE88652).withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18.0 * zoom),
    );

    final coreRect = Rect.fromCenter(
      center: shadowCenter,
      width: spanX * 0.72,
      height: spanX * 0.15,
    );
    canvas.drawOval(
      coreRect,
      Paint()
        ..color = const Color(0xFFB35E34).withValues(alpha: 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 9.0 * zoom),
    );
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
    final dynamicLight = _Vec3(
      _light.x + parallax.dx * 0.22,
      _light.y - parallax.dy * 0.22,
      _light.z,
    );
    final lightLen = math.sqrt(
      dynamicLight.x * dynamicLight.x +
          dynamicLight.y * dynamicLight.y +
          dynamicLight.z * dynamicLight.z,
    );
    final light = dynamicLight * (1 / lightLen);
    final shade = (0.42 + 0.58 * normal.dot(light).clamp(0.0, 1.0)).clamp(0.0, 1.0).toDouble();

    final corners = [
      frame.origin,
      frame.origin + frame.axisU,
      frame.origin + frame.axisU + frame.axisV,
      frame.origin + frame.axisV,
    ];
    final rotatedCorners = corners.map(orientation.rotate).toList();
    final projected = rotatedCorners
        .map((corner) => _CubeMath.project(corner, size, zoom: zoom))
        .toList();

    final path = Path()..moveTo(projected.first.dx, projected.first.dy);
    for (var i = 1; i < projected.length; i++) {
      path.lineTo(projected[i].dx, projected[i].dy);
    }
    path.close();

    // Pick the brightest and darkest corners relative to the 3D light vector
    // so the gradient shifts naturally as the cube spins while keeping 0.95 alpha.
    var litIndex = 0;
    var shadowIndex = 0;
    var maxDot = rotatedCorners.first.dot(light);
    var minDot = maxDot;
    for (var i = 1; i < rotatedCorners.length; i++) {
      final d = rotatedCorners[i].dot(light);
      if (d > maxDot) {
        maxDot = d;
        litIndex = i;
      }
      if (d < minDot) {
        minDot = d;
        shadowIndex = i;
      }
    }

    final faceBase = Color.lerp(const Color(0xFFD2D9E3), _baseColor(face), shade)!;
    final highlightColor =
        Color.lerp(faceBase, Colors.white, 0.45)!.withValues(alpha: 0.95);
    final midColor = faceBase.withValues(alpha: 0.95);
    final shadowColor =
        Color.lerp(const Color(0xFFBDC7D6), faceBase, 0.68)!.withValues(alpha: 0.95);

    final litCorner = projected[litIndex];
    final shadowCorner = projected[shadowIndex];
    final fillPaint = Paint();
    if ((litCorner - shadowCorner).distance >= 1.0) {
      fillPaint.shader = ui.Gradient.linear(
        litCorner,
        shadowCorner,
        [highlightColor, midColor, shadowColor],
        const [0.0, 0.55, 1.0],
      );
    } else {
      fillPaint.color = midColor;
    }
    canvas.drawPath(path, fillPaint);

    final screen = _buildFaceScreen(
      frame: frame,
      size: size,
      orientation: orientation,
      gridCols: gridCols,
      gridRows: gridRows,
      zoom: zoom,
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
        ..strokeWidth = (edge * 0.16).clamp(0.05, 0.05).toDouble()
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

    CanvasArrow? pressedOnFace;
    for (final arrow in arrows) {
      if (arrow.placedOn != face || arrow.isExited) continue;
      if (arrow.id == pressedArrowId) {
        pressedOnFace = arrow;
        continue;
      }
      _paintArrow(canvas, screen, arrow);
    }
    if (pressedOnFace != null) {
      _paintArrow(canvas, screen, pressedOnFace);
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
    final isPressed = arrow.id == pressedArrowId && arrow.exitDistance == 0.0;
    final scaleFactor = isPressed ? pressScale : 1.0;
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

    if (scaleFactor != 1.0) {
      var minX = points.first.dx;
      var maxX = points.first.dx;
      var minY = points.first.dy;
      var maxY = points.first.dy;
      for (final pt in points) {
        if (pt.dx < minX) minX = pt.dx;
        if (pt.dx > maxX) maxX = pt.dx;
        if (pt.dy < minY) minY = pt.dy;
        if (pt.dy > maxY) maxY = pt.dy;
      }
      final pivot = Offset((minX + maxX) * 0.5, (minY + maxY) * 0.5);
      points = points.map((pt) => pivot + (pt - pivot) * scaleFactor).toList();
    }

    final shaftHalf = 0.08 * scaleFactor;
    final headLen = 0.34 * scaleFactor;
    final headHalf = 0.17 * scaleFactor;

    final headBase =
        points.last - dir * math.min(headLen, deltaLen * scaleFactor * 0.75);
    final shaft = List<Offset>.from(points);
    shaft[shaft.length - 1] = headBase;

    final fill = Paint()..color = arrowColor;
    // Sharp flat-cut tail and crisp mitered corner joints keep every arrow a uniform width.
    for (var i = 0; i < shaft.length - 1; i++) {
      _fillGridQuad(canvas, screen, shaft[i], shaft[i + 1], shaftHalf, fill);
      if (i < shaft.length - 2) {
        _fillGridSharpCorner(
          canvas,
          screen,
          shaft[i],
          shaft[i + 1],
          shaft[i + 2],
          shaftHalf,
          fill,
        );
      }
    }

    final side = Offset(-dir.dy, dir.dx) * headHalf;
    _fillGridPolygon(
      canvas,
      screen,
      [points.last, headBase + side, headBase - side],
      fill,
    );
  }

  void _fillGridSharpCorner(
    Canvas canvas,
    _FaceScreen screen,
    Offset prev,
    Offset vertex,
    Offset next,
    double half,
    Paint paint,
  ) {
    final inDelta = vertex - prev;
    final outDelta = next - vertex;
    final inLen = inDelta.distance;
    final outLen = outDelta.distance;
    if (inLen < 0.001 || outLen < 0.001) return;

    final inDir = inDelta / inLen;
    final outDir = outDelta / outLen;
    _fillGridPolygon(
      canvas,
      screen,
      [
        vertex - inDir * half - outDir * half,
        vertex + inDir * half - outDir * half,
        vertex + inDir * half + outDir * half,
        vertex - inDir * half + outDir * half,
      ],
      paint,
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
  double zoom = 1.0,
}) {
  Offset projectGrid(Offset grid) {
    final world = frame.gridToWorld(grid, gridCols, gridRows);
    return _CubeMath.project(orientation.rotate(world), size, zoom: zoom);
  }

  final mid = Offset(gridCols / 2, gridRows / 2);
  final center = projectGrid(mid);
  final stepU = (projectGrid(mid + const Offset(1, 0)) - center).distance;
  final stepV = (projectGrid(mid + const Offset(0, 1)) - center).distance;

  return _FaceScreen(unit: math.min(stepU, stepV), map: projectGrid);
}
