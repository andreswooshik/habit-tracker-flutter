import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/services/services.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('Service Providers Integration', () {
    test('streakCalculatorProvider provides BasicStreakCalculator', () {
      final calculator = container.read(streakCalculatorProvider);

      expect(calculator, isNotNull);

      // Verify it works with a simple habit
      final habit = Habit.create(
        id: 'test-1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final today = DateTime(2024, 1, 15);
      final completions = {
        DateTime(2024, 1, 13),
        DateTime(2024, 1, 14),
        DateTime(2024, 1, 15),
      };

      final streak = calculator.calculateStreak(
        habit,
        completions,
      );

      expect(streak.current, equals(3));
      expect(streak.hasActiveStreak, isTrue);
    });

    test('dataGeneratorProvider provides RandomDataGenerator', () {
      final generator = container.read(dataGeneratorProvider);

      expect(generator, isNotNull);

      // Verify it generates habits
      final habits = generator.generateHabits(5);
      expect(habits, hasLength(5));
      expect(habits.every((h) => h.name.isNotEmpty), isTrue);
      expect(habits.every((h) => h.id.isNotEmpty), isTrue);

      // Verify unique IDs
      final ids = habits.map((h) => h.id).toSet();
      expect(ids, hasLength(5));
    });

    test('generated data can be used with streak calculator', () {
      final generator = container.read(dataGeneratorProvider);
      final calculator = container.read(streakCalculatorProvider);

      // Generate a daily habit
      final habits = generator.generateHabits(1);
      final habit = habits.first;

      // Generate completions for last 30 days
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));
      final completions = generator.generateCompletions(
        habit: habit,
        startDate: startDate,
        endDate: endDate,
        completionRate: 0.8,
      );

      // Calculate streak
      final streak = calculator.calculateStreak(
        habit,
        completions,
      );

      // Should have some streak (may or may not be on streak depending on today)
      expect(streak.longest, greaterThanOrEqualTo(0));
      expect(streak.current, greaterThanOrEqualTo(0));
    });

    test('multiple habits can be generated and have streaks calculated', () {
      final generator = container.read(dataGeneratorProvider);
      final calculator = container.read(streakCalculatorProvider);

      // Generate a complete dataset
      final dataset = generator.generateCompleteDataset(
        habitCount: 10,
        daysOfHistory: 60,
      );

      expect(dataset.habits, hasLength(10));
      expect(dataset.completions, hasLength(10));

      // Calculate streaks for all habits
      final today = DateTime.now();
      for (final habit in dataset.habits) {
        final completions = dataset.completions[habit.id] ?? {};
        final streak = calculator.calculateStreak(
          habit,
          completions,
        );

        // All calculations should succeed
        expect(streak, isNotNull);
        expect(streak.longest, greaterThanOrEqualTo(streak.current));
      }
    });

    test('generated data has realistic completion patterns', () {
      final generator = container.read(dataGeneratorProvider);
      final calculator = container.read(streakCalculatorProvider);

      // Generate daily habit with high completion rate
      final dataset = generator.generateCompleteDataset(
        habitCount: 1,
        daysOfHistory: 90,
      );

      final habit = dataset.habits.first;
      final completions = dataset.completions[habit.id] ?? {};
      final today = DateTime.now();

      final streak = calculator.calculateStreak(
        habit,
        completions,
      );

      // With 90 days of history, should have meaningful longest streak
      // (unless completion rate was very low)
      if (completions.length > 30) {
        expect(streak.longest, greaterThan(0));
      }
    });

    test('provider instances are consistent', () {
      final calculator1 = container.read(streakCalculatorProvider);
      final calculator2 = container.read(streakCalculatorProvider);
      final generator1 = container.read(dataGeneratorProvider);
      final generator2 = container.read(dataGeneratorProvider);

      // Same provider should return same instance
      expect(identical(calculator1, calculator2), isTrue);
      expect(identical(generator1, generator2), isTrue);
    });

    test('services can be used independently', () {
      // Calculator doesn't need generator
      final calculator = container.read(streakCalculatorProvider);
      final habit = Habit.create(
        id: 'independent',
        name: 'Independent Test',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.everyDay,
      );
      final streak = calculator.calculateStreak(
        habit,
        {DateTime(2024, 1, 1)},
      );
      expect(streak.current, equals(1));

      // Generator doesn't need calculator
      final generator = container.read(dataGeneratorProvider);
      final habits = generator.generateHabits(3);
      expect(habits, hasLength(3));
    });
  });

  group('End-to-End Workflows', () {
    test('demo mode workflow: generate and analyze', () {
      final generator = container.read(dataGeneratorProvider);
      final calculator = container.read(streakCalculatorProvider);

      // 1. Generate demo data (like onboarding demo mode)
      final dataset = generator.generateCompleteDataset(
        habitCount: 5,
        daysOfHistory: 30,
      );

      expect(dataset.habits, hasLength(5));

      // 2. Analyze each habit
      final today = DateTime.now();
      final streaks = <String, int>{};
      for (final habit in dataset.habits) {
        final completions = dataset.completions[habit.id] ?? {};
        final streak = calculator.calculateStreak(
          habit,
          completions,
        );
        streaks[habit.name] = streak.longest;
      }

      // 3. Verify we got meaningful data
      expect(streaks, hasLength(5));
      final totalStreaks = streaks.values.reduce((a, b) => a + b);
      expect(totalStreaks, greaterThan(0)); // At least some streaks should exist
    });

    test('onboarding workflow: generate sample habit', () {
      final generator = container.read(dataGeneratorProvider);
      final calculator = container.read(streakCalculatorProvider);

      // 1. Generate a single impressive habit for onboarding
      final habits = generator.generateHabits(1);
      final habit = habits.first;

      // 2. Generate good completion history
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 60));
      final completions = generator.generateCompletions(
        habit: habit,
        startDate: startDate,
        endDate: endDate,
        completionRate: 0.85, // High completion rate for demo
      );

      // 3. Calculate impressive stats
      final streak = calculator.calculateStreak(
        habit,
        completions,
      );

      // 4. Should have good numbers to show user
      expect(completions.length, greaterThan(30)); // At least ~51 completions
      expect(streak.longest, greaterThan(3)); // Some meaningful streak
    });

    test('testing workflow: generated habits have expected structure', () {
      final generator = container.read(dataGeneratorProvider);

      // Generate habits
      final habits = generator.generateHabits(10);

      // Should have proper structure
      expect(habits.length, equals(10));
      
      // All habits should have required fields
      for (final habit in habits) {
        expect(habit.id, isNotEmpty);
        expect(habit.name, isNotEmpty);
        expect(habit.category, isNotNull);
        expect(habit.frequency, isNotNull);
        expect(habit.createdAt, isNotNull);
      }
      
      // Should have variety in categories and frequencies
      final categories = habits.map((h) => h.category).toSet();
      final frequencies = habits.map((h) => h.frequency).toSet();
      expect(categories.length, greaterThan(1)); // Multiple categories
      expect(frequencies.length, greaterThan(1)); // Multiple frequencies
    });
  });
}
