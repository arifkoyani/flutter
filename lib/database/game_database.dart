import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LevelRecord {
  final int levelId;
  final bool isUnlocked;
  final bool isCompleted;
  final int stars; // 0 to 3
  final int mistakes;
  final DateTime? completedAt;

  const LevelRecord({
    required this.levelId,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.stars = 0,
    this.mistakes = 0,
    this.completedAt,
  });

  LevelRecord copyWith({
    bool? isUnlocked,
    bool? isCompleted,
    int? stars,
    int? mistakes,
    DateTime? completedAt,
  }) {
    return LevelRecord(
      levelId: levelId,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
      stars: stars ?? this.stars,
      mistakes: mistakes ?? this.mistakes,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'isUnlocked': isUnlocked,
        'isCompleted': isCompleted,
        'stars': stars,
        'mistakes': mistakes,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory LevelRecord.fromJson(Map<String, dynamic> json) => LevelRecord(
        levelId: json['levelId'] as int,
        isUnlocked: json['isUnlocked'] as bool? ?? false,
        isCompleted: json['isCompleted'] as bool? ?? false,
        stars: json['stars'] as int? ?? 0,
        mistakes: json['mistakes'] as int? ?? 0,
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
      );
}

/// In-app local database service for player progress
class GameDatabase extends ChangeNotifier {
  static final GameDatabase instance = GameDatabase._internal();

  GameDatabase._internal() {
    _initializeDefaultRecords();
  }

  final Map<int, LevelRecord> _records = {};
  Directory? _storageDir;
  bool _isInitialized = false;

  void _initializeDefaultRecords() {
    // Level 1 is unlocked by default
    _records[1] = const LevelRecord(levelId: 1, isUnlocked: true);
    for (int i = 2; i <= 10; i++) {
      _records[i] = LevelRecord(levelId: i, isUnlocked: false);
    }
  }

  /// Loads persisted stage progress from local app storage on the device.
  Future<void> init({Directory? storageDir, bool forceReload = false}) async {
    if (_isInitialized && !forceReload && storageDir == null) return;
    try {
      _storageDir = storageDir ?? await getApplicationDocumentsDirectory();
      final file = File('${_storageDir!.path}/game_progress.json');
      if (file.existsSync()) {
        final raw = file.readAsStringSync();
        if (raw.trim().isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            _records.clear();
            _initializeDefaultRecords();
            decoded.forEach((k, v) {
              final id = int.tryParse(k);
              if (id != null && v is Map<String, dynamic>) {
                _records[id] = LevelRecord.fromJson(v);
              }
            });
            // Ensure Stage 1 is always unlocked.
            _records[1] = getRecord(1).copyWith(isUnlocked: true);
          }
        }
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('GameDatabase init note: $e');
    }
  }

  /// Clears in-memory records back to defaults (useful for isolated tests).
  void resetInMemory({Directory? storageDir}) {
    _records.clear();
    _initializeDefaultRecords();
    _storageDir = storageDir;
    _isInitialized = false;
    notifyListeners();
  }

  Future<void> _saveToDisk() async {
    try {
      final dir = _storageDir ?? await getApplicationDocumentsDirectory();
      _storageDir = dir;
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File('${dir.path}/game_progress.json');
      file.writeAsStringSync(jsonEncode(exportToJson()), flush: true);
    } catch (e) {
      debugPrint('GameDatabase save note: $e');
    }
  }

  LevelRecord getRecord(int levelId) {
    return _records[levelId] ??
        LevelRecord(levelId: levelId, isUnlocked: levelId == 1);
  }

  bool isLevelUnlocked(int levelId) {
    return getRecord(levelId).isUnlocked;
  }

  int getStars(int levelId) {
    return getRecord(levelId).stars;
  }

  /// Record a level completion: save stars, mistakes, unlock next level, and persist to disk.
  Future<void> recordLevelCompletion({
    required int levelId,
    required int stars,
    required int mistakes,
  }) async {
    final existing = getRecord(levelId);
    final bestStars = stars > existing.stars ? stars : existing.stars;

    _records[levelId] = existing.copyWith(
      isCompleted: true,
      stars: bestStars,
      mistakes: mistakes,
      completedAt: DateTime.now(),
    );

    // Automatically unlock the next level
    final nextLevelId = levelId + 1;
    if (_records.containsKey(nextLevelId)) {
      _records[nextLevelId] = _records[nextLevelId]!.copyWith(isUnlocked: true);
    } else {
      _records[nextLevelId] = LevelRecord(levelId: nextLevelId, isUnlocked: true);
    }

    notifyListeners();
    await _saveToDisk();
  }

  Map<String, dynamic> exportToJson() {
    return _records.map((k, v) => MapEntry(k.toString(), v.toJson()));
  }

  void importFromJson(Map<String, dynamic> data) {
    data.forEach((k, v) {
      final id = int.tryParse(k);
      if (id != null && v is Map<String, dynamic>) {
        _records[id] = LevelRecord.fromJson(v);
      }
    });
    notifyListeners();
  }
}
