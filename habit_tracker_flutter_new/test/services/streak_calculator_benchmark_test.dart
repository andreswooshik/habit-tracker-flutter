import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/services/streak_calculator.dart';

void main() {
  group('Streak Calculator Performance Benchmarks', () {
    late BasicStreakCalculator calculator;

    setUp(() {
      calculator = const BasicStreakCalculator();
    });

    test('calculates streak in < 50ms for daily habit with 30 days', () {
      final habit = Habit.create(
        id: 'perf-1',
        name: 'Performance Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      final completions = <DateTime>{};
      final today = DateTime.now();
      for (int i = 0; i < 30; i++) {
        completions.add(today.subtract(Duration(days: i)));
      }

      final stopwatch = Stopwatch()..start();
      calculator.calculateStreak(habit, completions);
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Streak calculation should complete in < 50ms',
      );
    });

    test('calculates streak in < 50ms for daily habit with 90 days', () {
      final habit = Habit.create(
        id: 'perf-2',
        name: 'Performance Test 90',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      final completions = <DateTime>{};
      final today = DateTime.now();
      for (int i = 0; i < 90; i++) {
        completions.add(today.subtract(Duration(days: i)));
      }

      final stopwatch = Stopwatch()..start();
      calculator.calculateStreak(habit, completions);
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Streak calculation should complete in < 50ms even with 90 days',
      );
    });

    test('calculates streak in < 50ms for daily habit with 365 days', () {
      final habit = Habit.create(
        id: 'perf-3',
        name: 'Performance Test 365',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      final completions = <DateTime>{};
      final today = DateTime.now();
      for (int i = 0; i < 365; i++) {
        completions.add(today.subtract(Duration(days: i)));
      }

      final stopwatch = Stopwatch()..start();
      calculator.calculateStreak(habit, completions);
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Streak calculation should complete in < 50ms even with 365 days',
      );
    });

    test('calculates streak in < 50ms for weekdays habit with 90 days', () {
      final habit = Habit.create(
        id: 'perf-4',
        name: 'Performance Test Weekdays',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.weekdays,
      );

      final completions = <DateTime>{};
      final today = DateTime.now();
      for (int i = 0; i < 90; i++) {
        final date = today.subtract(Duration(days: i));
        // Only add weekdays
        if (date.weekday <= 5) {
          completions.add(date);
        }
      }

      final stopwatch = Stopwatch()..start();
      calculator.calculateStreak(habit, completions);
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Weekdays streak calculation should complete in < 50ms',
      );
    });

    test('calculates streak in < 50ms for custom frequency with 90 days', () {
      final habit = Habit.create(
        id: 'perf-5',
        name: 'Performance Test Custom',
        category: HabitCategory.fitness,
        frequency: HabitFrequency.custom,
        customDays: [1, 3, 5], // Mon, Wed, Fri
      );

      final completions = <DateTime>{};
      final today = DateTime.now();
      for (int i = 0; i < 90; i++) {
        final date = today.subtract(Duration(days: i));
        // Only add custom days
        if ([1, 3, 5].contains(date.weekday)) {
          completions.add(date);
        }
      }

      final stopwatch = Stopwatch()..start();
      calculator.calculateStreak(habit, completions);
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Custom frequency streak calculation should complete in < 50ms',
      );
    });

    test('calculates streak in < 50ms with sparse data (10% completion)', () {
      final habit = Habit.create(
        id: 'perf-6',
        name: 'Performance Test Sparse',
        category: HabitCategory.learning,
        frequency: HabitFrequency.everyDay,
      );

      final completions = <DateTime>{};
      final today = DateTime.now();
      // Only 10% completion rate
      for (int i = 0; i < 365; i += 10) {
        completions.add(today.subtract(Duration(days: i)));
      }

      final stopwatch = Stopwatch()..start();
      calculator.calculateStreak(habit, completions);
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Sparse data streak calculation should complete in < 50ms',
      );
    });

    test('calculates longest streak in < 50ms with large dataset', () {
      final habit = Habit.create(
        id: 'perf-7',
        name: 'Performance Test Longest',
        category: HabitCategory.mindfulness,
        frequency: HabitFrequency.everyDay,
      );

      final completions = <DateTime>{};
      final today = DateTime.now();
      
      // Create multiple streaks in history
      // Streak 1: 30 days (oldest)
      for (int i = 200; i < 230; i++) {
        completions.add(today.subtract(Duration(days: i)));
      }
      
      // Gap of 10 days
      
      // Streak 2: 45 days (longest, in middle)
      for (int i = 140; i < 185; i++) {
        completions.add(today.subtract(Duration(days: i)));
      }
      
      // Gap of 10 days
      
      // Streak 3: 20 days (most recent)
      for (int i = 0; i < 20; i++) {
        completions.add(today.subtract(Duration(days: i)));
      }

      final stopwatch = Stopwatch()..start();
      calculator.calculateLongestStreak(habit, completions);
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Longest streak calculation should complete in < 50ms',
      );
    });

    test('maintains performance with unsorted completion dates', () {
      final habit = Habit.create(
        id: 'perf-8',
        name: 'Performance Test Unsorted',
        category: HabitCategory.social,
        frequency: HabitFrequency.everyDay,
      );

      final completions = <DateTime>{};
      final today = DateTime.now();
      
      // Add dates in random order
      for (int i = 0; i < 90; i++) {
        completions.add(today.subtract(Duration(days: i)));
      }

      final stopwatch = Stopwatch()..start();
      calculator.calculateStreak(habit, completions);
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Unsorted data should not impact performance significantly',
      );
    });

    test('calculates streak in < 50ms with grace period enabled', () {
      final habit = Habit.create(
        id: 'perf-9',
        name: 'Performance Test Grace',
        category: HabitCategory.creativity,
        frequency: HabitFrequency.everyDay,
        hasGracePeriod: true,
      );

      final completions = <DateTime>{};
      final today = DateTime.now();
      
      // Create pattern with some gaps (that grace period would cover)
      for (int i = 0; i < 90; i++) {
        if (i % 5 != 0) { // Skip every 5th day
          completions.add(today.subtract(Duration(days: i)));
        }
      }

      final stopwatch = Stopwatch()..start();
      calculator.calculateStreak(habit, completions);
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Grace period calculation should not significantly impact performance',
      );
    });

    test('average calculation time over 100 iterations < 50ms', () {
      final habit = Habit.create(
        id: 'perf-10',
        name: 'Performance Test Average',
        category: HabitCategory.finance,
        frequency: HabitFrequency.everyDay,
      );

      final completions = <DateTime>{};
      final today = DateTime.now();
      for (int i = 0; i < 60; i++) {
        completions.add(today.subtract(Duration(days: i)));
      }

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        calculator.calculateStreak(habit, completions);
      }
      stopwatch.stop();

      final averageMs = stopwatch.elapsedMilliseconds / 100;
      expect(
        averageMs,
        lessThan(50),
        reason: 'Average calculation time over 100 iterations should be < 50ms',
      );
    });
  });

  group('Performance Edge Cases', () {
    late BasicStreakCalculator calculator;

    setUp(() {
      calculator = const BasicStreakCalculator();
    });

    test('handles empty completions efficiently', () {
      final habit = Habit.create(
        id: 'edge-1',
        name: 'Empty Test',
        category: HabitCategory.other,
        frequency: HabitFrequency.everyDay,
      );

      final stopwatch = Stopwatch()..start();
      calculator.calculateStreak(habit, {});
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(10),
        reason: 'Empty completions should be handled very quickly',
      );
    });

    test('handles single completion efficiently', () {
      final habit = Habit.create(
        id: 'edge-2',
        name: 'Single Test',
        category: HabitCategory.other,
        frequency: HabitFrequency.everyDay,
      );

      final stopwatch = Stopwatch()..start();
      calculator.calculateStreak(habit, {DateTime.now()});
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(10),
        reason: 'Single completion should be handled very quickly',
      );
    });

    test('handles duplicate dates efficiently', () {
      final habit = Habit.create(
        id: 'edge-3',
        name: 'Duplicate Test',
        category: HabitCategory.other,
        frequency: HabitFrequency.everyDay,
      );

      final today = DateTime.now();
      final completions = <DateTime>{
        today,
        today.add(const Duration(hours: 1)),
        today.add(const Duration(hours: 2)),
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 1, hours: 5)),
      };

      final stopwatch = Stopwatch()..start();
      calculator.calculateStreak(habit, completions);
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(20),
        reason: 'Duplicate dates should be normalized efficiently',
      );
    });
  });
}
