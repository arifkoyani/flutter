import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../models/puzzle_level.dart';

class LevelSummary {
  final int id;
  final String levelName;
  final String subtitle;
  final int totalArrows;
  final int durationSeconds;

  const LevelSummary({
    required this.id,
    required this.levelName,
    required this.subtitle,
    required this.totalArrows,
    required this.durationSeconds,
  });
}

class _JsonLevelConfig {
  final int id;
  final String levelName;
  final String subtitle;
  final int gridSize;
  final int maxMistakes;
  final Map<CubeFace, int> arrowsPerSide;
  final int totalArrows;
  final int durationSeconds;

  const _JsonLevelConfig({
    required this.id,
    required this.levelName,
    required this.subtitle,
    required this.gridSize,
    required this.maxMistakes,
    required this.arrowsPerSide,
    required this.totalArrows,
    required this.durationSeconds,
  });

  factory _JsonLevelConfig.fromJson(Map<String, dynamic> json) {
    final rawSides = json['arrowsPerSide'] as Map<String, dynamic>? ?? const {};
    final sides = <CubeFace, int>{
      for (final face in CubeFace.values)
        face: (rawSides[face.name] as num?)?.toInt() ?? 0,
    };
    final sumSides = sides.values.fold<int>(0, (sum, count) => sum + count);
    return _JsonLevelConfig(
      id: (json['id'] as num).toInt(),
      levelName: json['levelName'] as String? ?? 'Stage ${json['id']}',
      subtitle: json['subtitle'] as String? ?? '',
      gridSize: (json['gridSize'] as num?)?.toInt() ?? 6,
      maxMistakes: (json['maxMistakes'] as num?)?.toInt() ?? 3,
      arrowsPerSide: sides,
      totalArrows: (json['totalArrows'] as num?)?.toInt() ?? sumSides,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 60,
    );
  }
}

class LevelsData {
  static Map<int, _JsonLevelConfig> _jsonConfigs = {};
  static bool _isLoaded = false;

  static bool get isLoaded => _isLoaded;

  static int get totalLevels =>
      _jsonConfigs.isNotEmpty ? _jsonConfigs.length : levels.length;

  static List<LevelSummary> get levelSummaries {
    if (_jsonConfigs.isNotEmpty) {
      final sorted = _jsonConfigs.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      return sorted
          .map(
            (cfg) => LevelSummary(
              id: cfg.id,
              levelName: cfg.levelName,
              subtitle: cfg.subtitle,
              totalArrows: cfg.totalArrows,
              durationSeconds: cfg.durationSeconds,
            ),
          )
          .toList();
    }
    return levels
        .map(
          (lvl) => LevelSummary(
            id: lvl.id,
            levelName: lvl.name,
            subtitle: lvl.subtitle,
            totalArrows: getLevel(lvl.id).arrows.length,
            durationSeconds: lvl.durationSeconds,
          ),
        )
        .toList();
  }

  /// Loads level definitions from `assets/data/levels.json`.
  static Future<void> load() async {
    if (_isLoaded) return;
    try {
      final raw = await rootBundle.loadString('assets/data/levels.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final list = decoded['levels'] as List<dynamic>? ?? const [];
      final parsed = <int, _JsonLevelConfig>{};
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final cfg = _JsonLevelConfig.fromJson(item);
          parsed[cfg.id] = cfg;
        }
      }
      _jsonConfigs = parsed;
      _isLoaded = true;
    } catch (e) {
      debugPrint('LevelsData load fallback: $e');
    }
  }

  static final List<PuzzleLevel> levels = [
    // Level 1: First Steps (Dense non-overlapping arrows across the cube)
    PuzzleLevel(
      id: 1,
      name: 'First Steps',
      subtitle: 'Escape the Arrows',
      gridCols: 6,
      gridRows: 6,
      maxMistakes: 3,
      walls: const [],
      exits: const [],
      arrows: [
        // 1. Center vertical Up -> Clear immediately
        CanvasArrow(
          id: 1,
          points: const [Offset(2.65, 3.55), Offset(2.65, 0.35)],
          exitDirection: ArrowDirection.up,
        ),
        // 2. Center vertical Up (Behind Arrow 1) -> Blocked by Arrow 1
        CanvasArrow(
          id: 2,
          points: const [Offset(2.65, 5.65), Offset(2.65, 4.15)],
          exitDirection: ArrowDirection.up,
        ),
        // 3. Center-right vertical Down -> Clear immediately
        CanvasArrow(
          id: 3,
          points: const [Offset(3.35, 2.65), Offset(3.35, 5.65)],
          exitDirection: ArrowDirection.down,
        ),
        // 4. Center-right vertical Down (Behind Arrow 3) -> Blocked by Arrow 3
        CanvasArrow(
          id: 4,
          points: const [Offset(3.35, 0.35), Offset(3.35, 2.05)],
          exitDirection: ArrowDirection.down,
        ),
        // 5. Top-left straight Left -> Clear immediately
        CanvasArrow(
          id: 5,
          points: const [Offset(1.95, 0.45), Offset(0.40, 0.45)],
          exitDirection: ArrowDirection.left,
        ),
        // 6. Mid-left L-shape (Down then Left) -> Clear immediately
        CanvasArrow(
          id: 6,
          points: const [Offset(1.95, 1.15), Offset(1.95, 2.75), Offset(0.40, 2.75)],
          exitDirection: ArrowDirection.left,
        ),
        // 7. Upper-left Down (Behind Arrow 6) -> Blocked by Arrow 6
        CanvasArrow(
          id: 7,
          points: const [Offset(1.25, 1.15), Offset(1.25, 2.05)],
          exitDirection: ArrowDirection.down,
        ),
        // 8. Outer-left Down (Behind Arrow 6) -> Blocked by Arrow 6
        CanvasArrow(
          id: 8,
          points: const [Offset(0.55, 1.15), Offset(0.55, 2.15)],
          exitDirection: ArrowDirection.down,
        ),
        // 9. Lower-left L-shape (Right then Down) -> Clear immediately
        CanvasArrow(
          id: 9,
          points: const [Offset(0.55, 4.85), Offset(1.95, 4.85), Offset(1.95, 5.65)],
          exitDirection: ArrowDirection.down,
        ),
        // 10. Mid-left short Down (Behind Arrow 9) -> Blocked by Arrow 9
        CanvasArrow(
          id: 10,
          points: const [Offset(0.55, 3.45), Offset(0.55, 4.25)],
          exitDirection: ArrowDirection.down,
        ),
        // 11. Inner-left short Down (Behind Arrow 9) -> Blocked by Arrow 9
        CanvasArrow(
          id: 11,
          points: const [Offset(1.95, 3.35), Offset(1.95, 4.25)],
          exitDirection: ArrowDirection.down,
        ),
        // 12. Bottom-left straight Left -> Clear immediately
        CanvasArrow(
          id: 12,
          points: const [Offset(1.35, 5.55), Offset(0.40, 5.55)],
          exitDirection: ArrowDirection.left,
        ),
        // 13. Upper-right L-shape (Up then Right) -> Clear immediately
        CanvasArrow(
          id: 13,
          points: const [Offset(4.05, 1.85), Offset(4.05, 0.40), Offset(5.60, 0.40)],
          exitDirection: ArrowDirection.right,
        ),
        // 14. Center-right long Up (Behind Arrow 13) -> Blocked by Arrow 13
        CanvasArrow(
          id: 14,
          points: const [Offset(4.05, 5.60), Offset(4.05, 2.50)],
          exitDirection: ArrowDirection.up,
        ),
        // 15. Upper-right short Right -> Clear immediately
        CanvasArrow(
          id: 15,
          points: const [Offset(4.75, 1.15), Offset(5.60, 1.15)],
          exitDirection: ArrowDirection.right,
        ),
        // 16. Mid-right Down (Behind Arrow 17) -> Blocked by Arrow 17
        CanvasArrow(
          id: 16,
          points: const [Offset(4.75, 1.80), Offset(4.75, 3.60)],
          exitDirection: ArrowDirection.down,
        ),
        // 17. Bottom-right short Down -> Clear immediately
        CanvasArrow(
          id: 17,
          points: const [Offset(4.75, 4.25), Offset(4.75, 5.60)],
          exitDirection: ArrowDirection.down,
        ),
        // 18. Far-right long Down -> Clear immediately
        CanvasArrow(
          id: 18,
          points: const [Offset(5.45, 1.80), Offset(5.45, 5.60)],
          exitDirection: ArrowDirection.down,
        ),
        // 19. Inner-left mid slot Down (Behind Arrow 9) -> Blocked by Arrow 9
        CanvasArrow(
          id: 19,
          points: const [Offset(1.25, 3.45), Offset(1.25, 4.25)],
          exitDirection: ArrowDirection.down,
        ),
      ],
    ),

    // Level 2: Arrow Forest (More L-bends)
    PuzzleLevel(
      id: 2,
      name: 'Arrow Forest',
      subtitle: 'Navigate the winding woods',
      gridCols: 6,
      gridRows: 6,
      maxMistakes: 3,
      arrows: [
        CanvasArrow(
          id: 1,
          points: const [Offset(1, 4), Offset(1, 1), Offset(5, 1)],
          exitDirection: ArrowDirection.right,
        ),
        CanvasArrow(
          id: 2,
          points: const [Offset(3, 5), Offset(3, 2)],
          exitDirection: ArrowDirection.up,
        ),
        CanvasArrow(
          id: 3,
          points: const [Offset(5, 3), Offset(5, 5)],
          exitDirection: ArrowDirection.down,
        ),
      ],
    ),

    // Level 3: Mystery Maze
    PuzzleLevel(
      id: 3,
      name: 'Mystery Maze',
      subtitle: 'Twisted corridors & tight turns',
      gridCols: 6,
      gridRows: 6,
      maxMistakes: 3,
      arrows: [
        CanvasArrow(
          id: 1,
          points: const [Offset(2, 5), Offset(2, 1)],
          exitDirection: ArrowDirection.up,
        ),
        CanvasArrow(
          id: 2,
          points: const [Offset(4, 1.5), Offset(4, 5)],
          exitDirection: ArrowDirection.down,
        ),
      ],
    ),

    // Level 4: Desert Escape
    PuzzleLevel(
      id: 4,
      name: 'Desert Escape',
      subtitle: 'Sun-baked dunes',
      gridCols: 6,
      gridRows: 6,
      maxMistakes: 3,
      arrows: [
        CanvasArrow(
          id: 1,
          points: const [Offset(1, 1), Offset(5, 1)],
          exitDirection: ArrowDirection.right,
        ),
      ],
    ),

    // Level 5: Prism Cube
    PuzzleLevel(
      id: 5,
      name: 'Prism Cube',
      subtitle: 'Floating Core',
      gridCols: 6,
      gridRows: 6,
      maxMistakes: 3,
      durationSeconds: 90,
      arrows: [
        CanvasArrow(
          id: 1,
          points: const [Offset(3, 5), Offset(3, 0.5)],
          exitDirection: ArrowDirection.up,
        ),
      ],
    ),

    // Level 6: Frozen Peaks
    PuzzleLevel(
      id: 6,
      name: 'Frozen Peaks',
      subtitle: 'Ice Adventure',
      gridCols: 7,
      gridRows: 7,
      maxMistakes: 3,
      durationSeconds: 105,
      arrows: const [],
    ),

    // Level 7: Lava Kingdom
    PuzzleLevel(
      id: 7,
      name: 'Lava Kingdom',
      subtitle: 'Fire and Fury',
      gridCols: 7,
      gridRows: 7,
      maxMistakes: 3,
      durationSeconds: 120,
      arrows: const [],
    ),

    // Level 8: Ocean Depths
    PuzzleLevel(
      id: 8,
      name: 'Ocean Depths',
      subtitle: 'Underwater Mystery',
      gridCols: 8,
      gridRows: 8,
      maxMistakes: 3,
      durationSeconds: 135,
      arrows: const [],
    ),

    // Level 9: Sky Islands
    PuzzleLevel(
      id: 9,
      name: 'Sky Islands',
      subtitle: 'Above the Clouds',
      gridCols: 8,
      gridRows: 8,
      maxMistakes: 3,
      durationSeconds: 150,
      arrows: const [],
    ),

    // Level 10: Crystal Temple
    PuzzleLevel(
      id: 10,
      name: 'Crystal Temple',
      subtitle: 'The Ultimate Quest',
      gridCols: 9,
      gridRows: 9,
      maxMistakes: 3,
      durationSeconds: 165,
      arrows: const [],
    ),
  ];

  static PuzzleLevel getLevel(int id) {
    final base = levels.firstWhere(
      (lvl) => lvl.id == id,
      orElse: () => levels.first,
    );
    final config = _jsonConfigs[id];
    final gridSize = config?.gridSize ?? base.gridCols;
    final arrows = <CanvasArrow>[];

    if (gridSize > 6) {
      final defaultCounts = <CubeFace, int>{
        CubeFace.front: 20 + (id - 6) * 4,
        CubeFace.back: 18 + (id - 6) * 4,
        CubeFace.left: 19 + (id - 6) * 4,
        CubeFace.right: 19 + (id - 6) * 4,
        CubeFace.top: 17 + (id - 6) * 4,
        CubeFace.bottom: 17 + (id - 6) * 4,
      };
      final facesOrder = [
        CubeFace.front,
        CubeFace.right,
        CubeFace.left,
        CubeFace.back,
        CubeFace.top,
        CubeFace.bottom,
      ];
      for (int fIdx = 0; fIdx < facesOrder.length; fIdx++) {
        final face = facesOrder[fIdx];
        final targetCount =
            config?.arrowsPerSide[face] ?? defaultCounts[face]!;
        arrows.addAll(
          _generateDenseFaceArrows(
            face: face,
            gridSize: gridSize,
            targetCount: targetCount,
            idOffset: (id * 1000) + (fIdx * 100) + 1,
            seed: id * 131 + fIdx * 37,
          ),
        );
      }
    } else {
      final frontPool = config != null ? levels.first.arrows : base.arrows;
      final sidePool = _sideFaceArrows();

      List<CanvasArrow> buildFaceArrows(CubeFace face, List<CanvasArrow> pool) {
        final targetCount = config?.arrowsPerSide[face];
        if (targetCount == null) {
          return pool.map((a) => a.clone()).toList();
        }
        return pool
            .take(targetCount.clamp(0, pool.length))
            .map((a) => a.clone())
            .toList();
      }

      arrows.addAll(buildFaceArrows(CubeFace.front, frontPool));
      for (final face in [
        CubeFace.right,
        CubeFace.left,
        CubeFace.back,
        CubeFace.top,
        CubeFace.bottom,
      ]) {
        arrows.addAll(
          buildFaceArrows(
            face,
            sidePool.where((a) => a.placedOn == face).toList(),
          ),
        );
      }
    }

    return PuzzleLevel(
      id: config?.id ?? base.id,
      name: config?.levelName ?? base.name,
      subtitle: (config != null && config.subtitle.isNotEmpty)
          ? config.subtitle
          : base.subtitle,
      gridCols: gridSize,
      gridRows: gridSize,
      maxMistakes: config?.maxMistakes ?? base.maxMistakes,
      durationSeconds: config?.durationSeconds ?? base.durationSeconds,
      walls: base.walls,
      exits: base.exits,
      arrows: arrows,
    );
  }

  /// Generates a dense, non-overlapping, provably solvable set of arrows
  /// on an expanded grid (Stages 6–10) by placing arrows in reverse clearing
  /// order onto discrete well-spaced lanes.
  static List<CanvasArrow> _generateDenseFaceArrows({
    required CubeFace face,
    required int gridSize,
    required int targetCount,
    required int idOffset,
    required int seed,
  }) {
    final laneCount = gridSize + 3;
    final span = gridSize - 0.90;
    final coords = List<double>.generate(
      laneCount,
      (i) => 0.45 + (i * span) / (laneCount - 1),
    );

    List<CanvasArrow> tryBuild({required bool compactOnly, required int runSeed}) {
      final occupied = List.generate(
        laneCount,
        (_) => List<bool>.filled(laneCount, false),
      );
      final rayHits = List.generate(
        laneCount,
        (_) => List<int>.filled(laneCount, 0),
      );
      final rng = math.Random(runSeed);
      final placed = <CanvasArrow>[];

      bool inBounds(int c, int r) =>
          c >= 0 && c < laneCount && r >= 0 && r < laneCount;

      int clearRaySteps(int tipC, int tipR, ArrowDirection dir) {
        final dc = dir.unitVector.dx.round();
        final dr = dir.unitVector.dy.round();
        var c = tipC + dc;
        var r = tipR + dr;
        var steps = 0;
        while (inBounds(c, r)) {
          if (occupied[c][r]) return -1;
          steps++;
          c += dc;
          r += dr;
        }
        return steps;
      }

      void markExitRay(int tipC, int tipR, ArrowDirection dir) {
        final dc = dir.unitVector.dx.round();
        final dr = dir.unitVector.dy.round();
        var c = tipC + dc;
        var r = tipR + dr;
        while (inBounds(c, r)) {
          rayHits[c][r]++;
          c += dc;
          r += dr;
        }
      }

      const dirs = [
        ArrowDirection.up,
        ArrowDirection.down,
        ArrowDirection.left,
        ArrowDirection.right,
      ];

      for (int step = 0; step < targetCount; step++) {
        final remainingNeeded = targetCount - placed.length;
        final preferCompact = compactOnly || remainingNeeded >= 14;
        final candidates = <({
          List<(int, int)> cells,
          List<Offset> points,
          ArrowDirection dir,
          int score,
        })>[];

        for (int c0 = 0; c0 < laneCount; c0++) {
          for (int r0 = 0; r0 < laneCount; r0++) {
            if (occupied[c0][r0]) continue;
            for (final dir in dirs) {
              final dc = dir.unitVector.dx.round();
              final dr = dir.unitVector.dy.round();

              // Straight segments of length 2..3 (or up to 4 when compactOnly is false)
              final maxStraight = compactOnly ? 2 : (preferCompact ? 3 : 4);
              final cells = <(int, int)>[(c0, r0)];
              for (int len = 2; len <= maxStraight; len++) {
                final nc = c0 + dc * (len - 1);
                final nr = r0 + dr * (len - 1);
                if (!inBounds(nc, nr) || occupied[nc][nr]) break;
                cells.add((nc, nr));
                final raySteps = clearRaySteps(nc, nr, dir);
                if (raySteps >= 0) {
                  var blockingScore = 0;
                  for (final cell in cells) {
                    blockingScore += rayHits[cell.$1][cell.$2] * 5;
                  }
                  final score = blockingScore +
                      raySteps * 3 +
                      (compactOnly ? -len * 2 : len * 2) +
                      rng.nextInt(4);
                  candidates.add((
                    cells: List<(int, int)>.from(cells),
                    points: [
                      Offset(coords[c0], coords[r0]),
                      Offset(coords[nc], coords[nr]),
                    ],
                    dir: dir,
                    score: score,
                  ));
                }
              }

              if (compactOnly) continue;

              // L-bend segments: leg1 along perp, leg2 along dir
              for (final perpSign in [-1, 1]) {
                final pdc = -dr * perpSign;
                final pdr = dc * perpSign;
                final maxLeg1 = preferCompact ? 1 : 2;
                for (int leg1 = 1; leg1 <= maxLeg1; leg1++) {
                  final bendC = c0 + pdc * leg1;
                  final bendR = r0 + pdr * leg1;
                  if (!inBounds(bendC, bendR) || occupied[bendC][bendR]) break;
                  final maxLeg2 = preferCompact ? 1 : 2;
                  for (int leg2 = 1; leg2 <= maxLeg2; leg2++) {
                    final tipC = bendC + dc * leg2;
                    final tipR = bendR + dr * leg2;
                    if (!inBounds(tipC, tipR) || occupied[tipC][tipR]) break;

                    final raySteps = clearRaySteps(tipC, tipR, dir);
                    if (raySteps >= 0) {
                      final lCells = <(int, int)>[];
                      for (int k = 0; k <= leg1; k++) {
                        lCells.add((c0 + pdc * k, r0 + pdr * k));
                      }
                      for (int k = 1; k <= leg2; k++) {
                        lCells.add((bendC + dc * k, bendR + dr * k));
                      }
                      var blockingScore = 0;
                      for (final cell in lCells) {
                        blockingScore += rayHits[cell.$1][cell.$2] * 6;
                      }
                      final score = blockingScore +
                          raySteps * 3 +
                          (preferCompact ? 3 : 7) +
                          rng.nextInt(4);
                      candidates.add((
                        cells: lCells,
                        points: [
                          Offset(coords[c0], coords[r0]),
                          Offset(coords[bendC], coords[bendR]),
                          Offset(coords[tipC], coords[tipR]),
                        ],
                        dir: dir,
                        score: score,
                      ));
                    }
                  }
                }
              }
            }
          }
        }

        if (candidates.isEmpty) break;
        candidates.sort((a, b) => b.score.compareTo(a.score));
        final chosen = candidates.first;
        for (final cell in chosen.cells) {
          occupied[cell.$1][cell.$2] = true;
        }
        final tipCell = chosen.cells.last;
        markExitRay(tipCell.$1, tipCell.$2, chosen.dir);

        placed.add(
          CanvasArrow(
            id: idOffset + placed.length,
            face: face,
            points: chosen.points,
            exitDirection: chosen.dir,
          ),
        );
      }

      return placed;
    }

    var best = tryBuild(compactOnly: false, runSeed: seed);
    if (best.length == targetCount) return best;

    for (int attempt = 1; attempt <= 6; attempt++) {
      final candidate = tryBuild(compactOnly: attempt >= 3, runSeed: seed + attempt * 17);
      if (candidate.length == targetCount) return candidate;
      if (candidate.length > best.length) best = candidate;
    }
    return best;
  }

  /// Denser solvable sets for the five faces around the front puzzle.
  static List<CanvasArrow> _sideFaceArrows() {
    return [
      // Right: densely packed solvable set with varied lengths and bends.
      CanvasArrow(
        id: 101,
        face: CubeFace.right,
        points: const [Offset(0.50, 0.90), Offset(0.50, 5.60)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 102,
        face: CubeFace.right,
        points: const [Offset(2.60, 0.40), Offset(2.60, 5.60)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 103,
        face: CubeFace.right,
        points: const [Offset(5.45, 1.20), Offset(5.45, 5.60)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 104,
        face: CubeFace.right,
        points: const [Offset(1.15, 0.55), Offset(2.00, 0.55)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 105,
        face: CubeFace.right,
        points: const [Offset(2.00, 1.25), Offset(1.10, 1.25)],
        exitDirection: ArrowDirection.left,
      ),
      CanvasArrow(
        id: 106,
        face: CubeFace.right,
        points: const [Offset(1.20, 1.95), Offset(1.20, 3.35), Offset(1.95, 3.35)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 107,
        face: CubeFace.right,
        points: const [Offset(1.95, 2.65), Offset(1.95, 1.90)],
        exitDirection: ArrowDirection.up,
      ),
      CanvasArrow(
        id: 108,
        face: CubeFace.right,
        points: const [Offset(2.05, 4.05), Offset(1.10, 4.05)],
        exitDirection: ArrowDirection.left,
      ),
      CanvasArrow(
        id: 109,
        face: CubeFace.right,
        points: const [Offset(1.15, 4.80), Offset(2.00, 4.80), Offset(2.00, 5.55)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 110,
        face: CubeFace.right,
        points: const [Offset(3.25, 0.55), Offset(4.85, 0.55)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 111,
        face: CubeFace.right,
        points: const [Offset(3.30, 1.25), Offset(4.75, 1.25)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 112,
        face: CubeFace.right,
        points: const [Offset(3.30, 1.95), Offset(3.30, 3.35)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 113,
        face: CubeFace.right,
        points: const [Offset(4.05, 1.95), Offset(4.05, 3.15)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 114,
        face: CubeFace.right,
        points: const [Offset(4.75, 2.00), Offset(4.75, 4.00), Offset(3.25, 4.00)],
        exitDirection: ArrowDirection.left,
      ),
      CanvasArrow(
        id: 115,
        face: CubeFace.right,
        points: const [Offset(3.25, 4.70), Offset(4.75, 4.70)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 116,
        face: CubeFace.right,
        points: const [Offset(4.85, 5.45), Offset(3.25, 5.45)],
        exitDirection: ArrowDirection.left,
      ),

      // Left: densely packed solvable set with varied lengths and bends.
      CanvasArrow(
        id: 201,
        face: CubeFace.left,
        points: const [Offset(0.90, 0.50), Offset(5.60, 0.50)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 202,
        face: CubeFace.left,
        points: const [Offset(0.40, 2.65), Offset(5.60, 2.65)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 203,
        face: CubeFace.left,
        points: const [Offset(1.30, 5.45), Offset(5.60, 5.45)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 204,
        face: CubeFace.left,
        points: const [Offset(0.55, 1.15), Offset(0.55, 2.00)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 205,
        face: CubeFace.left,
        points: const [Offset(1.25, 2.05), Offset(1.25, 1.10)],
        exitDirection: ArrowDirection.up,
      ),
      CanvasArrow(
        id: 206,
        face: CubeFace.left,
        points: const [Offset(1.95, 1.20), Offset(3.35, 1.20), Offset(3.35, 1.95)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 207,
        face: CubeFace.left,
        points: const [Offset(2.65, 1.95), Offset(1.90, 1.95)],
        exitDirection: ArrowDirection.left,
      ),
      CanvasArrow(
        id: 208,
        face: CubeFace.left,
        points: const [Offset(4.05, 2.00), Offset(4.05, 1.05)],
        exitDirection: ArrowDirection.up,
      ),
      CanvasArrow(
        id: 209,
        face: CubeFace.left,
        points: const [Offset(4.80, 1.15), Offset(4.80, 2.00), Offset(5.55, 2.00)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 210,
        face: CubeFace.left,
        points: const [Offset(0.55, 3.25), Offset(0.55, 4.85)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 211,
        face: CubeFace.left,
        points: const [Offset(1.25, 3.30), Offset(1.25, 4.75)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 212,
        face: CubeFace.left,
        points: const [Offset(1.95, 3.30), Offset(3.35, 3.30)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 213,
        face: CubeFace.left,
        points: const [Offset(1.95, 4.05), Offset(3.15, 4.05)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 214,
        face: CubeFace.left,
        points: const [Offset(2.00, 4.75), Offset(4.00, 4.75), Offset(4.00, 3.25)],
        exitDirection: ArrowDirection.up,
      ),
      CanvasArrow(
        id: 215,
        face: CubeFace.left,
        points: const [Offset(4.70, 3.25), Offset(4.70, 4.75)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 216,
        face: CubeFace.left,
        points: const [Offset(5.45, 4.85), Offset(5.45, 3.25)],
        exitDirection: ArrowDirection.up,
      ),

      // Back: dense concentric spiral
      CanvasArrow(
        id: 301,
        face: CubeFace.back,
        points: const [Offset(0.45, 0.45), Offset(0.45, 5.55)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 302,
        face: CubeFace.back,
        points: const [Offset(5.55, 5.20), Offset(5.55, 0.45)],
        exitDirection: ArrowDirection.up,
      ),
      CanvasArrow(
        id: 303,
        face: CubeFace.back,
        points: const [Offset(1.15, 0.45), Offset(4.85, 0.45)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 304,
        face: CubeFace.back,
        points: const [Offset(4.85, 5.55), Offset(1.10, 5.55)],
        exitDirection: ArrowDirection.left,
      ),
      CanvasArrow(
        id: 305,
        face: CubeFace.back,
        points: const [Offset(1.15, 1.15), Offset(1.15, 4.70)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 306,
        face: CubeFace.back,
        points: const [Offset(4.85, 4.75), Offset(4.85, 1.10)],
        exitDirection: ArrowDirection.up,
      ),
      CanvasArrow(
        id: 307,
        face: CubeFace.back,
        points: const [Offset(1.85, 1.20), Offset(4.15, 1.20)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 308,
        face: CubeFace.back,
        points: const [Offset(4.20, 4.85), Offset(1.80, 4.85)],
        exitDirection: ArrowDirection.left,
      ),
      CanvasArrow(
        id: 309,
        face: CubeFace.back,
        points: const [Offset(1.85, 1.90), Offset(1.85, 4.15)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 310,
        face: CubeFace.back,
        points: const [Offset(4.15, 4.10), Offset(4.15, 1.95)],
        exitDirection: ArrowDirection.up,
      ),
      CanvasArrow(
        id: 311,
        face: CubeFace.back,
        points: const [Offset(2.55, 1.90), Offset(3.45, 1.90)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 312,
        face: CubeFace.back,
        points: const [Offset(3.50, 4.15), Offset(2.50, 4.15)],
        exitDirection: ArrowDirection.left,
      ),
      CanvasArrow(
        id: 313,
        face: CubeFace.back,
        points: const [Offset(2.55, 2.60), Offset(2.55, 3.45)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 314,
        face: CubeFace.back,
        points: const [Offset(3.45, 3.45), Offset(3.45, 2.65)],
        exitDirection: ArrowDirection.up,
      ),

      // Top: dense mixed straight & L-bend arrows
      CanvasArrow(
        id: 401,
        face: CubeFace.top,
        points: const [Offset(0.45, 0.45), Offset(5.55, 0.45)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 402,
        face: CubeFace.top,
        points: const [Offset(5.25, 1.15), Offset(0.45, 1.15)],
        exitDirection: ArrowDirection.left,
      ),
      CanvasArrow(
        id: 403,
        face: CubeFace.top,
        points: const [Offset(1.10, 5.55), Offset(5.55, 5.55)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 404,
        face: CubeFace.top,
        points: const [Offset(0.45, 1.85), Offset(0.45, 4.85)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 405,
        face: CubeFace.top,
        points: const [Offset(5.55, 4.85), Offset(5.55, 1.95)],
        exitDirection: ArrowDirection.up,
      ),
      CanvasArrow(
        id: 406,
        face: CubeFace.top,
        points: const [Offset(1.15, 1.85), Offset(2.55, 1.85), Offset(2.55, 2.75)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 407,
        face: CubeFace.top,
        points: const [Offset(3.25, 1.85), Offset(4.85, 1.85)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 408,
        face: CubeFace.top,
        points: const [Offset(1.15, 2.60), Offset(1.85, 2.60), Offset(1.85, 4.15)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 409,
        face: CubeFace.top,
        points: const [Offset(2.55, 3.45), Offset(4.75, 3.45)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 410,
        face: CubeFace.top,
        points: const [Offset(3.30, 2.60), Offset(4.85, 2.60)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 411,
        face: CubeFace.top,
        points: const [Offset(1.15, 3.35), Offset(1.15, 4.85)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 412,
        face: CubeFace.top,
        points: const [Offset(1.90, 4.85), Offset(4.85, 4.85)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 413,
        face: CubeFace.top,
        points: const [Offset(2.55, 4.15), Offset(4.90, 4.15)],
        exitDirection: ArrowDirection.right,
      ),

      // Bottom: dense mixed straight & L-bend arrows
      CanvasArrow(
        id: 501,
        face: CubeFace.bottom,
        points: const [Offset(0.45, 0.45), Offset(0.45, 5.55)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 502,
        face: CubeFace.bottom,
        points: const [Offset(1.15, 5.20), Offset(1.15, 0.45)],
        exitDirection: ArrowDirection.up,
      ),
      CanvasArrow(
        id: 503,
        face: CubeFace.bottom,
        points: const [Offset(5.55, 0.90), Offset(5.55, 5.55)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 504,
        face: CubeFace.bottom,
        points: const [Offset(4.85, 0.45), Offset(1.85, 0.45)],
        exitDirection: ArrowDirection.left,
      ),
      CanvasArrow(
        id: 505,
        face: CubeFace.bottom,
        points: const [Offset(1.95, 5.55), Offset(4.85, 5.55)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 506,
        face: CubeFace.bottom,
        points: const [Offset(1.95, 1.15), Offset(4.70, 1.15)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 507,
        face: CubeFace.bottom,
        points: const [Offset(1.85, 1.85), Offset(1.85, 3.45), Offset(2.75, 3.45)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 508,
        face: CubeFace.bottom,
        points: const [Offset(2.55, 1.85), Offset(2.55, 2.75)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 509,
        face: CubeFace.bottom,
        points: const [Offset(3.25, 1.85), Offset(4.85, 1.85)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 510,
        face: CubeFace.bottom,
        points: const [Offset(3.45, 2.55), Offset(3.45, 4.85)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 511,
        face: CubeFace.bottom,
        points: const [Offset(4.15, 2.55), Offset(4.85, 2.55), Offset(4.85, 4.70)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 512,
        face: CubeFace.bottom,
        points: const [Offset(4.15, 3.30), Offset(4.15, 4.85)],
        exitDirection: ArrowDirection.down,
      ),
      CanvasArrow(
        id: 513,
        face: CubeFace.bottom,
        points: const [Offset(1.85, 4.15), Offset(2.80, 4.15)],
        exitDirection: ArrowDirection.right,
      ),
      CanvasArrow(
        id: 514,
        face: CubeFace.bottom,
        points: const [Offset(2.80, 4.85), Offset(1.80, 4.85)],
        exitDirection: ArrowDirection.left,
      ),
    ];
  }
}
