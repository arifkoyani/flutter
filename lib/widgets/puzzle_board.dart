import 'package:material_ui/material_ui.dart';
import '../models/puzzle_level.dart';

class PuzzleBoard extends StatefulWidget {
  final int gridSize;
  final List<ArrowItem> arrows;
  final Function(ArrowItem arrow, bool isClear) onArrowTap;

  const PuzzleBoard({
    super.key,
    required this.gridSize,
    required this.arrows,
    required this.onArrowTap,
  });

  @override
  State<PuzzleBoard> createState() => _PuzzleBoardState();
}

class _PuzzleBoardState extends State<PuzzleBoard>
    with TickerProviderStateMixin {
  static const Color primaryOrange = Color(0xFFFF550D);

  int? _shakingArrowId;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  bool _isPathClear(ArrowItem arrow) {
    int r = arrow.row + arrow.direction.deltaRow;
    int c = arrow.col + arrow.direction.deltaCol;

    while (r >= 0 && r < widget.gridSize && c >= 0 && c < widget.gridSize) {
      final isOccupied = widget.arrows.any(
        (other) => !other.isExited && other.row == r && other.col == c,
      );
      if (isOccupied) {
        return false; // Another arrow blocks its path!
      }
      r += arrow.direction.deltaRow;
      c += arrow.direction.deltaCol;
    }
    return true; // Path is clear to the boundary!
  }

  void _handleTap(ArrowItem arrow) {
    if (arrow.isExited) return;

    final clear = _isPathClear(arrow);

    if (clear) {
      widget.onArrowTap(arrow, true);
    } else {
      // Trigger blocked shake animation
      setState(() {
        _shakingArrowId = arrow.id;
      });
      _shakeController.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _shakingArrowId = null;
          });
        }
      });
      widget.onArrowTap(arrow, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth < 380.0
            ? constraints.maxWidth
            : 360.0;
        final cellSize = (boardSize - 32) / widget.gridSize;

        return Center(
          child: Container(
            width: boardSize,
            height: boardSize,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FB),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background Grid Cells
                Positioned.fill(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: widget.gridSize,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: widget.gridSize * widget.gridSize,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFEEF0F3),
                            width: 1.2,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Arrow Tiles
                ...widget.arrows.map((arrow) {
                  if (arrow.isExited) return const SizedBox.shrink();

                  final isShaking = _shakingArrowId == arrow.id;
                  final left = arrow.col * (cellSize + 8) + 4;
                  final top = arrow.row * (cellSize + 8) + 4;

                  return Positioned(
                    left: left,
                    top: top,
                    child: GestureDetector(
                      onTap: () => _handleTap(arrow),
                      child: AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          final shakeOffset = isShaking
                              ? (arrow.direction.deltaCol != 0
                                  ? Offset(_shakeAnimation.value, 0)
                                  : Offset(0, _shakeAnimation.value))
                              : Offset.zero;

                          return Transform.translate(
                            offset: shakeOffset,
                            child: child,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: cellSize - 8,
                          height: cellSize - 8,
                          decoration: BoxDecoration(
                            gradient: isShaking
                                ? const LinearGradient(
                                    colors: [Color(0xFFFF3B30), Color(0xFFD63031)],
                                  )
                                : const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFF6B2B),
                                      primaryOrange,
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isShaking
                                  ? Colors.redAccent
                                  : const Color(0xFFFF8547),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isShaking
                                    ? Colors.red.withValues(alpha: 0.45)
                                    : primaryOrange.withValues(alpha: 0.38),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              arrow.direction.icon,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
