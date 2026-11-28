import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';

/// Full-screen minimalist gameplay background with subtle warm peach glow,
/// soft wrapping ribbon, floating particles, and bottom-right orange wave.
class GameplayBackground extends StatelessWidget {
  final Offset parallax;

  const GameplayBackground({
    super.key,
    this.parallax = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            key: const ValueKey('gameplay_background'),
            painter: _GameplayBackgroundPainter(parallax: parallax),
          ),
        ),
      ),
    );
  }
}

class _GameplayBackgroundPainter extends CustomPainter {
  final Offset parallax;

  const _GameplayBackgroundPainter({this.parallax = Offset.zero});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // 1. Clean white/off-white full-screen canvas with subtle warm peach center gradient.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.5, 0),
          Offset(w * 0.5, h),
          const [
            Color(0xFFFFFFFF),
            Color(0xFFFFFCF9),
            Color(0xFFFFF6EE),
          ],
          const [0.0, 0.52, 1.0],
        ),
    );

    // Soft ambient warm peach glow behind the main 3D cube area.
    final cubeCenter = Offset(
      w * 0.5 - parallax.dx * 16.0,
      h * 0.50 - parallax.dy * 16.0,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          cubeCenter,
          math.max(w, h) * 0.44,
          [
            const Color(0xFFFFB285).withValues(alpha: 0.20),
            const Color(0xFFFFDFC9).withValues(alpha: 0.10),
            const Color(0xFFFFFFFF).withValues(alpha: 0.0),
          ],
          const [0.0, 0.52, 1.0],
        ),
    );

    // 2. Subtle peach curved ribbon/glow wrapping behind the sides of the cube.
    canvas.save();
    canvas.translate(-parallax.dx * 24.0, -parallax.dy * 20.0);
    _drawSideRibbonGlow(canvas, w, h);
    canvas.restore();

    // 3. Compact abstract curved orange wave emerging from the bottom-right corner.
    _drawBottomRightWave(canvas, w, h);
  }

  void _drawSideRibbonGlow(Canvas canvas, double w, double h) {
    final ribbonPath = Path()
      ..moveTo(-w * 0.08, h * 0.44)
      ..cubicTo(
        w * 0.16,
        h * 0.34,
        w * 0.36,
        h * 0.62,
        w * 0.64,
        h * 0.52,
      )
      ..cubicTo(
        w * 0.84,
        h * 0.45,
        w * 0.96,
        h * 0.37,
        w * 1.08,
        h * 0.42,
      );

    canvas.drawPath(
      ribbonPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.11
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18.0)
        ..shader = ui.Gradient.linear(
          Offset(0, h * 0.46),
          Offset(w, h * 0.46),
          [
            const Color(0xFFFFD8BF).withValues(alpha: 0.0),
            const Color(0xFFFFC8A4).withValues(alpha: 0.24),
            const Color(0xFFFFB88D).withValues(alpha: 0.22),
            const Color(0xFFFFD8BF).withValues(alpha: 0.0),
          ],
          const [0.0, 0.28, 0.72, 1.0],
        ),
    );

    // Delicate inner peach curve accent
    final accentPath = Path()
      ..moveTo(-w * 0.04, h * 0.58)
      ..quadraticBezierTo(w * 0.24, h * 0.65, w * 0.48, h * 0.56)
      ..quadraticBezierTo(w * 0.78, h * 0.46, w * 1.04, h * 0.54);

    canvas.drawPath(
      accentPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.032
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0)
        ..shader = ui.Gradient.linear(
          Offset(0, h * 0.56),
          Offset(w, h * 0.56),
          [
            const Color(0xFFFFCFAF).withValues(alpha: 0.0),
            const Color(0xFFFFBA8F).withValues(alpha: 0.20),
            const Color(0xFFFFCFAF).withValues(alpha: 0.0),
          ],
          const [0.0, 0.5, 1.0],
        ),
    );
  }

  void _drawBottomRightWave(Canvas canvas, double w, double h) {
    // Soft outer pastel peach halo wave (50% compact corner scale)
    canvas.save();
    canvas.translate(-parallax.dx * 10.0, -parallax.dy * 9.0);
    final outerWave = Path()
      ..moveTo(w * 0.67, h)
      ..cubicTo(
        w * 0.72,
        h * 0.935,
        w * 0.82,
        h * 0.94,
        w * 0.89,
        h * 0.895,
      )
      ..cubicTo(
        w * 0.945,
        h * 0.86,
        w * 0.975,
        h * 0.83,
        w,
        h * 0.82,
      )
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(
      outerWave,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.725, h),
          Offset(w, h * 0.825),
          [
            const Color(0xFFFFD3B5).withValues(alpha: 0.42),
            const Color(0xFFFFAD7A).withValues(alpha: 0.55),
          ],
        ),
    );
    canvas.restore();

    // Main vibrant smooth orange organic wave from bottom-right corner
    canvas.save();
    canvas.translate(-parallax.dx * 15.0, -parallax.dy * 13.0);
    final mainWave = Path()
      ..moveTo(w * 0.73, h)
      ..cubicTo(
        w * 0.78,
        h * 0.955,
        w * 0.85,
        h * 0.955,
        w * 0.915,
        h * 0.915,
      )
      ..cubicTo(
        w * 0.96,
        h * 0.885,
        w * 0.985,
        h * 0.86,
        w,
        h * 0.85,
      )
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(
      mainWave,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.75, h),
          Offset(w, h * 0.85),
          const [
            Color(0xFFFF8847),
            Color(0xFFFF550D),
            Color(0xFFE94600),
          ],
          const [0.0, 0.58, 1.0],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GameplayBackgroundPainter oldDelegate) =>
      oldDelegate.parallax != parallax;
}

enum _HintSlotPhase { shiftSide, rotateAngle, zoomInOut, none }

/// Subtle monochrome hint slot positioned below the cube that displays:
/// - `0%–30%`: `"Shift any side"` alongside the 4-way directional tutorial
/// - `30%–50%` (up to 10s): slow rotate icon + `"rotate any angle"`
/// - `50%–75%`: `"zoom in & out"` alongside the two-thumb pinch tutorial
class TapToRotateHintBar extends StatefulWidget {
  final int totalDurationSeconds;
  final int remainingSeconds;
  final bool isActive;

  const TapToRotateHintBar({
    super.key,
    required this.totalDurationSeconds,
    required this.remainingSeconds,
    required this.isActive,
  });

  @override
  State<TapToRotateHintBar> createState() => _TapToRotateHintBarState();
}

class _TapToRotateHintBarState extends State<TapToRotateHintBar> {
  static const TextStyle _hintTextStyle = TextStyle(
    color: Color(0xFF6B7280),
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  Timer? _rotateTimer;
  double _turns = 0.0;

  _HintSlotPhase get _phase {
    if (!widget.isActive || widget.totalDurationSeconds <= 0) {
      return _HintSlotPhase.none;
    }
    final elapsed = (widget.totalDurationSeconds - widget.remainingSeconds)
        .clamp(0, widget.totalDurationSeconds);
    final progress = elapsed / widget.totalDurationSeconds;
    if (progress < 0.30) {
      return _HintSlotPhase.shiftSide;
    }
    if (progress < 0.50) {
      final startSec = (widget.totalDurationSeconds * 0.30).ceil();
      final elapsedSinceStart = elapsed - startSec;
      if (elapsedSinceStart >= 0 && elapsedSinceStart < 10) {
        return _HintSlotPhase.rotateAngle;
      }
      return _HintSlotPhase.none;
    }
    if (progress < 0.75) {
      return _HintSlotPhase.zoomInOut;
    }
    return _HintSlotPhase.none;
  }

  @override
  void initState() {
    super.initState();
    _syncRotateTimer();
  }

  @override
  void didUpdateWidget(covariant TapToRotateHintBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRotateTimer();
  }

  void _syncRotateTimer() {
    final shouldSpin = _phase == _HintSlotPhase.rotateAngle;
    if (shouldSpin && _rotateTimer == null) {
      _rotateTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
        if (mounted && _phase == _HintSlotPhase.rotateAngle) {
          setState(() => _turns += 1.0);
        }
      });
    } else if (!shouldSpin && _rotateTimer != null) {
      _rotateTimer?.cancel();
      _rotateTimer = null;
    }
  }

  @override
  void dispose() {
    _rotateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phase;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: switch (phase) {
        _HintSlotPhase.shiftSide => const Text(
            'Shift any side',
            key: ValueKey('hint_shift_any_side'),
            style: _hintTextStyle,
          ),
        _HintSlotPhase.rotateAngle => Row(
            key: const ValueKey('tap_to_rotate_hint_bar'),
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedRotation(
                turns: _turns,
                duration: const Duration(milliseconds: 1600),
                curve: Curves.easeInOut,
                child: const Icon(
                  Icons.rotate_right_rounded,
                  size: 22,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 6),
              const Text('rotate any angle', style: _hintTextStyle),
            ],
          ),
        _HintSlotPhase.zoomInOut => const Text(
            'zoom in & out',
            key: ValueKey('hint_zoom_in_out'),
            style: _hintTextStyle,
          ),
        _HintSlotPhase.none => const SizedBox.shrink(
            key: ValueKey('tap_to_rotate_hint_hidden'),
          ),
      },
    );
  }
}

enum _CubeTutorialPhase { none, rotate, pinchZoom }

/// Percentage-timed non-blocking tutorial overlay positioned around the 3D cube:
/// - 0% to 30% of level duration: directional rotate arrows on all 4 sides
/// - 50% to 75% of level duration: two-thumb pinch zoom-in / zoom-out cue
class CubeTutorialOverlay extends StatefulWidget {
  final int totalDurationSeconds;
  final int remainingSeconds;
  final bool isActive;

  const CubeTutorialOverlay({
    super.key,
    required this.totalDurationSeconds,
    required this.remainingSeconds,
    required this.isActive,
  });

  @override
  State<CubeTutorialOverlay> createState() => _CubeTutorialOverlayState();
}

class _CubeTutorialOverlayState extends State<CubeTutorialOverlay> {
  static const Color primaryOrange = Color(0xFFFF550D);

  Timer? _motionTimer;
  bool _motionForward = false;

  _CubeTutorialPhase get _phase {
    if (!widget.isActive || widget.totalDurationSeconds <= 0) {
      return _CubeTutorialPhase.none;
    }
    final elapsed = (widget.totalDurationSeconds - widget.remainingSeconds)
        .clamp(0, widget.totalDurationSeconds);
    final progress = elapsed / widget.totalDurationSeconds;
    if (progress < 0.30) {
      return _CubeTutorialPhase.rotate;
    }
    if (progress >= 0.50 && progress < 0.75) {
      return _CubeTutorialPhase.pinchZoom;
    }
    return _CubeTutorialPhase.none;
  }

  @override
  void initState() {
    super.initState();
    _syncMotionTimer();
  }

  @override
  void didUpdateWidget(covariant CubeTutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotionTimer();
  }

  void _syncMotionTimer() {
    final shouldRun = _phase != _CubeTutorialPhase.none;
    if (shouldRun && _motionTimer == null) {
      _motionTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
        if (mounted) {
          setState(() => _motionForward = !_motionForward);
        }
      });
    } else if (!shouldRun && _motionTimer != null) {
      _motionTimer?.cancel();
      _motionTimer = null;
      _motionForward = false;
    }
  }

  @override
  void dispose() {
    _motionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phase;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: switch (phase) {
        _CubeTutorialPhase.rotate => _buildRotateTutorial(),
        _CubeTutorialPhase.pinchZoom => _buildPinchZoomTutorial(),
        _CubeTutorialPhase.none => const SizedBox.shrink(
            key: ValueKey('cube_tutorial_hidden'),
          ),
      },
    );
  }

  Widget _buildRotateTutorial() {
    return Stack(
      key: const ValueKey('cube_rotate_tutorial'),
      children: [
        // Top vertical rotate icon close to the cube
        Align(
          alignment: const Alignment(0.0, -0.56),
          child: AnimatedSlide(
            offset: _motionForward ? const Offset(0, -0.18) : Offset.zero,
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeInOut,
            child: _buildTutorialBadge(Icons.keyboard_arrow_up_rounded),
          ),
        ),
        // Bottom vertical rotate icon close to the cube
        Align(
          alignment: const Alignment(0.0, 0.56),
          child: AnimatedSlide(
            offset: _motionForward ? const Offset(0, 0.18) : Offset.zero,
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeInOut,
            child: _buildTutorialBadge(Icons.keyboard_arrow_down_rounded),
          ),
        ),
        // Left horizontal rotate icon close to the cube
        Align(
          alignment: const Alignment(-0.96, 0.0),
          child: AnimatedSlide(
            offset: _motionForward ? const Offset(-0.18, 0) : Offset.zero,
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeInOut,
            child: _buildTutorialBadge(Icons.keyboard_arrow_left_rounded),
          ),
        ),
        // Right horizontal rotate icon close to the cube
        Align(
          alignment: const Alignment(0.96, 0.0),
          child: AnimatedSlide(
            offset: _motionForward ? const Offset(0.18, 0) : Offset.zero,
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeInOut,
            child: _buildTutorialBadge(Icons.keyboard_arrow_right_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildPinchZoomTutorial() {
    return Stack(
      key: const ValueKey('cube_zoom_tutorial'),
      children: [
        // Upper-left thumb sliding diagonally outward/inward
        Align(
          alignment: const Alignment(-0.42, -0.42),
          child: AnimatedSlide(
            offset: _motionForward
                ? const Offset(-0.26, -0.26)
                : const Offset(0.14, 0.14),
            duration: const Duration(milliseconds: 560),
            curve: Curves.easeInOutCubic,
            child: _buildThumbChip(
              icon: Icons.touch_app_rounded,
              quarterTurns: -1,
            ),
          ),
        ),
        // Lower-right thumb sliding opposite to demonstrate two-thumb pinch
        Align(
          alignment: const Alignment(0.42, 0.42),
          child: AnimatedSlide(
            offset: _motionForward
                ? const Offset(0.26, 0.26)
                : const Offset(-0.14, -0.14),
            duration: const Duration(milliseconds: 560),
            curve: Curves.easeInOutCubic,
            child: _buildThumbChip(
              icon: Icons.touch_app_rounded,
              quarterTurns: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTutorialBadge(IconData icon) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.88),
        border: Border.all(color: const Color(0xFFFFD8C2), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, size: 20, color: primaryOrange),
    );
  }

  Widget _buildThumbChip({
    required IconData icon,
    required int quarterTurns,
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.92),
        border: Border.all(color: primaryOrange.withValues(alpha: 0.45), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: Icon(icon, size: 19, color: primaryOrange),
      ),
    );
  }
}
