library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'streak_calculator.dart';
import 'data_generator.dart';
import 'interfaces/i_streak_calculator.dart';
import 'interfaces/i_data_generator.dart';
import '../models/streak_data.dart';
import '../providers/providers.dart';

final streakCalculatorProvider = Provider<IStreakCalculator>((ref) {
  return const BasicStreakCalculator();
});

final dataGeneratorProvider = Provider<IDataGenerator>((ref) {
  return RandomDataGenerator();
});

final streakDataProvider = Provider.family<StreakData, String>((ref, habitId) {
  // Get the streak calculator service
  final calculator = ref.watch(streakCalculatorProvider);

  // Get the specific habit from the habits state
  final habitState = ref.watch(habitsProvider);
  final habit = habitState.habitsById[habitId];

  // Return zero streak if habit not found or is archived
  if (habit == null || habit.isArchived) {
    return StreakData.zero();
  }

  // Get completion dates for this habit from completions state
  final completionsState = ref.watch(completionsProvider);
  final completions = completionsState.completions[habitId] ?? {};

  // Calculate and return streak data
  return calculator.calculateStreak(habit, completions);
});

final allStreaksProvider = Provider<Map<String, StreakData>>((ref) {
  final calculator = ref.watch(streakCalculatorProvider);
  final habitState = ref.watch(habitsProvider);
  final activeHabits = habitState.habits.where((h) => !h.isArchived);

  final completionsState = ref.watch(completionsProvider);

  final streaks = <String, StreakData>{};
  for (final habit in activeHabits) {
    final completions = completionsState.completions[habit.id] ?? {};
    streaks[habit.id] = calculator.calculateStreak(habit, completions);
  }

  return streaks;
});
