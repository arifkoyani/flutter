import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../models/puzzle_level.dart';
import '../data/levels_data.dart';
import '../widgets/gameplay_background.dart';
import '../widgets/puzzle_board.dart';
import '../database/game_database.dart';
import '../services/audio_service.dart';
import '../services/gyro_parallax_controller.dart';
import '../services/preferences_service.dart';
import 'settings/setting.dart';

class GamePlayScreen extends StatefulWidget {
  final int levelId;

  const GamePlayScreen({
    super.key,
    this.levelId = 1,
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Color primaryOrange = Color(0xFFFF550D);

  late PuzzleLevel _level;
  late List<CanvasArrow> _arrows;
  int _mistakes = 0;
  int _remainingArrows = 0;
  int _remainingSeconds = 60;
  int _levelRunCount = 0;
  bool _isGameOver = false;
  bool _isVictory = false;
  bool _isTimeUp = false;
  bool _isAppPaused = false;

  Timer? _countdownTimer;
  late final GyroParallaxController _parallaxController;
  late final AnimationController _mistakeFlashController;
  late final Animation<double> _mistakeFlashAnimation;

  @visibleForTesting
  GyroParallaxController get parallaxController => _parallaxController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _parallaxController = GyroParallaxController()..start();
    _mistakeFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _mistakeFlashAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
    ]).animate(_mistakeFlashController);
    _loadLevel(widget.levelId);
    if (!LevelsData.isLoaded) {
      LevelsData.load().then((_) {
        if (mounted &&
            _mistakes == 0 &&
            _remainingArrows == _arrows.length &&
            !_isGameOver &&
            !_isVictory) {
          setState(() {
            _loadLevel(widget.levelId);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _parallaxController.dispose();
    _mistakeFlashController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AudioService.instance.handleAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _parallaxController.pause();
        if (!_isAppPaused) {
          setState(() {
            _isAppPaused = true;
          });
          _countdownTimer?.cancel();
          _countdownTimer = null;
        }
        break;
      case AppLifecycleState.resumed:
        _parallaxController.resume();
        if (_isAppPaused) {
          setState(() {
            _isAppPaused = false;
          });
          if (!_isGameOver && !_isVictory && _remainingSeconds > 0) {
            _startCountdown();
          }
        }
        break;
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload cannot fill fields added to arrows already on screen.
    _loadLevel(_level.id);
  }

  void _loadLevel(int id) {
    _countdownTimer?.cancel();
    _levelRunCount++;
    _level = LevelsData.getLevel(id);
    _arrows = _level.arrows.map((a) => a.clone()).toList();
    _mistakes = 0;
    _remainingArrows = _arrows.length;
    _remainingSeconds = _level.durationSeconds;
    _isGameOver = false;
    _isVictory = false;
    _isTimeUp = false;
    _mistakeFlashController.reset();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (_isAppPaused || _isGameOver || _isVictory) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isGameOver || _isVictory || _isAppPaused) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
        });
        _onTimeUp();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _onTimeUp() {
    if (_isGameOver || _isVictory) return;
    _isTimeUp = true;
    _mistakeFlashController.forward(from: 0.0);
    if (PreferencesService.instance.isVibrationOn) {
      HapticFeedback.mediumImpact();
    }
    AudioService.instance.playGameOverSound();
    _handleGameOver();
  }

  void _resetCurrentLevel() {
    setState(() {
      _loadLevel(_level.id);
    });
  }

  void _onArrowTapped(CanvasArrow arrow, bool isClear) {
    if (_isGameOver || _isVictory || _isAppPaused) return;

    if (isClear) {
      AudioService.instance.playSwooshSound();
      if (PreferencesService.instance.isVibrationOn) {
        HapticFeedback.lightImpact();
      }

      setState(() {
        _remainingArrows--;
      });

      // Check for victory
      if (_remainingArrows == 0) {
        _handleVictory();
      }
    } else {
      // Mistake made
      setState(() {
        _mistakes++;
      });
      _mistakeFlashController.forward(from: 0.0);

      if (PreferencesService.instance.isVibrationOn) {
        HapticFeedback.mediumImpact();
      }

      if (_mistakes >= _level.maxMistakes) {
        AudioService.instance.playGameOverSound();
        _handleGameOver();
      } else {
        AudioService.instance.playMistakeSound();
      }
    }
  }

  Future<void> _handleVictory() async {
    _isVictory = true;
    _countdownTimer?.cancel();

    // Play stage complete win sound effect
    AudioService.instance.playWinSound();

    // Calculate stars: 0 mistakes = 3 stars, 1 = 2 stars, 2 = 1 star
    final starsEarned = _mistakes == 0
        ? 3
        : (_mistakes == 1 ? 2 : 1);

    // Record in local game database
    await GameDatabase.instance.recordLevelCompletion(
      levelId: _level.id,
      stars: starsEarned,
      mistakes: _mistakes,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _buildVictoryDialog(starsEarned);
      },
    );
  }

  void _handleGameOver() {
    _isGameOver = true;
    _countdownTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _buildGameOverDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const GameplayBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Stage ${_level.id}: ${_level.name}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Top-right Settings button (replaced refresh button)
          IconButton(
            icon: const Icon(
              Icons.settings_rounded,
              color: primaryOrange,
              size: 28,
            ),
            tooltip: 'Settings',
            onPressed: () async {
              _countdownTimer?.cancel();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingScreen(),
                ),
              );
              if (mounted &&
                  !_isGameOver &&
                  !_isVictory &&
                  _remainingSeconds > 0) {
                _startCountdown();
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSide = math.min(constraints.maxWidth - 24.0, 460.0);
            final minNeeded = boardSide + 148.0;
            if (constraints.maxHeight >= minNeeded) {
              return Column(
                children: [
                  _buildHudColumn(),
                  Expanded(
                    child: ClipRect(
                      clipper: _BelowBannerClipper(),
                      child: Center(
                        child: FractionalTranslation(
                          translation: const Offset(0.0, -0.10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: _buildPuzzleBoard(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  _buildHudColumn(),
                  ClipRect(
                    clipper: _BelowBannerClipper(),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: _buildPuzzleBoard(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _mistakeFlashAnimation,
              builder: (context, _) {
                final intensity = _mistakeFlashAnimation.value;
                if (intensity <= 0.001) {
                  return const SizedBox.shrink();
                }
                return CustomPaint(
                  key: const ValueKey('mistake_edge_blur_overlay'),
                  painter: _MistakeEdgeBlurPainter(intensity: intensity),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLivesHud() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFEEEEEE),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'LIVES',
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_level.maxMistakes, (index) {
                final isAlive = index < (_level.maxMistakes - _mistakes);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Icon(
                      isAlive
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey<bool>(isAlive),
                      size: 24,
                      color: isAlive
                          ? const Color(0xFFFF3B30)
                          : const Color(0xFFD1D5DB),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildTimerHud() {
    final isLowTime = _remainingSeconds <= 10;
    final accentColor = isLowTime ? const Color(0xFFFF3B30) : primaryOrange;
    return Center(
      child: Container(
        key: const ValueKey('level_countdown_timer'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isLowTime
                ? const Color(0xFFFF3B30).withValues(alpha: 0.35)
                : const Color(0xFFEEEEEE),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_rounded,
              size: 18,
              color: accentColor,
            ),
            const SizedBox(width: 6),
            const Text(
              'TIME',
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(_remainingSeconds),
              style: TextStyle(
                color: isLowTime ? const Color(0xFFFF3B30) : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrowsLeftHud() {
    return Center(
      child: Container(
        key: const ValueKey('remaining_arrows_counter'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFEEEEEE),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.near_me_rounded,
              size: 17,
              color: primaryOrange,
            ),
            const SizedBox(width: 6),
            const Text(
              'ARROWS',
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$_remainingArrows',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHudColumn() {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildLivesHud(),
        const SizedBox(height: 6),
        _buildTimerHud(),
        const SizedBox(height: 6),
        _buildArrowsLeftHud(),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildPuzzleBoard() {
    return Stack(
      alignment: Alignment.center,
      children: [
        ValueListenableBuilder<Offset>(
          valueListenable: _parallaxController,
          builder: (context, parallax, _) {
            return PuzzleBoard(
              key: ValueKey(_level.id),
              levelId: _level.id,
              gridCols: _level.gridCols,
              gridRows: _level.gridRows,
              arrows: _arrows,
              walls: _level.id == 1 ? const [] : _level.walls,
              onArrowTap: _onArrowTapped,
              parallax: parallax,
            );
          },
        ),
        if (_level.id <= 2) ...[
          Positioned.fill(
            child: IgnorePointer(
              child: CubeTutorialOverlay(
                totalDurationSeconds: _level.durationSeconds,
                remainingSeconds: _remainingSeconds,
                isActive: !_isGameOver && !_isVictory && !_isAppPaused,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: const Alignment(0.0, 0.80),
                child: TapToRotateHintBar(
                  key: ValueKey('tap_to_rotate_${_level.id}_$_levelRunCount'),
                  totalDurationSeconds: _level.durationSeconds,
                  remainingSeconds: _remainingSeconds,
                  isActive: !_isGameOver && !_isVictory && !_isAppPaused,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Victory Dialog with stars
  Widget _buildVictoryDialog(int stars) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stars Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isAwarded = index < stars;
                return Icon(
                  Icons.star_rounded,
                  size: 44,
                  color: isAwarded ? const Color(0xFFFFB800) : const Color(0xFFE0E0E0),
                );
              }),
            ),
            const SizedBox(height: 16),

            const Text(
              'Stage Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You cleared all ${_arrows.length} arrows successfully!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 24),

            // Next Level Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (_level.id < LevelsData.totalLevels) {
                    setState(() {
                      _loadLevel(_level.id + 1);
                    });
                  } else {
                    Navigator.pop(context); // Return to map
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _level.id < LevelsData.totalLevels
                      ? 'Next Stage'
                      : 'Back to Adventure Map',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Return to Map
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to map
              },
              child: const Text(
                'Adventure Map',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Game Over Dialog (3 mistakes)
  Widget _buildGameOverDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(seconds: 1),
        curve: Curves.easeOutBack,
        builder: (context, t, child) {
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.75 + 0.25 * t,
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.redAccent,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Stage Failed',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isTimeUp
                    ? "Time's up!\nTry clearing the arrows before time runs out!"
                    : 'You made ${_level.maxMistakes} mistakes.\nCheck the path of the arrows carefully!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 24),

              // Retry Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _resetCurrentLevel();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Retry Stage',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Back to Adventure Map',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clips the arrow canvas strictly at y=0 (just below the objective banner),
/// while keeping left, right, and bottom wide open for full-screen escaping.
class _BelowBannerClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(-2000, 0, size.width + 2000, 3000);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

/// Renders a brief light-red Gaussian blur vignette around the screen edges
/// when the player taps a blocked (wrong) arrow.
class _MistakeEdgeBlurPainter extends CustomPainter {
  final double intensity;

  const _MistakeEdgeBlurPainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.0 || size.isEmpty) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 48.0
      ..color = const Color(0xFFFF3B30).withValues(alpha: 0.78 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36.0);

    canvas.drawRect(Offset.zero & size, edgePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MistakeEdgeBlurPainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}
