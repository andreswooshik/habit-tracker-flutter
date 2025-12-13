import 'package:equatable/equatable.dart';

/// Enum representing different achievement types
enum AchievementType {
  streak3('3-Day Streak', 3),
  streak7('Week Warrior', 7),
  streak30('Month Master', 30),
  streak100('Century Club', 100),
  streak365('Year Champion', 365),
  firstCompletion('First Step', 1),
  perfect7('Perfect Week', 7),
  perfect30('Perfect Month', 30);

  final String displayName;
  final int requiredDays;

  const AchievementType(this.displayName, this.requiredDays);
}

/// Immutable achievement entity representing a milestone reached
/// 
/// Achievements are unlocked based on streak milestones
class Achievement extends Equatable {
  /// Unique identifier for the achievement instance
  final String id;

  /// The type of achievement
  final AchievementType type;

  /// The habit this achievement is for
  final String habitId;

  /// The habit name (for display)
  final String habitName;

  /// When this achievement was unlocked
  final DateTime unlockedAt;

  /// The streak count when unlocked
  final int streakCount;

  /// Whether this achievement has been seen by the user
  final bool isSeen;

  const Achievement({
    required this.id,
    required this.type,
    required this.habitId,
    required this.habitName,
    required this.unlockedAt,
    required this.streakCount,
    this.isSeen = false,
  });

  /// Factory constructor for creating an achievement from streak data
  factory Achievement.fromStreak({
    required String id,
    required AchievementType type,
    required String habitId,
    required String habitName,
    required int streakCount,
  }) {
    return Achievement(
      id: id,
      type: type,
      habitId: habitId,
      habitName: habitName,
      unlockedAt: DateTime.now(),
      streakCount: streakCount,
      isSeen: false,
    );
  }

  /// Determines which achievements should be unlocked for a given streak
  static List<AchievementType> getUnlockedTypes(int streakCount) {
    final unlocked = <AchievementType>[];

    if (streakCount >= 1) unlocked.add(AchievementType.firstCompletion);
    if (streakCount >= 3) unlocked.add(AchievementType.streak3);
    if (streakCount >= 7) {
      unlocked.add(AchievementType.streak7);
      unlocked.add(AchievementType.perfect7);
    }
    if (streakCount >= 30) {
      unlocked.add(AchievementType.streak30);
      unlocked.add(AchievementType.perfect30);
    }
    if (streakCount >= 100) unlocked.add(AchievementType.streak100);
    if (streakCount >= 365) unlocked.add(AchievementType.streak365);

    return unlocked;
  }

  /// Returns the emoji icon for this achievement
  String get icon {
    switch (type) {
      case AchievementType.firstCompletion:
        return '🎯';
      case AchievementType.streak3:
        return '🔥';
      case AchievementType.streak7:
      case AchievementType.perfect7:
        return '⚡';
      case AchievementType.streak30:
      case AchievementType.perfect30:
        return '💪';
      case AchievementType.streak100:
        return '🏆';
      case AchievementType.streak365:
        return '👑';
    }
  }

  /// Returns a description of the achievement
  String get description {
    switch (type) {
      case AchievementType.firstCompletion:
        return 'Completed your first day!';
      case AchievementType.streak3:
        return 'Maintained a 3-day streak!';
      case AchievementType.streak7:
        return 'Achieved a full week streak!';
      case AchievementType.perfect7:
        return 'Perfect consistency for 7 days!';
      case AchievementType.streak30:
        return 'Built a 30-day habit!';
      case AchievementType.perfect30:
        return 'Perfect consistency for a month!';
      case AchievementType.streak100:
        return 'Incredible 100-day streak!';
      case AchievementType.streak365:
        return 'Legendary full year streak!';
    }
  }

  /// Returns the rarity level (common, rare, epic, legendary)
  String get rarity {
    if (streakCount >= 365) return 'legendary';
    if (streakCount >= 100) return 'epic';
    if (streakCount >= 30) return 'rare';
    return 'common';
  }

  /// Whether this is a major milestone
  bool get isMajorMilestone {
    return type == AchievementType.streak30 ||
        type == AchievementType.streak100 ||
        type == AchievementType.streak365;
  }

  /// Creates a copy of this achievement with updated fields
  Achievement copyWith({
    String? id,
    AchievementType? type,
    String? habitId,
    String? habitName,
    DateTime? unlockedAt,
    int? streakCount,
    bool? isSeen,
  }) {
    return Achievement(
      id: id ?? this.id,
      type: type ?? this.type,
      habitId: habitId ?? this.habitId,
      habitName: habitName ?? this.habitName,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      streakCount: streakCount ?? this.streakCount,
      isSeen: isSeen ?? this.isSeen,
    );
  }

  /// Marks this achievement as seen
  Achievement markAsSeen() => copyWith(isSeen: true);

  @override
  List<Object?> get props => [
        id,
        type,
        habitId,
        habitName,
        unlockedAt,
        streakCount,
        isSeen,
      ];

  @override
  String toString() {
    return 'Achievement(${type.displayName}, habit: $habitName, '
        'streak: $streakCount, seen: $isSeen)';
  }
}
