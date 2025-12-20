import '../models/habit.dart';
import '../models/streak_data.dart';
import 'interfaces/i_streak_calculator.dart';

class BasicStreakCalculator implements IStreakCalculator {
  /// Creates a [BasicStreakCalculator] instance.
  const BasicStreakCalculator();

  @override
  StreakData calculateStreak(Habit habit, Set<DateTime> completions) {
    // Normalize all completion dates
    final normalizedCompletions = completions
        .map((date) => _normalizeDate(date))
        .where((date) => habit.isScheduledFor(date))
        .toSet();

    if (normalizedCompletions.isEmpty) {
      return StreakData.zero();
    }

    // Find the most recent completion
    final sortedCompletions = normalizedCompletions.toList()..sort();
    final lastCompleted = sortedCompletions.last;

    // Calculate current streak
    final currentStreak = _calculateCurrentStreak(
      habit,
      normalizedCompletions,
      lastCompleted,
    );

    // Calculate longest streak in entire history
    final longestStreak = _calculateLongestStreakFromHistory(
      habit,
      normalizedCompletions,
    );

    return StreakData.simple(
      current: currentStreak,
      longest: longestStreak > currentStreak ? longestStreak : currentStreak,
    );
  }

  @override
  int calculateLongestStreak(Habit habit, Set<DateTime> completions) {
    // Normalize and filter completions
    final normalizedCompletions = completions
        .map((date) => _normalizeDate(date))
        .where((date) => habit.isScheduledFor(date))
        .toSet();

    if (normalizedCompletions.isEmpty) {
      return 0;
    }

    return _calculateLongestStreakFromHistory(habit, normalizedCompletions);
  }

  int _calculateCurrentStreak(
    Habit habit,
    Set<DateTime> completions,
    DateTime lastCompleted,
  ) {
    int streak = 0;
    DateTime currentDate = lastCompleted;
    bool missedOneDay = false; // Track if we've used the grace period

    while (true) {
      // Check if this scheduled day has a completion
      if (habit.isScheduledFor(currentDate)) {
        if (completions.contains(currentDate)) {
          streak++;
          missedOneDay = false; // Reset grace period usage on completion
        } else {
          // Missed a scheduled day
          if (habit.hasGracePeriod && !missedOneDay) {
            // Use grace period - allow one miss
            missedOneDay = true;
          } else {
            // No grace period or already used it - streak is broken
            break;
          }
        }
      }

      // Move to previous day
      currentDate = currentDate.subtract(const Duration(days: 1));

      // Safety check: don't go back more than 1000 days
      if (lastCompleted.difference(currentDate).inDays > 1000) {
        break;
      }
    }

    return streak;
  }

  int _calculateLongestStreakFromHistory(
    Habit habit,
    Set<DateTime> completions,
  ) {
    if (completions.isEmpty) return 0;

    final sortedCompletions = completions.toList()..sort();

    int longestStreak = 0;
    int currentStreak = 0;
    DateTime? previousScheduledDate;
    bool missedOneDay = false;

    for (final completion in sortedCompletions) {
      if (previousScheduledDate == null) {
        // First completion
        currentStreak = 1;
        previousScheduledDate = completion;
        continue;
      }

      // Find the next scheduled date after previous
      final nextExpectedDate = _findNextScheduledDate(
        habit,
        previousScheduledDate,
      );

      if (completion == nextExpectedDate) {
        // Consecutive scheduled day - continue streak
        currentStreak++;
        missedOneDay = false;
      } else if (habit.hasGracePeriod &&
          !missedOneDay &&
          completion == _findNextScheduledDate(habit, nextExpectedDate)) {
        // Missed one scheduled day but within grace period
        currentStreak++;
        missedOneDay = true;
      } else {
        // Streak broken - start new streak
        longestStreak =
            longestStreak > currentStreak ? longestStreak : currentStreak;
        currentStreak = 1;
        missedOneDay = false;
      }

      previousScheduledDate = completion;
    }

    // Check final streak
    return longestStreak > currentStreak ? longestStreak : currentStreak;
  }

  DateTime _findNextScheduledDate(Habit habit, DateTime from) {
    DateTime nextDate = from.add(const Duration(days: 1));

    // Scan up to 7 days forward to find next scheduled day
    for (int i = 0; i < 7; i++) {
      if (habit.isScheduledFor(nextDate)) {
        return nextDate;
      }
      nextDate = nextDate.add(const Duration(days: 1));
    }

    // Fallback: return next day if no scheduled day found
    return from.add(const Duration(days: 1));
  }


  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
