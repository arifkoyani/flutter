import 'package:material_ui/material_ui.dart';
import 'game_play_screen.dart';
import '../data/levels_data.dart';
import '../database/game_database.dart';
import '../widgets/adventure_background.dart';

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
  late final TransformationController _transformationController;

  late final AnimationController _floatController;
  late final Animation<double> _zLiftAnimation;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
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
    _floatController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _onLevelTap(AdventureLevel level) {
    setState(() {
      _selectedLevelId = level.id;
    });
  }

  AdventureLevel get _selectedLevel =>
      _levels.firstWhere((lvl) => lvl.id == _selectedLevelId);

  void _resetZoom() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFC),
      body: Stack(
        children: [
          const AdventureDashboardBackground(),
          SafeArea(
            child: Column(
          children: [
            // Minimal Top Bar with generous white space & Settings/Zoom Reset
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Quick Zoom Reset Pill
                  GestureDetector(
                    onTap: _resetZoom,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.center_focus_strong_rounded,
                            size: 15,
                            color: Color(0xFF666666),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'RESET VIEW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF666666),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Settings Button
                  if (widget.onSettingsPressed != null)
                    IconButton(
                      icon: const Icon(
                        Icons.settings_rounded,
                        color: primaryOrange,
                        size: 28,
                      ),
                      tooltip: 'Settings',
                      onPressed: widget.onSettingsPressed,
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),

            // Interactive Pan & Zoom Area (Drag up/down, Zoom in/out)
            Expanded(
              child: ClipRect(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  boundaryMargin: const EdgeInsets.symmetric(
                    horizontal: 120.0,
                    vertical: 240.0,
                  ),
                  minScale: 0.75,
                  maxScale: 2.2,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 16.0,
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

                        // Winding Upward Adventure Path
                        _buildWindingLevelPath(),

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
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Fixed Bottom Play Button Area
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                bottom: 20.0,
                top: 8.0,
              ),
              child: _buildPlayButton(),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildWindingLevelPath() {
    final reversedLevels = _levels.reversed.toList();

    // Alternating horizontal alignments:
    // Stage 5: Center
    // Stage 4: Center-Right
    // Stage 3: Center-Left
    // Stage 2: Center-Right
    // Stage 1: Center-Left
    final alignments = [
      Alignment.center,
      Alignment.centerRight,
      Alignment.centerLeft,
      Alignment.centerRight,
      Alignment.centerLeft,
    ];

    // Connection path fractions (0.0=left, 1.0=right)
    final fractions = [0.5, 0.85, 0.15, 0.85, 0.15];

    return Column(
      children: List.generate(reversedLevels.length, (index) {
        final level = reversedLevels[index];
        final alignment = alignments[index];
        final isSelected = level.id == _selectedLevelId;

        return Column(
          children: [
            Align(
              alignment: alignment,
              child: _build3DLevelCard(level, isSelected),
            ),
            if (index < reversedLevels.length - 1)
              _buildPathConnector(
                startFraction: fractions[index],
                endFraction: fractions[index + 1],
              ),
          ],
        );
      }),
    );
  }

  // 3D Box with Z-axis depth, multi-layered shadows, and smooth animation
  Widget _build3DLevelCard(AdventureLevel level, bool isSelected) {
    final isUnlocked = level.isUnlocked;

    return GestureDetector(
      onTap: () => _onLevelTap(level),
      child: AnimatedBuilder(
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
                child: Text(
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
              ),
              const SizedBox(height: 12),

              // Level Icon Orb with inner shadow
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
      ),
    );
  }

  Widget _buildPathConnector({
    required double startFraction,
    required double endFraction,
  }) {
    return SizedBox(
      height: 48,
      child: Center(
        child: CustomPaint(
          size: const Size(180, 48),
          painter: _WindingPathPainter(
            startFraction: startFraction,
            endFraction: endFraction,
            color: primaryOrange.withValues(alpha: 0.35),
          ),
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

// Custom painter for curved winding path with 3D gradient look
class _WindingPathPainter extends CustomPainter {
  final double startFraction;
  final double endFraction;
  final Color color;

  _WindingPathPainter({
    required this.startFraction,
    required this.endFraction,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final startX = 24.0 + (size.width - 48.0) * startFraction;
    final endX = 24.0 + (size.width - 48.0) * endFraction;

    path.moveTo(startX, 0);
    path.cubicTo(
      startX,
      size.height * 0.55,
      endX,
      size.height * 0.45,
      endX,
      size.height,
    );

    // Draw dashed path
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WindingPathPainter oldDelegate) {
    return oldDelegate.startFraction != startFraction ||
        oldDelegate.endFraction != endFraction ||
        oldDelegate.color != color;
  }
}
