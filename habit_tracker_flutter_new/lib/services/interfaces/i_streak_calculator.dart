import '../../models/habit.dart';
import '../../models/streak_data.dart';

/// Interface for calculating habit streaks and related statistics.
///
/// Defines the contract for streak calculation services, enabling:
/// - Current streak calculation from completion history
/// - Longest streak identification
/// - Flexible implementation (algorithm variations, caching strategies)
///
/// This interface follows the Dependency Inversion Principle (DIP) by allowing
/// high-level provider logic to depend on abstractions rather than concrete
/// streak calculation algorithms.
///
/// Example implementations might include:
/// - `BasicStreakCalculator`: Simple date-based streak counting
/// - `CachedStreakCalculator`: Optimized with memoization
/// - `SmartStreakCalculator`: Considers frequency patterns
abstract class IStreakCalculator {
  /// Calculates the current streak data for a habit based on its completion history.
  ///
  /// A streak represents consecutive days where the habit was completed according
  /// to its frequency requirements. The calculation considers:
  /// - Habit frequency (daily, specific days, custom intervals)
  /// - Completion dates (timezone-normalized)
  /// - Current date context
  ///
  /// Returns [StreakData] containing:
  /// - `currentStreak`: Number of consecutive completions ending today/yesterday
  /// - `longestStreak`: Maximum consecutive completions in history
  /// - `lastCompletedDate`: Most recent completion (or null)
  /// - `isOnStreak`: Whether the streak is currently active
  ///
  /// Examples:
  /// ```dart
  /// // Daily habit completed last 5 days
  /// final streak = calculator.calculateStreak(habit, completions);
  /// print(streak.currentStreak);  // 5
  /// print(streak.isOnStreak);     // true
  ///
  /// // Weekly habit (Mondays) - missed this week
  /// final weeklyStreak = calculator.calculateStreak(weeklyHabit, dates);
  /// print(weeklyStreak.currentStreak);  // 0
  /// print(weeklyStreak.longestStreak);  // 8 (from past)
  /// ```
  ///
  /// Parameters:
  /// - [habit]: The habit to calculate streaks for (contains frequency rules)
  /// - [completions]: Set of dates when the habit was completed
  ///
  /// Returns: [StreakData] with current and longest streak information
  ///
  /// Throws:
  /// - May throw exceptions if habit data is invalid or completions are malformed
  ///   (implementation-specific behavior)
  StreakData calculateStreak(
    Habit habit,
    Set<DateTime> completions,
  );

  /// Calculates only the longest streak from the habit's completion history.
  ///
  /// This is a more efficient operation when only the maximum streak is needed,
  /// as it can skip current streak context calculations.
  ///
  /// Useful for:
  /// - Statistics views showing best performance
  /// - Achievement tracking (e.g., "10-day streak achieved")
  /// - Leaderboards or comparative analytics
  ///
  /// Examples:
  /// ```dart
  /// // Find best performance
  /// final longest = calculator.calculateLongestStreak(habit, completions);
  /// if (longest >= 30) {
  ///   showAchievement('30-day champion!');
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [habit]: The habit to analyze (contains frequency rules)
  /// - [completions]: Set of dates when the habit was completed
  ///
  /// Returns: Integer representing the maximum consecutive completions ever achieved
  ///
  /// Implementation note:
  /// - Should be faster than [calculateStreak] when only max is needed
  /// - May share logic with [calculateStreak] for consistency
  int calculateLongestStreak(
    Habit habit,
    Set<DateTime> completions,
  );
}

// Note: This interface depends on:
// - Habit model (from lib/models/habit.dart)
// - StreakData model (from lib/models/streak_data.dart)
// - DateTime (from dart:core)
//
// Implementations will be created in lib/services/ directory
