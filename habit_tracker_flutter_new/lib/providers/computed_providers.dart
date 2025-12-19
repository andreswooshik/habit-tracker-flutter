library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/streak_data.dart';
import '../services/services.dart';
import 'providers.dart';

final todaysHabitsProvider = Provider<List<Habit>>((ref) {
  // Get the selected date
  final selectedDate = ref.watch(selectedDateProvider);

  // Get all habits
  final habitState = ref.watch(habitsProvider);

  // Filter to active habits scheduled for the selected date
  final scheduledHabits = habitState.habits
      .where((habit) => !habit.isArchived && habit.isScheduledFor(selectedDate))
      .toList();

  // Get completion state to sort completed habits last
  final completionsState = ref.watch(completionsProvider);

  // Sort: incomplete first, then alphabetically
  scheduledHabits.sort((a, b) {
    final aCompleted = completionsState.isCompletedOn(a.id, selectedDate);
    final bCompleted = completionsState.isCompletedOn(b.id, selectedDate);

    // If completion status differs, incomplete comes first
    if (aCompleted != bCompleted) {
      return aCompleted ? 1 : -1;
    }

    // Same completion status, sort alphabetically
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  return scheduledHabits;
});

final habitCompletionProvider =
    Provider.family<bool, ({String habitId, DateTime date})>(
  (ref, params) {
    final completionsState = ref.watch(completionsProvider);
    return completionsState.isCompletedOn(params.habitId, params.date);
  },
);

final todaysHabitsCountProvider = Provider<int>((ref) {
  final todaysHabits = ref.watch(todaysHabitsProvider);
  return todaysHabits.length;
});

final completedTodayCountProvider = Provider<int>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final todaysHabits = ref.watch(todaysHabitsProvider);
  final completionsState = ref.watch(completionsProvider);

  return todaysHabits
      .where((habit) => completionsState.isCompletedOn(habit.id, selectedDate))
      .length;
});

/// ```
final todaysProgressProvider = Provider<double>((ref) {
  final total = ref.watch(todaysHabitsCountProvider);
  if (total == 0) return 0.0;

  final completed = ref.watch(completedTodayCountProvider);
  return completed / total;
});

final habitStreakProvider = Provider.family<StreakData, String>((ref, habitId) {
  final habitState = ref.watch(habitsProvider);
  final completionsState = ref.watch(completionsProvider);
  final streakCalculator = ref.watch(streakCalculatorProvider);

  // Find the habit
  final habit = habitState.habits.firstWhere(
    (h) => h.id == habitId,
    orElse: () => throw Exception('Habit not found'),
  );

  // Get completions for this habit
  final habitCompletions = completionsState.completions[habitId] ?? {};

  // Calculate and return streak
  return streakCalculator.calculateStreak(habit, habitCompletions);
});
