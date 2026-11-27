import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';

/// Full-screen minimalist pastel peach & cream 3D landscape background
/// for the Adventure Map dashboard.
class AdventureDashboardBackground extends StatelessWidget {
  const AdventureDashboardBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            key: ValueKey('adventure_dashboard_background'),
            painter: _AdventureBackgroundPainter(),
          ),
        ),
      ),
    );
  }
}

class _AdventureBackgroundPainter extends CustomPainter {
  const _AdventureBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;

    // 1. Full-screen warm off-white sky with a very subtle peach gradient.
    final skyRect = Offset.zero & size;
    final skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(w * 0.5, 0),
        Offset(w * 0.5, h),
        const [
          Color(0xFFFFFEFC), // Warm off-white top
          Color(0xFFFFF8F2), // Soft cream upper-mid
          Color(0xFFFFEDE0), // Delicate pastel peach mid
          Color(0xFFFFDFC7), // Warmer peach lower glow
        ],
        const [0.0, 0.36, 0.72, 1.0],
      );
    canvas.drawRect(skyRect, skyPaint);

    // Subtle upper-center soft sunlit aura keeping the stage card zone airy.
    final sunGlow = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.5, h * 0.24),
        w * 0.65,
        [
          Colors.white.withValues(alpha: 0.75),
          const Color(0xFFFFF5EC).withValues(alpha: 0.0),
        ],
      );
    canvas.drawRect(skyRect, sunGlow);

    // 2. Faint, soft clouds near the upper mountain area (kept near sides/upper sky).
    _drawSoftCloud(canvas, Offset(w * 0.18, h * 0.22), w * 0.16, 0.55);
    _drawSoftCloud(canvas, Offset(w * 0.80, h * 0.18), w * 0.19, 0.50);
    _drawSoftCloud(canvas, Offset(w * 0.48, h * 0.31), w * 0.14, 0.32);

    // 3. Distant atmospheric peach mountains (low center valley for card readability).
    _drawDistantMountains(canvas, w, h);

    // 4. Soft 3D low-poly mid mountains with sunlit & shaded facets.
    _drawMidMountains(canvas, w, h);

    // Subtle atmospheric mist fade between mid mountains and rolling hills.
    final mistPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * 0.48),
        Offset(0, h * 0.66),
        [
          const Color(0xFFFFF4EB).withValues(alpha: 0.0),
          const Color(0xFFFFF4EB).withValues(alpha: 0.42),
          const Color(0xFFFFF4EB).withValues(alpha: 0.0),
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, h * 0.48, w, h * 0.18), mistPaint);

    // Distant pine trees along outer mid-mountain slopes.
    _drawPineTree(
      canvas,
      base: Offset(w * 0.07, h * 0.57),
      height: h * 0.042,
      litColor: const Color(0xFFF6B995).withValues(alpha: 0.65),
      shadeColor: const Color(0xFFECA57B).withValues(alpha: 0.65),
      trunkColor: const Color(0xFFD89774).withValues(alpha: 0.55),
    );
    _drawPineTree(
      canvas,
      base: Offset(w * 0.93, h * 0.55),
      height: h * 0.045,
      litColor: const Color(0xFFF6B995).withValues(alpha: 0.65),
      shadeColor: const Color(0xFFECA57B).withValues(alpha: 0.65),
      trunkColor: const Color(0xFFD89774).withValues(alpha: 0.55),
    );

    // 5. Rolling pastel peach hills across lower-mid and lower sections.
    _drawRollingHills(canvas, w, h);

    // Stylized soft-3D pine trees positioned near the left and right edges.
    _drawPineTree(
      canvas,
      base: Offset(w * 0.08, h * 0.72),
      height: h * 0.056,
      litColor: const Color(0xFFF7A678),
      shadeColor: const Color(0xFFE78B5B),
      trunkColor: const Color(0xFFC97852),
    );
    _drawPineTree(
      canvas,
      base: Offset(w * 0.145, h * 0.745),
      height: h * 0.040,
      litColor: const Color(0xFFF8B48C),
      shadeColor: const Color(0xFFEA9667),
      trunkColor: const Color(0xFFCE815B),
    );
    _drawPineTree(
      canvas,
      base: Offset(w * 0.89, h * 0.705),
      height: h * 0.058,
      litColor: const Color(0xFFF7A678),
      shadeColor: const Color(0xFFE78B5B),
      trunkColor: const Color(0xFFC97852),
    );
    _drawPineTree(
      canvas,
      base: Offset(w * 0.825, h * 0.732),
      height: h * 0.042,
      litColor: const Color(0xFFF8B48C),
      shadeColor: const Color(0xFFEA9667),
      trunkColor: const Color(0xFFCE815B),
    );
    _drawPineTree(
      canvas,
      base: Offset(w * 0.06, h * 0.845),
      height: h * 0.064,
      litColor: const Color(0xFFF5935D),
      shadeColor: const Color(0xFFDF743F),
      trunkColor: const Color(0xFFB9643D),
    );
    _drawPineTree(
      canvas,
      base: Offset(w * 0.935, h * 0.835),
      height: h * 0.062,
      litColor: const Color(0xFFF5935D),
      shadeColor: const Color(0xFFDF743F),
      trunkColor: const Color(0xFFB9643D),
    );

    // 6. Warm bottom peach glow blending naturally into the landscape.
    final bottomGlow = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.5, h * 0.98),
        w * 0.85,
        [
          const Color(0xFFFF550D).withValues(alpha: 0.16),
          const Color(0xFFFF9B66).withValues(alpha: 0.10),
          const Color(0xFFFFDFC7).withValues(alpha: 0.0),
        ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, h * 0.68, w, h * 0.32), bottomGlow);
  }

  void _drawSoftCloud(
    Canvas canvas,
    Offset center,
    double width,
    double opacity,
  ) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    final h = width * 0.28;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: width, height: h),
        Radius.circular(h * 0.5),
      ),
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx - width * 0.18, center.dy - h * 0.28),
      width * 0.16,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + width * 0.08, center.dy - h * 0.36),
      width * 0.20,
      paint,
    );
  }

  void _drawDistantMountains(Canvas canvas, double w, double h) {
    final path = Path()
      ..moveTo(0, h * 0.44)
      ..lineTo(w * 0.16, h * 0.365)
      ..lineTo(w * 0.34, h * 0.435)
      ..lineTo(w * 0.54, h * 0.405)
      ..lineTo(w * 0.76, h * 0.45)
      ..lineTo(w * 0.90, h * 0.38)
      ..lineTo(w, h * 0.425)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * 0.36),
        Offset(0, h * 0.62),
        [
          const Color(0xFFFBE1CF).withValues(alpha: 0.68),
          const Color(0xFFFFF1E6).withValues(alpha: 0.45),
        ],
      );
    canvas.drawPath(path, paint);
  }

  void _drawMidMountains(Canvas canvas, double w, double h) {
    // Left mountain ridge with subtle 3D sunlit vs shaded facet
    final leftLit = Path()
      ..moveTo(0, h * 0.52)
      ..lineTo(w * 0.14, h * 0.445)
      ..lineTo(w * 0.24, h * 0.56)
      ..lineTo(0, h * 0.60)
      ..close();
    canvas.drawPath(
      leftLit,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, h * 0.445),
          Offset(0, h * 0.60),
          const [Color(0xFFFBE0CE), Color(0xFFFEECE0)],
        ),
    );

    final leftShade = Path()
      ..moveTo(w * 0.14, h * 0.445)
      ..lineTo(w * 0.44, h * 0.575)
      ..lineTo(w * 0.24, h * 0.59)
      ..close();
    canvas.drawPath(
      leftShade,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.14, h * 0.445),
          Offset(w * 0.44, h * 0.59),
          const [Color(0xFFF5C9AC), Color(0xFFFBE2D0)],
        ),
    );

    // Right mountain ridge with subtle 3D sunlit vs shaded facet
    final rightLit = Path()
      ..moveTo(w * 0.56, h * 0.57)
      ..lineTo(w * 0.82, h * 0.455)
      ..lineTo(w * 0.78, h * 0.59)
      ..close();
    canvas.drawPath(
      rightLit,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.82, h * 0.455),
          Offset(w * 0.56, h * 0.59),
          const [Color(0xFFFBE0CE), Color(0xFFFEECE0)],
        ),
    );

    final rightShade = Path()
      ..moveTo(w * 0.82, h * 0.455)
      ..lineTo(w, h * 0.53)
      ..lineTo(w, h * 0.61)
      ..lineTo(w * 0.78, h * 0.59)
      ..close();
    canvas.drawPath(
      rightShade,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.82, h * 0.455),
          Offset(w, h * 0.61),
          const [Color(0xFFF4C5A7), Color(0xFFFADFC9)],
        ),
    );
  }

  void _drawRollingHills(Canvas canvas, double w, double h) {
    // Upper-mid soft rolling peach hill
    final hill1 = Path()
      ..moveTo(0, h * 0.63)
      ..quadraticBezierTo(w * 0.26, h * 0.57, w * 0.56, h * 0.635)
      ..quadraticBezierTo(w * 0.82, h * 0.69, w, h * 0.61)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      hill1,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, h * 0.57),
          Offset(0, h * 0.82),
          const [Color(0xFFFAD8C0), Color(0xFFFEEADB)],
        ),
    );

    // Mid-lower rolling peach hill sloping from right
    final hill2 = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.28, h * 0.765, w * 0.58, h * 0.705)
      ..quadraticBezierTo(w * 0.82, h * 0.66, w, h * 0.715)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      hill2,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, h * 0.66),
          Offset(0, h * 0.90),
          const [Color(0xFFF7C4A2), Color(0xFFFCE2CE)],
        ),
    );

    // Foreground lower-left rolling hill
    final hill3 = Path()
      ..moveTo(0, h * 0.785)
      ..quadraticBezierTo(w * 0.34, h * 0.745, w * 0.72, h * 0.825)
      ..quadraticBezierTo(w * 0.88, h * 0.855, w, h * 0.82)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      hill3,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, h * 0.75),
          Offset(0, h),
          const [Color(0xFFF5B78E), Color(0xFFFBD5BA)],
        ),
    );

    // Foreground base slope at bottom
    final hill4 = Path()
      ..moveTo(0, h * 0.88)
      ..quadraticBezierTo(w * 0.42, h * 0.915, w * 0.78, h * 0.86)
      ..quadraticBezierTo(w * 0.92, h * 0.84, w, h * 0.865)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      hill4,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, h * 0.84),
          Offset(0, h),
          const [Color(0xFFF2AA7E), Color(0xFFF9C8A6)],
        ),
    );
  }

  void _drawPineTree(
    Canvas canvas, {
    required Offset base,
    required double height,
    required Color litColor,
    required Color shadeColor,
    required Color trunkColor,
  }) {
    final width = height * 0.56;

    // Soft ground shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(base.dx + width * 0.08, base.dy + height * 0.02),
        width: width * 0.75,
        height: height * 0.12,
      ),
      Paint()..color = const Color(0xFFC9784B).withValues(alpha: 0.18),
    );

    // Trunk
    final trunkW = width * 0.16;
    final trunkH = height * 0.16;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          base.dx - trunkW * 0.5,
          base.dy - trunkH,
          trunkW,
          trunkH,
        ),
        Radius.circular(trunkW * 0.3),
      ),
      Paint()..color = trunkColor,
    );

    // Three stacked low-poly 3D tiers (lit left half + shaded right half)
    final tiers = [
      (bottomY: base.dy - trunkH * 0.75, topY: base.dy - height * 0.56, halfW: width * 0.52),
      (bottomY: base.dy - height * 0.38, topY: base.dy - height * 0.78, halfW: width * 0.41),
      (bottomY: base.dy - height * 0.62, topY: base.dy - height, halfW: width * 0.28),
    ];

    final litPaint = Paint()..color = litColor;
    final shadePaint = Paint()..color = shadeColor;

    for (final tier in tiers) {
      final leftHalf = Path()
        ..moveTo(base.dx, tier.topY)
        ..lineTo(base.dx - tier.halfW, tier.bottomY)
        ..lineTo(base.dx, tier.bottomY + height * 0.02)
        ..close();
      canvas.drawPath(leftHalf, litPaint);

      final rightHalf = Path()
        ..moveTo(base.dx, tier.topY)
        ..lineTo(base.dx, tier.bottomY + height * 0.02)
        ..lineTo(base.dx + tier.halfW, tier.bottomY)
        ..close();
      canvas.drawPath(rightHalf, shadePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AdventureBackgroundPainter oldDelegate) => false;
}
