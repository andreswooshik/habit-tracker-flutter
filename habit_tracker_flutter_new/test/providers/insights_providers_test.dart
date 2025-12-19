import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/providers/insights_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('Phase 5: Insights Providers - habitInsightsProvider basics', () {
    test('returns empty insights when no habits exist', () {
      final insights = container.read(habitInsightsProvider);

      expect(insights.totalActiveHabits, equals(0));
      expect(insights.totalCompletions, equals(0));
      expect(insights.hasHabits, isFalse);
    });

    test('counts total active habits correctly', () {
      // Add 3 habits
      for (int i = 1; i <= 3; i++) {
        container.read(habitsProvider.notifier).addHabit(
          Habit.create(
            id: '$i',
            name: 'Habit $i',
            category: HabitCategory.health,
            frequency: HabitFrequency.everyDay,
          ),
        );
      }

      final insights = container.read(habitInsightsProvider);
      expect(insights.totalActiveHabits, equals(3));
    });

    test('excludes archived habits from count', () {
      final habit1 = Habit.create(
        id: '1',
        name: 'Active',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habit2 = Habit.create(
        id: '2',
        name: 'To Archive',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit1);
      container.read(habitsProvider.notifier).addHabit(habit2);
      container.read(habitsProvider.notifier).archiveHabit('2');

      final insights = container.read(habitInsightsProvider);
      expect(insights.totalActiveHabits, equals(1));
    });

    test('counts total completions across all habits', () {
      final habit1 = Habit.create(
        id: '1',
        name: 'Habit 1',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habit2 = Habit.create(
        id: '2',
        name: 'Habit 2',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit1);
      container.read(habitsProvider.notifier).addHabit(habit2);

      // Complete habit1 3 times, habit2 2 times
      for (int i = 1; i <= 3; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }
      for (int i = 1; i <= 2; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('2', DateTime(2024, 1, i));
      }

      final insights = container.read(habitInsightsProvider);
      expect(insights.totalCompletions, equals(5));
    });
  });

  group('Phase 5: Insights Providers - streak calculations', () {
    test('identifies longest current streak', () {
      // Habit 1: 5-day streak
      final habit1 = Habit.create(
        id: '1',
        name: 'Short Streak',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      // Habit 2: 10-day streak
      final habit2 = Habit.create(
        id: '2',
        name: 'Long Streak',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit1);
      container.read(habitsProvider.notifier).addHabit(habit2);

      // Set selected date to Jan 10
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 10);

      // Habit 1: complete Jan 6-10 (5 days)
      for (int i = 6; i <= 10; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      // Habit 2: complete Jan 1-10 (10 days)
      for (int i = 1; i <= 10; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('2', DateTime(2024, 1, i));
      }

      final insights = container.read(habitInsightsProvider);
      expect(insights.longestCurrentStreak, equals(10));
      expect(insights.topStreakHabitName, equals('Long Streak'));
    });

    test('calculates average streak correctly', () {
      // Create 3 habits with different streaks: 5, 10, 15 days
      for (int i = 1; i <= 3; i++) {
        container.read(habitsProvider.notifier).addHabit(
          Habit.create(
            id: '$i',
            name: 'Habit $i',
            category: HabitCategory.health,
            frequency: HabitFrequency.everyDay,
          ),
        );
      }

      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 20);

      // Habit 1: 5-day streak (Jan 16-20)
      for (int i = 16; i <= 20; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      // Habit 2: 10-day streak (Jan 11-20)
      for (int i = 11; i <= 20; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('2', DateTime(2024, 1, i));
      }

      // Habit 3: 15-day streak (Jan 6-20)
      for (int i = 6; i <= 20; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('3', DateTime(2024, 1, i));
      }

      final insights = container.read(habitInsightsProvider);
      expect(insights.averageStreak, closeTo(10.0, 0.01)); // (5+10+15)/3 = 10
    });
  });

  group('Phase 5: Insights Providers - completion rates', () {
    test('calculates overall completion rate correctly', () {
      final habit = Habit.create(
        id: '1',
        name: 'Daily',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 31);

      // Complete 21 out of 31 days (Jan 1-31, reference is Jan 31)
      // The range is Jan 1-31 (31 days total after subtract(Duration(days: 30)))
      for (int i = 1; i <= 21; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      final insights = container.read(habitInsightsProvider);
      expect(insights.overallCompletionRate, closeTo(0.677, 0.01)); // 21/31 ≈ 67.7%
    });

    test('calculates weekly consistency correctly', () {
      final habit = Habit.create(
        id: '1',
        name: 'Daily',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 8);

      // Complete 5 out of 7 days
      for (int i = 2; i <= 8; i += 2) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      final insights = container.read(habitInsightsProvider);
      // Should be close to 4/7 ≈ 0.57 (days 2,4,6,8)
      expect(insights.weeklyConsistency, greaterThan(0.5));
      expect(insights.weeklyConsistency, lessThan(0.7));
    });
  });

  group('Phase 5: Insights Providers - most completed habit', () {
    test('identifies most completed habit', () {
      final habit1 = Habit.create(
        id: '1',
        name: 'Less Completed',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habit2 = Habit.create(
        id: '2',
        name: 'Most Completed',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit1);
      container.read(habitsProvider.notifier).addHabit(habit2);

      // Complete habit1 5 times, habit2 15 times
      for (int i = 1; i <= 5; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }
      for (int i = 1; i <= 15; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('2', DateTime(2024, 1, i));
      }

      final insights = container.read(habitInsightsProvider);
      expect(insights.mostCompletedHabitId, equals('2'));
      expect(insights.mostCompletedHabitName, equals('Most Completed'));
      expect(insights.mostCompletedCount, equals(15));
    });
  });

  group('Phase 5: Insights Providers - habits at risk', () {
    test('identifies habits missed yesterday', () {
      final habit1 = Habit.create(
        id: '1',
        name: 'Completed Yesterday',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habit2 = Habit.create(
        id: '2',
        name: 'Missed Yesterday',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit1);
      container.read(habitsProvider.notifier).addHabit(habit2);

      // Set today as Jan 10
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 10);

      // Complete habit1 on Jan 9, but not habit2
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 9));

      final insights = container.read(habitInsightsProvider);
      expect(insights.habitsAtRisk.length, equals(1));
      expect(insights.habitsAtRisk.contains('2'), isTrue);
      expect(insights.hasHabitsAtRisk, isTrue);
    });

    test('excludes habits not scheduled yesterday', () {
      final weekdaysHabit = Habit.create(
        id: '1',
        name: 'Weekdays Only',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.weekdays,
      );

      container.read(habitsProvider.notifier).addHabit(weekdaysHabit);

      // Set today as Sunday (yesterday was Saturday)
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 7);

      final insights = container.read(habitInsightsProvider);
      // Weekdays habit wasn't scheduled on Saturday, so not at risk
      expect(insights.habitsAtRisk, isEmpty);
    });
  });

  group('Phase 5: Insights Providers - perfect days', () {
    test('counts perfect days correctly', () {
      final habit1 = Habit.create(
        id: '1',
        name: 'Habit 1',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habit2 = Habit.create(
        id: '2',
        name: 'Habit 2',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit1);
      container.read(habitsProvider.notifier).addHabit(habit2);

      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 5);

      // Complete both habits on Jan 1, 2, 3 (3 perfect days)
      for (int day = 1; day <= 3; day++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, day));
        container.read(completionsProvider.notifier)
            .markComplete('2', DateTime(2024, 1, day));
      }

      // Jan 4: only habit1 completed (not perfect)
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 4));

      final insights = container.read(habitInsightsProvider);
      expect(insights.perfectDaysCount, greaterThanOrEqualTo(3));
    });

    test('calculates current perfect streak', () {
      final habit = Habit.create(
        id: '1',
        name: 'Daily',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 5);

      // Complete Jan 3, 4, 5 (3-day perfect streak)
      for (int day = 3; day <= 5; day++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, day));
      }

      // Jan 2 not completed (breaks earlier streak)

      final insights = container.read(habitInsightsProvider);
      expect(insights.currentPerfectStreak, greaterThanOrEqualTo(3));
    });
  });

  group('Phase 5: Insights Providers - category performance', () {
    test('identifies best and worst categories', () {
      // Health category: 90% completion
      final healthHabit = Habit.create(
        id: '1',
        name: 'Health',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      // Productivity category: 50% completion
      final productivityHabit = Habit.create(
        id: '2',
        name: 'Productivity',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(healthHabit);
      container.read(habitsProvider.notifier).addHabit(productivityHabit);

      container.read(selectedDateProvider.notifier).state = DateTime(2024, 2, 1);

      // Health: complete 27/30 days in January (90%)
      for (int i = 1; i <= 27; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      // Productivity: complete 15/30 days in January (50%)
      for (int i = 1; i <= 15; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('2', DateTime(2024, 1, i));
      }

      final insights = container.read(habitInsightsProvider);
      expect(insights.bestCategory, equals('Health'));
      expect(insights.worstCategory, equals('Productivity'));
    });
  });

  group('Phase 5: Insights Providers - performance indicators', () {
    test('isPerformingWell returns true when rate >= 70%', () {
      final habit = Habit.create(
        id: '1',
        name: 'Daily',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 31);

      // Complete 22/31 days (71%). Reference is Jan 31, so we check Jan 1-31 (31 days)
      for (int i = 1; i <= 22; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      final insights = container.read(habitInsightsProvider);
      expect(insights.isPerformingWell, isTrue);
    });

    test('hasStrongWeeklyConsistency returns true when >= 80%', () {
      final habit = Habit.create(
        id: '1',
        name: 'Daily',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 8);

      // Complete 6/7 days (85.7%)
      for (int i = 2; i <= 8; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      final insights = container.read(habitInsightsProvider);
      expect(insights.hasStrongWeeklyConsistency, isTrue);
    });
  });

  group('Phase 5: Insights Providers - achievements count', () {
    test('counts achievements based on streaks', () {
      final habit = Habit.create(
        id: '1',
        name: 'Long Streak',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 2, 1);

      // Create 30-day streak (should unlock 7-day and 30-day achievements)
      for (int i = 3; i <= 32; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      final insights = container.read(habitInsightsProvider);
      expect(insights.totalAchievements, greaterThanOrEqualTo(2)); // 7-day + 30-day
    });
  });
}
