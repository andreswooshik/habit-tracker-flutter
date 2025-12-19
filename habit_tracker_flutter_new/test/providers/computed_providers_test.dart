import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/providers/computed_providers.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
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
      final dailyHabit = Habit.create(
        id: '1',
        name: 'Daily',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final weekdaysHabit = Habit.create(
        id: '2',
        name: 'Weekdays',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.weekdays,
      );

      container.read(habitsProvider.notifier).addHabit(dailyHabit);
      container.read(habitsProvider.notifier).addHabit(weekdaysHabit);

      // Set selected date to a weekday (Monday)
      final monday = DateTime(2024, 1, 1); // January 1, 2024 is a Monday
      container.read(selectedDateProvider.notifier).state = monday;

      final todaysHabits = container.read(todaysHabitsProvider);
      
      // Both should be scheduled on Monday
      expect(todaysHabits, hasLength(2));
      expect(todaysHabits.any((h) => h.id == '1'), isTrue);
      expect(todaysHabits.any((h) => h.id == '2'), isTrue);
    });

    test('excludes habits not scheduled for selected date', () {
      // Add weekdays habit
      final weekdaysHabit = Habit.create(
        id: '1',
        name: 'Weekdays',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.weekdays,
      );

      container.read(habitsProvider.notifier).addHabit(weekdaysHabit);

      // Set selected date to Saturday
      final saturday = DateTime(2024, 1, 6); // January 6, 2024 is a Saturday
      container.read(selectedDateProvider.notifier).state = saturday;

      final todaysHabits = container.read(todaysHabitsProvider);
      
      // Should be empty - weekdays habit not scheduled on Saturday
      expect(todaysHabits, isEmpty);
    });

    test('excludes archived habits', () {
      final activeHabit = Habit.create(
        id: '1',
        name: 'Active',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habitToArchive = Habit.create(
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
      final habit1 = Habit.create(
        id: '1',
        name: 'Zzz Last',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habit2 = Habit.create(
        id: '2',
        name: 'Aaa First',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habit3 = Habit.create(
        id: '3',
        name: 'Mmm Middle',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit1);
      container.read(habitsProvider.notifier).addHabit(habit2);
      container.read(habitsProvider.notifier).addHabit(habit3);

      final today = DateTime.now();
      container.read(selectedDateProvider.notifier).state = today;

      // Mark habit2 as complete
      container.read(completionsProvider.notifier).markComplete('2', today);

      final todaysHabits = container.read(todaysHabitsProvider);
      
      // Should be sorted: incomplete (alphabetically), then completed
      expect(todaysHabits, hasLength(3));
      expect(todaysHabits[0].name, equals('Mmm Middle')); // Incomplete
      expect(todaysHabits[1].name, equals('Zzz Last'));   // Incomplete
      expect(todaysHabits[2].name, equals('Aaa First'));  // Completed (last)
    });

    test('sorts alphabetically within same completion status', () {
      // Add habits in reverse alphabetical order
      final habitZ = Habit.create(
        id: 'z',
        name: 'Zzz',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habitM = Habit.create(
        id: 'm',
        name: 'Mmm',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habitA = Habit.create(
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
      final customHabit = Habit.create(
        id: '1',
        name: 'MWF',
        category: HabitCategory.fitness,
        frequency: HabitFrequency.custom,
        customDays: [1, 3, 5], // Mon, Wed, Fri
      );

      container.read(habitsProvider.notifier).addHabit(customHabit);

      // Test on Monday (should appear)
      final monday = DateTime(2024, 1, 1);
      container.read(selectedDateProvider.notifier).state = monday;
      var todaysHabits = container.read(todaysHabitsProvider);
      expect(todaysHabits, hasLength(1));

      // Test on Tuesday (should not appear)
      final tuesday = DateTime(2024, 1, 2);
      container.read(selectedDateProvider.notifier).state = tuesday;
      todaysHabits = container.read(todaysHabitsProvider);
      expect(todaysHabits, isEmpty);

      // Test on Wednesday (should appear)
      final wednesday = DateTime(2024, 1, 3);
      container.read(selectedDateProvider.notifier).state = wednesday;
      todaysHabits = container.read(todaysHabitsProvider);
      expect(todaysHabits, hasLength(1));
    });

    test('updates when selected date changes', () {
      // Add weekdays habit
      final weekdaysHabit = Habit.create(
        id: '1',
        name: 'Work',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.weekdays,
      );

      container.read(habitsProvider.notifier).addHabit(weekdaysHabit);

      // Start on Monday
      final monday = DateTime(2024, 1, 1);
      container.read(selectedDateProvider.notifier).state = monday;
      var todaysHabits = container.read(todaysHabitsProvider);
      expect(todaysHabits, hasLength(1));

      // Change to Saturday
      final saturday = DateTime(2024, 1, 6);
      container.read(selectedDateProvider.notifier).state = saturday;
      todaysHabits = container.read(todaysHabitsProvider);
      expect(todaysHabits, isEmpty);
    });
  });

  group('Phase 5: Computed Providers - habitCompletionProvider', () {
    test('returns false when habit not completed', () {
      final habit = Habit.create(
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
      final habit = Habit.create(
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
      final habit = Habit.create(
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
      final habit = Habit.create(
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
          Habit.create(
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
      container.read(selectedDateProvider.notifier).state = today;

      // Add 3 daily habits
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

      // Complete 2 of them
      container.read(completionsProvider.notifier).markComplete('1', today);
      container.read(completionsProvider.notifier).markComplete('2', today);

      final completed = container.read(completedTodayCountProvider);
      expect(completed, equals(2));
    });

    test('todaysProgressProvider calculates percentage correctly', () {
      final today = DateTime.now();
      container.read(selectedDateProvider.notifier).state = today;

      // Add 4 daily habits
      for (int i = 1; i <= 4; i++) {
        container.read(habitsProvider.notifier).addHabit(
          Habit.create(
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
      container.read(selectedDateProvider.notifier).state = today;

      // Add 2 daily habits
      for (int i = 1; i <= 2; i++) {
        container.read(habitsProvider.notifier).addHabit(
          Habit.create(
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
}
