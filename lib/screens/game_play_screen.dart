import 'package:material_ui/material_ui.dart';
import '../models/puzzle_level.dart';
import '../data/levels_data.dart';
import '../widgets/puzzle_board.dart';
import '../database/game_database.dart';

class GamePlayScreen extends StatefulWidget {
  final int levelId;

  const GamePlayScreen({
    super.key,
    this.levelId = 1,
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  static const Color primaryOrange = Color(0xFFFF550D);

  late PuzzleLevel _level;
  late List<ArrowItem> _arrows;
  int _mistakes = 0;
  int _remainingArrows = 0;
  bool _isGameOver = false;
  bool _isVictory = false;

  @override
  void initState() {
    super.initState();
    _loadLevel(widget.levelId);
  }

  void _loadLevel(int id) {
    _level = LevelsData.getLevel(id);
    _arrows = _level.initialArrows.map((a) => a.clone()).toList();
    _mistakes = 0;
    _remainingArrows = _arrows.length;
    _isGameOver = false;
    _isVictory = false;
  }

  void _resetCurrentLevel() {
    setState(() {
      _loadLevel(_level.id);
    });
  }

  void _onArrowTapped(ArrowItem arrow, bool isClear) {
    if (_isGameOver || _isVictory) return;

    if (isClear) {
      setState(() {
        arrow.isExited = true;
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

      if (_mistakes >= _level.maxMistakes) {
        _handleGameOver();
      }
    }
  }

  Future<void> _handleVictory() async {
    _isVictory = true;

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: primaryOrange, size: 26),
            tooltip: 'Restart Level',
            onPressed: _resetCurrentLevel,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Top Status HUD (Mistakes Hearts & Arrows Remaining)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mistakes tracker (Hearts)
                    _buildMistakesHUD(),

                    // Remaining Arrows Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryOrange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: primaryOrange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_remainingArrows / ${_arrows.length} LEFT',
                            style: const TextStyle(
                              color: primaryOrange,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Gameplay Objective Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8ECF2)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tap arrows that have an unobstructed path to exit!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Interactive Puzzle Board
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: PuzzleBoard(
                  gridSize: _level.gridSize,
                  arrows: _arrows,
                  onArrowTap: _onArrowTapped,
                ),
              ),

              const SizedBox(height: 20),

              // Bottom restart button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _resetCurrentLevel,
                    icon: const Icon(Icons.replay_rounded, color: primaryOrange),
                    label: const Text(
                      'Reset Puzzle',
                      style: TextStyle(
                        color: primaryOrange,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryOrange, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3 Mistakes indicator (Hearts)
  Widget _buildMistakesHUD() {
    return Row(
      children: [
        const Text(
          'MISTAKES: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF666666),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(_level.maxMistakes, (index) {
          final isLost = index < _mistakes;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Icon(
              isLost ? Icons.heart_broken_rounded : Icons.favorite_rounded,
              color: isLost ? const Color(0xFFB0B0B0) : const Color(0xFFFF3B30),
              size: 22,
            ),
          );
        }),
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
              'You cleared all 10 arrows with $_mistakes mistake${_mistakes == 1 ? '' : 's'}.',
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
                  if (_level.id < 5) {
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
                  _level.id < 5 ? 'Next Stage' : 'Back to Adventure Map',
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
            const Text(
              'You made 3 mistakes.\nCheck the path of the arrows carefully!',
              textAlign: TextAlign.center,
              style: TextStyle(
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
    );
  }
}
