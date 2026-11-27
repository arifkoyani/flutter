import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'game_play_screen.dart';
import '../data/levels_data.dart';
import '../database/game_database.dart';
import '../widgets/adventure_background.dart';
import '../widgets/stage_illustrations.dart';

class AdventureLevel {
  final int id;
  final String name;
  final String subtitle;
  final IconData icon;
  final bool isUnlocked;

  const AdventureLevel({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    this.isUnlocked = false,
  });
}

class AdventureMapScreen extends StatefulWidget {
  final VoidCallback? onSettingsPressed;

  const AdventureMapScreen({
    super.key,
    this.onSettingsPressed,
  });

  @override
  State<AdventureMapScreen> createState() => _AdventureMapScreenState();
}

class _AdventureMapScreenState extends State<AdventureMapScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryOrange = Color(0xFFFF550D);

  static const List<IconData> _stageIcons = [
    Icons.explore_rounded,
    Icons.park_rounded,
    Icons.grid_4x4_rounded,
    Icons.wb_sunny_rounded,
    Icons.emoji_events_rounded,
  ];

  List<AdventureLevel> get _levels {
    final summaries = LevelsData.levelSummaries;
    return List.generate(summaries.length, (index) {
      final summary = summaries[index];
      final icon = _stageIcons[index % _stageIcons.length];
      return AdventureLevel(
        id: summary.id,
        name: summary.levelName,
        subtitle: summary.subtitle,
        icon: icon,
        isUnlocked: GameDatabase.instance.isLevelUnlocked(summary.id),
      );
    });
  }

  int _selectedLevelId = 1;
  final Map<int, Offset> _cardOffsets = {};
  late final TransformationController _transformationController;

  late final AnimationController _floatController;
  late final Animation<double> _zLiftAnimation;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    GameDatabase.instance.addListener(_onProgressChanged);
    GameDatabase.instance.init();
    if (!LevelsData.isLoaded) {
      LevelsData.load().then((_) {
        if (mounted) setState(() {});
      });
    }

    // Subtle Z-axis breathing & lift animation (2000ms loop)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _zLiftAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    GameDatabase.instance.removeListener(_onProgressChanged);
    _floatController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  void _onLevelTap(AdventureLevel level) {
    setState(() {
      _selectedLevelId = level.id;
    });
  }

  AdventureLevel get _selectedLevel =>
      _levels.firstWhere((lvl) => lvl.id == _selectedLevelId);

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFC),
      body: Stack(
        children: [
          const AdventureDashboardBackground(),

          // Whole-screen interactive pan & zoom Adventure Map (no clipping overlay)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return InteractiveViewer(
                  transformationController: _transformationController,
                  constrained: false,
                  clipBehavior: Clip.none,
                  boundaryMargin: const EdgeInsets.symmetric(
                    horizontal: 140.0,
                    vertical: 220.0,
                  ),
                  minScale: 0.65,
                  maxScale: 2.2,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                        top: mediaPadding.top + 18.0,
                        bottom: mediaPadding.bottom + 104.0,
                      ),
                      child: Column(
                        children: [
                          // Summit Peak Badge (Top of the Mountain)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: primaryOrange.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: primaryOrange.withValues(alpha: 0.25),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryOrange.withValues(alpha: 0.1),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.flag_rounded,
                                  size: 16,
                                  color: primaryOrange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'THE SUMMIT • STAGE ${_levels.last.id}',
                                  style: const TextStyle(
                                    color: primaryOrange,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Winding Upward Adventure Path with draggable cards & flexible thread
                          _buildWindingLevelPath(constraints.maxWidth - 40.0),

                          const SizedBox(height: 24),

                          // Bottom Start Marker
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE5E5E5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.navigation_rounded,
                                  size: 14,
                                  color: primaryOrange,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'STARTING BASE • STAGE ${_levels.first.id}',
                                  style: TextStyle(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Top-right Settings Button (floating, no top bar overlay)
          if (widget.onSettingsPressed != null)
            Positioned(
              top: mediaPadding.top + 8.0,
              right: 12.0,
              child: IconButton(
                icon: const Icon(
                  Icons.settings_rounded,
                  color: primaryOrange,
                  size: 28,
                ),
                tooltip: 'Settings',
                onPressed: widget.onSettingsPressed,
              ),
            ),

          // Bottom Play Button
          Positioned(
            left: 20.0,
            right: 20.0,
            bottom: mediaPadding.bottom + 20.0,
            child: _buildPlayButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildWindingLevelPath(double contentWidth) {
    final reversedLevels = _levels.reversed.toList();
    const cardWidth = 178.0;
    const cardHeight = 198.0;
    const verticalPitch = 246.0;
    final horizontalRange = math.max(0.0, contentWidth - cardWidth);

    // Alternating horizontal fractions (Stage 5 Center -> Stage 1 Left)
    final alignFractions = [0.5, 1.0, 0.0, 1.0, 0.0];
    final totalHeight = (reversedLevels.length - 1) * verticalPitch + cardHeight + 16.0;

    Offset baseTopLeft(int index) {
      final frac = alignFractions[index % alignFractions.length];
      return Offset(horizontalRange * frac, index * verticalPitch);
    }

    Offset cardTopLeft(int index, int levelId) {
      return baseTopLeft(index) + (_cardOffsets[levelId] ?? Offset.zero);
    }

    return SizedBox(
      width: contentWidth,
      height: totalHeight,
      child: AnimatedBuilder(
        animation: _zLiftAnimation,
        builder: (context, _) {
          final anchors = List<Offset>.generate(reversedLevels.length, (index) {
            final level = reversedLevels[index];
            final topLeft = cardTopLeft(index, level.id);
            final isSelected = level.id == _selectedLevelId;
            final liftY = isSelected ? (-8.0 - _zLiftAnimation.value * 2.4) : 0.0;
            return Offset(
              topLeft.dx + cardWidth * 0.5,
              topLeft.dy + cardHeight * 0.5 + liftY,
            );
          });

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Flexible connecting thread painted live behind the cards
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    key: const ValueKey('flexible_stage_threads'),
                    painter: _FlexibleThreadPainter(
                      anchors: anchors,
                      color: primaryOrange,
                    ),
                  ),
                ),
              ),

              // Slide-draggable stage cards (up, down, left, right)
              ...List.generate(reversedLevels.length, (index) {
                final level = reversedLevels[index];
                final isSelected = level.id == _selectedLevelId;
                final pos = cardTopLeft(index, level.id);
                final base = baseTopLeft(index);

                return Positioned(
                  left: pos.dx,
                  top: pos.dy,
                  child: GestureDetector(
                    key: ValueKey('draggable_stage_card_${level.id}'),
                    behavior: HitTestBehavior.opaque,
                    dragStartBehavior: DragStartBehavior.down,
                    onTap: () => _onLevelTap(level),
                    onPanStart: (_) => _onLevelTap(level),
                    onPanUpdate: (details) {
                      setState(() {
                        final current = _cardOffsets[level.id] ?? Offset.zero;
                        final next = current + details.delta;
                        final minDx = -base.dx - 24.0;
                        final maxDx = (horizontalRange - base.dx) + 24.0;
                        final minDy = -base.dy - 36.0;
                        final maxDy = (totalHeight - cardHeight - base.dy) + 36.0;
                        _cardOffsets[level.id] = Offset(
                          next.dx.clamp(minDx, maxDx).toDouble(),
                          next.dy.clamp(minDy, maxDy).toDouble(),
                        );
                      });
                    },
                    child: _build3DLevelCard(level, isSelected),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  // 3D Box with Z-axis depth, multi-layered shadows, and smooth animation
  Widget _build3DLevelCard(AdventureLevel level, bool isSelected) {
    final isUnlocked = level.isUnlocked;
    final isCompleted = GameDatabase.instance.getRecord(level.id).isCompleted;

    return AnimatedBuilder(
        animation: _zLiftAnimation,
        builder: (context, child) {
          // Dynamic Z-axis translation and perspective tilt
          final dynamicLift = isSelected ? (_zLiftAnimation.value * 6.0) : 0.0;
          final zTranslation = isSelected ? (24.0 + dynamicLift) : 0.0;
          final yTranslation = isSelected ? (-8.0 - dynamicLift * 0.4) : 0.0;
          final scaleFactor = isSelected ? 1.05 : 1.0;

          // 3D Perspective Matrix (Move in Z-axis toward user)
          final transformMatrix = Matrix4.identity()
            ..setEntry(3, 2, 0.0012) // Perspective focal depth
            ..translateByDouble(0.0, yTranslation, zTranslation, 1.0)
            ..scaleByDouble(scaleFactor, scaleFactor, 1.0, 1.0);

          return Transform(
            alignment: Alignment.center,
            transform: transformMatrix,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          width: 178,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryOrange
                : (isUnlocked
                    ? const Color(0xFFFFF7F2)
                    : const Color(0xFFF9F9F9)),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF7A40)
                  : (isUnlocked
                      ? primaryOrange.withValues(alpha: 0.35)
                      : const Color(0xFFE4E4E4)),
              width: isSelected ? 2.5 : 1.5,
            ),
            // Multi-layered deep shadows for modern 3D elevation
            boxShadow: isSelected
                ? [
                    // Deep contact shadow on surface below
                    BoxShadow(
                      color: primaryOrange.withValues(alpha: 0.38),
                      blurRadius: 26,
                      spreadRadius: 2,
                      offset: const Offset(0, 14),
                    ),
                    // Ambient orange glow
                    BoxShadow(
                      color: primaryOrange.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    // Top rim highlight shadow
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 2,
                      offset: const Offset(0, -1),
                    ),
                  ]
                : (isUnlocked
                    ? [
                        // Soft modern resting shadow
                        const BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 16,
                          spreadRadius: -2,
                          offset: Offset(0, 8),
                        ),
                        const BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : [
                        // Locked muted shadow
                        const BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ]),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Stage Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.22)
                      : (isUnlocked
                          ? primaryOrange.withValues(alpha: 0.12)
                          : const Color(0xFFEDEDED)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'STAGE ${level.id}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isUnlocked ? primaryOrange : const Color(0xFF888888)),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: isSelected ? Colors.white : const Color(0xFF2E9E5B),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3D Stage Illustration (Stages 1–3) or Icon Orb (Stages 4–5)
              if (Stage3DIllustration.supportsStage(level.id))
                Stage3DIllustration(
                  stageId: level.id,
                  isSelected: isSelected,
                  isUnlocked: isUnlocked,
                )
              else
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Colors.white
                        : (isUnlocked
                            ? primaryOrange.withValues(alpha: 0.14)
                            : const Color(0xFFEEEEEE)),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    isUnlocked ? level.icon : Icons.lock_rounded,
                    color: isSelected
                        ? primaryOrange
                        : (isUnlocked ? primaryOrange : const Color(0xFFAAAAAA)),
                    size: 26,
                  ),
                ),
              const SizedBox(height: 12),

              // Level Name
              Text(
                level.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isUnlocked ? Colors.black : const Color(0xFF888888)),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),

              // Subtitle
              Text(
                isUnlocked ? level.subtitle : 'Locked',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.85)
                      : (isUnlocked
                          ? const Color(0xFF777777)
                          : const Color(0xFFAAAAAA)),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildPlayButton() {
    final level = _selectedLevel;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // Strong modern elevated button shadow
          BoxShadow(
            color: primaryOrange.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (!level.isUnlocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF1E293B),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                content: Row(
                  children: [
                    const Icon(Icons.lock_rounded, color: Colors.amberAccent, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Stage ${level.id} is locked! Complete Stage ${level.id - 1} first.',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 2),
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GamePlayScreen(levelId: level.id),
            ),
          ).then((_) {
            if (mounted) setState(() {});
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, size: 30, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'PLAY • STAGE ${level.id}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a flexible elastic connecting thread linking consecutive stage cards.
class _FlexibleThreadPainter extends CustomPainter {
  final List<Offset> anchors;
  final Color color;

  const _FlexibleThreadPainter({
    required this.anchors,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (anchors.length < 2) return;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    final threadPaint = Paint()
      ..color = color.withValues(alpha: 0.42)
      ..strokeWidth = 4.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.50)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < anchors.length - 1; i++) {
      final a = anchors[i];
      final b = anchors[i + 1];
      final delta = b - a;
      final dist = delta.distance;
      final slack = math.max(0.0, 280.0 - dist);
      final sag = 10.0 + slack * 0.32;

      final cp1 = Offset(
        a.dx + delta.dx * 0.16,
        a.dy + delta.dy * 0.48 + sag,
      );
      final cp2 = Offset(
        b.dx - delta.dx * 0.16,
        b.dy - delta.dy * 0.48 + sag,
      );

      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, b.dx, b.dy);

      canvas.save();
      canvas.translate(0.0, 3.5);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();

      canvas.drawPath(path, threadPaint);
      canvas.drawPath(path, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FlexibleThreadPainter oldDelegate) {
    if (oldDelegate.color != color || oldDelegate.anchors.length != anchors.length) {
      return true;
    }
    for (int i = 0; i < anchors.length; i++) {
      if (oldDelegate.anchors[i] != anchors[i]) return true;
    }
    return false;
  }
}
