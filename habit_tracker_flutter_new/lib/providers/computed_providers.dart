/// Computed providers that derive state from core providers.
///
/// These providers combine and transform data from base providers
/// (habitsProvider, completionsProvider, etc.) to create derived state
/// for the UI layer.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import 'providers.dart';

/// Provider that returns habits scheduled for the currently selected date.
///
/// This provider combines:
/// - [habitsProvider] - all habits
/// - [selectedDateProvider] - currently selected date
///
/// Returns a sorted list of active (non-archived) habits that are
/// scheduled for the selected date based on their frequency.
///
/// Sorting priority:
/// 1. Completed habits last
/// 2. Alphabetically by name
///
/// Example usage:
/// ```dart
/// // In a widget
/// final todaysHabits = ref.watch(todaysHabitsProvider);
/// for (final habit in todaysHabits) {
///   HabitCard(habit: habit);
/// }
/// ```
///
/// Performance: Rebuilds only when habits or selected date changes.
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

/// Family provider that checks if a habit is completed on a specific date.
///
/// Parameters:
/// - habitId: The ID of the habit to check
/// - date: The date to check (will be normalized to midnight)
///
/// Returns true if the habit is marked complete on the given date,
/// false otherwise.
///
/// Example usage:
/// ```dart
/// // Check if habit is completed today
/// final isCompleted = ref.watch(
///   habitCompletionProvider((habitId: 'abc', date: DateTime.now()))
/// );
///
/// // Toggle completion
/// if (isCompleted) {
///   CompletionButton(onTap: () => markIncomplete(habitId));
/// } else {
///   CompletionButton(onTap: () => markComplete(habitId));
/// }
/// ```
///
/// Performance: Cached per (habitId, date) combination.
final habitCompletionProvider = Provider.family<bool, ({String habitId, DateTime date})>(
  (ref, params) {
    final completionsState = ref.watch(completionsProvider);
    return completionsState.isCompletedOn(params.habitId, params.date);
  },
);

/// Provider that returns the count of habits scheduled for the selected date.
///
/// Useful for displaying summary statistics like "5 habits today".
///
/// Example usage:
/// ```dart
/// final count = ref.watch(todaysHabitsCountProvider);
/// Text('$count habits today');
/// ```
final todaysHabitsCountProvider = Provider<int>((ref) {
  final todaysHabits = ref.watch(todaysHabitsProvider);
  return todaysHabits.length;
});

/// Provider that returns the count of completed habits for the selected date.
///
/// Useful for displaying progress like "3/5 completed".
///
/// Example usage:
/// ```dart
/// final completed = ref.watch(completedTodayCountProvider);
/// final total = ref.watch(todaysHabitsCountProvider);
/// Text('$completed/$total completed');
/// ```
final completedTodayCountProvider = Provider<int>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final todaysHabits = ref.watch(todaysHabitsProvider);
  final completionsState = ref.watch(completionsProvider);
  
  return todaysHabits
      .where((habit) => completionsState.isCompletedOn(habit.id, selectedDate))
      .length;
});

/// Provider that returns the completion percentage for the selected date.
///
/// Returns a value between 0.0 and 1.0 representing the percentage
/// of today's habits that have been completed.
///
/// Returns 0.0 if there are no habits scheduled for today.
///
/// Example usage:
/// ```dart
/// final progress = ref.watch(todaysProgressProvider);
/// CircularProgressIndicator(value: progress);
/// Text('${(progress * 100).toInt()}% complete');
/// ```
final todaysProgressProvider = Provider<double>((ref) {
  final total = ref.watch(todaysHabitsCountProvider);
  if (total == 0) return 0.0;
  
  final completed = ref.watch(completedTodayCountProvider);
  return completed / total;
});
