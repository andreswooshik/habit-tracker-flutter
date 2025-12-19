import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/providers/calendar_providers.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('Phase 5: Calendar Providers - calendarDataProvider', () {
    test('generates full month of dates', () {
      final habit = Habit.create(
        id: '1',
        name: 'Daily',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);

      // Get January 2024 calendar data (31 days)
      final calendarData = container.read(
        calendarDataProvider((habitId: '1', year: 2024, month: 1)),
      );

      expect(calendarData.length, equals(31));
    });

    test('marks completed dates with 1', () {
      final habit = Habit.create(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);

      // Complete Jan 15 and Jan 20
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 15));
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 20));

      final calendarData = container.read(
        calendarDataProvider((habitId: '1', year: 2024, month: 1)),
      );

      expect(calendarData[DateTime(2024, 1, 15)], equals(1));
      expect(calendarData[DateTime(2024, 1, 20)], equals(1));
    });

    test('marks incomplete dates with 0', () {
      final habit = Habit.create(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);

      final calendarData = container.read(
        calendarDataProvider((habitId: '1', year: 2024, month: 1)),
      );

      // All days should be 0 (incomplete)
      expect(calendarData.values.every((v) => v == 0), isTrue);
    });

    test('handles different month lengths correctly', () {
      final habit = Habit.create(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);

      // February 2024 (leap year, 29 days)
      var calendarData = container.read(
        calendarDataProvider((habitId: '1', year: 2024, month: 2)),
      );
      expect(calendarData.length, equals(29));

      // February 2023 (non-leap year, 28 days)
      calendarData = container.read(
        calendarDataProvider((habitId: '1', year: 2023, month: 2)),
      );
      expect(calendarData.length, equals(28));

      // April 2024 (30 days)
      calendarData = container.read(
        calendarDataProvider((habitId: '1', year: 2024, month: 4)),
      );
      expect(calendarData.length, equals(30));
    });

    test('returns empty data for nonexistent habit', () {
      final calendarData = container.read(
        calendarDataProvider((habitId: 'nonexistent', year: 2024, month: 1)),
      );

      // Should still generate 31 dates, all with 0
      expect(calendarData.length, equals(31));
      expect(calendarData.values.every((v) => v == 0), isTrue);
    });
  });

  group('Phase 5: Calendar Providers - habitCompletionsInRangeProvider', () {
    test('returns completions within date range', () {
      final habit = Habit.create(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);

      // Complete several dates
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 10));
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 15));
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 20));
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 25));

      // Query Jan 15-20 range
      final completions = container.read(
        habitCompletionsInRangeProvider((
          habitId: '1',
          startDate: DateTime(2024, 1, 15),
          endDate: DateTime(2024, 1, 20),
        )),
      );

      expect(completions.length, equals(2));
      expect(completions.contains(DateTime(2024, 1, 15)), isTrue);
      expect(completions.contains(DateTime(2024, 1, 20)), isTrue);
    });

    test('excludes completions outside range', () {
      final habit = Habit.create(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);

      // Complete dates before, during, and after range
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 5));  // Before
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 15)); // During
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 25)); // After

      // Query Jan 10-20 range
      final completions = container.read(
        habitCompletionsInRangeProvider((
          habitId: '1',
          startDate: DateTime(2024, 1, 10),
          endDate: DateTime(2024, 1, 20),
        )),
      );

      expect(completions.length, equals(1));
      expect(completions.contains(DateTime(2024, 1, 15)), isTrue);
    });

    test('returns empty set for no completions', () {
      final habit = Habit.create(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);

      final completions = container.read(
        habitCompletionsInRangeProvider((
          habitId: '1',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        )),
      );

      expect(completions, isEmpty);
    });
  });

  group('Phase 5: Calendar Providers - habitsScheduledCountProvider', () {
    test('counts habits scheduled for given date', () {
      // Add 2 daily habits
      for (int i = 1; i <= 2; i++) {
        container.read(habitsProvider.notifier).addHabit(
          Habit.create(
            id: '$i',
            name: 'Daily $i',
            category: HabitCategory.health,
            frequency: HabitFrequency.everyDay,
          ),
        );
      }

      // Add 1 weekdays habit
      container.read(habitsProvider.notifier).addHabit(
        Habit.create(
          id: '3',
          name: 'Weekdays',
          category: HabitCategory.productivity,
          frequency: HabitFrequency.weekdays,
        ),
      );

      // Monday: should have all 3
      final monday = DateTime(2024, 1, 1);
      var count = container.read(habitsScheduledCountProvider(monday));
      expect(count, equals(3));

      // Saturday: should have only 2 (daily habits)
      final saturday = DateTime(2024, 1, 6);
      count = container.read(habitsScheduledCountProvider(saturday));
      expect(count, equals(2));
    });

    test('excludes archived habits', () {
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

      final count = container.read(
        habitsScheduledCountProvider(DateTime.now()),
      );
      expect(count, equals(1));
    });
  });

  group('Phase 5: Calendar Providers - completionRateProvider', () {
    test('calculates correct rate for daily habit', () {
      final habit = Habit.create(
        id: '1',
        name: 'Daily',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);

      // Complete 7 out of 10 days
      final endDate = DateTime(2024, 1, 10);
      for (int i = 1; i <= 7; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      final rate = container.read(
        completionRateProvider((
          habitId: '1',
          startDate: DateTime(2024, 1, 1),
          endDate: endDate,
        )),
      );

      expect(rate, equals(0.7)); // 7/10 = 70%
    });

    test('calculates correct rate for weekdays habit', () {
      final habit = Habit.create(
        id: '1',
        name: 'Weekdays',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.weekdays,
      );

      container.read(habitsProvider.notifier).addHabit(habit);

      // Jan 1-7, 2024: Mon-Sun (5 weekdays)
      // Complete Mon, Tue, Thu (3 out of 5)
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 1)); // Mon
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 2)); // Tue
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 4)); // Thu

      final rate = container.read(
        completionRateProvider((
          habitId: '1',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 7),
        )),
      );

      expect(rate, equals(0.6)); // 3/5 = 60%
    });

    test('returns 1.0 for 100% completion', () {
      final habit = Habit.create(
        id: '1',
        name: 'Perfect',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);

      // Complete all 5 days
      for (int i = 1; i <= 5; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      final rate = container.read(
        completionRateProvider((
          habitId: '1',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 5),
        )),
      );

      expect(rate, equals(1.0)); // 100%
    });

    test('returns 0.0 for nonexistent habit', () {
      final rate = container.read(
        completionRateProvider((
          habitId: 'nonexistent',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 10),
        )),
      );

      expect(rate, equals(0.0));
    });

    test('returns 0.0 when no scheduled days in range', () {
      // Weekdays habit, but query only weekend
      final habit = Habit.create(
        id: '1',
        name: 'Weekdays',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.weekdays,
      );

      container.read(habitsProvider.notifier).addHabit(habit);

      // Saturday-Sunday (no weekdays)
      final rate = container.read(
        completionRateProvider((
          habitId: '1',
          startDate: DateTime(2024, 1, 6),  // Sat
          endDate: DateTime(2024, 1, 7),    // Sun
        )),
      );

      expect(rate, equals(0.0));
    });
  });

  group('Phase 5: Calendar Providers - habitsForDateProvider', () {
    test('returns habits scheduled for given date', () {
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

      // Monday: both should be scheduled
      final monday = DateTime(2024, 1, 1);
      var habits = container.read(habitsForDateProvider(monday));
      expect(habits.length, equals(2));

      // Saturday: only daily
      final saturday = DateTime(2024, 1, 6);
      habits = container.read(habitsForDateProvider(saturday));
      expect(habits.length, equals(1));
      expect(habits.first.id, equals('1'));
    });
  });
}
