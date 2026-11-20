import 'dart:math' as math;
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import '../models/puzzle_level.dart';

class PuzzleBoard extends StatefulWidget {
  final int gridCols;
  final int gridRows;
  final List<CanvasArrow> arrows;
  final List<MazeWall> walls;
  final Function(CanvasArrow arrow, bool isClear) onArrowTap;

  const PuzzleBoard({
    super.key,
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
  static const Color _primaryOrange = Color(0xFFFF550D);

  CanvasArrow? _activeArrow;
  int? _activeArrowId;
  bool _tapLocked = false;

  // Tap selection: scale up + orange glow
  late final AnimationController _selectController;
  late final Animation<double> _selectScale;
  late final Animation<double> _selectGlow;

  // Clear path: accelerating exit through the border
  late final AnimationController _exitController;
  late final Animation<double> _exitDistance;
  late final Animation<double> _exitOpacity;
  double _exitTravel = 0.0;
  int _trailStep = 0;

  // Blocked path: nudge forward, bounce back, shake + red flash
  late final AnimationController _blockedController;
  late final Animation<double> _blockedForward;
  late final Animation<double> _blockedShake;
  late final Animation<double> _blockedFlash;

  // Particles
  late final Ticker _particleTicker;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();

    // ── Selection ──
    _selectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _selectScale = Tween<double>(begin: 1.0, end: 1.16).animate(
      CurvedAnimation(parent: _selectController, curve: Curves.easeOutBack),
    );
    _selectGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _selectController, curve: Curves.easeOut),
    );

    // ── Exit ──
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
    );
    _exitDistance = CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeInCubic,
    );
    _exitOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 62),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 38),
    ]).animate(_exitController);

    _exitController.addListener(_onExitTick);

    _exitController.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      final arrow = _activeArrow;
      if (arrow == null) return;

      arrow.isExited = true;
      arrow.exitOffset = 0.0;

      _spawnBurst(_exitEdgePoint(arrow), count: 18);
      _finishActive();
      widget.onArrowTap(arrow, true);
    });

    // ── Blocked ──
    _blockedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 470),
    );

    _blockedForward = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.42)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.42, end: -0.14)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.14, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 68,
      ),
    ]).animate(_blockedController);

    _blockedShake = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 18),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -5.0), weight: 6),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 6.0), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 8),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 3.0), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 3.0, end: 0.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 44),
    ]).animate(_blockedController);

    _blockedFlash = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 18),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 6),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 24),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 52),
    ]).animate(_blockedController);

    _blockedController.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      final arrow = _activeArrow;
      if (arrow == null) return;

      arrow.isShaking = false;
      arrow.exitOffset = 0.0;
      _finishActive();
      widget.onArrowTap(arrow, false);
    });

    _particleTicker = createTicker(_onParticleTick);
  }

  @override
  void dispose() {
    _particleTicker.dispose();
    _selectController.dispose();
    _exitController.dispose();
    _blockedController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  // Path check
  // ──────────────────────────────────────────────────────────────
  bool _isPathClear(CanvasArrow arrow) {
    final tip = arrow.tip;
    final dir = arrow.exitDirection.unitVector;

    for (double step = 0.4; step <= 8.0; step += 0.3) {
      final probe = Offset(tip.dx + dir.dx * step, tip.dy + dir.dy * step);

      for (final other in widget.arrows) {
        if (other.id == arrow.id || other.isExited) continue;

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

  // ──────────────────────────────────────────────────────────────
  // Input
  // ──────────────────────────────────────────────────────────────
  void _onTapDown(TapDownDetails details, Size canvasSize) {
    if (_tapLocked) return;

    const padding = 20.0;
    final usableW = canvasSize.width - padding * 2;
    final usableH = canvasSize.height - padding * 2;
    final cellW = usableW / widget.gridCols;
    final cellH = usableH / widget.gridRows;

    final tap = details.localPosition;
    final tapGrid = Offset(
      (tap.dx - padding) / cellW,
      (tap.dy - padding) / cellH,
    );

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

    final arrow = tappedArrow;
    final isClear = _isPathClear(arrow);

    _activeArrow = arrow;
    _activeArrowId = arrow.id;
    _tapLocked = true;
    setState(() {});

    _selectController.forward(from: 0.0).whenComplete(() {
      if (!mounted || _activeArrow == null) return;
      if (isClear) {
        _runExit(arrow);
      } else {
        arrow.isShaking = true;
        _blockedController.forward(from: 0.0);
      }
    });
  }

  void _runExit(CanvasArrow arrow) {
    _exitTravel = _exitDistanceFor(arrow);
    _trailStep = 0;
    _exitController.forward(from: 0.0);
  }

  void _finishActive() {
    if (!mounted) return;
    setState(() {
      _activeArrow = null;
      _activeArrowId = null;
      _tapLocked = false;
      _selectController.value = 0.0;
    });
  }

  // ──────────────────────────────────────────────────────────────
  // Exit helpers
  // ──────────────────────────────────────────────────────────────
  double _exitDistanceFor(CanvasArrow arrow) {
    final tip = arrow.tip;
    switch (arrow.exitDirection) {
      case ArrowDirection.up:
        return tip.dy + 1.2;
      case ArrowDirection.down:
        return widget.gridRows - tip.dy + 1.2;
      case ArrowDirection.left:
        return tip.dx + 1.2;
      case ArrowDirection.right:
        return widget.gridCols - tip.dx + 1.2;
    }
  }

  Offset _exitEdgePoint(CanvasArrow arrow) {
    final p = arrow.tip + arrow.exitDirection.unitVector * _exitTravel;
    return Offset(
      p.dx.clamp(0.15, widget.gridCols - 0.15).toDouble(),
      p.dy.clamp(0.15, widget.gridRows - 0.15).toDouble(),
    );
  }

  Offset _arrowHeadAt(CanvasArrow arrow) {
    return arrow.tip + arrow.exitDirection.unitVector * arrow.exitOffset;
  }

  void _onExitTick() {
    final arrow = _activeArrow;
    if (arrow == null) return;

    arrow.exitOffset = _exitDistance.value * _exitTravel;

    final step = (_exitController.value * 10).floor();
    if (step > _trailStep) {
      _trailStep = step;
      _spawnTrail(_arrowHeadAt(arrow), arrow.exitDirection.unitVector);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Particles
  // ──────────────────────────────────────────────────────────────
  void _onParticleTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }

    final dt = ((elapsed - _lastTick).inMicroseconds / 1000000.0)
        .clamp(0.0, 0.05)
        .toDouble();
    _lastTick = elapsed;
    if (dt <= 0) return;

    for (final p in _particles) {
      p.velocity += const Offset(0, 6.5) * dt;
      p.velocity *= (1 - 2.4 * dt);
      p.position += p.velocity * dt;
      p.life -= dt;
    }

    _particles.removeWhere((p) => p.life <= 0);

    if (_particles.isEmpty) {
      _particleTicker.stop();
      _lastTick = Duration.zero;
    }

    if (mounted) setState(() {});
  }

  void _ensureTicker() {
    if (!_particleTicker.isActive) {
      _lastTick = Duration.zero;
      _particleTicker.start();
    }
  }

  Color _particleColor() {
    final roll = _random.nextDouble();
    if (roll < 0.35) return _primaryOrange;
    if (roll < 0.6) return const Color(0xFFFFA726);
    if (roll < 0.8) return const Color(0xFFFFD54F);
    return Colors.white;
  }

  void _spawnBurst(Offset gridPos, {int count = 16}) {
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 2.0 + _random.nextDouble() * 5.5;
      final life = 0.35 + _random.nextDouble() * 0.4;
      _particles.add(_Particle(
        position: gridPos,
        velocity: Offset(math.cos(angle), math.sin(angle)) * speed,
        life: life,
        maxLife: life,
        size: 2.0 + _random.nextDouble() * 3.2,
        color: _particleColor(),
      ));
    }
    _ensureTicker();
  }

  void _spawnTrail(Offset gridPos, Offset dir) {
    for (int i = 0; i < 3; i++) {
      final jitter = Offset(
        _random.nextDouble() - 0.5,
        _random.nextDouble() - 0.5,
      );
      final life = 0.22 + _random.nextDouble() * 0.2;
      _particles.add(_Particle(
        position: gridPos + jitter * 0.2,
        velocity: -dir * (1.2 + _random.nextDouble() * 1.8) + jitter * 1.4,
        life: life,
        maxLife: life,
        size: 1.6 + _random.nextDouble() * 2.2,
        color: _particleColor(),
      ));
    }
    _ensureTicker();
  }

  // ──────────────────────────────────────────────────────────────
  // Utils
  // ──────────────────────────────────────────────────────────────
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

        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: GestureDetector(
                onTapDown: (details) => _onTapDown(details, Size(size, size)),
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _selectController,
                    _exitController,
                    _blockedController,
                  ]),
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(size, size),
                      painter: _MazeArrowCanvasPainter(
                        gridCols: widget.gridCols,
                        gridRows: widget.gridRows,
                        arrows: widget.arrows,
                        walls: widget.walls,
                        activeArrowId: _activeArrowId,
                        selectionScale: _selectScale.value,
                        glow: _selectGlow.value,
                        blockedForward: _blockedForward.value,
                        blockedShake: _blockedShake.value,
                        blockedFlash: _blockedFlash.value,
                        exitOpacity: _exitOpacity.value,
                        particles: _particles,
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

class _Particle {
  Offset position;
  Offset velocity;
  double life;
  final double maxLife;
  final double size;
  final Color color;

  _Particle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.color,
  });
}

/// Canvas Painter that renders the Anatomy of the Arrow & Maze Walls
class _MazeArrowCanvasPainter extends CustomPainter {
  final int gridCols;
  final int gridRows;
  final List<CanvasArrow> arrows;
  final List<MazeWall> walls;
  final int? activeArrowId;
  final double selectionScale;
  final double glow;
  final double blockedForward;
  final double blockedShake;
  final double blockedFlash;
  final double exitOpacity;
  final List<_Particle> particles;

  static const Color primaryOrange = Color(0xFFFF550D);
  static const Color dangerRed = Color(0xFFE53935);

  _MazeArrowCanvasPainter({
    required this.gridCols,
    required this.gridRows,
    required this.arrows,
    required this.walls,
    this.activeArrowId,
    required this.selectionScale,
    required this.glow,
    required this.blockedForward,
    required this.blockedShake,
    required this.blockedFlash,
    required this.exitOpacity,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 20.0;
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

    // 1. Maze walls
    final wallPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final wall in walls) {
      canvas.drawLine(toPixel(wall.from), toPixel(wall.to), wallPaint);
    }

    // 2. Arrows
    for (final arrow in arrows) {
      if (arrow.isExited) continue;

      final isActive = arrow.id == activeArrowId;
      final dir = arrow.exitDirection.unitVector;

      final forwardGrid = arrow.exitOffset + (isActive ? blockedForward : 0.0);
      final forwardShift = Offset(dir.dx * forwardGrid * cellW, dir.dy * forwardGrid * cellH);

      final shakeShift = isActive && blockedShake != 0.0
          ? (dir.dx != 0 ? Offset(0, blockedShake) : Offset(blockedShake, 0))
          : Offset.zero;

      var pixelPoints = arrow.points
          .map((p) => toPixel(p) + forwardShift + shakeShift)
          .toList();
      if (pixelPoints.length < 2) continue;

      // Selection scale around the arrow's centroid
      final scale = isActive ? selectionScale : 1.0;
      if (scale != 1.0) {
        var cx = 0.0;
        var cy = 0.0;
        for (final p in pixelPoints) {
          cx += p.dx;
          cy += p.dy;
        }
        cx /= pixelPoints.length;
        cy /= pixelPoints.length;
        pixelPoints = pixelPoints
            .map((p) => Offset(
                  cx + (p.dx - cx) * scale,
                  cy + (p.dy - cy) * scale,
                ))
            .toList();
      }

      final flash = isActive ? blockedFlash : 0.0;
      final opacity = (isActive ? exitOpacity : 1.0).clamp(0.0, 1.0);
      final arrowColor = Color.lerp(primaryOrange, dangerRed, flash)!
          .withValues(alpha: opacity);
      final currentGlow = isActive ? (glow * (1.0 - flash)).clamp(0.0, 1.0) : 0.0;

      // ─── A. Build shaft path ───
      final shaftPath = Path();
      shaftPath.moveTo(pixelPoints.first.dx, pixelPoints.first.dy);
      for (int i = 1; i < pixelPoints.length; i++) {
        shaftPath.lineTo(pixelPoints[i].dx, pixelPoints[i].dy);
      }

      // ─── B. Build arrowhead triangle ───
      final tip = pixelPoints.last;
      final prev = pixelPoints[pixelPoints.length - 2];
      final angle = math.atan2(tip.dy - prev.dy, tip.dx - prev.dx);

      const headLength = 18.0;
      const headWidth = 15.0;

      final headPath = Path();
      headPath.moveTo(tip.dx, tip.dy);
      headPath.lineTo(
        tip.dx - headLength * math.cos(angle) + (headWidth / 2) * math.sin(angle),
        tip.dy - headLength * math.sin(angle) - (headWidth / 2) * math.cos(angle),
      );
      headPath.lineTo(
        tip.dx - headLength * math.cos(angle) - (headWidth / 2) * math.sin(angle),
        tip.dy - headLength * math.sin(angle) + (headWidth / 2) * math.cos(angle),
      );
      headPath.close();

      // ─── C. Orange selection glow ───
      if (currentGlow > 0.01) {
        final glowPaint = Paint()
          ..color = primaryOrange.withValues(alpha: 0.55 * currentGlow * opacity)
          ..strokeWidth = 17
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
        canvas.drawPath(shaftPath, glowPaint);

        final glowHead = Paint()
          ..color = primaryOrange.withValues(alpha: 0.5 * currentGlow * opacity)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
        canvas.drawPath(headPath, glowHead);
      }

      // ─── D. Shaft ───
      final shaftPaint = Paint()
        ..color = arrowColor
        ..strokeWidth = 7.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(shaftPath, shaftPaint);

      // ─── E. Arrowhead ───
      final headPaint = Paint()
        ..color = arrowColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(headPath, headPaint);

      final headStroke = Paint()
        ..color = Color.lerp(
          const Color(0xFFD63031),
          dangerRed,
          flash,
        )!.withValues(alpha: opacity)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(headPath, headStroke);
    }

    // 3. Particles on top
    for (final p in particles) {
      final t = (p.life / p.maxLife).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: t)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(toPixel(p.position), p.size * (0.5 + 0.5 * t), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MazeArrowCanvasPainter oldDelegate) {
    return true;
  }
}
