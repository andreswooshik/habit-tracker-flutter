import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import '../mocks/provider_container.dart';
import '../mocks/test_habits.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = createTestProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('Phase 5: Computed Providers - todaysHabitsProvider', () {
    test('returns empty list when no habits exist', () {
      final todaysHabits = container.read(todaysHabitsProvider);
      expect(todaysHabits, isEmpty);
    });

    test('filters habits scheduled for selected date', () {
      // Add habits with different frequencies
      final dailyHabit = backdatedHabit(
        id: '1',
        name: 'Daily',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final weekdaysHabit = backdatedHabit(
        id: '2',
        name: 'Weekdays',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.weekdays,
      );

      container.read(habitsProvider.notifier).addHabit(dailyHabit);
      container.read(habitsProvider.notifier).addHabit(weekdaysHabit);

      // Set selected date to a weekday (Monday)
      final monday = DateTime(2024, 1, 1); // January 1, 2024 is a Monday
      container.read(todayProvider.notifier).state = monday;

      final todaysHabits = container.read(todaysHabitsProvider);

      // Both should be scheduled on Monday
      expect(todaysHabits, hasLength(2));
      expect(todaysHabits.any((h) => h.id == '1'), isTrue);
      expect(todaysHabits.any((h) => h.id == '2'), isTrue);
    });

    test('excludes habits not scheduled for selected date', () {
      // Add weekdays habit
      final weekdaysHabit = backdatedHabit(
        id: '1',
        name: 'Weekdays',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.weekdays,
      );

      container.read(habitsProvider.notifier).addHabit(weekdaysHabit);

      // Set selected date to Saturday
      final saturday = DateTime(2024, 1, 6); // January 6, 2024 is a Saturday
      container.read(todayProvider.notifier).state = saturday;

      final todaysHabits = container.read(todaysHabitsProvider);

      // Should be empty - weekdays habit not scheduled on Saturday
      expect(todaysHabits, isEmpty);
    });

    test('excludes archived habits', () {
      final activeHabit = backdatedHabit(
        id: '1',
        name: 'Active',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habitToArchive = backdatedHabit(
        id: '2',
        name: 'Will Archive',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(activeHabit);
      container.read(habitsProvider.notifier).addHabit(habitToArchive);

      // Archive the second habit
      container.read(habitsProvider.notifier).archiveHabit('2');

      final todaysHabits = container.read(todaysHabitsProvider);

      expect(todaysHabits, hasLength(1));
      expect(todaysHabits.first.id, equals('1'));
      expect(todaysHabits.first.isArchived, isFalse);
    });

    test('sorts incomplete habits before completed habits', () {
      // Add three daily habits
      final habit1 = backdatedHabit(
        id: '1',
        name: 'Zzz Last',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habit2 = backdatedHabit(
        id: '2',
        name: 'Aaa First',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habit3 = backdatedHabit(
        id: '3',
        name: 'Mmm Middle',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit1);
      container.read(habitsProvider.notifier).addHabit(habit2);
      container.read(habitsProvider.notifier).addHabit(habit3);

      final today = DateTime.now();
      container.read(todayProvider.notifier).state = today;

      // Mark habit2 as complete
      container.read(completionsProvider.notifier).markComplete('2', today);

      final todaysHabits = container.read(todaysHabitsProvider);

      // Should be sorted: incomplete (alphabetically), then completed
      expect(todaysHabits, hasLength(3));
      expect(todaysHabits[0].name, equals('Mmm Middle')); // Incomplete
      expect(todaysHabits[1].name, equals('Zzz Last')); // Incomplete
      expect(todaysHabits[2].name, equals('Aaa First')); // Completed (last)
    });

    test('sorts alphabetically within same completion status', () {
      // Add habits in reverse alphabetical order
      final habitZ = backdatedHabit(
        id: 'z',
        name: 'Zzz',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habitM = backdatedHabit(
        id: 'm',
        name: 'Mmm',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habitA = backdatedHabit(
        id: 'a',
        name: 'Aaa',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habitZ);
      container.read(habitsProvider.notifier).addHabit(habitM);
      container.read(habitsProvider.notifier).addHabit(habitA);

      final todaysHabits = container.read(todaysHabitsProvider);

      // Should be sorted alphabetically
      expect(todaysHabits, hasLength(3));
      expect(todaysHabits[0].name, equals('Aaa'));
      expect(todaysHabits[1].name, equals('Mmm'));
      expect(todaysHabits[2].name, equals('Zzz'));
    });

    test('handles custom frequency correctly', () {
      // Monday, Wednesday, Friday habit
      final customHabit = backdatedHabit(
        id: '1',
        name: 'MWF',
        category: HabitCategory.fitness,
        frequency: HabitFrequency.custom,
        customDays: [1, 3, 5], // Mon, Wed, Fri
      );

      container.read(habitsProvider.notifier).addHabit(customHabit);

      // Test on Monday (should appear)
      final monday = DateTime(2024, 1, 1);
      container.read(todayProvider.notifier).state = monday;
      var todaysHabits = container.read(todaysHabitsProvider);
      expect(todaysHabits, hasLength(1));

      // Test on Tuesday (should not appear)
      final tuesday = DateTime(2024, 1, 2);
      container.read(todayProvider.notifier).state = tuesday;
      todaysHabits = container.read(todaysHabitsProvider);
      expect(todaysHabits, isEmpty);

      // Test on Wednesday (should appear)
      final wednesday = DateTime(2024, 1, 3);
      container.read(todayProvider.notifier).state = wednesday;
      todaysHabits = container.read(todaysHabitsProvider);
      expect(todaysHabits, hasLength(1));
    });

    test('updates when selected date changes', () {
      // Add weekdays habit
      final weekdaysHabit = backdatedHabit(
        id: '1',
        name: 'Work',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.weekdays,
      );

      container.read(habitsProvider.notifier).addHabit(weekdaysHabit);

      // Start on Monday
      final monday = DateTime(2024, 1, 1);
      container.read(todayProvider.notifier).state = monday;
      var todaysHabits = container.read(todaysHabitsProvider);
      expect(todaysHabits, hasLength(1));

      // Change to Saturday
      final saturday = DateTime(2024, 1, 6);
      container.read(todayProvider.notifier).state = saturday;
      todaysHabits = container.read(todaysHabitsProvider);
      expect(todaysHabits, isEmpty);
    });
  });

  group('Phase 5: Computed Providers - habitCompletionProvider', () {
    test('returns false when habit not completed', () {
      final habit = backdatedHabit(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);

      final today = DateTime.now();
      final isCompleted = container.read(
        habitCompletionProvider((habitId: '1', date: today)),
      );

      expect(isCompleted, isFalse);
    });

    test('returns true when habit completed', () {
      final habit = backdatedHabit(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);

      final today = DateTime.now();
      container.read(completionsProvider.notifier).markComplete('1', today);

      final isCompleted = container.read(
        habitCompletionProvider((habitId: '1', date: today)),
      );

      expect(isCompleted, isTrue);
    });

    test('handles different dates independently', () {
      final habit = backdatedHabit(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);

      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      // Complete today only
      container.read(completionsProvider.notifier).markComplete('1', today);

      // Check both dates
      final todayCompleted = container.read(
        habitCompletionProvider((habitId: '1', date: today)),
      );
      final yesterdayCompleted = container.read(
        habitCompletionProvider((habitId: '1', date: yesterday)),
      );

      expect(todayCompleted, isTrue);
      expect(yesterdayCompleted, isFalse);
    });

    test('normalizes date to midnight', () {
      final habit = backdatedHabit(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);

      final morning = DateTime(2024, 1, 15, 8, 30);
      final evening = DateTime(2024, 1, 15, 20, 45);

      // Mark complete in morning
      container.read(completionsProvider.notifier).markComplete('1', morning);

      // Check in evening (same day)
      final isCompleted = container.read(
        habitCompletionProvider((habitId: '1', date: evening)),
      );

      expect(isCompleted, isTrue);
    });
  });

  group('Phase 5: Computed Providers - Summary Stats', () {
    test('todaysHabitsCountProvider returns correct count', () {
      // Add 3 daily habits
      for (int i = 1; i <= 3; i++) {
        container.read(habitsProvider.notifier).addHabit(
              backdatedHabit(
                id: '$i',
                name: 'Habit $i',
                category: HabitCategory.health,
                frequency: HabitFrequency.everyDay,
              ),
            );
      }

      final count = container.read(todaysHabitsCountProvider);
      expect(count, equals(3));
    });

    test('completedTodayCountProvider returns correct count', () {
      final today = DateTime.now();
      container.read(todayProvider.notifier).state = today;

      // Add 3 daily habits
      for (int i = 1; i <= 3; i++) {
        container.read(habitsProvider.notifier).addHabit(
              backdatedHabit(
                id: '$i',
                name: 'Habit $i',
                category: HabitCategory.health,
                frequency: HabitFrequency.everyDay,
              ),
            );
      }

      // Complete 2 of them
      container.read(completionsProvider.notifier).markComplete('1', today);
      container.read(completionsProvider.notifier).markComplete('2', today);

      final completed = container.read(completedTodayCountProvider);
      expect(completed, equals(2));
    });

    test('todaysProgressProvider calculates percentage correctly', () {
      final today = DateTime.now();
      container.read(todayProvider.notifier).state = today;

      // Add 4 daily habits
      for (int i = 1; i <= 4; i++) {
        container.read(habitsProvider.notifier).addHabit(
              backdatedHabit(
                id: '$i',
                name: 'Habit $i',
                category: HabitCategory.health,
                frequency: HabitFrequency.everyDay,
              ),
            );
      }

      // Complete 3 of them
      container.read(completionsProvider.notifier).markComplete('1', today);
      container.read(completionsProvider.notifier).markComplete('2', today);
      container.read(completionsProvider.notifier).markComplete('3', today);

      final progress = container.read(todaysProgressProvider);
      expect(progress, equals(0.75)); // 3/4 = 75%
    });

    test('todaysProgressProvider returns 0.0 when no habits', () {
      final progress = container.read(todaysProgressProvider);
      expect(progress, equals(0.0));
    });

    test('todaysProgressProvider returns 1.0 when all completed', () {
      final today = DateTime.now();
      container.read(todayProvider.notifier).state = today;

      // Add 2 daily habits
      for (int i = 1; i <= 2; i++) {
        container.read(habitsProvider.notifier).addHabit(
              backdatedHabit(
                id: '$i',
                name: 'Habit $i',
                category: HabitCategory.health,
                frequency: HabitFrequency.everyDay,
              ),
            );
      }

      // Complete both
      container.read(completionsProvider.notifier).markComplete('1', today);
      container.read(completionsProvider.notifier).markComplete('2', today);

      final progress = container.read(todaysProgressProvider);
      expect(progress, equals(1.0)); // 100%
    });
  });

  group('Dashboard / habit list date independence (regression)', () {
    // Bug: browsing another date in the habit list screen used to
    // change the dashboard's "today" cards, because both derived from
    // selectedDateProvider. Today-anchored and selected-date-anchored
    // providers must stay independent.

    void addWeekdaysHabit() {
      container.read(habitsProvider.notifier).addHabit(
            backdatedHabit(
              id: '1',
              name: 'Weekdays',
              category: HabitCategory.productivity,
              frequency: HabitFrequency.weekdays,
            ),
          );
    }

    test('browsing another date does not change the today providers', () {
      addWeekdaysHabit();

      final monday = DateTime(2024, 1, 1); // Monday
      final saturday = DateTime(2024, 1, 6); // Saturday, not scheduled
      container.read(todayProvider.notifier).state = monday;
      container.read(completionsProvider.notifier).markComplete('1', monday);

      // Browse to Saturday in the habit list screen
      container.read(selectedDateProvider.notifier).state = saturday;

      // Dashboard still shows Monday's data
      expect(container.read(todaysHabitsProvider), hasLength(1));
      expect(container.read(completedTodayCountProvider), equals(1));
      expect(container.read(todaysProgressProvider), equals(1.0));
    });

    test('selected-date providers follow the browsed date', () {
      addWeekdaysHabit();

      final monday = DateTime(2024, 1, 1);
      final saturday = DateTime(2024, 1, 6);
      container.read(todayProvider.notifier).state = monday;

      container.read(selectedDateProvider.notifier).state = monday;
      expect(container.read(selectedDateHabitsProvider), hasLength(1));

      container.read(selectedDateProvider.notifier).state = saturday;
      expect(container.read(selectedDateHabitsProvider), isEmpty);
      expect(container.read(selectedDateCompletedCountProvider), equals(0));
      expect(container.read(selectedDateProgressProvider), equals(0.0));

      // The dashboard never moved off Monday
      expect(container.read(todaysHabitsProvider), hasLength(1));
    });
  });
}
