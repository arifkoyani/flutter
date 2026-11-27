import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';

/// Renders soft-3D isometric game illustrations for Stages 1–10 on the
/// Adventure Map cards using consistent isometric perspective & lighting.
class Stage3DIllustration extends StatelessWidget {
  final int stageId;
  final bool isSelected;
  final bool isUnlocked;

  const Stage3DIllustration({
    super.key,
    required this.stageId,
    required this.isSelected,
    required this.isUnlocked,
  });

  static bool supportsStage(int stageId) =>
      stageId >= 1 && stageId <= 10;

  @override
  Widget build(BuildContext context) {
    final painter = switch (stageId) {
      1 => _Compass3DPainter(isSelected: isSelected),
      2 => _Forest3DPainter(isSelected: isSelected),
      3 => _Maze3DPainter(isSelected: isSelected),
      4 => _Desert3DPainter(isSelected: isSelected),
      5 => _FinalCube3DPainter(isSelected: isSelected),
      6 => _FrozenPeaks3DPainter(isSelected: isSelected),
      7 => _LavaKingdom3DPainter(isSelected: isSelected),
      8 => _OceanDepths3DPainter(isSelected: isSelected),
      9 => _SkyIslands3DPainter(isSelected: isSelected),
      10 => _CrystalTemple3DPainter(isSelected: isSelected),
      _ => null,
    };

    if (painter == null) {
      return const SizedBox.shrink();
    }

    Widget artwork = SizedBox(
      width: 96,
      height: 78,
      child: RepaintBoundary(
        child: CustomPaint(
          key: ValueKey('stage_${stageId}_3d_illustration'),
          painter: painter,
        ),
      ),
    );

    if (!isUnlocked) {
      artwork = Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0.72, child: artwork),
          Positioned(
            right: 4,
            top: 2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE4E4E4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 13,
                color: Color(0xFF888888),
              ),
            ),
          ),
        ],
      );
    }

    return artwork;
  }
}

/// Shared soft-3D primitive helpers (ambient shadows, pebbles, and foliage).
class _StageArtHelpers {
  static void drawGroundShadow(
    Canvas canvas,
    Offset center,
    double rx,
    double ry, {
    double alpha = 0.22,
    double blur = 6.0,
  }) {
    final paint = Paint()
      ..color = const Color(0xFF3A1809).withValues(alpha: alpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      paint,
    );
  }

  static void drawRock(
    Canvas canvas,
    Offset center,
    double rx,
    double ry, {
    Color lit = const Color(0xFFE7DBD0),
    Color mid = const Color(0xFFBBAEA2),
    Color shade = const Color(0xFF8C7E73),
  }) {
    drawGroundShadow(
      canvas,
      Offset(center.dx + rx * 0.12, center.dy + ry * 0.55),
      rx * 1.05,
      ry * 0.62,
      alpha: 0.24,
      blur: 3.0,
    );

    final rect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
    final rockPath = Path()
      ..moveTo(center.dx - rx, center.dy + ry * 0.22)
      ..quadraticBezierTo(
        center.dx - rx * 0.85,
        center.dy - ry * 0.92,
        center.dx - rx * 0.1,
        center.dy - ry,
      )
      ..quadraticBezierTo(
        center.dx + rx * 0.85,
        center.dy - ry * 0.88,
        center.dx + rx,
        center.dy + ry * 0.18,
      )
      ..quadraticBezierTo(
        center.dx + rx * 0.5,
        center.dy + ry,
        center.dx - rx * 0.2,
        center.dy + ry * 0.95,
      )
      ..quadraticBezierTo(
        center.dx - rx * 0.85,
        center.dy + ry * 0.85,
        center.dx - rx,
        center.dy + ry * 0.22,
      )
      ..close();

    canvas.drawPath(
      rockPath,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          [lit, mid, shade],
          const [0.0, 0.52, 1.0],
        ),
    );

    // Subtle upper-left specular highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - rx * 0.28, center.dy - ry * 0.34),
        width: rx * 0.72,
        height: ry * 0.42,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.42),
    );
  }

  static void drawBushCluster(
    Canvas canvas,
    Offset center,
    double scale,
  ) {
    drawGroundShadow(
      canvas,
      Offset(center.dx + 1.5 * scale, center.dy + 4.0 * scale),
      9.5 * scale,
      4.5 * scale,
      alpha: 0.22,
      blur: 3.5,
    );

    void drawLeafBall(Offset c, double r, Color top, Color bottom) {
      final rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(c.dx - r * 0.35, c.dy - r * 0.35),
            r * 1.4,
            [top, bottom],
          ),
      );
      canvas.drawCircle(
        Offset(c.dx - r * 0.28, c.dy - r * 0.3),
        r * 0.26,
        Paint()..color = Colors.white.withValues(alpha: 0.28),
      );
      // Warm rim bounce on lower edge
      canvas.drawArc(
        rect.deflate(0.6),
        0.35,
        1.4,
        false,
        Paint()
          ..color = const Color(0xFFFFD8BD).withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    drawLeafBall(
      Offset(center.dx - 4.8 * scale, center.dy + 0.8 * scale),
      4.2 * scale,
      const Color(0xFF66C177),
      const Color(0xFF2D7642),
    );
    drawLeafBall(
      Offset(center.dx + 4.8 * scale, center.dy + 1.2 * scale),
      3.8 * scale,
      const Color(0xFF5AB66C),
      const Color(0xFF266838),
    );
    drawLeafBall(
      Offset(center.dx, center.dy - 1.6 * scale),
      5.0 * scale,
      const Color(0xFF83D98F),
      const Color(0xFF398C4E),
    );
  }

  static void drawLeafSprout(
    Canvas canvas,
    Offset base,
    double scale, {
    double tilt = -0.3,
  }) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(tilt);

    void drawLeaf(double angle, double length, double width, bool bright) {
      canvas.save();
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-width, -length * 0.48, 0, -length)
        ..quadraticBezierTo(width, -length * 0.48, 0, 0)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, -length),
            Offset(width, 0),
            bright
                ? const [Color(0xFF8EE19A), Color(0xFF429858)]
                : const [Color(0xFF6BC77B), Color(0xFF2E7541)],
          ),
      );
      canvas.restore();
    }

    drawLeaf(-0.42, 9.5 * scale, 3.3 * scale, true);
    drawLeaf(0.12, 11.2 * scale, 3.6 * scale, true);
    drawLeaf(0.58, 8.2 * scale, 2.9 * scale, false);

    canvas.restore();
  }
}

/// Stage 1: Soft-3D orange compass with raised rim, detailed needle, glossy dial,
/// decorative rocks, and green plants around the base.
class _Compass3DPainter extends CustomPainter {
  final bool isSelected;

  const _Compass3DPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.48;
    final rx = size.width * 0.34;
    final ry = rx * 0.62;
    final depth = size.height * 0.14;

    // 1. Soft ground shadow beneath the compass puck
    _StageArtHelpers.drawGroundShadow(
      canvas,
      Offset(cx + 2, cy + depth + ry * 0.25),
      rx * 1.15,
      ry * 1.06,
      alpha: isSelected ? 0.34 : 0.24,
      blur: 7.0,
    );

    // Back-left foliage peeking behind the compass rim
    _StageArtHelpers.drawLeafSprout(
      canvas,
      Offset(cx - rx * 0.88, cy + depth * 0.15),
      0.85,
      tilt: -0.45,
    );

    // 2. Extruded 3D cylindrical rim wall
    final topRimRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: rx * 2,
      height: ry * 2,
    );
    final bottomRimRect = Rect.fromCenter(
      center: Offset(cx, cy + depth),
      width: rx * 2,
      height: ry * 2,
    );

    final wallPath = Path()
      ..moveTo(topRimRect.left, cy)
      ..arcTo(topRimRect, math.pi, -math.pi, false)
      ..lineTo(bottomRimRect.right, cy + depth)
      ..arcTo(bottomRimRect, 0, math.pi, false)
      ..close();

    canvas.drawPath(
      wallPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(topRimRect.left, cy),
          Offset(topRimRect.right, cy + depth),
          isSelected
              ? const [
                  Color(0xFFFFB28A),
                  Color(0xFFE85214),
                  Color(0xFF9F2900),
                ]
              : const [
                  Color(0xFFFF8C52),
                  Color(0xFFFF550D),
                  Color(0xFFB53200),
                ],
          const [0.0, 0.45, 1.0],
        ),
    );

    // 3. Top raised circular bezel ring
    canvas.drawOval(
      topRimRect,
      Paint()
        ..shader = ui.Gradient.linear(
          topRimRect.topLeft,
          topRimRect.bottomRight,
          isSelected
              ? const [Color(0xFFFFE5D4), Color(0xFFFF884D), Color(0xFFD64006)]
              : const [Color(0xFFFF9862), Color(0xFFFF550D), Color(0xFFCE3B04)],
          const [0.0, 0.52, 1.0],
        ),
    );

    // Crisp specular highlight arc on the top-left raised rim
    canvas.drawArc(
      topRimRect.deflate(1.2),
      math.pi * 1.05,
      math.pi * 0.72,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: isSelected ? 0.72 : 0.58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // 4. Inner recessed compass dial
    final dialRx = rx * 0.74;
    final dialRy = ry * 0.72;
    final dialCenter = Offset(cx, cy + 1.2);
    final dialRect = Rect.fromCenter(
      center: dialCenter,
      width: dialRx * 2,
      height: dialRy * 2,
    );

    // Beveled inner rim wall drop shadow
    canvas.drawOval(
      dialRect.inflate(1.8),
      Paint()..color = const Color(0xFF8A2200).withValues(alpha: 0.35),
    );

    canvas.drawOval(
      dialRect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx - dialRx * 0.25, cy - dialRy * 0.3),
          dialRx * 1.4,
          const [Color(0xFFFFFFFF), Color(0xFFFFF4EA), Color(0xFFF3DAC7)],
          const [0.0, 0.58, 1.0],
        ),
    );

    // Inner ambient occlusion crescent along upper rim
    canvas.drawArc(
      dialRect.deflate(1.0),
      math.pi * 1.02,
      math.pi * 0.96,
      false,
      Paint()
        ..color = const Color(0xFFB84A1B).withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    // Subtle tick ring & cardinal diamond pips
    final tickPaint = Paint()
      ..color = const Color(0xFFC2A390)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final a = (i / 12) * math.pi * 2;
      final rIn = (i % 3 == 0) ? 0.74 : 0.83;
      final p1 = Offset(
        dialCenter.dx + math.cos(a) * dialRx * rIn,
        dialCenter.dy + math.sin(a) * dialRy * rIn,
      );
      final p2 = Offset(
        dialCenter.dx + math.cos(a) * dialRx * 0.90,
        dialCenter.dy + math.sin(a) * dialRy * 0.90,
      );
      canvas.drawLine(
        p1,
        p2,
        i == 9
            ? (Paint()
              ..color = const Color(0xFFFF550D)
              ..strokeWidth = 1.8
              ..strokeCap = StrokeCap.round)
            : tickPaint,
      );
    }

    // 5. Detailed 3D compass needle (NE-SW) with cast dial shadow
    const needleAngle = -0.68;
    final dir = Offset(math.cos(needleAngle), math.sin(needleAngle) * 0.65);
    final perp = Offset(-dir.dy, dir.dx * 0.65);
    final northTip = dialCenter + dir * (dialRx * 0.68);
    final southTip = dialCenter - dir * (dialRx * 0.64);
    final leftWing = dialCenter + perp * (dialRx * 0.19);
    final rightWing = dialCenter - perp * (dialRx * 0.19);

    // Needle drop shadow on dial
    final shadowShift = const Offset(1.5, 2.2);
    final needleShadowPath = Path()
      ..moveTo(northTip.dx + shadowShift.dx, northTip.dy + shadowShift.dy)
      ..lineTo(leftWing.dx + shadowShift.dx, leftWing.dy + shadowShift.dy)
      ..lineTo(southTip.dx + shadowShift.dx, southTip.dy + shadowShift.dy)
      ..lineTo(rightWing.dx + shadowShift.dx, rightWing.dy + shadowShift.dy)
      ..close();
    canvas.drawPath(
      needleShadowPath,
      Paint()
        ..color = const Color(0xFF7D3314).withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );

    // North half (left lit facet & right shaded facet)
    canvas.drawPath(
      Path()
        ..moveTo(northTip.dx, northTip.dy)
        ..lineTo(leftWing.dx, leftWing.dy)
        ..lineTo(dialCenter.dx, dialCenter.dy)
        ..close(),
      Paint()..color = const Color(0xFFFF7A3D),
    );
    canvas.drawPath(
      Path()
        ..moveTo(northTip.dx, northTip.dy)
        ..lineTo(dialCenter.dx, dialCenter.dy)
        ..lineTo(rightWing.dx, rightWing.dy)
        ..close(),
      Paint()..color = const Color(0xFFD63900),
    );

    // South half (cool ivory & shaded slate facets)
    canvas.drawPath(
      Path()
        ..moveTo(southTip.dx, southTip.dy)
        ..lineTo(leftWing.dx, leftWing.dy)
        ..lineTo(dialCenter.dx, dialCenter.dy)
        ..close(),
      Paint()..color = const Color(0xFFF3ECE6),
    );
    canvas.drawPath(
      Path()
        ..moveTo(southTip.dx, southTip.dy)
        ..lineTo(dialCenter.dx, dialCenter.dy)
        ..lineTo(rightWing.dx, rightWing.dy)
        ..close(),
      Paint()..color = const Color(0xFFBFB4AC),
    );

    // Raised 3D center pivot cap
    canvas.drawCircle(
      dialCenter + const Offset(0.5, 1.0),
      3.4,
      Paint()..color = const Color(0xFF7D2500).withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      dialCenter,
      3.2,
      Paint()
        ..shader = ui.Gradient.radial(
          dialCenter - const Offset(1.0, 1.0),
          4.2,
          const [Color(0xFFFFD8BE), Color(0xFFFF783A), Color(0xFFC23600)],
          const [0.0, 0.55, 1.0],
        ),
    );
    canvas.drawCircle(
      dialCenter - const Offset(0.9, 0.9),
      0.9,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );

    // 6. Soft glossy glass highlight over dial
    canvas.save();
    canvas.clipPath(Path()..addOval(dialRect));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - dialRx * 0.25, cy - dialRy * 0.45),
        width: dialRx * 1.25,
        height: dialRy * 0.65,
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx - dialRx, cy - dialRy),
          Offset(cx, cy),
          [
            Colors.white.withValues(alpha: 0.46),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
    );
    canvas.restore();

    // 7. Decorative rocks & green plants around the front base
    _StageArtHelpers.drawRock(
      canvas,
      Offset(cx - rx * 0.82, cy + depth + ry * 0.24),
      5.8,
      3.8,
    );
    _StageArtHelpers.drawRock(
      canvas,
      Offset(cx - rx * 0.46, cy + depth + ry * 0.62),
      4.1,
      2.7,
      lit: const Color(0xFFDCD0C5),
      mid: const Color(0xFFAC9E92),
    );
    _StageArtHelpers.drawLeafSprout(
      canvas,
      Offset(cx - rx * 0.64, cy + depth + ry * 0.42),
      0.88,
      tilt: -0.22,
    );

    _StageArtHelpers.drawRock(
      canvas,
      Offset(cx + rx * 0.78, cy + depth + ry * 0.25),
      5.2,
      3.4,
    );
    _StageArtHelpers.drawLeafSprout(
      canvas,
      Offset(cx + rx * 0.94, cy + depth + ry * 0.08),
      0.82,
      tilt: 0.32,
    );
  }

  @override
  bool shouldRepaint(covariant _Compass3DPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected;
}

/// Stage 2: Soft-3D grove of green pine trees in varied sizes, with layered
/// branches, contact shadows, small rocks, and green bushes.
class _Forest3DPainter extends CustomPainter {
  final bool isSelected;

  const _Forest3DPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft ambient forest floor shadow pad
    _StageArtHelpers.drawGroundShadow(
      canvas,
      Offset(w * 0.50, h * 0.80),
      w * 0.36,
      h * 0.13,
      alpha: isSelected ? 0.30 : 0.20,
      blur: 7.5,
    );

    // Back-left small-medium tree
    _draw3DPine(
      canvas,
      base: Offset(w * 0.30, h * 0.73),
      height: h * 0.44,
      width: w * 0.22,
      tiers: 3,
      warmBoost: isSelected,
    );

    // Back-right medium tree
    _draw3DPine(
      canvas,
      base: Offset(w * 0.71, h * 0.75),
      height: h * 0.50,
      width: w * 0.24,
      tiers: 3,
      warmBoost: isSelected,
    );

    // Center hero tall pine tree
    _draw3DPine(
      canvas,
      base: Offset(w * 0.50, h * 0.80),
      height: h * 0.66,
      width: w * 0.31,
      tiers: 4,
      warmBoost: isSelected,
    );

    // Front-left small pine tree
    _draw3DPine(
      canvas,
      base: Offset(w * 0.24, h * 0.82),
      height: h * 0.33,
      width: w * 0.17,
      tiers: 2,
      warmBoost: isSelected,
    );

    // Front bushes & rocks
    _StageArtHelpers.drawBushCluster(canvas, Offset(w * 0.67, h * 0.79), 0.92);
    _StageArtHelpers.drawBushCluster(canvas, Offset(w * 0.35, h * 0.82), 0.76);

    _StageArtHelpers.drawRock(
      canvas,
      Offset(w * 0.80, h * 0.82),
      4.6,
      3.0,
    );
    _StageArtHelpers.drawRock(
      canvas,
      Offset(w * 0.43, h * 0.85),
      3.8,
      2.4,
      lit: const Color(0xFFEFE3D8),
      mid: const Color(0xFFBBAEA2),
    );
    _StageArtHelpers.drawRock(
      canvas,
      Offset(w * 0.18, h * 0.85),
      3.4,
      2.2,
    );
  }

  void _draw3DPine(
    Canvas canvas, {
    required Offset base,
    required double height,
    required double width,
    required int tiers,
    required bool warmBoost,
  }) {
    // Contact shadow under tree base
    _StageArtHelpers.drawGroundShadow(
      canvas,
      Offset(base.dx + 1.5, base.dy + 1.0),
      width * 0.52,
      width * 0.20,
      alpha: 0.26,
      blur: 3.5,
    );

    // 3D rounded trunk
    final trunkW = width * 0.22;
    final trunkH = height * 0.20;
    final trunkRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        base.dx - trunkW * 0.5,
        base.dy - trunkH,
        trunkW,
        trunkH + 1.5,
      ),
      Radius.circular(trunkW * 0.35),
    );
    canvas.drawRRect(
      trunkRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(base.dx - trunkW * 0.5, base.dy),
          Offset(base.dx + trunkW * 0.5, base.dy),
          const [Color(0xFFC48259), Color(0xFF965A38), Color(0xFF6B3C22)],
          const [0.0, 0.55, 1.0],
        ),
    );

    // Layered 3D foliage cones from bottom to top
    final foliageBottom = base.dy - trunkH * 0.72;
    final foliageHeight = height - trunkH * 0.72;

    for (int i = 0; i < tiers; i++) {
      final t0 = i / tiers;
      final tierWidth = width * (1.0 - t0 * 0.42);
      final tierHeight = (foliageHeight / tiers) * 1.48;
      final tierBottom = foliageBottom - (foliageHeight * 0.76) * t0;
      final tierTop = tierBottom - tierHeight;
      final halfW = tierWidth * 0.5;

      // Soft ambient occlusion shadow cast onto the lower tier
      if (i > 0) {
        final shadowPath = Path()
          ..moveTo(base.dx - halfW * 0.92, tierBottom + 2.2)
          ..quadraticBezierTo(
            base.dx,
            tierBottom + 5.2,
            base.dx + halfW * 0.92,
            tierBottom + 2.2,
          )
          ..quadraticBezierTo(
            base.dx,
            tierBottom + 1.0,
            base.dx - halfW * 0.92,
            tierBottom + 2.2,
          )
          ..close();
        canvas.drawPath(
          shadowPath,
          Paint()
            ..color = const Color(0xFF1A4A28).withValues(alpha: 0.30)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
        );
      }

      // Rounded scalloped 3D cone silhouette
      final conePath = Path()
        ..moveTo(base.dx, tierTop)
        ..quadraticBezierTo(
          base.dx - halfW * 0.45,
          tierTop + tierHeight * 0.52,
          base.dx - halfW,
          tierBottom - 1.5,
        )
        ..quadraticBezierTo(
          base.dx - halfW * 0.45,
          tierBottom + 3.2,
          base.dx,
          tierBottom + 2.8,
        )
        ..quadraticBezierTo(
          base.dx + halfW * 0.45,
          tierBottom + 3.2,
          base.dx + halfW,
          tierBottom - 1.5,
        )
        ..quadraticBezierTo(
          base.dx + halfW * 0.45,
          tierTop + tierHeight * 0.52,
          base.dx,
          tierTop,
        )
        ..close();

      canvas.drawPath(
        conePath,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(base.dx - halfW * 0.8, tierTop),
            Offset(base.dx + halfW * 0.9, tierBottom),
            warmBoost
                ? const [
                    Color(0xFF9DF0A7),
                    Color(0xFF56B76C),
                    Color(0xFF28733D),
                  ]
                : const [
                    Color(0xFF83DC90),
                    Color(0xFF47A75E),
                    Color(0xFF236637),
                  ],
            const [0.0, 0.50, 1.0],
          ),
      );

      // Left sunlit edge highlight + warm cream bounce on tip
      final highlightPath = Path()
        ..moveTo(base.dx, tierTop + 1.0)
        ..quadraticBezierTo(
          base.dx - halfW * 0.40,
          tierTop + tierHeight * 0.52,
          base.dx - halfW * 0.85,
          tierBottom - 1.8,
        );
      canvas.drawPath(
        highlightPath,
        Paint()
          ..color = const Color(0xFFFFF5E8).withValues(alpha: 0.36)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Forest3DPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected;
}

/// Stage 3: Isometric raised square 3D maze platform with orange and cream
/// beveled walls, visible depth, and a small orange flag at the center.
class _Maze3DPainter extends CustomPainter {
  final bool isSelected;

  const _Maze3DPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.5, size.height * 0.30);
    final tileW = size.width * 0.088;
    final tileH = tileW * 0.56;

    Offset iso(double u, double v, [double z = 0.0]) {
      return Offset(
        origin.dx + (u - v) * tileW,
        origin.dy + (u + v) * tileH - z,
      );
    }

    // 1. Soft isometric contact shadow underneath the platform
    final shadowCenter = iso(2.5, 2.5, -9.5);
    _StageArtHelpers.drawGroundShadow(
      canvas,
      Offset(shadowCenter.dx + 1.5, shadowCenter.dy + 3.0),
      tileW * 5.2,
      tileH * 4.8,
      alpha: isSelected ? 0.34 : 0.22,
      blur: 7.0,
    );

    // 2. Raised square 3D platform slab (u, v in [0, 5], extruded downward)
    const deckH = 8.5;
    final pTop = iso(0, 0);
    final pRight = iso(5, 0);
    final pBottom = iso(5, 5);
    final pLeft = iso(0, 5);

    final bRight = iso(5, 0, -deckH);
    final bBottom = iso(5, 5, -deckH);
    final bLeft = iso(0, 5, -deckH);

    // Left-front slab face (sunlit cream/peach)
    canvas.drawPath(
      Path()
        ..moveTo(pLeft.dx, pLeft.dy)
        ..lineTo(pBottom.dx, pBottom.dy)
        ..lineTo(bBottom.dx, bBottom.dy)
        ..lineTo(bLeft.dx, bLeft.dy)
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(
          pLeft,
          bBottom,
          const [Color(0xFFF6DECE), Color(0xFFE7C2AA)],
        ),
    );

    // Right-front slab face (shaded warm taupe-peach)
    canvas.drawPath(
      Path()
        ..moveTo(pBottom.dx, pBottom.dy)
        ..lineTo(pRight.dx, pRight.dy)
        ..lineTo(bRight.dx, bRight.dy)
        ..lineTo(bBottom.dx, bBottom.dy)
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(
          pBottom,
          bRight,
          const [Color(0xFFDDB296), Color(0xFFC28E6E)],
        ),
    );

    // Top deck surface
    final deckPath = Path()
      ..moveTo(pTop.dx, pTop.dy)
      ..lineTo(pRight.dx, pRight.dy)
      ..lineTo(pBottom.dx, pBottom.dy)
      ..lineTo(pLeft.dx, pLeft.dy)
      ..close();
    canvas.drawPath(
      deckPath,
      Paint()
        ..shader = ui.Gradient.linear(
          pTop,
          pBottom,
          const [Color(0xFFFFFCF8), Color(0xFFFBE7D8)],
        ),
    );

    // Beveled top edge highlight
    canvas.drawPath(
      Path()
        ..moveTo(pLeft.dx, pLeft.dy)
        ..lineTo(pTop.dx, pTop.dy)
        ..lineTo(pRight.dx, pRight.dy),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round,
    );

    // 3. Draw 3D orange & cream maze walls back-to-front by (u + v) depth
    // Wall blocks arranged on a 5x5 grid around the open center tile (2, 2).
    final walls = <({int u, int v, bool isOrange})>[
      // Back outer ring
      (u: 0, v: 0, isOrange: true),
      (u: 1, v: 0, isOrange: true),
      (u: 3, v: 0, isOrange: false),
      (u: 4, v: 0, isOrange: true),
      (u: 0, v: 1, isOrange: false),
      (u: 0, v: 2, isOrange: true),
      (u: 0, v: 3, isOrange: true),
      (u: 4, v: 1, isOrange: true),
      (u: 4, v: 2, isOrange: false),
      // Inner labyrinth walls around center (2, 2)
      (u: 2, v: 1, isOrange: false),
      (u: 1, v: 2, isOrange: true),
      (u: 3, v: 2, isOrange: true),
      (u: 1, v: 3, isOrange: false),
      (u: 2, v: 3, isOrange: true),
      // Front outer ring with entrance gap
      (u: 0, v: 4, isOrange: false),
      (u: 2, v: 4, isOrange: false),
      (u: 4, v: 4, isOrange: true),
    ];

    walls.sort((a, b) => (a.u + a.v).compareTo(b.u + b.v));

    var flagDrawn = false;
    for (final w in walls) {
      if (!flagDrawn && (w.u + w.v) > 4) {
        _drawCenterFlag(canvas, iso(2.5, 2.5));
        flagDrawn = true;
      }
      _drawMazeBlock(
        canvas,
        iso: iso,
        u: w.u.toDouble(),
        v: w.v.toDouble(),
        isOrange: w.isOrange,
      );
    }
    if (!flagDrawn) {
      _drawCenterFlag(canvas, iso(2.5, 2.5));
    }

    // Small environmental rock & sprout peeking next to the platform corner
    _StageArtHelpers.drawRock(
      canvas,
      Offset(pLeft.dx - 2.0, pLeft.dy + 9.0),
      3.8,
      2.4,
    );
    _StageArtHelpers.drawLeafSprout(
      canvas,
      Offset(pRight.dx + 1.0, pRight.dy + 7.5),
      0.72,
      tilt: 0.25,
    );
  }

  void _drawMazeBlock(
    Canvas canvas, {
    required Offset Function(double u, double v, [double z]) iso,
    required double u,
    required double v,
    required bool isOrange,
  }) {
    const pad = 0.08;
    const wallH = 6.2;
    final u0 = u + pad;
    final u1 = u + 1.0 - pad;
    final v0 = v + pad;
    final v1 = v + 1.0 - pad;

    // Ambient occlusion shadow cast onto the deck
    final s0 = iso(u0 + 0.14, v1 + 0.14);
    final s1 = iso(u1 + 0.16, v1 + 0.16);
    final s2 = iso(u1 + 0.16, v0 + 0.14);
    final s3 = iso(u0 + 0.14, v0 + 0.14);
    canvas.drawPath(
      Path()
        ..moveTo(s0.dx, s0.dy)
        ..lineTo(s1.dx, s1.dy)
        ..lineTo(s2.dx, s2.dy)
        ..lineTo(s3.dx, s3.dy)
        ..close(),
      Paint()..color = const Color(0xFF9C542F).withValues(alpha: 0.22),
    );

    final bL = iso(u0, v1);
    final bB = iso(u1, v1);
    final bR = iso(u1, v0);

    final tT = iso(u0, v0, wallH);
    final tR = iso(u1, v0, wallH);
    final tB = iso(u1, v1, wallH);
    final tL = iso(u0, v1, wallH);

    // Left sunlit wall face
    canvas.drawPath(
      Path()
        ..moveTo(tL.dx, tL.dy)
        ..lineTo(tB.dx, tB.dy)
        ..lineTo(bB.dx, bB.dy)
        ..lineTo(bL.dx, bL.dy)
        ..close(),
      Paint()
        ..color = isOrange
            ? (isSelected ? const Color(0xFFFF864E) : const Color(0xFFFF6D2C))
            : const Color(0xFFF6E2D2),
    );

    // Right shaded wall face
    canvas.drawPath(
      Path()
        ..moveTo(tB.dx, tB.dy)
        ..lineTo(tR.dx, tR.dy)
        ..lineTo(bR.dx, bR.dy)
        ..lineTo(bB.dx, bB.dy)
        ..close(),
      Paint()
        ..color = isOrange ? const Color(0xFFC93900) : const Color(0xFFDFBFAA),
    );

    // Top face with soft gradient & beveled highlight
    final topPath = Path()
      ..moveTo(tT.dx, tT.dy)
      ..lineTo(tR.dx, tR.dy)
      ..lineTo(tB.dx, tB.dy)
      ..lineTo(tL.dx, tL.dy)
      ..close();
    canvas.drawPath(
      topPath,
      Paint()
        ..shader = ui.Gradient.linear(
          tT,
          tB,
          isOrange
              ? (isSelected
                  ? const [Color(0xFFFFCCB0), Color(0xFFFF8047)]
                  : const [Color(0xFFFFA576), Color(0xFFFF6A28)])
              : const [Color(0xFFFFFFFF), Color(0xFFFCEEE2)],
        ),
    );
    canvas.drawPath(
      topPath,
      Paint()
        ..color = Colors.white.withValues(alpha: isOrange ? 0.35 : 0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawCenterFlag(Canvas canvas, Offset base) {
    // Cast shadow across center courtyard
    canvas.drawLine(
      base,
      Offset(base.dx + 8.5, base.dy + 3.2),
      Paint()
        ..color = const Color(0xFF7D3414).withValues(alpha: 0.28)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    const poleH = 16.5;
    final top = Offset(base.dx, base.dy - poleH);

    // 3D pole
    canvas.drawLine(
      base,
      top,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(base.dx - 1, top.dy),
          Offset(base.dx + 1, base.dy),
          const [Color(0xFFFFF8F2), Color(0xFF8C7A6E)],
        )
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Waving orange pennant flag
    final flagPath = Path()
      ..moveTo(top.dx, top.dy + 1.0)
      ..quadraticBezierTo(
        top.dx + 5.5,
        top.dy - 1.2,
        top.dx + 11.5,
        top.dy + 3.8,
      )
      ..quadraticBezierTo(
        top.dx + 5.5,
        top.dy + 7.4,
        top.dx,
        top.dy + 7.6,
      )
      ..close();

    canvas.drawPath(
      flagPath,
      Paint()
        ..shader = ui.Gradient.linear(
          top,
          Offset(top.dx + 11.5, top.dy + 7.5),
          isSelected
              ? const [Color(0xFFFFE0CC), Color(0xFFFF6D2C)]
              : const [Color(0xFFFF864D), Color(0xFFFF550D)],
        ),
    );
    canvas.drawPath(
      flagPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Rounded pole finial ball
    canvas.drawCircle(
      top,
      2.1,
      Paint()
        ..shader = ui.Gradient.radial(
          top - const Offset(0.6, 0.6),
          2.8,
          const [Color(0xFFFFFFFF), Color(0xFFFF9A66), Color(0xFFD64408)],
          const [0.0, 0.55, 1.0],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _Maze3DPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected;
}

/// Stage 4: Soft-3D miniature desert adventure with sweeping golden-orange sand
/// dunes, a winding dune path, blue oasis pool, curved palm trees, sandstone
/// rocks, and 3D cactus plants.
class _Desert3DPainter extends CustomPainter {
  final bool isSelected;

  const _Desert3DPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft isometric contact shadow beneath the desert base
    _StageArtHelpers.drawGroundShadow(
      canvas,
      Offset(w * 0.50, h * 0.80),
      w * 0.42,
      h * 0.14,
      alpha: isSelected ? 0.32 : 0.22,
      blur: 7.5,
    );

    // 2. Rounded isometric desert sand base mound (back-left & front-right)
    final basePath = Path()
      ..moveTo(w * 0.10, h * 0.66)
      ..quadraticBezierTo(w * 0.30, h * 0.50, w * 0.56, h * 0.54)
      ..quadraticBezierTo(w * 0.86, h * 0.57, w * 0.90, h * 0.72)
      ..quadraticBezierTo(w * 0.86, h * 0.87, w * 0.50, h * 0.88)
      ..quadraticBezierTo(w * 0.14, h * 0.86, w * 0.10, h * 0.66)
      ..close();

    canvas.drawPath(
      basePath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.14, h * 0.52),
          Offset(w * 0.86, h * 0.88),
          isSelected
              ? const [
                  Color(0xFFFFE5B8),
                  Color(0xFFFFB25C),
                  Color(0xFFD96418),
                ]
              : const [
                  Color(0xFFFFD89E),
                  Color(0xFFFFA047),
                  Color(0xFFDA5E16),
                ],
          const [0.0, 0.52, 1.0],
        ),
    );

    // 3. Large sweeping golden-orange main sand dune (upper-left to center)
    final backDune = Path()
      ..moveTo(w * 0.13, h * 0.67)
      ..quadraticBezierTo(w * 0.28, h * 0.33, w * 0.46, h * 0.30)
      ..quadraticBezierTo(w * 0.64, h * 0.29, w * 0.80, h * 0.58)
      ..quadraticBezierTo(w * 0.52, h * 0.66, w * 0.13, h * 0.67)
      ..close();

    canvas.drawPath(
      backDune,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.25, h * 0.28),
          Offset(w * 0.74, h * 0.64),
          isSelected
              ? const [Color(0xFFFFEECC), Color(0xFFFFB152), Color(0xFFE06918)]
              : const [Color(0xFFFFDFAA), Color(0xFFFF983B), Color(0xFFD65410)],
          const [0.0, 0.55, 1.0],
        ),
    );

    // Shaded right slope of main dune for 3D ridge definition
    final duneRidgeShade = Path()
      ..moveTo(w * 0.46, h * 0.30)
      ..quadraticBezierTo(w * 0.52, h * 0.47, w * 0.47, h * 0.65)
      ..quadraticBezierTo(w * 0.66, h * 0.63, w * 0.80, h * 0.58)
      ..quadraticBezierTo(w * 0.64, h * 0.29, w * 0.46, h * 0.30)
      ..close();

    canvas.drawPath(
      duneRidgeShade,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.46, h * 0.30),
          Offset(w * 0.78, h * 0.62),
          const [Color(0xFFE56A1E), Color(0xFFBC4209)],
        ),
    );

    // Sunlit golden ridge crest highlight
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.17, h * 0.62)
        ..quadraticBezierTo(w * 0.31, h * 0.34, w * 0.46, h * 0.305)
        ..quadraticBezierTo(w * 0.51, h * 0.45, w * 0.47, h * 0.63),
      Paint()
        ..color = const Color(0xFFFFF7E2).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // 4. Winding cream-sand path curving around the front dune
    final trailPath = Path()
      ..moveTo(w * 0.19, h * 0.77)
      ..quadraticBezierTo(w * 0.34, h * 0.68, w * 0.45, h * 0.75)
      ..quadraticBezierTo(w * 0.54, h * 0.80, w * 0.61, h * 0.72);
    canvas.drawPath(
      trailPath,
      Paint()
        ..color = const Color(0xFFFFF1D8).withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round,
    );

    // 5. Small desert oasis with blue water & glossy ripple highlight
    final oasisCenter = Offset(w * 0.66, h * 0.71);
    final oasisRect = Rect.fromCenter(
      center: oasisCenter,
      width: w * 0.30,
      height: h * 0.18,
    );
    // Warm recessed sand bank around pool
    canvas.drawOval(
      oasisRect.inflate(2.2),
      Paint()..color = const Color(0xFFC75B19).withValues(alpha: 0.42),
    );
    canvas.drawOval(
      oasisRect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(oasisCenter.dx - 3.0, oasisCenter.dy - 2.0),
          w * 0.18,
          const [Color(0xFF7BE3FF), Color(0xFF28A9E6), Color(0xFF0A6FA8)],
          const [0.0, 0.58, 1.0],
        ),
    );
    // Glossy water highlight
    canvas.drawArc(
      oasisRect.deflate(3.0),
      math.pi * 1.1,
      math.pi * 0.65,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.68)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );

    // 6. Curved palm trees beside the oasis
    _drawPalmTree(
      canvas,
      base: Offset(w * 0.75, h * 0.64),
      tip: Offset(w * 0.83, h * 0.30),
      curveCtrl: Offset(w * 0.84, h * 0.48),
      scale: 1.0,
    );
    _drawPalmTree(
      canvas,
      base: Offset(w * 0.59, h * 0.62),
      tip: Offset(w * 0.53, h * 0.37),
      curveCtrl: Offset(w * 0.52, h * 0.50),
      scale: 0.76,
    );

    // 7. 3D cactus plants & sandstone rocks
    _draw3DCactus(canvas, Offset(w * 0.28, h * 0.68), 1.0);
    _draw3DCactus(canvas, Offset(w * 0.19, h * 0.70), 0.68);

    _StageArtHelpers.drawRock(
      canvas,
      Offset(w * 0.46, h * 0.81),
      4.5,
      2.8,
      lit: const Color(0xFFF6C79E),
      mid: const Color(0xFFD18A56),
      shade: const Color(0xFF9C5930),
    );
    _StageArtHelpers.drawRock(
      canvas,
      Offset(w * 0.81, h * 0.76),
      3.8,
      2.4,
      lit: const Color(0xFFF4C196),
      mid: const Color(0xFFC9804D),
      shade: const Color(0xFF915028),
    );
  }

  void _drawPalmTree(
    Canvas canvas, {
    required Offset base,
    required Offset tip,
    required Offset curveCtrl,
    required double scale,
  }) {
    _StageArtHelpers.drawGroundShadow(
      canvas,
      Offset(base.dx + 2.0, base.dy + 1.2),
      5.5 * scale,
      2.6 * scale,
      alpha: 0.24,
      blur: 3.0,
    );

    // Curved trunk with warm brown 3D shading
    final trunkPath = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(curveCtrl.dx, curveCtrl.dy, tip.dx, tip.dy);
    canvas.drawPath(
      trunkPath,
      Paint()
        ..shader = ui.Gradient.linear(
          base,
          tip,
          const [Color(0xFF9C5C34), Color(0xFFC67E4D)],
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2 * scale
        ..strokeCap = StrokeCap.round,
    );

    // 5 arched 3D green palm fronds radiating from crown
    final frondSpecs = [
      (dx: -12.0, dy: -2.0, cy: -6.5, bright: true),
      (dx: -10.0, dy: 5.5, cy: -1.5, bright: false),
      (dx: 0.5, dy: -8.5, cy: -9.5, bright: true),
      (dx: 12.0, dy: -2.5, cy: -7.0, bright: true),
      (dx: 10.5, dy: 5.5, cy: -1.0, bright: false),
    ];
    for (final f in frondSpecs) {
      final end = Offset(tip.dx + f.dx * scale, tip.dy + f.dy * scale);
      final ctrl = Offset(tip.dx + f.dx * 0.55 * scale, tip.dy + f.cy * scale);
      final frondPath = Path()
        ..moveTo(tip.dx, tip.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy - 2.2 * scale, end.dx, end.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy + 2.0 * scale, tip.dx, tip.dy)
        ..close();
      canvas.drawPath(
        frondPath,
        Paint()
          ..shader = ui.Gradient.linear(
            tip,
            end,
            f.bright
                ? const [Color(0xFF8BE296), Color(0xFF3E9354)]
                : const [Color(0xFF69C377), Color(0xFF286E3B)],
          ),
      );
    }
  }

  void _draw3DCactus(Canvas canvas, Offset base, double scale) {
    _StageArtHelpers.drawGroundShadow(
      canvas,
      Offset(base.dx + 1.0, base.dy + 1.0),
      4.5 * scale,
      2.2 * scale,
      alpha: 0.25,
      blur: 2.5,
    );

    final bodyH = 15.0 * scale;
    final bodyW = 5.0 * scale;

    // Left arm
    final leftArm = Path()
      ..moveTo(base.dx - bodyW * 0.4, base.dy - bodyH * 0.42)
      ..quadraticBezierTo(
        base.dx - bodyW * 1.2,
        base.dy - bodyH * 0.42,
        base.dx - bodyW * 1.15,
        base.dy - bodyH * 0.72,
      );
    canvas.drawPath(
      leftArm,
      Paint()
        ..color = const Color(0xFF47A55D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * scale
        ..strokeCap = StrokeCap.round,
    );

    // Right arm
    final rightArm = Path()
      ..moveTo(base.dx + bodyW * 0.4, base.dy - bodyH * 0.30)
      ..quadraticBezierTo(
        base.dx + bodyW * 1.15,
        base.dy - bodyH * 0.30,
        base.dx + bodyW * 1.10,
        base.dy - bodyH * 0.58,
      );
    canvas.drawPath(
      rightArm,
      Paint()
        ..color = const Color(0xFF2E7943)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8 * scale
        ..strokeCap = StrokeCap.round,
    );

    // Main rounded cactus trunk
    final trunkRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(base.dx - bodyW * 0.5, base.dy - bodyH, bodyW, bodyH),
      Radius.circular(bodyW * 0.5),
    );
    canvas.drawRRect(
      trunkRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(base.dx - bodyW * 0.5, base.dy - bodyH),
          Offset(base.dx + bodyW * 0.5, base.dy),
          const [Color(0xFF83DC90), Color(0xFF44A159), Color(0xFF236636)],
          const [0.0, 0.52, 1.0],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _Desert3DPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected;
}

/// Stage 5: Ultimate Final Challenge – floating white/light-grey 3D geometric
/// cube with intricate raised orange arrow mazes on all three visible faces,
/// glowing orange energy aura, floating platform below, and golden trophy above.
class _FinalCube3DPainter extends CustomPainter {
  final bool isSelected;

  const _FinalCube3DPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.50;
    final cy = size.height * 0.56;

    // 1. Floating platform underneath
    final platCenter = Offset(cx, size.height * 0.83);
    final platRx = size.width * 0.29;
    final platRy = platRx * 0.42;

    _StageArtHelpers.drawGroundShadow(
      canvas,
      Offset(cx, size.height * 0.90),
      platRx * 0.96,
      platRy * 0.92,
      alpha: isSelected ? 0.34 : 0.22,
      blur: 6.5,
    );

    final topPlatRect = Rect.fromCenter(
      center: platCenter,
      width: platRx * 2,
      height: platRy * 2,
    );
    final botPlatRect = Rect.fromCenter(
      center: Offset(platCenter.dx, platCenter.dy + 4.5),
      width: platRx * 2,
      height: platRy * 2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(topPlatRect.left, platCenter.dy)
        ..arcTo(topPlatRect, math.pi, -math.pi, false)
        ..lineTo(botPlatRect.right, platCenter.dy + 4.5)
        ..arcTo(botPlatRect, 0, math.pi, false)
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(topPlatRect.left, platCenter.dy),
          Offset(topPlatRect.right, platCenter.dy + 4.5),
          const [Color(0xFFF3D5C0), Color(0xFFD8A98C), Color(0xFFA8765A)],
          const [0.0, 0.5, 1.0],
        ),
    );
    canvas.drawOval(
      topPlatRect,
      Paint()
        ..shader = ui.Gradient.linear(
          topPlatRect.topLeft,
          topPlatRect.bottomRight,
          const [Color(0xFFFFFFFF), Color(0xFFFCE8D8)],
        ),
    );
    // Cube shadow cast onto the floating platform
    _StageArtHelpers.drawGroundShadow(
      canvas,
      platCenter,
      platRx * 0.65,
      platRy * 0.62,
      alpha: 0.24,
      blur: 4.0,
    );

    // 2. Subtle glowing orange energy aura around the floating cube
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.32,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          size.width * 0.32,
          [
            (isSelected ? const Color(0xFFFFD8BD) : const Color(0xFFFF550D))
                .withValues(alpha: isSelected ? 0.34 : 0.24),
            const Color(0xFFFF884D).withValues(alpha: 0.08),
            const Color(0xFFFF550D).withValues(alpha: 0.0),
          ],
          const [0.0, 0.58, 1.0],
        ),
    );

    // 3. Large isometric 3D geometric cube (white & light-grey surfaces)
    final r = size.width * 0.205;
    final dx = r * 0.866;
    final dy = r * 0.50;

    final cCenter = Offset(cx, cy);
    final cTop = Offset(cx, cy - r);
    final cTopRight = Offset(cx + dx, cy - dy);
    final cBotRight = Offset(cx + dx, cy + dy);
    final cBot = Offset(cx, cy + r);
    final cBotLeft = Offset(cx - dx, cy + dy);
    final cTopLeft = Offset(cx - dx, cy - dy);

    // Top face (bright white)
    final topFace = Path()
      ..moveTo(cTop.dx, cTop.dy)
      ..lineTo(cTopRight.dx, cTopRight.dy)
      ..lineTo(cCenter.dx, cCenter.dy)
      ..lineTo(cTopLeft.dx, cTopLeft.dy)
      ..close();
    canvas.drawPath(
      topFace,
      Paint()
        ..shader = ui.Gradient.linear(
          cTop,
          cCenter,
          const [Color(0xFFFFFFFF), Color(0xFFF6F7F9)],
        ),
    );

    // Left-front face (soft light grey)
    final leftFace = Path()
      ..moveTo(cTopLeft.dx, cTopLeft.dy)
      ..lineTo(cCenter.dx, cCenter.dy)
      ..lineTo(cBot.dx, cBot.dy)
      ..lineTo(cBotLeft.dx, cBotLeft.dy)
      ..close();
    canvas.drawPath(
      leftFace,
      Paint()
        ..shader = ui.Gradient.linear(
          cTopLeft,
          cBot,
          const [Color(0xFFF4F5F7), Color(0xFFE3E7ED)],
        ),
    );

    // Right-front face (cool shaded grey)
    final rightFace = Path()
      ..moveTo(cCenter.dx, cCenter.dy)
      ..lineTo(cTopRight.dx, cTopRight.dy)
      ..lineTo(cBotRight.dx, cBotRight.dy)
      ..lineTo(cBot.dx, cBot.dy)
      ..close();
    canvas.drawPath(
      rightFace,
      Paint()
        ..shader = ui.Gradient.linear(
          cCenter,
          cBotRight,
          const [Color(0xFFE4E8EE), Color(0xFFCCD2DC)],
        ),
    );

    // Crisp beveled cube edges & warm highlight
    final bevelPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(cTopLeft, cCenter, bevelPaint);
    canvas.drawLine(cCenter, cTopRight, bevelPaint);
    canvas.drawLine(cCenter, cBot, bevelPaint);
    canvas.drawPath(
      Path()
        ..moveTo(cTop.dx, cTop.dy)
        ..lineTo(cTopRight.dx, cTopRight.dy)
        ..lineTo(cBotRight.dx, cBotRight.dy)
        ..lineTo(cBot.dx, cBot.dy)
        ..lineTo(cBotLeft.dx, cBotLeft.dy)
        ..lineTo(cTopLeft.dx, cTopLeft.dy)
        ..close(),
      Paint()
        ..color = isSelected
            ? const Color(0xFFFFD8BD).withValues(alpha: 0.75)
            : const Color(0xFFBFC6D1).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 4. Raised intricate orange arrow mazes on all three visible cube faces
    Offset mapTop(double u, double v) =>
        cTop + (cTopRight - cTop) * u + (cTopLeft - cTop) * v;
    Offset mapLeft(double u, double v) =>
        cTopLeft + (cCenter - cTopLeft) * u + (cBotLeft - cTopLeft) * v;
    Offset mapRight(double u, double v) =>
        cCenter + (cTopRight - cCenter) * u + (cBot - cCenter) * v;

    // Top face orange arrows
    _drawFaceArrow(canvas, mapTop, [const Offset(0.22, 0.25), const Offset(0.78, 0.25)]);
    _drawFaceArrow(canvas, mapTop, [const Offset(0.75, 0.75), const Offset(0.22, 0.75)]);
    _drawFaceArrow(canvas, mapTop, [const Offset(0.26, 0.50), const Offset(0.68, 0.50)]);

    // Left face orange arrows (vertical & L-bend)
    _drawFaceArrow(canvas, mapLeft, [const Offset(0.25, 0.80), const Offset(0.25, 0.20)]);
    _drawFaceArrow(canvas, mapLeft, [
      const Offset(0.52, 0.22),
      const Offset(0.52, 0.68),
      const Offset(0.84, 0.68),
    ]);
    _drawFaceArrow(canvas, mapLeft, [const Offset(0.78, 0.22), const Offset(0.78, 0.48)]);

    // Right face orange arrows
    _drawFaceArrow(canvas, mapRight, [const Offset(0.20, 0.28), const Offset(0.82, 0.28)]);
    _drawFaceArrow(canvas, mapRight, [
      const Offset(0.76, 0.80),
      const Offset(0.76, 0.52),
      const Offset(0.24, 0.52),
    ]);
    _drawFaceArrow(canvas, mapRight, [const Offset(0.24, 0.78), const Offset(0.58, 0.78)]);

    // 5. Small golden trophy perched above the cube
    _drawGoldenTrophy(canvas, Offset(cx, cTop.dy + 1.5));

    // Tiny glowing energy sparks around the cube
    final sparkPaint = Paint()
      ..color = isSelected ? const Color(0xFFFFF0DD) : const Color(0xFFFF9852);
    canvas.drawCircle(Offset(cx - r * 1.15, cy - r * 0.45), 1.6, sparkPaint);
    canvas.drawCircle(Offset(cx + r * 1.18, cy - r * 0.25), 1.4, sparkPaint);
    canvas.drawCircle(Offset(cx - r * 0.95, cy + r * 0.65), 1.2, sparkPaint);
  }

  void _drawFaceArrow(
    Canvas canvas,
    Offset Function(double u, double v) map,
    List<Offset> pts,
  ) {
    if (pts.length < 2) return;

    final path = Path()..moveTo(map(pts.first.dx, pts.first.dy).dx, map(pts.first.dx, pts.first.dy).dy);
    for (int i = 1; i < pts.length; i++) {
      final p = map(pts[i].dx, pts[i].dy);
      path.lineTo(p.dx, p.dy);
    }

    // Raised 3D depth shadow underneath arrow
    canvas.save();
    canvas.translate(0.7, 1.1);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFB53100).withValues(alpha: 0.48)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    // Main vibrant orange arrow body
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFF550D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Arrowhead triangle
    final tipGrid = pts.last;
    final prevGrid = pts[pts.length - 2];
    final tipPx = map(tipGrid.dx, tipGrid.dy);
    final prevPx = map(prevGrid.dx, prevGrid.dy);
    final delta = tipPx - prevPx;
    final len = delta.distance;
    if (len > 0.5) {
      final dir = delta / len;
      final perp = Offset(-dir.dy, dir.dx);
      final headTip = tipPx + dir * 1.4;
      final base = tipPx - dir * 1.8;
      canvas.drawPath(
        Path()
          ..moveTo(headTip.dx, headTip.dy)
          ..lineTo(base.dx + perp.dx * 2.2, base.dy + perp.dy * 2.2)
          ..lineTo(base.dx - perp.dx * 2.2, base.dy - perp.dy * 2.2)
          ..close(),
        Paint()..color = const Color(0xFFFF550D),
      );
    }
  }

  void _drawGoldenTrophy(Canvas canvas, Offset base) {
    // Contact shadow on top cube face
    _StageArtHelpers.drawGroundShadow(
      canvas,
      Offset(base.dx, base.dy + 0.5),
      5.2,
      2.4,
      alpha: 0.22,
      blur: 2.2,
    );

    // Pedestal base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(base.dx, base.dy - 1.5),
          width: 8.5,
          height: 3.2,
        ),
        const Radius.circular(1.0),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(base.dx - 4, base.dy - 3),
          Offset(base.dx + 4, base.dy),
          const [Color(0xFFFFD54F), Color(0xFFD97706)],
        ),
    );

    // Stem
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(base.dx, base.dy - 4.2),
        width: 2.6,
        height: 3.2,
      ),
      Paint()..color = const Color(0xFFE59500),
    );

    // Curved handles
    final handlePaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(base.dx - 4.8, base.dy - 9.2), width: 4.5, height: 5.5),
      math.pi * 0.5,
      math.pi,
      false,
      handlePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(base.dx + 4.8, base.dy - 9.2), width: 4.5, height: 5.5),
      -math.pi * 0.5,
      math.pi,
      false,
      handlePaint,
    );

    // Golden cup bowl
    final cupPath = Path()
      ..moveTo(base.dx - 4.8, base.dy - 12.5)
      ..lineTo(base.dx + 4.8, base.dy - 12.5)
      ..quadraticBezierTo(base.dx + 4.5, base.dy - 5.8, base.dx, base.dy - 5.5)
      ..quadraticBezierTo(base.dx - 4.5, base.dy - 5.8, base.dx - 4.8, base.dy - 12.5)
      ..close();

    canvas.drawPath(
      cupPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(base.dx - 4.8, base.dy - 12.5),
          Offset(base.dx + 4.8, base.dy - 5.5),
          const [Color(0xFFFFF59D), Color(0xFFFFCA28), Color(0xFFD97706)],
          const [0.0, 0.5, 1.0],
        ),
    );

    // Glossy highlight on cup left side
    canvas.drawLine(
      Offset(base.dx - 2.6, base.dy - 11.4),
      Offset(base.dx - 1.8, base.dy - 7.5),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.78)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _FinalCube3DPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected;
}

/// Shared 3D crystal cluster helper used by Frozen Peaks and Crystal Temple.
void _draw3DCrystal(
  Canvas canvas, {
  required Offset base,
  required double width,
  required double height,
  required Color lit,
  required Color mid,
  required Color shade,
  double tilt = 0.0,
}) {
  canvas.save();
  canvas.translate(base.dx, base.dy);
  canvas.rotate(tilt);

  final hw = width * 0.5;
  final tip = Offset(0, -height);
  final midL = Offset(-hw, -height * 0.34);
  final midC = Offset(hw * 0.08, -height * 0.26);
  final midR = Offset(hw, -height * 0.38);
  final botL = Offset(-hw * 0.72, 0);
  final botC = Offset(hw * 0.05, height * 0.08);
  final botR = Offset(hw * 0.78, -height * 0.03);

  // Left sunlit facet
  canvas.drawPath(
    Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(midL.dx, midL.dy)
      ..lineTo(botL.dx, botL.dy)
      ..lineTo(botC.dx, botC.dy)
      ..lineTo(midC.dx, midC.dy)
      ..close(),
    Paint()
      ..shader = ui.Gradient.linear(
        tip,
        botL,
        [lit, mid],
      ),
  );

  // Right shaded facet
  canvas.drawPath(
    Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(midC.dx, midC.dy)
      ..lineTo(botC.dx, botC.dy)
      ..lineTo(botR.dx, botR.dy)
      ..lineTo(midR.dx, midR.dy)
      ..close(),
    Paint()
      ..shader = ui.Gradient.linear(
        tip,
        botR,
        [mid, shade],
      ),
  );

  // Crisp facet ridge highlight
  canvas.drawLine(
    tip,
    midC,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round,
  );
  canvas.restore();
}

/// Stage 6: Frozen Peaks – miniature snowy mountain landscape, blue-white ice
/// crystals, frozen waterfall, snow-covered pine trees, glowing icy path, and
/// snow rocks.
class _FrozenPeaks3DPainter extends CustomPainter {
  final bool isSelected;

  const _FrozenPeaks3DPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _StageArtHelpers.drawGroundShadow(
      canvas,
      Offset(w * 0.50, h * 0.82),
      w * 0.42,
      h * 0.14,
      alpha: isSelected ? 0.34 : 0.22,
      blur: 7.5,
    );

    // 1. Rounded snowy isometric diorama base
    final basePath = Path()
      ..moveTo(w * 0.10, h * 0.68)
      ..quadraticBezierTo(w * 0.25, h * 0.54, w * 0.52, h * 0.54)
      ..quadraticBezierTo(w * 0.84, h * 0.55, w * 0.90, h * 0.71)
      ..quadraticBezierTo(w * 0.86, h * 0.87, w * 0.50, h * 0.88)
      ..quadraticBezierTo(w * 0.14, h * 0.86, w * 0.10, h * 0.68)
      ..close();
    canvas.drawPath(
      basePath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.14, h * 0.54),
          Offset(w * 0.86, h * 0.88),
          const [Color(0xFFFFFFFF), Color(0xFFD6EEFF), Color(0xFF7CB6E6)],
          const [0.0, 0.55, 1.0],
        ),
    );

    // 2. Main snow mountain (left-center) & secondary peak (right)
    _drawSnowPeak(
      canvas,
      peak: Offset(w * 0.36, h * 0.15),
      leftBase: Offset(w * 0.13, h * 0.67),
      midBase: Offset(w * 0.39, h * 0.70),
      rightBase: Offset(w * 0.61, h * 0.64),
    );
    _drawSnowPeak(
      canvas,
      peak: Offset(w * 0.66, h * 0.24),
      leftBase: Offset(w * 0.47, h * 0.65),
      midBase: Offset(w * 0.66, h * 0.69),
      rightBase: Offset(w * 0.87, h * 0.66),
    );

    // 3. Frozen waterfall cascading into icy front pool
    final poolRect = Rect.fromCenter(
      center: Offset(w * 0.52, h * 0.77),
      width: w * 0.28,
      height: h * 0.13,
    );
    canvas.drawOval(
      poolRect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.50, h * 0.76),
          w * 0.16,
          const [Color(0xFFE8FAFF), Color(0xFF7ED8FA), Color(0xFF3A96D4)],
          const [0.0, 0.58, 1.0],
        ),
    );
    final fallPath = Path()
      ..moveTo(w * 0.49, h * 0.51)
      ..quadraticBezierTo(w * 0.50, h * 0.64, w * 0.48, h * 0.76)
      ..lineTo(w * 0.55, h * 0.76)
      ..quadraticBezierTo(w * 0.54, h * 0.63, w * 0.53, h * 0.51)
      ..close();
    canvas.drawPath(
      fallPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.51, h * 0.51),
          Offset(w * 0.51, h * 0.76),
          const [Color(0xFFFFFFFF), Color(0xFF9BE3FF), Color(0xFF56B4E9)],
          const [0.0, 0.5, 1.0],
        ),
    );

    // 4. Glowing icy pathway winding from valley to front-left
    final icePath = Path()
      ..moveTo(w * 0.50, h * 0.62)
      ..quadraticBezierTo(w * 0.43, h * 0.72, w * 0.34, h * 0.76)
      ..quadraticBezierTo(w * 0.26, h * 0.80, w * 0.22, h * 0.77);
    canvas.drawPath(
      icePath,
      Paint()
        ..color = const Color(0xFF8BE8FF).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawPath(
      icePath,
      Paint()
        ..color = const Color(0xFFEFFCFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );

    // 5. Large blue-white ice crystals
    _draw3DCrystal(
      canvas,
      base: Offset(w * 0.77, h * 0.73),
      width: 10.5,
      height: 22.0,
      lit: const Color(0xFFFFFFFF),
      mid: const Color(0xFF93DCFF),
      shade: const Color(0xFF3E8FD1),
      tilt: 0.14,
    );
    _draw3DCrystal(
      canvas,
      base: Offset(w * 0.83, h * 0.75),
      width: 7.5,
      height: 15.0,
      lit: const Color(0xFFF2FBFF),
      mid: const Color(0xFF7FD2FC),
      shade: const Color(0xFF337EC2),
      tilt: 0.32,
    );
    _draw3DCrystal(
      canvas,
      base: Offset(w * 0.20, h * 0.70),
      width: 8.5,
      height: 17.5,
      lit: const Color(0xFFFFFFFF),
      mid: const Color(0xFFA0E2FF),
      shade: const Color(0xFF4797D6),
      tilt: -0.22,
    );

    // 6. Snow-covered pine trees & snow rocks
    _drawSnowPine(canvas, Offset(w * 0.29, h * 0.71), 15.0);
    _drawSnowPine(canvas, Offset(w * 0.67, h * 0.76), 12.0);
    _StageArtHelpers.drawRock(
      canvas,
      Offset(w * 0.40, h * 0.82),
      4.2,
      2.6,
      lit: const Color(0xFFFFFFFF),
      mid: const Color(0xFFC5DFF5),
      shade: const Color(0xFF7FAAD1),
    );
    _StageArtHelpers.drawRock(
      canvas,
      Offset(w * 0.62, h * 0.82),
      3.5,
      2.2,
      lit: const Color(0xFFFFFFFF),
      mid: const Color(0xFFBBD8F2),
      shade: const Color(0xFF77A2CA),
    );
  }

  void _drawSnowPeak(
    Canvas canvas, {
    required Offset peak,
    required Offset leftBase,
    required Offset midBase,
    required Offset rightBase,
  }) {
    // Left sunlit rock & snow slope
    canvas.drawPath(
      Path()
        ..moveTo(peak.dx, peak.dy)
        ..lineTo(leftBase.dx, leftBase.dy)
        ..lineTo(midBase.dx, midBase.dy)
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(
          peak,
          leftBase,
          const [Color(0xFFFFFFFF), Color(0xFFD2E8FA), Color(0xFF8CBCE6)],
          const [0.0, 0.55, 1.0],
        ),
    );
    // Right shaded icy ridge
    canvas.drawPath(
      Path()
        ..moveTo(peak.dx, peak.dy)
        ..lineTo(midBase.dx, midBase.dy)
        ..lineTo(rightBase.dx, rightBase.dy)
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(
          peak,
          rightBase,
          const [Color(0xFFDDEEFF), Color(0xFF85B8E4), Color(0xFF538AC4)],
          const [0.0, 0.52, 1.0],
        ),
    );

    // Bright rounded snow cap draped over peak
    final snowCap = Path()
      ..moveTo(peak.dx, peak.dy)
      ..lineTo(peak.dx - (peak.dx - leftBase.dx) * 0.44, peak.dy + (leftBase.dy - peak.dy) * 0.42)
      ..quadraticBezierTo(
        midBase.dx - (midBase.dx - peak.dx) * 0.4,
        peak.dy + (midBase.dy - peak.dy) * 0.48,
        peak.dx + (midBase.dx - peak.dx) * 0.5,
        peak.dy + (midBase.dy - peak.dy) * 0.44,
      )
      ..lineTo(peak.dx + (rightBase.dx - peak.dx) * 0.42, peak.dy + (rightBase.dy - peak.dy) * 0.40)
      ..close();
    canvas.drawPath(
      snowCap,
      Paint()
        ..shader = ui.Gradient.linear(
          peak,
          Offset(peak.dx + 8, peak.dy + 18),
          const [Color(0xFFFFFFFF), Color(0xFFE1F3FF)],
        ),
    );
  }

  void _drawSnowPine(Canvas canvas, Offset base, double h) {
    _StageArtHelpers.drawGroundShadow(
      canvas,
      Offset(base.dx + 1, base.dy + 1),
      h * 0.34,
      h * 0.14,
      alpha: 0.22,
      blur: 2.5,
    );
    for (int i = 0; i < 2; i++) {
      final t = i * 0.42;
      final bw = h * (0.62 - i * 0.14);
      final topY = base.dy - h * (0.65 + i * 0.35);
      final botY = base.dy - h * t - 1.5;
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, topY)
          ..lineTo(base.dx - bw * 0.5, botY)
          ..quadraticBezierTo(base.dx, botY + 2.2, base.dx + bw * 0.5, botY)
          ..close(),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(base.dx - bw * 0.5, topY),
            Offset(base.dx + bw * 0.5, botY),
            const [Color(0xFF70C9B2), Color(0xFF2B7A6F)],
          ),
      );
      // Snow frosting on top tip
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, topY)
          ..lineTo(base.dx - bw * 0.26, topY + (botY - topY) * 0.42)
          ..quadraticBezierTo(base.dx, topY + (botY - topY) * 0.50, base.dx + bw * 0.26, topY + (botY - topY) * 0.42)
          ..close(),
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FrozenPeaks3DPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected;
}

/// Stage 7: Lava Kingdom – miniature dark volcanic island with an erupting
/// volcano, glowing orange lava streams, floating lava platforms, and warm
/// fire-lit edges.
class _LavaKingdom3DPainter extends CustomPainter {
  final bool isSelected;

  const _LavaKingdom3DPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Warm orange-red underglow shadow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF4500).withValues(alpha: isSelected ? 0.36 : 0.26)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.81), width: w * 0.82, height: h * 0.24),
      glowPaint,
    );

    // 1. Dark volcanic island base with glowing magma rim
    final islandPath = Path()
      ..moveTo(w * 0.12, h * 0.69)
      ..quadraticBezierTo(w * 0.28, h * 0.56, w * 0.52, h * 0.56)
      ..quadraticBezierTo(w * 0.84, h * 0.57, w * 0.88, h * 0.72)
      ..quadraticBezierTo(w * 0.84, h * 0.87, w * 0.50, h * 0.88)
      ..quadraticBezierTo(w * 0.16, h * 0.86, w * 0.12, h * 0.69)
      ..close();
    canvas.drawPath(
      islandPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.14, h * 0.56),
          Offset(w * 0.86, h * 0.88),
          const [Color(0xFF6B4C48), Color(0xFF432B29), Color(0xFF231515)],
          const [0.0, 0.52, 1.0],
        ),
    );
    canvas.drawPath(
      islandPath,
      Paint()
        ..color = const Color(0xFFFF7A33).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    // 2. Small floating lava platforms on left & right
    _drawFloatingLavaChunk(canvas, Offset(w * 0.15, h * 0.44), 13.0);
    _drawFloatingLavaChunk(canvas, Offset(w * 0.84, h * 0.48), 11.5);

    // 3. Large erupting volcano cone
    final conePath = Path()
      ..moveTo(w * 0.40, h * 0.29)
      ..lineTo(w * 0.60, h * 0.29)
      ..quadraticBezierTo(w * 0.68, h * 0.52, w * 0.80, h * 0.68)
      ..quadraticBezierTo(w * 0.50, h * 0.74, w * 0.20, h * 0.68)
      ..quadraticBezierTo(w * 0.32, h * 0.52, w * 0.40, h * 0.29)
      ..close();
    canvas.drawPath(
      conePath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.22, h * 0.30),
          Offset(w * 0.78, h * 0.72),
          const [Color(0xFF734A42), Color(0xFF472A26), Color(0xFF251514)],
          const [0.0, 0.50, 1.0],
        ),
    );

    // Glowing crater rim & magma pool
    final craterRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.29),
      width: w * 0.20,
      height: h * 0.085,
    );
    canvas.drawOval(
      craterRect.inflate(2.5),
      Paint()
        ..color = const Color(0xFFFF6600).withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );
    canvas.drawOval(
      craterRect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.50, h * 0.29),
          w * 0.12,
          const [Color(0xFFFFF7AE), Color(0xFFFF8C1A), Color(0xFFFF3B00)],
          const [0.0, 0.55, 1.0],
        ),
    );

    // 4. Glowing lava streams flowing down the slopes & across base
    final mainLava = Path()
      ..moveTo(w * 0.49, h * 0.32)
      ..quadraticBezierTo(w * 0.44, h * 0.48, w * 0.51, h * 0.58)
      ..quadraticBezierTo(w * 0.56, h * 0.67, w * 0.43, h * 0.77)
      ..quadraticBezierTo(w * 0.35, h * 0.82, w * 0.28, h * 0.79);
    final sideLava = Path()
      ..moveTo(w * 0.54, h * 0.32)
      ..quadraticBezierTo(w * 0.61, h * 0.48, w * 0.67, h * 0.66)
      ..quadraticBezierTo(w * 0.72, h * 0.74, w * 0.77, h * 0.76);

    for (final p in [mainLava, sideLava]) {
      canvas.drawPath(
        p,
        Paint()
          ..color = const Color(0xFFFF4D00).withValues(alpha: 0.72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
      canvas.drawPath(
        p,
        Paint()
          ..color = const Color(0xFFFFCC4D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }

    // Erupting glowing embers above crater
    final emberPaint = Paint()..color = const Color(0xFFFFE57F);
    canvas.drawCircle(Offset(w * 0.46, h * 0.18), 2.1, emberPaint);
    canvas.drawCircle(Offset(w * 0.53, h * 0.13), 2.5, Paint()..color = const Color(0xFFFF9433));
    canvas.drawCircle(Offset(w * 0.58, h * 0.20), 1.6, emberPaint);

    // 5. Dark volcanic rocks around base
    _StageArtHelpers.drawRock(
      canvas,
      Offset(w * 0.24, h * 0.73),
      4.5,
      3.0,
      lit: const Color(0xFF7D5C58),
      mid: const Color(0xFF4A3331),
      shade: const Color(0xFF281919),
    );
    _StageArtHelpers.drawRock(
      canvas,
      Offset(w * 0.66, h * 0.80),
      4.8,
      3.1,
      lit: const Color(0xFF845A52),
      mid: const Color(0xFF4B312F),
      shade: const Color(0xFF271717),
    );
  }

  void _drawFloatingLavaChunk(Canvas canvas, Offset center, double w) {
    final h = w * 0.55;
    // Glowing lava underside aura
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.45), width: w * 0.9, height: h * 0.6),
      Paint()
        ..color = const Color(0xFFFF550D).withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - w * 0.5, center.dy)
        ..lineTo(center.dx, center.dy - h * 0.45)
        ..lineTo(center.dx + w * 0.5, center.dy)
        ..lineTo(center.dx + w * 0.25, center.dy + h * 0.75)
        ..lineTo(center.dx - w * 0.25, center.dy + h * 0.75)
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(center.dx - w * 0.4, center.dy - h * 0.4),
          Offset(center.dx + w * 0.4, center.dy + h * 0.7),
          const [Color(0xFF75524C), Color(0xFF33201F)],
        ),
    );
    // Glowing magma top crack
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w * 0.45, height: h * 0.26),
      Paint()..color = const Color(0xFFFF9833),
    );
  }

  @override
  bool shouldRepaint(covariant _LavaKingdom3DPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected;
}

/// Stage 8: Ocean Depths – miniature underwater ocean seabed, mysterious glowing
/// cave, colorful coral reef, blue crystals, underwater rocks, and tropical fish.
class _OceanDepths3DPainter extends CustomPainter {
  final bool isSelected;

  const _OceanDepths3DPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _StageArtHelpers.drawGroundShadow(
      canvas,
      Offset(w * 0.50, h * 0.82),
      w * 0.42,
      h * 0.14,
      alpha: isSelected ? 0.34 : 0.22,
      blur: 7.5,
    );

    // 1. Rounded ocean floor seabed base
    final seabed = Path()
      ..moveTo(w * 0.10, h * 0.68)
      ..quadraticBezierTo(w * 0.26, h * 0.53, w * 0.52, h * 0.53)
      ..quadraticBezierTo(w * 0.84, h * 0.54, w * 0.90, h * 0.70)
      ..quadraticBezierTo(w * 0.86, h * 0.87, w * 0.50, h * 0.88)
      ..quadraticBezierTo(w * 0.14, h * 0.86, w * 0.10, h * 0.68)
      ..close();
    canvas.drawPath(
      seabed,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.15, h * 0.54),
          Offset(w * 0.85, h * 0.88),
          const [Color(0xFF8BE2EC), Color(0xFF3399C6), Color(0xFF134A78)],
          const [0.0, 0.48, 1.0],
        ),
    );

    // 2. Mysterious glowing underwater cave (back-left)
    final caveOuter = Path()
      ..moveTo(w * 0.16, h * 0.67)
      ..quadraticBezierTo(w * 0.18, h * 0.28, w * 0.38, h * 0.26)
      ..quadraticBezierTo(w * 0.57, h * 0.27, w * 0.60, h * 0.64)
      ..close();
    canvas.drawPath(
      caveOuter,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.18, h * 0.28),
          Offset(w * 0.58, h * 0.66),
          const [Color(0xFF4A7AA8), Color(0xFF23476E), Color(0xFF10243D)],
          const [0.0, 0.55, 1.0],
        ),
    );
    // Glowing cyan cave opening
    final caveHole = Path()
      ..moveTo(w * 0.25, h * 0.65)
      ..quadraticBezierTo(w * 0.27, h * 0.39, w * 0.39, h * 0.38)
      ..quadraticBezierTo(w * 0.50, h * 0.39, w * 0.51, h * 0.64)
      ..close();
    canvas.drawPath(
      caveHole,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.38, h * 0.54),
          w * 0.18,
          const [Color(0xFF72FFFF), Color(0xFF1586BA), Color(0xFF0A2847)],
          const [0.0, 0.55, 1.0],
        ),
    );

    // 3. Colorful branching 3D coral reef (right & center-right)
    _drawCoralBranch(
      canvas,
      Offset(w * 0.67, h * 0.70),
      1.05,
      const Color(0xFFFF8852),
      const Color(0xFFD93E0A),
    );
    _drawCoralBranch(
      canvas,
      Offset(w * 0.78, h * 0.72),
      0.82,
      const Color(0xFFFF8DAA),
      const Color(0xFFC9446B),
    );

    // 4. Blue crystal formations & underwater rocks
    _draw3DCrystal(
      canvas,
      base: Offset(w * 0.22, h * 0.74),
      width: 9.0,
      height: 18.0,
      lit: const Color(0xFFD8FCFF),
      mid: const Color(0xFF39C6F4),
      shade: const Color(0xFF0E68A8),
      tilt: -0.20,
    );
    _draw3DCrystal(
      canvas,
      base: Offset(w * 0.56, h * 0.75),
      width: 7.5,
      height: 14.5,
      lit: const Color(0xFFD8FCFF),
      mid: const Color(0xFF39C6F4),
      shade: const Color(0xFF0E68A8),
      tilt: 0.18,
    );
    _StageArtHelpers.drawRock(
      canvas,
      Offset(w * 0.42, h * 0.80),
      5.0,
      3.0,
      lit: const Color(0xFF8FB4CE),
      mid: const Color(0xFF4A7394),
      shade: const Color(0xFF23425E),
    );

    // 5. Small tropical fish & bubbles
    _drawFish(canvas, Offset(w * 0.62, h * 0.31), 1.0, facingRight: false);
    _drawFish(canvas, Offset(w * 0.36, h * 0.22), 0.78, facingRight: true);

    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(w * 0.48, h * 0.25), 2.4, bubblePaint);
    canvas.drawCircle(Offset(w * 0.53, h * 0.17), 1.7, bubblePaint);
    canvas.drawCircle(Offset(w * 0.74, h * 0.26), 2.0, bubblePaint);
  }

  void _drawCoralBranch(
    Canvas canvas,
    Offset base,
    double scale,
    Color lit,
    Color shade,
  ) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(base.dx - 10 * scale, base.dy - 22 * scale),
        Offset(base.dx + 10 * scale, base.dy),
        [lit, shade],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(base.dx - 2 * scale, base.dy - 12 * scale, base.dx - 7 * scale, base.dy - 20 * scale),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - 1 * scale, base.dy - 7 * scale)
        ..quadraticBezierTo(base.dx + 4 * scale, base.dy - 14 * scale, base.dx + 2 * scale, base.dy - 23 * scale),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy - 5 * scale)
        ..quadraticBezierTo(base.dx + 8 * scale, base.dy - 10 * scale, base.dx + 10 * scale, base.dy - 17 * scale),
      paint,
    );
  }

  void _drawFish(
    Canvas canvas,
    Offset center,
    double scale, {
    required bool facingRight,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (!facingRight) canvas.scale(-1, 1);

    // Tail fin
    canvas.drawPath(
      Path()
        ..moveTo(-4.5 * scale, 0)
        ..lineTo(-9.5 * scale, -4.0 * scale)
        ..lineTo(-9.5 * scale, 4.0 * scale)
        ..close(),
      Paint()..color = const Color(0xFFFF9838),
    );
    // Body
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 11.5 * scale, height: 7.0 * scale),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, -3.5 * scale),
          Offset(0, 3.5 * scale),
          const [Color(0xFFFFBA42), Color(0xFFFF550D)],
        ),
    );
    // White stripe & eye
    canvas.drawLine(
      Offset(-0.8 * scale, -2.8 * scale),
      Offset(-0.8 * scale, 2.8 * scale),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 1.6 * scale,
    );
    canvas.drawCircle(
      Offset(3.0 * scale, -0.7 * scale),
      0.9 * scale,
      Paint()..color = const Color(0xFF14243B),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OceanDepths3DPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected;
}

/// Stage 9: Sky Islands – floating islands suspended above soft white clouds,
/// green trees, connecting wooden bridge, and a miniature waterfall spilling
/// into cloud mist.
class _SkyIslands3DPainter extends CustomPainter {
  final bool isSelected;

  const _SkyIslands3DPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft white clouds behind and beneath the islands
    _drawFluffyCloud(canvas, Offset(w * 0.25, h * 0.34), 24.0, 0.85);
    _drawFluffyCloud(canvas, Offset(w * 0.74, h * 0.22), 20.0, 0.82);

    // 2. Back-right upper floating island
    _drawFloatingIsland(canvas, center: Offset(w * 0.72, h * 0.41), rx: 16.5, depth: 12.0);
    _drawRoundTree(canvas, Offset(w * 0.76, h * 0.37), 0.78);

    // 3. Connecting arched bridge between main island and upper-right island
    final bridge = Path()
      ..moveTo(w * 0.48, h * 0.47)
      ..quadraticBezierTo(w * 0.58, h * 0.41, w * 0.64, h * 0.42);
    canvas.drawPath(
      bridge,
      Paint()
        ..color = const Color(0xFF8C5633)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      bridge,
      Paint()
        ..color = const Color(0xFFE0A775)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    // 4. Main center-left floating island
    _drawFloatingIsland(canvas, center: Offset(w * 0.36, h * 0.53), rx: 22.0, depth: 16.0);
    _drawRoundTree(canvas, Offset(w * 0.26, h * 0.47), 1.05);
    _drawRoundTree(canvas, Offset(w * 0.36, h * 0.45), 0.85);

    // Miniature waterfall cascading off the front of the main island
    final fallPath = Path()
      ..moveTo(w * 0.41, h * 0.56)
      ..quadraticBezierTo(w * 0.44, h * 0.68, w * 0.43, h * 0.81)
      ..lineTo(w * 0.49, h * 0.81)
      ..quadraticBezierTo(w * 0.49, h * 0.68, w * 0.46, h * 0.56)
      ..close();
    canvas.drawPath(
      fallPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.44, h * 0.56),
          Offset(w * 0.45, h * 0.81),
          const [Color(0xFFB3F2FF), Color(0xFF42B8EB)],
        ),
    );

    // 5. Lower-right small floating island
    _drawFloatingIsland(canvas, center: Offset(w * 0.74, h * 0.70), rx: 12.5, depth: 9.0);
    _drawRoundTree(canvas, Offset(w * 0.74, h * 0.66), 0.65);

    // 6. Soft foreground clouds beneath waterfall & islands
    _drawFluffyCloud(canvas, Offset(w * 0.47, h * 0.82), 28.0, isSelected ? 0.96 : 0.92);
    _drawFluffyCloud(canvas, Offset(w * 0.24, h * 0.79), 20.0, 0.88);
  }

  void _drawFloatingIsland(
    Canvas canvas, {
    required Offset center,
    required double rx,
    required double depth,
  }) {
    final ry = rx * 0.46;
    // Tapered rocky earth cone underneath
    final rockPath = Path()
      ..moveTo(center.dx - rx * 0.95, center.dy + ry * 0.1)
      ..quadraticBezierTo(center.dx - rx * 0.55, center.dy + depth * 0.9, center.dx, center.dy + depth)
      ..quadraticBezierTo(center.dx + rx * 0.55, center.dy + depth * 0.9, center.dx + rx * 0.95, center.dy + ry * 0.1)
      ..close();
    canvas.drawPath(
      rockPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(center.dx - rx, center.dy),
          Offset(center.dx + rx, center.dy + depth),
          const [Color(0xFFD1936A), Color(0xFF9C603B), Color(0xFF693D23)],
          const [0.0, 0.55, 1.0],
        ),
    );

    // Lush green grass cap
    final capRect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
    canvas.drawOval(
      capRect.shift(const Offset(0, 1.8)),
      Paint()..color = const Color(0xFF2B6F3E),
    );
    canvas.drawOval(
      capRect,
      Paint()
        ..shader = ui.Gradient.linear(
          capRect.topLeft,
          capRect.bottomRight,
          const [Color(0xFF8BE296), Color(0xFF47A75E)],
        ),
    );
  }

  void _drawRoundTree(Canvas canvas, Offset base, double scale) {
    canvas.drawLine(
      base,
      Offset(base.dx, base.dy - 6.0 * scale),
      Paint()
        ..color = const Color(0xFF854F2E)
        ..strokeWidth = 2.6 * scale
        ..strokeCap = StrokeCap.round,
    );
    final c = Offset(base.dx, base.dy - 9.0 * scale);
    final r = 5.4 * scale;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(c.dx - r * 0.35, c.dy - r * 0.35),
          r * 1.4,
          const [Color(0xFF91E89C), Color(0xFF388E4E)],
        ),
    );
  }

  void _drawFluffyCloud(Canvas canvas, Offset center, double width, double alpha) {
    final h = width * 0.36;
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - h),
        Offset(center.dx, center.dy + h * 0.5),
        [
          Colors.white.withValues(alpha: alpha),
          const Color(0xFFE3ECF7).withValues(alpha: alpha),
        ],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: width, height: h),
        Radius.circular(h * 0.5),
      ),
      paint,
    );
    canvas.drawCircle(Offset(center.dx - width * 0.18, center.dy - h * 0.32), width * 0.18, paint);
    canvas.drawCircle(Offset(center.dx + width * 0.12, center.dy - h * 0.38), width * 0.21, paint);
  }

  @override
  bool shouldRepaint(covariant _SkyIslands3DPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected;
}

/// Stage 10: Crystal Temple – ancient isometric stepped temple with central
/// stairs, glowing orange & golden crystals, floating crystal fragments, and
/// glowing golden artifact at the apex.
class _CrystalTemple3DPainter extends CustomPainter {
  final bool isSelected;

  const _CrystalTemple3DPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.50;
    final baseOrigin = Offset(cx, size.height * 0.44);
    final uVec = Offset(size.width * 0.19, size.height * 0.11);
    final vVec = Offset(-size.width * 0.19, size.height * 0.11);

    Offset iso(double u, double v, [double z = 0.0]) {
      return baseOrigin + uVec * u + vVec * v + Offset(0, -z);
    }

    // 1. Soft golden-orange ambient ground shadow
    _StageArtHelpers.drawGroundShadow(
      canvas,
      Offset(cx, size.height * 0.84),
      size.width * 0.40,
      size.height * 0.13,
      alpha: isSelected ? 0.34 : 0.22,
      blur: 7.5,
    );

    // 2. Stepped isometric temple base plinth & grand central stairs
    _drawIsoBox(
      canvas,
      iso: iso,
      u0: -1.15,
      u1: 1.15,
      v0: -1.15,
      v1: 1.15,
      z0: -14.0,
      z1: -6.0,
      topColors: const [Color(0xFFFFFFFF), Color(0xFFF6DFCF)],
      leftColor: const Color(0xFFF3DAC7),
      rightColor: const Color(0xFFD5B199),
    );

    // Main temple sanctuary block
    _drawIsoBox(
      canvas,
      iso: iso,
      u0: -0.78,
      u1: 0.78,
      v0: -0.78,
      v1: 0.78,
      z0: -6.0,
      z1: 9.0,
      topColors: const [Color(0xFFFFFFFF), Color(0xFFF9E6D6)],
      leftColor: const Color(0xFFF7E2D2),
      rightColor: const Color(0xFFD9B49B),
    );

    // Stepped pyramid roof tier
    _drawIsoBox(
      canvas,
      iso: iso,
      u0: -0.52,
      u1: 0.52,
      v0: -0.52,
      v1: 0.52,
      z0: 9.0,
      z1: 15.5,
      topColors: const [Color(0xFFFFF8F0), Color(0xFFFFDFC4)],
      leftColor: const Color(0xFFFFD8BA),
      rightColor: const Color(0xFFE0B08E),
    );

    // 3. Grand central doorway & stairs on the left-front face (v = 0.78)
    final doorTL = iso(-0.24, 0.79, 3.5);
    final doorTR = iso(0.24, 0.79, 3.5);
    final doorBR = iso(0.24, 0.79, -6.0);
    final doorBL = iso(-0.24, 0.79, -6.0);
    canvas.drawPath(
      Path()
        ..moveTo(doorTL.dx, doorTL.dy)
        ..lineTo(doorTR.dx, doorTR.dy)
        ..lineTo(doorBR.dx, doorBR.dy)
        ..lineTo(doorBL.dx, doorBL.dy)
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(
          doorTL,
          doorBR,
          const [Color(0xFFFFA95C), Color(0xFF6B2A12)],
        ),
    );
    // Three stepped front stairs leading down from doorway
    for (int s = 0; s < 3; s++) {
      _drawIsoBox(
        canvas,
        iso: iso,
        u0: -0.32,
        u1: 0.32,
        v0: 0.78 + s * 0.14,
        v1: 0.94 + s * 0.14,
        z0: -14.0,
        z1: -6.5 - s * 2.4,
        topColors: const [Color(0xFFFFFFFF), Color(0xFFFCE8D8)],
        leftColor: const Color(0xFFF0D2BC),
        rightColor: const Color(0xFFCFA88E),
      );
    }

    // 4. Large glowing orange & golden crystals flanking the temple
    _draw3DCrystal(
      canvas,
      base: iso(-0.95, 0.55, -6.0),
      width: 9.5,
      height: 20.0,
      lit: const Color(0xFFFFF1A8),
      mid: const Color(0xFFFF9838),
      shade: const Color(0xFFD63B00),
      tilt: -0.18,
    );
    _draw3DCrystal(
      canvas,
      base: iso(0.95, -0.45, -6.0),
      width: 9.5,
      height: 21.0,
      lit: const Color(0xFFFFF5B8),
      mid: const Color(0xFFFFB733),
      shade: const Color(0xFFD96500),
      tilt: 0.20,
    );
    _draw3DCrystal(
      canvas,
      base: iso(0.75, 0.92, -6.0),
      width: 8.0,
      height: 15.5,
      lit: const Color(0xFFFFE5A3),
      mid: const Color(0xFFFF6D28),
      shade: const Color(0xFFB82B00),
      tilt: 0.12,
    );

    // 5. Floating crystal fragments hovering around the temple
    _draw3DCrystal(
      canvas,
      base: Offset(cx - size.width * 0.31, size.height * 0.34),
      width: 5.5,
      height: 10.5,
      lit: const Color(0xFFFFF7B8),
      mid: const Color(0xFFFFAE38),
      shade: const Color(0xFFD94A00),
      tilt: -0.25,
    );
    _draw3DCrystal(
      canvas,
      base: Offset(cx + size.width * 0.32, size.height * 0.36),
      width: 5.5,
      height: 10.5,
      lit: const Color(0xFFFFF7B8),
      mid: const Color(0xFFFF8833),
      shade: const Color(0xFFCC3800),
      tilt: 0.28,
    );

    // 6. Glowing golden treasure artifact hovering at the top
    final apex = iso(0, 0, 23.5);
    canvas.drawCircle(
      apex,
      11.5,
      Paint()
        ..shader = ui.Gradient.radial(
          apex,
          11.5,
          [
            const Color(0xFFFFE57F).withValues(alpha: 0.55),
            const Color(0xFFFF7A28).withValues(alpha: 0.18),
            const Color(0xFFFF550D).withValues(alpha: 0.0),
          ],
          const [0.0, 0.55, 1.0],
        ),
    );
    _draw3DCrystal(
      canvas,
      base: Offset(apex.dx, apex.dy + 6.5),
      width: 9.0,
      height: 13.5,
      lit: const Color(0xFFFFFFFF),
      mid: const Color(0xFFFFD54F),
      shade: const Color(0xFFE66A00),
    );
  }

  void _drawIsoBox(
    Canvas canvas, {
    required Offset Function(double u, double v, [double z]) iso,
    required double u0,
    required double u1,
    required double v0,
    required double v1,
    required double z0,
    required double z1,
    required List<Color> topColors,
    required Color leftColor,
    required Color rightColor,
  }) {
    final bL = iso(u0, v1, z0);
    final bB = iso(u1, v1, z0);
    final bR = iso(u1, v0, z0);

    final tT = iso(u0, v0, z1);
    final tR = iso(u1, v0, z1);
    final tB = iso(u1, v1, z1);
    final tL = iso(u0, v1, z1);

    // Left-front face
    canvas.drawPath(
      Path()
        ..moveTo(tL.dx, tL.dy)
        ..lineTo(tB.dx, tB.dy)
        ..lineTo(bB.dx, bB.dy)
        ..lineTo(bL.dx, bL.dy)
        ..close(),
      Paint()..color = leftColor,
    );
    // Right-front face
    canvas.drawPath(
      Path()
        ..moveTo(tB.dx, tB.dy)
        ..lineTo(tR.dx, tR.dy)
        ..lineTo(bR.dx, bR.dy)
        ..lineTo(bB.dx, bB.dy)
        ..close(),
      Paint()..color = rightColor,
    );
    // Top face
    final topPath = Path()
      ..moveTo(tT.dx, tT.dy)
      ..lineTo(tR.dx, tR.dy)
      ..lineTo(tB.dx, tB.dy)
      ..lineTo(tL.dx, tL.dy)
      ..close();
    canvas.drawPath(
      topPath,
      Paint()..shader = ui.Gradient.linear(tT, tB, topColors),
    );
    canvas.drawPath(
      topPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  @override
  bool shouldRepaint(covariant _CrystalTemple3DPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected;
}
