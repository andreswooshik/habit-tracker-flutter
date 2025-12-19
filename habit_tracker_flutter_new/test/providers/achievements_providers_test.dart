import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/achievement.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/providers/achievements_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('Phase 5: Achievements Providers - achievementsProvider', () {
    test('returns empty list when no habits exist', () {
      final achievements = container.read(achievementsProvider);
      expect(achievements, isEmpty);
    });

    test('generates first completion achievement for 1-day streak', () {
      final habit = Habit.create(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 2);
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 2));

      final achievements = container.read(achievementsProvider);
      
      expect(achievements.length, equals(1));
      expect(achievements.first.type, equals(AchievementType.firstCompletion));
      expect(achievements.first.habitId, equals('1'));
      expect(achievements.first.habitName, equals('Test'));
    });

    test('generates multiple achievements for 7-day streak', () {
      final habit = Habit.create(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 7);

      // Complete 7 consecutive days
      for (int i = 1; i <= 7; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      final achievements = container.read(achievementsProvider);
      
      // Should have: firstCompletion, streak3, streak7, perfect7
      expect(achievements.length, equals(4));
      expect(achievements.any((a) => a.type == AchievementType.firstCompletion), isTrue);
      expect(achievements.any((a) => a.type == AchievementType.streak3), isTrue);
      expect(achievements.any((a) => a.type == AchievementType.streak7), isTrue);
      expect(achievements.any((a) => a.type == AchievementType.perfect7), isTrue);
    });

    test('generates achievements for 30-day streak', () {
      final habit = Habit.create(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 30);

      // Complete 30 consecutive days
      for (int i = 1; i <= 30; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      final achievements = container.read(achievementsProvider);
      
      // Should have: firstCompletion, streak3, streak7, perfect7, streak30, perfect30
      expect(achievements.length, equals(6));
      expect(achievements.any((a) => a.type == AchievementType.streak30), isTrue);
      expect(achievements.any((a) => a.type == AchievementType.perfect30), isTrue);
    });

    test('generates separate achievements for multiple habits', () {
      final habit1 = Habit.create(
        id: '1',
        name: 'Habit 1',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habit2 = Habit.create(
        id: '2',
        name: 'Habit 2',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit1);
      container.read(habitsProvider.notifier).addHabit(habit2);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 3);

      // Both habits: 3-day streak
      for (int i = 1; i <= 3; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
        container.read(completionsProvider.notifier)
            .markComplete('2', DateTime(2024, 1, i));
      }

      final achievements = container.read(achievementsProvider);
      
      // Each habit should have: firstCompletion, streak3
      expect(achievements.length, equals(4));
      expect(achievements.where((a) => a.habitId == '1').length, equals(2));
      expect(achievements.where((a) => a.habitId == '2').length, equals(2));
    });

    test('excludes archived habits from achievements', () {
      final habit = Habit.create(
        id: '1',
        name: 'To Archive',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 3);

      // Create 3-day streak
      for (int i = 1; i <= 3; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      // Archive the habit
      container.read(habitsProvider.notifier).archiveHabit('1');

      final achievements = container.read(achievementsProvider);
      expect(achievements, isEmpty);
    });
  });

  group('Phase 5: Achievements Providers - habitAchievementsProvider', () {
    test('returns achievements for specific habit', () {
      final habit1 = Habit.create(
        id: '1',
        name: 'Habit 1',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habit2 = Habit.create(
        id: '2',
        name: 'Habit 2',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit1);
      container.read(habitsProvider.notifier).addHabit(habit2);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 3);

      // Both habits: 3-day streak
      for (int i = 1; i <= 3; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
        container.read(completionsProvider.notifier)
            .markComplete('2', DateTime(2024, 1, i));
      }

      final habit1Achievements = container.read(habitAchievementsProvider('1'));
      final habit2Achievements = container.read(habitAchievementsProvider('2'));
      
      expect(habit1Achievements.length, equals(2));
      expect(habit2Achievements.length, equals(2));
      expect(habit1Achievements.every((a) => a.habitId == '1'), isTrue);
      expect(habit2Achievements.every((a) => a.habitId == '2'), isTrue);
    });
  });

  group('Phase 5: Achievements Providers - unseenAchievementsCountProvider', () {
    test('returns count of unseen achievements', () {
      final habit = Habit.create(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 3);

      // Create 3-day streak (firstCompletion + streak3 = 2 achievements)
      for (int i = 1; i <= 3; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      final unseenCount = container.read(unseenAchievementsCountProvider);
      expect(unseenCount, equals(2));
    });
  });

  group('Phase 5: Consistency Providers - weeklyConsistencyProvider', () {
    test('calculates 100% consistency for perfect week', () {
      final habit = Habit.create(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 7);

      // Complete all 7 days
      for (int i = 1; i <= 7; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      final consistency = container.read(weeklyConsistencyProvider);
      expect(consistency['1'], equals(1.0)); // 100%
    });

    test('calculates 50% consistency for half completed week', () {
      final habit = Habit.create(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 8);

      // Complete 4 out of 7 days (Jan 2-8)
      for (int i = 2; i <= 8; i += 2) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      final consistency = container.read(weeklyConsistencyProvider);
      expect(consistency['1'], closeTo(0.57, 0.01)); // 4/7 ≈ 57%
    });

    test('respects habit frequency when calculating consistency', () {
      final weekdaysHabit = Habit.create(
        id: '1',
        name: 'Weekdays',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.weekdays,
      );

      container.read(habitsProvider.notifier).addHabit(weekdaysHabit);
      
      // Jan 1-7, 2024: Mon-Sun (5 weekdays)
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 7);

      // Complete Mon, Tue, Thu (3 out of 5 weekdays)
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 1)); // Mon
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 2)); // Tue
      container.read(completionsProvider.notifier)
          .markComplete('1', DateTime(2024, 1, 4)); // Thu

      final consistency = container.read(weeklyConsistencyProvider);
      expect(consistency['1'], equals(0.6)); // 3/5 = 60%
    });

    test('returns 0% for completely missed week', () {
      final habit = Habit.create(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 7);

      // No completions
      final consistency = container.read(weeklyConsistencyProvider);
      expect(consistency['1'], equals(0.0));
    });

    test('calculates consistency for multiple habits', () {
      final habit1 = Habit.create(
        id: '1',
        name: 'Perfect',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habit2 = Habit.create(
        id: '2',
        name: 'Struggling',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit1);
      container.read(habitsProvider.notifier).addHabit(habit2);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 7);

      // Habit 1: perfect 7/7
      for (int i = 1; i <= 7; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      // Habit 2: 2/7
      container.read(completionsProvider.notifier)
          .markComplete('2', DateTime(2024, 1, 1));
      container.read(completionsProvider.notifier)
          .markComplete('2', DateTime(2024, 1, 7));

      final consistency = container.read(weeklyConsistencyProvider);
      expect(consistency['1'], equals(1.0)); // 100%
      expect(consistency['2'], closeTo(0.286, 0.01)); // 2/7 ≈ 28.6%
    });
  });

  group('Phase 5: Consistency Providers - habitConsistencyProvider', () {
    test('returns consistency for specific habit', () {
      final habit = Habit.create(
        id: '1',
        name: 'Test',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 7);

      // Complete 5 out of 7 days
      for (int i = 1; i <= 5; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      final consistency = container.read(habitConsistencyProvider('1'));
      expect(consistency, closeTo(0.714, 0.01)); // 5/7 ≈ 71.4%
    });

    test('returns 0.0 for nonexistent habit', () {
      final consistency = container.read(habitConsistencyProvider('nonexistent'));
      expect(consistency, equals(0.0));
    });
  });

  group('Phase 5: Consistency Providers - habitsByConsistencyProvider', () {
    test('groups habits by consistency level', () {
      // Create habits with different consistency levels
      final highConsistency = Habit.create(
        id: '1',
        name: 'High',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final mediumConsistency = Habit.create(
        id: '2',
        name: 'Medium',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.everyDay,
      );
      final lowConsistency = Habit.create(
        id: '3',
        name: 'Low',
        category: HabitCategory.mindfulness,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(highConsistency);
      container.read(habitsProvider.notifier).addHabit(mediumConsistency);
      container.read(habitsProvider.notifier).addHabit(lowConsistency);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 7);

      // High: 6/7 (85.7%)
      for (int i = 1; i <= 6; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      // Medium: 4/7 (57.1%)
      for (int i = 1; i <= 4; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('2', DateTime(2024, 1, i));
      }

      // Low: 2/7 (28.6%)
      for (int i = 1; i <= 2; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('3', DateTime(2024, 1, i));
      }

      final grouped = container.read(habitsByConsistencyProvider);
      
      expect(grouped['high']?.length, equals(1));
      expect(grouped['medium']?.length, equals(1));
      expect(grouped['low']?.length, equals(1));
      
      expect(grouped['high']?.first.id, equals('1'));
      expect(grouped['medium']?.first.id, equals('2'));
      expect(grouped['low']?.first.id, equals('3'));
    });
  });

  group('Phase 5: Consistency Providers - averageConsistencyProvider', () {
    test('calculates average consistency across all habits', () {
      final habit1 = Habit.create(
        id: '1',
        name: 'Habit 1',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyDay,
      );
      final habit2 = Habit.create(
        id: '2',
        name: 'Habit 2',
        category: HabitCategory.productivity,
        frequency: HabitFrequency.everyDay,
      );

      container.read(habitsProvider.notifier).addHabit(habit1);
      container.read(habitsProvider.notifier).addHabit(habit2);
      container.read(selectedDateProvider.notifier).state = DateTime(2024, 1, 7);

      // Habit 1: 7/7 (100%)
      for (int i = 1; i <= 7; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('1', DateTime(2024, 1, i));
      }

      // Habit 2: 3/7 (42.9%)
      for (int i = 1; i <= 3; i++) {
        container.read(completionsProvider.notifier)
            .markComplete('2', DateTime(2024, 1, i));
      }

      final avgConsistency = container.read(averageConsistencyProvider);
      expect(avgConsistency, closeTo(0.714, 0.01)); // (1.0 + 0.429) / 2 ≈ 0.714
    });

    test('returns 0.0 when no habits exist', () {
      final avgConsistency = container.read(averageConsistencyProvider);
      expect(avgConsistency, equals(0.0));
    });
  });
}
