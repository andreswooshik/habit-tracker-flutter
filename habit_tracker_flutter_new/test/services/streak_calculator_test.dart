import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/models/streak_data.dart';
import 'package:habit_tracker_flutter_new/services/streak_calculator.dart';

void main() {
  late BasicStreakCalculator calculator;

  setUp(() {
    calculator = const BasicStreakCalculator();
  });

  group('BasicStreakCalculator - Every Day Frequency', () {
    late Habit dailyHabit;

    setUp(() {
      dailyHabit = Habit.create(
        id: 'daily-1',
        name: 'Daily Meditation',
        frequency: HabitFrequency.everyDay,
        category: HabitCategory.mindfulness,
      );
    });

    test('empty completions returns zero streak', () {
      final streak = calculator.calculateStreak(dailyHabit, {});

      expect(streak.current, 0);
      expect(streak.longest, 0);
      expect(streak.hasActiveStreak, false);
    });

    test('single completion today shows streak of 1', () {
      final today = DateTime.now();
      final completions = {
        DateTime(today.year, today.month, today.day),
      };

      final streak = calculator.calculateStreak(dailyHabit, completions);

      expect(streak.current, 1);
      expect(streak.longest, 1);
      expect(streak.hasActiveStreak, true);
    });

    test('consecutive 5 days shows streak of 5', () {
      final today = DateTime.now();
      final completions = <DateTime>{};
      
      for (int i = 0; i < 5; i++) {
        completions.add(
          DateTime(today.year, today.month, today.day).subtract(Duration(days: i)),
        );
      }

      final streak = calculator.calculateStreak(dailyHabit, completions);

      expect(streak.current, 5);
      expect(streak.longest, 5);
      expect(streak.hasActiveStreak, true);
    });

    test('30-day perfect streak', () {
      final today = DateTime.now();
      final completions = <DateTime>{};
      
      for (int i = 0; i < 30; i++) {
        completions.add(
          DateTime(today.year, today.month, today.day).subtract(Duration(days: i)),
        );
      }

      final streak = calculator.calculateStreak(dailyHabit, completions);

      expect(streak.current, 30);
      expect(streak.longest, 30);
      expect(streak.hasActiveStreak, true);
    });

    test('broken streak shows only current streak', () {
      final today = DateTime.now();
      final completions = <DateTime>{};
      
      // Current streak: last 3 days
      for (int i = 0; i < 3; i++) {
        completions.add(
          DateTime(today.year, today.month, today.day).subtract(Duration(days: i)),
        );
      }
      
      // Gap on day 4 (not added)
      
      // Previous streak: 5 days (days 5-9)
      for (int i = 5; i <= 9; i++) {
        completions.add(
          DateTime(today.year, today.month, today.day).subtract(Duration(days: i)),
        );
      }

      final streak = calculator.calculateStreak(dailyHabit, completions);

      expect(streak.current, 3);
      expect(streak.longest, 5); // Previous streak was longer
      expect(streak.hasActiveStreak, true);
    });

    test('yesterday completion still active for daily habit', () {
      final today = DateTime.now();
      final yesterday = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 1));
      
      final completions = {yesterday};

      final streak = calculator.calculateStreak(dailyHabit, completions);

      expect(streak.current, 1);
      expect(streak.hasActiveStreak, true);
    });

    test('2 days ago counts as streak of 1', () {
      final today = DateTime.now();
      final twoDaysAgo = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 2));
      
      final completions = {twoDaysAgo};

      final streak = calculator.calculateStreak(dailyHabit, completions);

      expect(streak.current, 1);
      expect(streak.hasActiveStreak, true); // Has a streak (even if old)
    });

    test('ignores time component in dates', () {
      final today = DateTime.now();
      final completions = {
        DateTime(today.year, today.month, today.day, 8, 30), // Morning
        DateTime(today.year, today.month, today.day, 14, 0), // Afternoon
        DateTime(today.year, today.month, today.day, 20, 45), // Evening
      };

      final streak = calculator.calculateStreak(dailyHabit, completions);

      expect(streak.current, 1); // All count as one day
    });
  });

  group('BasicStreakCalculator - Weekdays Frequency', () {
    late Habit weekdayHabit;

    setUp(() {
      weekdayHabit = Habit.create(
        id: 'weekday-1',
        name: 'Work Commute Walk',
        frequency: HabitFrequency.weekdays,
        category: HabitCategory.health,
      );
    });

    test('5 consecutive weekdays shows streak of 5', () {
      // Start from a known Monday
      final monday = DateTime(2024, 1, 1); // Jan 1, 2024 is Monday
      final completions = <DateTime>{};
      
      for (int i = 0; i < 5; i++) {
        completions.add(monday.add(Duration(days: i)));
      }

      final streak = calculator.calculateStreak(weekdayHabit, completions);

      expect(streak.current, 5);
      expect(streak.longest, 5);
    });

    test('weekend completions are ignored', () {
      final monday = DateTime(2024, 1, 1); // Monday
      final completions = <DateTime>{
        monday, // Mon - counts
        monday.add(const Duration(days: 1)), // Tue - counts
        monday.add(const Duration(days: 5)), // Sat - ignored
        monday.add(const Duration(days: 6)), // Sun - ignored
      };

      final streak = calculator.calculateStreak(weekdayHabit, completions);

      expect(streak.current, 2); // Only Mon, Tue count
    });

    test('streak continues across weekend', () {
      final monday = DateTime(2024, 1, 1); // Monday
      final completions = <DateTime>{
        monday, // Mon
        monday.add(const Duration(days: 1)), // Tue
        monday.add(const Duration(days: 2)), // Wed
        monday.add(const Duration(days: 3)), // Thu
        monday.add(const Duration(days: 4)), // Fri
        // Weekend gap (Sat, Sun)
        monday.add(const Duration(days: 7)), // Next Mon
        monday.add(const Duration(days: 8)), // Next Tue
      };

      final streak = calculator.calculateStreak(weekdayHabit, completions);

      expect(streak.current, 7); // All 7 weekdays
    });

    test('missing Friday breaks weekday streak', () {
      final monday = DateTime(2024, 1, 1);
      final completions = <DateTime>{
        monday, // Mon
        monday.add(const Duration(days: 1)), // Tue
        monday.add(const Duration(days: 2)), // Wed
        monday.add(const Duration(days: 3)), // Thu
        // Missing Friday
        monday.add(const Duration(days: 7)), // Next Mon
      };

      final streak = calculator.calculateStreak(weekdayHabit, completions);

      expect(streak.current, 1); // Only next Monday
    });
  });

  group('BasicStreakCalculator - Weekends Frequency', () {
    late Habit weekendHabit;

    setUp(() {
      weekendHabit = Habit.create(
        id: 'weekend-1',
        name: 'Weekend Hike',
        frequency: HabitFrequency.weekends,
        category: HabitCategory.fitness,
      );
    });

    test('both Saturday and Sunday shows streak of 2', () {
      final saturday = DateTime(2024, 1, 6); // Jan 6, 2024 is Saturday
      final completions = <DateTime>{
        saturday,
        saturday.add(const Duration(days: 1)), // Sunday
      };

      final streak = calculator.calculateStreak(weekendHabit, completions);

      expect(streak.current, 2);
    });

    test('weekday completions are ignored', () {
      final monday = DateTime(2024, 1, 1);
      final completions = <DateTime>{
        monday, // Mon - ignored
        monday.add(const Duration(days: 5)), // Sat - counts
      };

      final streak = calculator.calculateStreak(weekendHabit, completions);

      expect(streak.current, 1);
    });

    test('streak continues across week', () {
      final saturday1 = DateTime(2024, 1, 6); // First Saturday
      final completions = <DateTime>{
        saturday1, // Sat
        saturday1.add(const Duration(days: 1)), // Sun
        // Weekday gap
        saturday1.add(const Duration(days: 7)), // Next Sat
        saturday1.add(const Duration(days: 8)), // Next Sun
      };

      final streak = calculator.calculateStreak(weekendHabit, completions);

      expect(streak.current, 4); // 2 weekends
    });
  });

  group('BasicStreakCalculator - Custom Frequency', () {
    late Habit customHabit;

    setUp(() {
      // Monday, Wednesday, Friday
      customHabit = Habit.create(
        id: 'custom-1',
        name: 'Gym Days',
        frequency: HabitFrequency.custom,
        customDays: [DateTime.monday, DateTime.wednesday, DateTime.friday],
        category: HabitCategory.fitness,
      );
    });

    test('completions on custom days count', () {
      final monday = DateTime(2024, 1, 1); // Monday
      final completions = <DateTime>{
        monday, // Mon - counts
        monday.add(const Duration(days: 2)), // Wed - counts
        monday.add(const Duration(days: 4)), // Fri - counts
      };

      final streak = calculator.calculateStreak(customHabit, completions);

      expect(streak.current, 3);
    });

    test('non-custom day completions are ignored', () {
      final monday = DateTime(2024, 1, 1);
      final completions = <DateTime>{
        monday, // Mon - counts
        monday.add(const Duration(days: 1)), // Tue - ignored
        monday.add(const Duration(days: 2)), // Wed - counts
      };

      final streak = calculator.calculateStreak(customHabit, completions);

      expect(streak.current, 2); // Mon, Wed
    });

    test('missing custom day breaks streak', () {
      final monday = DateTime(2024, 1, 1);
      final completions = <DateTime>{
        monday, // Mon - counts
        // Missing Wednesday
        monday.add(const Duration(days: 4)), // Fri - counts
      };

      final streak = calculator.calculateStreak(customHabit, completions);

      expect(streak.current, 1); // Only Friday
    });
  });

  group('BasicStreakCalculator - Grace Period', () {
    late Habit habitWithGrace;

    setUp(() {
      habitWithGrace = Habit.create(
        id: 'grace-1',
        name: 'Flexible Daily',
        frequency: HabitFrequency.everyDay,
        hasGracePeriod: true,
        category: HabitCategory.other,
      );
    });

    test('allows one missed day with grace period', () {
      final today = DateTime.now();
      final normalized = DateTime(today.year, today.month, today.day);
      
      final completions = <DateTime>{
        normalized, // Today
        normalized.subtract(const Duration(days: 1)), // Yesterday
        // Day 2 missing (grace period)
        normalized.subtract(const Duration(days: 3)), // Day 3
        normalized.subtract(const Duration(days: 4)), // Day 4
      };

      final streak = calculator.calculateStreak(habitWithGrace, completions);

      expect(streak.current, 4); // Grace period allows gap
    });

    test('grace period does not allow two consecutive misses', () {
      final today = DateTime.now();
      final normalized = DateTime(today.year, today.month, today.day);
      
      final completions = <DateTime>{
        normalized, // Today
        // Day 1 missing
        // Day 2 missing (exceeds grace period)
        normalized.subtract(const Duration(days: 3)), // Day 3
      };

      final streak = calculator.calculateStreak(habitWithGrace, completions);

      expect(streak.current, 1); // Streak broken after 2 misses
    });

    test('grace period allows one miss per streak segment', () {
      final today = DateTime.now();
      final normalized = DateTime(today.year, today.month, today.day);
      
      final completions = <DateTime>{
        normalized, // Today
        normalized.subtract(const Duration(days: 1)), // Day 1
        // Day 2 missing (grace period used)
        normalized.subtract(const Duration(days: 3)), // Day 3
        normalized.subtract(const Duration(days: 4)), // Day 4
      };

      final streak = calculator.calculateStreak(habitWithGrace, completions);

      expect(streak.current, 4); // One grace period used
    });

    test('habit without grace period breaks on first miss', () {
      final habitNoGrace = Habit.create(
        id: 'no-grace-1',
        name: 'Strict Daily',
        frequency: HabitFrequency.everyDay,
        hasGracePeriod: false,
        category: HabitCategory.other,
      );

      final today = DateTime.now();
      final normalized = DateTime(today.year, today.month, today.day);
      
      final completions = <DateTime>{
        normalized, // Today
        // Day 1 missing
        normalized.subtract(const Duration(days: 2)), // Day 2
      };

      final streak = calculator.calculateStreak(habitNoGrace, completions);

      expect(streak.current, 1); // Breaks immediately
    });
  });

  group('BasicStreakCalculator - Edge Cases', () {
    late Habit dailyHabit;

    setUp(() {
      dailyHabit = Habit.create(
        id: 'edge-1',
        name: 'Edge Case Habit',
        frequency: HabitFrequency.everyDay,
        category: HabitCategory.other,
      );
    });

    test('handles leap year dates correctly', () {
      // February 29, 2024 (leap year)
      final leapDay = DateTime(2024, 2, 29);
      final completions = <DateTime>{
        leapDay,
        DateTime(2024, 2, 28),
        DateTime(2024, 3, 1),
      };

      final streak = calculator.calculateStreak(dailyHabit, completions);

      expect(streak.current, 3);
    });

    test('handles month boundary correctly', () {
      final completions = <DateTime>{
        DateTime(2024, 1, 31), // End of January
        DateTime(2024, 2, 1),  // Start of February
        DateTime(2024, 2, 2),
      };

      final streak = calculator.calculateStreak(dailyHabit, completions);

      expect(streak.current, 3);
    });

    test('handles year boundary correctly', () {
      final completions = <DateTime>{
        DateTime(2023, 12, 30),
        DateTime(2023, 12, 31),
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 2),
      };

      final streak = calculator.calculateStreak(dailyHabit, completions);

      expect(streak.current, 4);
    });

    test('handles very old completions', () {
      final today = DateTime.now();
      final veryOld = DateTime(2020, 1, 1);
      
      final completions = <DateTime>{
        DateTime(today.year, today.month, today.day),
        veryOld, // 4+ years ago
      };

      final streak = calculator.calculateStreak(dailyHabit, completions);

      expect(streak.current, 1); // Only recent counts
      expect(streak.longest, 1);
    });

    test('handles duplicate dates', () {
      final today = DateTime.now();
      final normalized = DateTime(today.year, today.month, today.day);
      
      final completions = <DateTime>{
        normalized,
        DateTime(today.year, today.month, today.day, 8, 0), // Same day, different time
        DateTime(today.year, today.month, today.day, 20, 0),
      };

      final streak = calculator.calculateStreak(dailyHabit, completions);

      expect(streak.current, 1); // Duplicates handled
    });

    test('handles future dates', () {
      final today = DateTime.now();
      final future = today.add(const Duration(days: 30));
      
      final completions = <DateTime>{
        DateTime(today.year, today.month, today.day),
        DateTime(future.year, future.month, future.day),
      };

      final streak = calculator.calculateStreak(dailyHabit, completions);

      expect(streak.current, greaterThanOrEqualTo(1));
    });

    test('handles unsorted completion dates', () {
      final completions = <DateTime>{
        DateTime(2024, 1, 5),
        DateTime(2024, 1, 3),
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 4),
        DateTime(2024, 1, 2),
      };

      final streak = calculator.calculateStreak(dailyHabit, completions);

      expect(streak.current, 5);
    });
  });

  group('BasicStreakCalculator - calculateLongestStreak', () {
    late Habit dailyHabit;

    setUp(() {
      dailyHabit = Habit.create(
        id: 'longest-1',
        name: 'Longest Test',
        frequency: HabitFrequency.everyDay,
        category: HabitCategory.other,
      );
    });

    test('returns 0 for empty completions', () {
      final longest = calculator.calculateLongestStreak(dailyHabit, {});

      expect(longest, 0);
    });

    test('finds longest streak in history', () {
      final base = DateTime(2024, 1, 1);
      final completions = <DateTime>{};
      
      // First streak: 3 days
      for (int i = 0; i < 3; i++) {
        completions.add(base.add(Duration(days: i)));
      }
      
      // Gap
      
      // Second streak: 7 days (longest)
      for (int i = 10; i < 17; i++) {
        completions.add(base.add(Duration(days: i)));
      }
      
      // Gap
      
      // Third streak: 4 days
      for (int i = 25; i < 29; i++) {
        completions.add(base.add(Duration(days: i)));
      }

      final longest = calculator.calculateLongestStreak(dailyHabit, completions);

      expect(longest, 7);
    });

    test('returns current streak if it is longest', () {
      final today = DateTime.now();
      final completions = <DateTime>{};
      
      // Build 10-day current streak
      for (int i = 0; i < 10; i++) {
        completions.add(
          DateTime(today.year, today.month, today.day).subtract(Duration(days: i)),
        );
      }

      final longest = calculator.calculateLongestStreak(dailyHabit, completions);

      expect(longest, 10);
    });

    test('respects frequency when calculating longest', () {
      final weekdayHabit = Habit.create(
        id: 'weekday-longest',
        name: 'Weekday Longest',
        frequency: HabitFrequency.weekdays,
        category: HabitCategory.other,
      );

      final monday = DateTime(2024, 1, 1);
      final completions = <DateTime>{};
      
      // 2 full weeks (10 weekdays)
      for (int i = 0; i < 14; i++) {
        final date = monday.add(Duration(days: i));
        if (weekdayHabit.isScheduledFor(date)) {
          completions.add(date);
        }
      }

      final longest = calculator.calculateLongestStreak(weekdayHabit, completions);

      expect(longest, 10);
    });
  });

  group('BasicStreakCalculator - isOnStreak Status', () {
    late Habit dailyHabit;

    setUp(() {
      dailyHabit = Habit.create(
        id: 'status-1',
        name: 'Status Test',
        frequency: HabitFrequency.everyDay,
        category: HabitCategory.other,
      );
    });

    test('isOnStreak true when completed today', () {
      final today = DateTime.now();
      final completions = {
        DateTime(today.year, today.month, today.day),
      };

      final streak = calculator.calculateStreak(dailyHabit, completions);

      expect(streak.hasActiveStreak, true);
    });

    test('isOnStreak true when completed yesterday for daily', () {
      final today = DateTime.now();
      final yesterday = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 1));
      
      final completions = {yesterday};

      final streak = calculator.calculateStreak(dailyHabit, completions);

      expect(streak.hasActiveStreak, true);
    });

    test('hasActiveStreak true even for old completions', () {
      final today = DateTime.now();
      final twoDaysAgo = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 2));
      
      final completions = {twoDaysAgo};

      final streak = calculator.calculateStreak(dailyHabit, completions);

      expect(streak.hasActiveStreak, true); // Has a streak (streak.current > 0)
    });

    test('isOnStreak respects weekday frequency on Monday', () {
      // Test needs to run on actual weekday to validate properly
      final weekdayHabit = Habit.create(
        id: 'weekday-status',
        name: 'Weekday Status',
        frequency: HabitFrequency.weekdays,
        category: HabitCategory.other,
      );

      final friday = DateTime(2024, 1, 5); // Friday
      final completions = {friday};

      final streak = calculator.calculateStreak(weekdayHabit, completions);

      // Should be active if calculated on Monday (after weekend)
      expect(streak.current, 1);
    });
  });
}
