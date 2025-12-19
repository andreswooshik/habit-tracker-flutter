import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/services/data_generator.dart';
import 'package:habit_tracker_flutter_new/services/interfaces/i_data_generator.dart';

void main() {
  group('RandomDataGenerator - Habit Generation', () {
    test('generates requested number of habits', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final habits = generator.generateHabits(10);
      
      expect(habits.length, 10);
    });

    test('generates habits with unique IDs', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final habits = generator.generateHabits(20);
      final ids = habits.map((h) => h.id).toSet();
      
      expect(ids.length, 20); // All unique
    });

    test('generates habits with valid names', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final habits = generator.generateHabits(5);
      
      for (final habit in habits) {
        expect(habit.name, isNotEmpty);
        expect(habit.name.trim(), isNot(isEmpty));
      }
    });

    test('generates habits across multiple categories', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final habits = generator.generateHabits(50);
      final categories = habits.map((h) => h.category).toSet();
      
      expect(categories.length, greaterThan(3)); // At least 4 different categories
    });

    test('generates habits with different frequencies', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final habits = generator.generateHabits(50);
      final frequencies = habits.map((h) => h.frequency).toSet();
      
      expect(frequencies.length, greaterThan(2)); // At least 3 different frequencies
    });

    test('custom frequency habits have custom days defined', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final habits = generator.generateHabits(100);
      final customHabits = habits.where((h) => h.frequency == HabitFrequency.custom);
      
      for (final habit in customHabits) {
        expect(habit.customDays, isNotNull);
        expect(habit.customDays, isNotEmpty);
        expect(habit.customDays!.every((day) => day >= 1 && day <= 7), true);
      }
    });

    test('generates mix of archived and active habits', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final habits = generator.generateHabits(100);
      final archived = habits.where((h) => h.isArchived).length;
      final active = habits.where((h) => !h.isArchived).length;
      
      expect(archived, greaterThan(0)); // Some archived
      expect(active, greaterThan(archived)); // Most are active
    });

    test('generates habits with varied creation dates', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final habits = generator.generateHabits(20);
      final creationDates = habits.map((h) => h.createdAt.day).toSet();
      
      expect(creationDates.length, greaterThan(1)); // Different dates
    });

    test('generates habits with varied target days', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final habits = generator.generateHabits(30);
      final targetDays = habits.map((h) => h.targetDays).toSet();
      
      expect(targetDays.length, greaterThan(2)); // At least 3 different targets
    });

    test('all generated habits are valid', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final habits = generator.generateHabits(50);
      
      for (final habit in habits) {
        expect(habit.isValid, true, reason: 'Habit ${habit.name} is invalid');
      }
    });

    test('throws ArgumentError for count <= 0', () {
      final generator = RandomDataGenerator(seed: 42);
      
      expect(() => generator.generateHabits(0), throwsArgumentError);
      expect(() => generator.generateHabits(-1), throwsArgumentError);
    });

    test('seeded generator produces deterministic results', () {
      final generator1 = RandomDataGenerator(seed: 12345);
      final generator2 = RandomDataGenerator(seed: 12345);
      
      final habits1 = generator1.generateHabits(10);
      final habits2 = generator2.generateHabits(10);
      
      for (int i = 0; i < 10; i++) {
        expect(habits1[i].name, habits2[i].name);
        expect(habits1[i].frequency, habits2[i].frequency);
        expect(habits1[i].category, habits2[i].category);
      }
    });

    test('different seeds produce different results', () {
      final generator1 = RandomDataGenerator(seed: 111);
      final generator2 = RandomDataGenerator(seed: 222);
      
      final habits1 = generator1.generateHabits(10);
      final habits2 = generator2.generateHabits(10);
      
      final differentCount = List.generate(10, (i) => i)
          .where((i) => habits1[i].name != habits2[i].name)
          .length;
      
      expect(differentCount, greaterThan(5)); // Most should be different
    });
  });

  group('RandomDataGenerator - Completion Generation', () {
    late Habit dailyHabit;

    setUp(() {
      dailyHabit = Habit.create(
        id: 'daily-1',
        name: 'Daily Test',
        frequency: HabitFrequency.everyDay,
        category: HabitCategory.health,
      );
    });

    test('generates completions within date range', () {
      final generator = RandomDataGenerator(seed: 42);
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      
      final completions = generator.generateCompletions(
        habit: dailyHabit,
        startDate: startDate,
        endDate: endDate,
      );
      
      for (final date in completions) {
        expect(date.isAfter(startDate.subtract(const Duration(days: 1))), true);
        expect(date.isBefore(endDate.add(const Duration(days: 1))), true);
      }
    });

    test('respects completion rate', () {
      final generator = RandomDataGenerator(seed: 42);
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31); // 31 days
      
      // Test with 100% completion rate
      final perfectCompletions = generator.generateCompletions(
        habit: dailyHabit,
        startDate: startDate,
        endDate: endDate,
        completionRate: 1.0,
      );
      
      expect(perfectCompletions.length, 31); // All days completed
    });

    test('completion rate of 0.0 generates no completions', () {
      final generator = RandomDataGenerator(seed: 42);
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 10);
      
      final completions = generator.generateCompletions(
        habit: dailyHabit,
        startDate: startDate,
        endDate: endDate,
        completionRate: 0.0,
      );
      
      expect(completions.length, 0);
    });

    test('respects habit frequency', () {
      final weekdayHabit = Habit.create(
        id: 'weekday-1',
        name: 'Weekday Test',
        frequency: HabitFrequency.weekdays,
        category: HabitCategory.productivity,
      );
      
      final generator = RandomDataGenerator(seed: 42);
      final startDate = DateTime(2024, 1, 1); // Monday
      final endDate = DateTime(2024, 1, 7); // Sunday
      
      final completions = generator.generateCompletions(
        habit: weekdayHabit,
        startDate: startDate,
        endDate: endDate,
        completionRate: 1.0,
      );
      
      // Should only have weekdays (Mon-Fri = 5 days)
      expect(completions.length, 5);
      
      // Verify all are weekdays
      for (final date in completions) {
        expect(date.weekday >= DateTime.monday, true);
        expect(date.weekday <= DateTime.friday, true);
      }
    });

    test('normalizes dates to midnight', () {
      final generator = RandomDataGenerator(seed: 42);
      final startDate = DateTime(2024, 1, 1, 15, 30); // With time
      final endDate = DateTime(2024, 1, 5, 20, 45); // With time
      
      final completions = generator.generateCompletions(
        habit: dailyHabit,
        startDate: startDate,
        endDate: endDate,
        completionRate: 1.0,
      );
      
      for (final date in completions) {
        expect(date.hour, 0);
        expect(date.minute, 0);
        expect(date.second, 0);
        expect(date.millisecond, 0);
      }
    });

    test('throws ArgumentError when endDate before startDate', () {
      final generator = RandomDataGenerator(seed: 42);
      final startDate = DateTime(2024, 1, 10);
      final endDate = DateTime(2024, 1, 1);
      
      expect(
        () => generator.generateCompletions(
          habit: dailyHabit,
          startDate: startDate,
          endDate: endDate,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for invalid completion rate', () {
      final generator = RandomDataGenerator(seed: 42);
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 10);
      
      expect(
        () => generator.generateCompletions(
          habit: dailyHabit,
          startDate: startDate,
          endDate: endDate,
          completionRate: -0.1,
        ),
        throwsArgumentError,
      );
      
      expect(
        () => generator.generateCompletions(
          habit: dailyHabit,
          startDate: startDate,
          endDate: endDate,
          completionRate: 1.5,
        ),
        throwsArgumentError,
      );
    });

    test('handles single day range', () {
      final generator = RandomDataGenerator(seed: 42);
      final date = DateTime(2024, 1, 15);
      
      final completions = generator.generateCompletions(
        habit: dailyHabit,
        startDate: date,
        endDate: date,
        completionRate: 1.0,
      );
      
      expect(completions.length, 1);
      expect(completions.first.year, 2024);
      expect(completions.first.month, 1);
      expect(completions.first.day, 15);
    });

    test('handles custom frequency habits', () {
      final customHabit = Habit.create(
        id: 'custom-1',
        name: 'Custom Test',
        frequency: HabitFrequency.custom,
        customDays: [DateTime.monday, DateTime.wednesday, DateTime.friday],
        category: HabitCategory.fitness,
      );
      
      final generator = RandomDataGenerator(seed: 42);
      final startDate = DateTime(2024, 1, 1); // Monday
      final endDate = DateTime(2024, 1, 14); // 2 weeks
      
      final completions = generator.generateCompletions(
        habit: customHabit,
        startDate: startDate,
        endDate: endDate,
        completionRate: 1.0,
      );
      
      // 2 weeks * 3 days/week = 6 days
      expect(completions.length, 6);
      
      // Verify all are Mon/Wed/Fri
      for (final date in completions) {
        expect(
          [DateTime.monday, DateTime.wednesday, DateTime.friday].contains(date.weekday),
          true,
        );
      }
    });

    test('seeded generator produces consistent completions', () {
      final generator1 = RandomDataGenerator(seed: 777);
      final generator2 = RandomDataGenerator(seed: 777);
      
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      
      final completions1 = generator1.generateCompletions(
        habit: dailyHabit,
        startDate: startDate,
        endDate: endDate,
        completionRate: 0.7,
      );
      
      final completions2 = generator2.generateCompletions(
        habit: dailyHabit,
        startDate: startDate,
        endDate: endDate,
        completionRate: 0.7,
      );
      
      expect(completions1, completions2);
    });
  });

  group('RandomDataGenerator - Complete Dataset', () {
    test('generates requested number of habits', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final data = generator.generateCompleteDataset(habitCount: 15);
      
      expect(data.habits.length, 15);
    });

    test('generates completions for all habits', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final data = generator.generateCompleteDataset(habitCount: 10);
      
      expect(data.completions.length, 10);
      
      for (final habit in data.habits) {
        expect(data.completions.containsKey(habit.id), true);
      }
    });

    test('completions respect habit creation dates', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final data = generator.generateCompleteDataset(
        habitCount: 20,
        daysOfHistory: 60,
      );
      
      for (final habit in data.habits) {
        final completions = data.completions[habit.id]!;
        
        if (completions.isNotEmpty) {
          final earliestCompletion = completions.reduce(
            (a, b) => a.isBefore(b) ? a : b,
          );
          
          // Earliest completion should not be before habit creation
          expect(
            earliestCompletion.isAfter(habit.createdAt.subtract(const Duration(days: 1))),
            true,
          );
        }
      }
    });

    test('generates varied completion patterns', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final data = generator.generateCompleteDataset(habitCount: 20);
      
      final completionCounts = data.completions.values
          .map((completions) => completions.length)
          .toList();
      
      // Should have variety (not all the same)
      final uniqueCounts = completionCounts.toSet();
      expect(uniqueCounts.length, greaterThan(3));
    });

    test('uses default parameters correctly', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final data = generator.generateCompleteDataset();
      
      expect(data.habits.length, 10); // Default habitCount
      expect(data.completions.length, 10);
    });

    test('throws ArgumentError for invalid habitCount', () {
      final generator = RandomDataGenerator(seed: 42);
      
      expect(
        () => generator.generateCompleteDataset(habitCount: 0),
        throwsArgumentError,
      );
      
      expect(
        () => generator.generateCompleteDataset(habitCount: -5),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for negative daysOfHistory', () {
      final generator = RandomDataGenerator(seed: 42);
      
      expect(
        () => generator.generateCompleteDataset(daysOfHistory: -10),
        throwsArgumentError,
      );
    });

    test('handles zero daysOfHistory', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final data = generator.generateCompleteDataset(daysOfHistory: 0);
      
      expect(data.habits.length, 10);
      expect(data.completions.length, 10);
      
      // Should have minimal completions (only today's date range)
      final totalCompletions = data.completions.values
          .fold(0, (sum, completions) => sum + completions.length);
      
      expect(totalCompletions, lessThan(15)); // Very few
    });

    test('more history generates more completions', () {
      final generator1 = RandomDataGenerator(seed: 100);
      final generator2 = RandomDataGenerator(seed: 100);
      
      final data7Days = generator1.generateCompleteDataset(daysOfHistory: 7);
      final data30Days = generator2.generateCompleteDataset(daysOfHistory: 30);
      
      final total7 = data7Days.completions.values
          .fold(0, (sum, completions) => sum + completions.length);
      
      final total30 = data30Days.completions.values
          .fold(0, (sum, completions) => sum + completions.length);
      
      expect(total30, greaterThan(total7));
    });

    test('all habits in dataset are valid', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final data = generator.generateCompleteDataset(habitCount: 30);
      
      for (final habit in data.habits) {
        expect(habit.isValid, true);
      }
    });

    test('completions only on scheduled days', () {
      final generator = RandomDataGenerator(seed: 42);
      
      final data = generator.generateCompleteDataset(habitCount: 20);
      
      for (final habit in data.habits) {
        final completions = data.completions[habit.id]!;
        
        for (final date in completions) {
          expect(habit.isScheduledFor(date), true,
              reason: 'Habit ${habit.name} has completion on non-scheduled day');
        }
      }
    });
  });

  group('RandomDataGenerator - GeneratedData Class', () {
    test('can create GeneratedData with data', () {
      final habits = [
        Habit.create(
          id: '1',
          name: 'Test',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.health,
        ),
      ];
      
      final completions = {
        '1': {DateTime(2024, 1, 1)},
      };
      
      final data = GeneratedData(habits: habits, completions: completions);
      
      expect(data.habits.length, 1);
      expect(data.completions.length, 1);
    });

    test('can create empty GeneratedData', () {
      final data = const GeneratedData.empty();
      
      expect(data.habits, isEmpty);
      expect(data.completions, isEmpty);
    });
  });
}
