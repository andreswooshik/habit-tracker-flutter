import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable state container for habit completions
/// 
/// Maps habit IDs to sets of completion dates
class CompletionsState {
  /// Map of habit ID to set of completion dates
  final Map<String, Set<DateTime>> completions;

  /// Whether the state is currently loading
  final bool isLoading;

  /// Error message if any operation failed
  final String? errorMessage;

  const CompletionsState({
    required this.completions,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Factory constructor for initial empty state
  factory CompletionsState.initial() {
    return const CompletionsState(
      completions: {},
      isLoading: false,
      errorMessage: null,
    );
  }

  /// Factory constructor for loading state
  factory CompletionsState.loading() {
    return const CompletionsState(
      completions: {},
      isLoading: true,
      errorMessage: null,
    );
  }

  /// Factory constructor for error state
  factory CompletionsState.error(String message) {
    return CompletionsState(
      completions: const {},
      isLoading: false,
      errorMessage: message,
    );
  }

  /// Gets completion dates for a specific habit
  Set<DateTime> getCompletionsForHabit(String habitId) {
    return completions[habitId] ?? {};
  }

  /// Checks if a habit is completed on a specific date
  bool isCompletedOn(String habitId, DateTime date) {
    final normalizedDate = _normalizeDate(date);
    return completions[habitId]?.contains(normalizedDate) ?? false;
  }

  /// Gets total completion count for a habit
  int getCompletionCount(String habitId) {
    return completions[habitId]?.length ?? 0;
  }

  /// Gets total completions across all habits
  int get totalCompletions {
    return completions.values.fold(0, (sum, dates) => sum + dates.length);
  }

  /// Checks if state has any completions
  bool get isEmpty => completions.isEmpty || totalCompletions == 0;

  /// Creates a copy with updated fields
  CompletionsState copyWith({
    Map<String, Set<DateTime>>? completions,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CompletionsState(
      completions: completions ?? this.completions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Normalizes a date by removing the time component
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  String toString() {
    return 'CompletionsState(habits: ${completions.length}, '
        'totalCompletions: $totalCompletions, '
        'isLoading: $isLoading, error: $errorMessage)';
  }
}

/// StateNotifier for managing habit completions
/// 
/// Tracks when habits are completed using a Map<String, Set<DateTime>> structure
/// for efficient O(1) lookups and set operations.
/// 
/// All dates are normalized to remove time components for consistent comparisons.
class CompletionsNotifier extends StateNotifier<CompletionsState> {
  CompletionsNotifier() : super(CompletionsState.initial());

  /// Normalizes a date by removing the time component
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Toggles completion status for a habit on a specific date
  /// 
  /// If the habit is completed on the date, it marks it incomplete.
  /// If the habit is not completed on the date, it marks it complete.
  /// Returns the new completion status (true if now complete, false if now incomplete).
  bool toggleCompletion(String habitId, DateTime date) {
    try {
      if (habitId.isEmpty) {
        state = state.copyWith(errorMessage: 'Habit ID cannot be empty');
        return false;
      }

      final normalizedDate = _normalizeDate(date);
      final currentCompletions = Map<String, Set<DateTime>>.from(state.completions);
      
      // Get or create the set of completions for this habit
      final habitCompletions = Set<DateTime>.from(
        currentCompletions[habitId] ?? {},
      );

      // Toggle the completion
      final wasCompleted = habitCompletions.contains(normalizedDate);
      if (wasCompleted) {
        habitCompletions.remove(normalizedDate);
      } else {
        habitCompletions.add(normalizedDate);
      }

      // Update the completions map
      if (habitCompletions.isEmpty) {
        currentCompletions.remove(habitId);
      } else {
        currentCompletions[habitId] = habitCompletions;
      }

      state = CompletionsState(
        completions: currentCompletions,
        isLoading: false,
        errorMessage: null,
      );

      return !wasCompleted; // Return the new state
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to toggle completion: ${e.toString()}',
      );
      return false;
    }
  }

  /// Marks a habit as complete on a specific date
  /// 
  /// Returns true if successful, false otherwise.
  bool markComplete(String habitId, DateTime date) {
    try {
      if (habitId.isEmpty) {
        state = state.copyWith(errorMessage: 'Habit ID cannot be empty');
        return false;
      }

      final normalizedDate = _normalizeDate(date);
      final currentCompletions = Map<String, Set<DateTime>>.from(state.completions);
      
      // Get or create the set of completions for this habit
      final habitCompletions = Set<DateTime>.from(
        currentCompletions[habitId] ?? {},
      );

      // Add the completion (set handles duplicates automatically)
      habitCompletions.add(normalizedDate);
      currentCompletions[habitId] = habitCompletions;

      state = CompletionsState(
        completions: currentCompletions,
        isLoading: false,
        errorMessage: null,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to mark complete: ${e.toString()}',
      );
      return false;
    }
  }

  /// Marks a habit as incomplete on a specific date
  /// 
  /// Returns true if successful, false otherwise.
  bool markIncomplete(String habitId, DateTime date) {
    try {
      if (habitId.isEmpty) {
        state = state.copyWith(errorMessage: 'Habit ID cannot be empty');
        return false;
      }

      final normalizedDate = _normalizeDate(date);
      final currentCompletions = Map<String, Set<DateTime>>.from(state.completions);
      
      // Get the set of completions for this habit
      final habitCompletions = currentCompletions[habitId];
      if (habitCompletions == null) {
        // Habit has no completions, nothing to remove
        return true;
      }

      // Remove the completion
      final updatedCompletions = Set<DateTime>.from(habitCompletions);
      updatedCompletions.remove(normalizedDate);

      // Update or remove the habit's completions
      if (updatedCompletions.isEmpty) {
        currentCompletions.remove(habitId);
      } else {
        currentCompletions[habitId] = updatedCompletions;
      }

      state = CompletionsState(
        completions: currentCompletions,
        isLoading: false,
        errorMessage: null,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to mark incomplete: ${e.toString()}',
      );
      return false;
    }
  }

  /// Marks multiple dates as complete for a habit in one operation
  /// 
  /// This is more efficient than calling markComplete multiple times.
  /// Returns the number of dates successfully marked complete.
  int bulkComplete(String habitId, List<DateTime> dates) {
    try {
      if (habitId.isEmpty) {
        state = state.copyWith(errorMessage: 'Habit ID cannot be empty');
        return 0;
      }

      if (dates.isEmpty) {
        return 0;
      }

      final normalizedDates = dates.map(_normalizeDate).toSet();
      final currentCompletions = Map<String, Set<DateTime>>.from(state.completions);
      
      // Get or create the set of completions for this habit
      final habitCompletions = Set<DateTime>.from(
        currentCompletions[habitId] ?? {},
      );

      // Add all dates to the set
      habitCompletions.addAll(normalizedDates);
      currentCompletions[habitId] = habitCompletions;

      state = CompletionsState(
        completions: currentCompletions,
        isLoading: false,
        errorMessage: null,
      );

      return normalizedDates.length;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to bulk complete: ${e.toString()}',
      );
      return 0;
    }
  }

  /// Marks multiple dates as incomplete for a habit in one operation
  /// 
  /// This is more efficient than calling markIncomplete multiple times.
  /// Returns the number of dates successfully marked incomplete.
  int bulkIncomplete(String habitId, List<DateTime> dates) {
    try {
      if (habitId.isEmpty) {
        state = state.copyWith(errorMessage: 'Habit ID cannot be empty');
        return 0;
      }

      if (dates.isEmpty) {
        return 0;
      }

      final normalizedDates = dates.map(_normalizeDate).toSet();
      final currentCompletions = Map<String, Set<DateTime>>.from(state.completions);
      
      // Get the set of completions for this habit
      final habitCompletions = currentCompletions[habitId];
      if (habitCompletions == null) {
        // Habit has no completions, nothing to remove
        return 0;
      }

      // Remove all dates from the set
      final updatedCompletions = Set<DateTime>.from(habitCompletions);
      final removedCount = normalizedDates.where(updatedCompletions.remove).length;

      // Update or remove the habit's completions
      if (updatedCompletions.isEmpty) {
        currentCompletions.remove(habitId);
      } else {
        currentCompletions[habitId] = updatedCompletions;
      }

      state = CompletionsState(
        completions: currentCompletions,
        isLoading: false,
        errorMessage: null,
      );

      return removedCount;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to bulk incomplete: ${e.toString()}',
      );
      return 0;
    }
  }

  /// Removes all completions for a specific habit
  /// 
  /// Useful when a habit is deleted.
  void removeHabitCompletions(String habitId) {
    try {
      final currentCompletions = Map<String, Set<DateTime>>.from(state.completions);
      currentCompletions.remove(habitId);

      state = CompletionsState(
        completions: currentCompletions,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to remove habit completions: ${e.toString()}',
      );
    }
  }

  /// Loads completions from a map (useful for initialization or restoration)
  void loadCompletions(Map<String, Set<DateTime>> completions) {
    try {
      // Normalize all dates in the input
      final normalizedCompletions = <String, Set<DateTime>>{};
      for (final entry in completions.entries) {
        final normalizedDates = entry.value.map(_normalizeDate).toSet();
        if (normalizedDates.isNotEmpty) {
          normalizedCompletions[entry.key] = normalizedDates;
        }
      }

      state = CompletionsState(
        completions: normalizedCompletions,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = CompletionsState.error('Failed to load completions: ${e.toString()}');
    }
  }

  /// Clears all completions (use with caution)
  void clearAllCompletions() {
    state = CompletionsState.initial();
  }

  /// Clears any error message from the state
  void clearError() {
    if (state.errorMessage != null) {
      state = CompletionsState(
        completions: state.completions,
        isLoading: state.isLoading,
        errorMessage: null,
      );
    }
  }
}

/// Global provider for CompletionsNotifier
/// 
/// This is the single source of truth for completion data in the application.
/// Use this provider throughout the app to access and modify completion data.
final completionsProvider = StateNotifierProvider<CompletionsNotifier, CompletionsState>((ref) {
  return CompletionsNotifier();
});
