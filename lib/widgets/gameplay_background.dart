import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';

/// Full-screen minimalist gameplay background with subtle warm peach glow,
/// soft wrapping ribbon, floating particles, and bottom-right orange wave.
class GameplayBackground extends StatelessWidget {
  const GameplayBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            key: ValueKey('gameplay_background'),
            painter: _GameplayBackgroundPainter(),
          ),
        ),
      ),
    );
  }
}

class _GameplayBackgroundPainter extends CustomPainter {
  const _GameplayBackgroundPainter();

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
    final cubeCenter = Offset(w * 0.5, h * 0.50);
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
    _drawSideRibbonGlow(canvas, w, h);

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

    // Main vibrant smooth orange organic wave from bottom-right corner
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
  }

  @override
  bool shouldRepaint(covariant _GameplayBackgroundPainter oldDelegate) => false;
}

/// Floating pill-shaped bottom instruction bar that demonstrates rotation
/// for 10 seconds at the start of each stage and then fades out.
class TapToRotateHintBar extends StatefulWidget {
  const TapToRotateHintBar({super.key});

  @override
  State<TapToRotateHintBar> createState() => _TapToRotateHintBarState();
}

class _TapToRotateHintBarState extends State<TapToRotateHintBar> {
  static const Color primaryOrange = Color(0xFFFF550D);

  Timer? _rotateTimer;
  Timer? _pulseResetTimer;
  Timer? _hideTimer;
  Timer? _removeTimer;

  double _turns = 0.0;
  bool _isPulsed = false;
  bool _visible = true;
  bool _removed = false;

  @override
  void initState() {
    super.initState();

    // Rotate the icon smoothly every 1.4s while visible.
    _rotateTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!mounted || !_visible) return;
      setState(() {
        _turns += 1.0;
        _isPulsed = true;
      });
      _pulseResetTimer?.cancel();
      _pulseResetTimer = Timer(const Duration(milliseconds: 520), () {
        if (mounted) {
          setState(() => _isPulsed = false);
        }
      });
    });

    // Show for 10 seconds, then fade out and disappear.
    _hideTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      _rotateTimer?.cancel();
      _pulseResetTimer?.cancel();
      setState(() {
        _visible = false;
        _isPulsed = false;
      });
      _removeTimer = Timer(const Duration(milliseconds: 420), () {
        if (mounted) {
          setState(() => _removed = true);
        }
      });
    });
  }

  @override
  void dispose() {
    _rotateTimer?.cancel();
    _pulseResetTimer?.cancel();
    _hideTimer?.cancel();
    _removeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_removed) {
      return const SizedBox.shrink();
    }

    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0.0, 0.25),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
        child: Center(
          child: Container(
            key: const ValueKey('tap_to_rotate_hint_bar'),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.90),
                  const Color(0xFFFFF4EC).withValues(alpha: 0.88),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFFFDFCC),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryOrange.withValues(alpha: 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: _isPulsed ? 1.14 : 1.0,
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeInOut,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryOrange.withValues(
                        alpha: _isPulsed ? 0.20 : 0.11,
                      ),
                    ),
                    child: AnimatedRotation(
                      turns: _turns,
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeInOutCubic,
                      child: const Icon(
                        Icons.rotate_right_rounded,
                        size: 17,
                        color: primaryOrange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                const Text(
                  'Tap to Rotate',
                  style: TextStyle(
                    color: Color(0xFF2B2D33),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
