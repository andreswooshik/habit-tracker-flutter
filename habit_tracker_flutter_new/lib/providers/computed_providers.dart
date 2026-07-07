library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/streak_data.dart';
import '../services/services.dart';
import 'providers.dart';

/// Habits scheduled for [date] (active only), incomplete first, then
/// alphabetical
///
/// Core scheduling logic shared by the today-anchored providers below
/// (dashboard, AI coach) and the selected-date providers (habit list).
final scheduledHabitsForDateProvider =
    Provider.family<List<Habit>, DateTime>((ref, date) {
  // Get all habits
  final habitState = ref.watch(habitsProvider);

  // Filter to active habits scheduled for the date
  final scheduledHabits = habitState.habits
      .where((habit) => !habit.isArchived && habit.isScheduledFor(date))
      .toList();

  // Get completion state to sort completed habits last
  final completionsState = ref.watch(completionsProvider);

  // Sort: incomplete first, then alphabetically
  scheduledHabits.sort((a, b) {
    final aCompleted = completionsState.isCompletedOn(a.id, date);
    final bCompleted = completionsState.isCompletedOn(b.id, date);

    // If completion status differs, incomplete comes first
    if (aCompleted != bCompleted) {
      return aCompleted ? 1 : -1;
    }

    // Same completion status, sort alphabetically
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  return scheduledHabits;
});

/// How many of the habits scheduled for [date] are completed
final completedCountForDateProvider =
    Provider.family<int, DateTime>((ref, date) {
  final habits = ref.watch(scheduledHabitsForDateProvider(date));
  final completionsState = ref.watch(completionsProvider);

  return habits
      .where((habit) => completionsState.isCompletedOn(habit.id, date))
      .length;
});

final habitCompletionProvider =
    Provider.family<bool, ({String habitId, DateTime date})>(
  (ref, params) {
    final completionsState = ref.watch(completionsProvider);
    return completionsState.isCompletedOn(params.habitId, params.date);
  },
);

// ---------------------------------------------------------------------------
// Anchored to the real today (dashboard, AI coach) — these do NOT react
// to the date being browsed in the habit list screen
// ---------------------------------------------------------------------------

final todaysHabitsProvider = Provider<List<Habit>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(scheduledHabitsForDateProvider(today));
});

final todaysHabitsCountProvider = Provider<int>((ref) {
  final todaysHabits = ref.watch(todaysHabitsProvider);
  return todaysHabits.length;
});

final completedTodayCountProvider = Provider<int>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(completedCountForDateProvider(today));
});

final todaysProgressProvider = Provider<double>((ref) {
  final total = ref.watch(todaysHabitsCountProvider);
  if (total == 0) return 0.0;

  final completed = ref.watch(completedTodayCountProvider);
  return completed / total;
});

// ---------------------------------------------------------------------------
// Anchored to the browsing date (habit list screen) — these follow
// selectedDateProvider as the user navigates between days
// ---------------------------------------------------------------------------

final selectedDateHabitsProvider = Provider<List<Habit>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  return ref.watch(scheduledHabitsForDateProvider(selectedDate));
});

final selectedDateHabitsCountProvider = Provider<int>((ref) {
  return ref.watch(selectedDateHabitsProvider).length;
});

final selectedDateCompletedCountProvider = Provider<int>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  return ref.watch(completedCountForDateProvider(selectedDate));
});

final selectedDateProgressProvider = Provider<double>((ref) {
  final total = ref.watch(selectedDateHabitsCountProvider);
  if (total == 0) return 0.0;

  final completed = ref.watch(selectedDateCompletedCountProvider);
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
