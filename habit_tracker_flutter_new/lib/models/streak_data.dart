import 'package:equatable/equatable.dart';

/// Immutable value object representing streak data for a habit
/// 
/// Contains both current streak and longest streak information
class StreakData extends Equatable {
  /// Current active streak count (consecutive completions)
  final int current;

  /// Longest streak ever achieved for this habit
  final int longest;

  /// The date the current streak started
  final DateTime? currentStreakStartDate;

  /// The date range of the longest streak (start, end)
  final (DateTime start, DateTime end)? longestStreakRange;

  /// Whether the current streak is frozen (grace period active)
  final bool isFrozen;

  /// Number of grace days used in current streak
  final int graceDaysUsed;

  const StreakData({
    required this.current,
    required this.longest,
    this.currentStreakStartDate,
    this.longestStreakRange,
    this.isFrozen = false,
    this.graceDaysUsed = 0,
  });

  /// Factory constructor for zero streak
  factory StreakData.zero() {
    return const StreakData(
      current: 0,
      longest: 0,
      currentStreakStartDate: null,
      longestStreakRange: null,
      isFrozen: false,
      graceDaysUsed: 0,
    );
  }

  /// Factory constructor for a simple streak with just counts
  factory StreakData.simple({
    required int current,
    required int longest,
  }) {
    return StreakData(
      current: current,
      longest: longest,
      currentStreakStartDate: null,
      longestStreakRange: null,
      isFrozen: false,
      graceDaysUsed: 0,
    );
  }

  /// Whether there is an active streak
  bool get hasActiveStreak => current > 0;

  /// Whether the current streak is a personal record
  bool get isPersonalRecord => current == longest && current > 0;

  /// Whether the current streak is close to the longest (within 3 days)
  bool get isNearRecord => longest > 0 && current >= longest - 3;

  /// Progress towards longest streak (0.0 to 1.0)
  double get progressToLongest {
    if (longest == 0) return 0.0;
    return (current / longest).clamp(0.0, 1.0);
  }

  /// Returns a motivational message based on streak
  String get motivationalMessage {
    if (current == 0) {
      return 'Start your streak today!';
    } else if (current == 1) {
      return 'Great start! Keep it going!';
    } else if (current < 7) {
      return 'Building momentum! $current days strong!';
    } else if (current < 30) {
      return 'Excellent consistency! $current day streak!';
    } else if (current < 100) {
      return 'Amazing dedication! $current days!';
    } else {
      return 'Legendary streak! $current days!';
    }
  }

  /// Returns a color indicator based on streak length
  /// Returns color name as string: 'grey', 'green', 'blue', 'purple', 'gold'
  String get colorIndicator {
    if (current == 0) return 'grey';
    if (current < 7) return 'green';
    if (current < 30) return 'blue';
    if (current < 100) return 'purple';
    return 'gold';
  }

  /// Duration of current streak in days
  int get currentStreakDuration {
    if (currentStreakStartDate == null) return 0;
    return DateTime.now().difference(currentStreakStartDate!).inDays + 1;
  }

  /// Duration of longest streak in days
  int? get longestStreakDuration {
    if (longestStreakRange == null) return null;
    final (start, end) = longestStreakRange!;
    return end.difference(start).inDays + 1;
  }

  /// Creates a copy of this streak data with updated fields
  StreakData copyWith({
    int? current,
    int? longest,
    DateTime? currentStreakStartDate,
    (DateTime, DateTime)? longestStreakRange,
    bool? isFrozen,
    int? graceDaysUsed,
  }) {
    return StreakData(
      current: current ?? this.current,
      longest: longest ?? this.longest,
      currentStreakStartDate: currentStreakStartDate ?? this.currentStreakStartDate,
      longestStreakRange: longestStreakRange ?? this.longestStreakRange,
      isFrozen: isFrozen ?? this.isFrozen,
      graceDaysUsed: graceDaysUsed ?? this.graceDaysUsed,
    );
  }

  /// Increments the current streak by 1
  StreakData incrementStreak() {
    final newCurrent = current + 1;
    final newLongest = newCurrent > longest ? newCurrent : longest;

    return copyWith(
      current: newCurrent,
      longest: newLongest,
      isFrozen: false,
      graceDaysUsed: 0,
    );
  }

  /// Breaks the current streak (resets to 0)
  StreakData breakStreak() {
    return copyWith(
      current: 0,
      currentStreakStartDate: null,
      isFrozen: false,
      graceDaysUsed: 0,
    );
  }

  /// Freezes the streak (uses grace period)
  StreakData freezeStreak() {
    return copyWith(
      isFrozen: true,
      graceDaysUsed: graceDaysUsed + 1,
    );
  }

  @override
  List<Object?> get props => [
        current,
        longest,
        currentStreakStartDate,
        longestStreakRange,
        isFrozen,
        graceDaysUsed,
      ];

  @override
  String toString() {
    return 'StreakData(current: $current, longest: $longest, '
        'frozen: $isFrozen, graceDays: $graceDaysUsed)';
  }
}
