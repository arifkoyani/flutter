import 'package:flutter/foundation.dart';

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

  void _initializeDefaultRecords() {
    // Level 1 is unlocked by default
    _records[1] = const LevelRecord(levelId: 1, isUnlocked: true);
    for (int i = 2; i <= 5; i++) {
      _records[i] = LevelRecord(levelId: i, isUnlocked: false);
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

  /// Record a level completion: save stars, mistakes, and unlock next level
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
