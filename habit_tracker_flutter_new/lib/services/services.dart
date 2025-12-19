/// Service providers for business logic.
///
/// This library exports Riverpod providers for services,
/// following the Dependency Inversion Principle (DIP).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'streak_calculator.dart';
import 'data_generator.dart';
import 'interfaces/i_streak_calculator.dart';
import 'interfaces/i_data_generator.dart';
import '../models/habit.dart';
import '../models/streak_data.dart';
import '../providers/providers.dart';

/// Provider for streak calculation service.
///
/// Returns a [BasicStreakCalculator] that implements [IStreakCalculator].
/// Used by streak-dependent providers to calculate current and longest streaks.
///
/// Example usage:
/// ```dart
/// final calculator = ref.read(streakCalculatorProvider);
/// final streak = calculator.calculateStreak(habit, completions);
/// ```
final streakCalculatorProvider = Provider<IStreakCalculator>((ref) {
  return const BasicStreakCalculator();
});

/// Provider for data generation service.
///
/// Returns a [RandomDataGenerator] that implements [IDataGenerator].
/// Used for:
/// - Demo mode
/// - Onboarding
/// - Testing with realistic data
///
/// Example usage:
/// ```dart
/// final generator = ref.read(dataGeneratorProvider);
/// final habits = generator.generateHabits(10);
/// final completions = generator.generateCompletions(habit: habit, ...);
/// ```
final dataGeneratorProvider = Provider<IDataGenerator>((ref) {
  return RandomDataGenerator();
});

/// Family provider that calculates and caches streaks for individual habits.
///
/// This provider automatically recomputes when either the habit or its
/// completion dates change, providing efficient per-habit streak caching.
///
/// The provider watches:
/// - The specific habit from [habitsProvider]
/// - Completion dates for this habit from [completionsProvider]
///
/// Returns [StreakData.zero()] if:
/// - Habit doesn't exist
/// - Habit is archived
/// - No completions exist
///
/// Example usage:
/// ```dart
/// // In a widget
/// final streak = ref.watch(streakDataProvider(habitId));
/// Text('Current streak: ${streak.current} days');
///
/// // One-time read
/// final streak = ref.read(streakDataProvider(habitId));
/// ```
///
/// Performance: Cached per habit, recomputes only on changes.
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

/// Provider that calculates streaks for all active habits.
///
/// Returns a map of habit ID to [StreakData], useful for dashboard
/// and analytics screens that need to display all streaks at once.
///
/// This provider automatically filters out archived habits.
///
/// Example usage:
/// ```dart
/// final allStreaks = ref.watch(allStreaksProvider);
/// for (final entry in allStreaks.entries) {
///   print('${entry.key}: ${entry.value.current} days');
/// }
/// ```
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
