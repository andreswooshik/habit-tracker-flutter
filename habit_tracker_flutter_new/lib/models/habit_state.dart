import 'package:equatable/equatable.dart';
import 'habit.dart';

/// Immutable state container for all habits in the application
/// 
/// Maintains both a list and a map for efficient access patterns
class HabitState extends Equatable {
  /// List of all habits (for ordered iteration)
  final List<Habit> habits;

  /// Map of habits by ID (for O(1) lookup)
  final Map<String, Habit> habitsById;

  /// Whether the state is currently loading
  final bool isLoading;

  /// Error message if any operation failed
  final String? errorMessage;

  const HabitState({
    required this.habits,
    required this.habitsById,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Factory constructor for initial empty state
  factory HabitState.initial() {
    return const HabitState(
      habits: [],
      habitsById: {},
      isLoading: false,
      errorMessage: null,
    );
  }

  /// Factory constructor for loading state
  factory HabitState.loading() {
    return const HabitState(
      habits: [],
      habitsById: {},
      isLoading: true,
      errorMessage: null,
    );
  }

  /// Factory constructor for error state
  factory HabitState.error(String message) {
    return HabitState(
      habits: const [],
      habitsById: const {},
      isLoading: false,
      errorMessage: message,
    );
  }

  /// Factory constructor from a list of habits
  factory HabitState.fromHabits(List<Habit> habits) {
    final habitsById = {
      for (var habit in habits) habit.id: habit,
    };

    return HabitState(
      habits: List.unmodifiable(habits),
      habitsById: Map.unmodifiable(habitsById),
      isLoading: false,
      errorMessage: null,
    );
  }

  /// Gets a habit by ID, returns null if not found
  Habit? getHabit(String id) => habitsById[id];

  /// Gets all active (non-archived) habits
  List<Habit> get activeHabits {
    return habits.where((h) => !h.isArchived).toList();
  }

  /// Gets all archived habits
  List<Habit> get archivedHabits {
    return habits.where((h) => h.isArchived).toList();
  }

  /// Gets habits scheduled for a specific date
  List<Habit> getHabitsForDate(DateTime date) {
    return activeHabits.where((h) => h.isScheduledFor(date)).toList();
  }

  /// Gets habits by category
  List<Habit> getHabitsByCategory(String categoryName) {
    return activeHabits
        .where((h) => h.category.name == categoryName)
        .toList();
  }

  /// Checks if state has any habits
  bool get isEmpty => habits.isEmpty;

  /// Checks if state has any active habits
  bool get hasActiveHabits => activeHabits.isNotEmpty;

  /// Total count of all habits
  int get totalCount => habits.length;

  /// Count of active habits
  int get activeCount => activeHabits.length;

  /// Count of archived habits
  int get archivedCount => archivedHabits.length;

  /// Creates a copy of this state with updated fields
  HabitState copyWith({
    List<Habit>? habits,
    Map<String, Habit>? habitsById,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HabitState(
      habits: habits ?? this.habits,
      habitsById: habitsById ?? this.habitsById,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Creates a copy with a habit added
  HabitState addHabit(Habit habit) {
    final newHabits = [...habits, habit];
    final newHabitsById = {...habitsById, habit.id: habit};

    return HabitState(
      habits: newHabits,
      habitsById: newHabitsById,
      isLoading: false,
      errorMessage: null,
    );
  }

  /// Creates a copy with a habit updated
  HabitState updateHabit(String id, Habit updatedHabit) {
    if (!habitsById.containsKey(id)) {
      return copyWith(errorMessage: 'Habit not found: $id');
    }

    final newHabits = habits.map((h) => h.id == id ? updatedHabit : h).toList();
    final newHabitsById = {...habitsById, id: updatedHabit};

    return HabitState(
      habits: newHabits,
      habitsById: newHabitsById,
      isLoading: false,
      errorMessage: null,
    );
  }

  /// Creates a copy with a habit removed
  HabitState removeHabit(String id) {
    final newHabits = habits.where((h) => h.id != id).toList();
    final newHabitsById = Map<String, Habit>.from(habitsById)..remove(id);

    return HabitState(
      habits: newHabits,
      habitsById: newHabitsById,
      isLoading: false,
      errorMessage: null,
    );
  }

  /// Creates a copy with a habit archived
  HabitState archiveHabit(String id) {
    final habit = habitsById[id];
    if (habit == null) {
      return copyWith(errorMessage: 'Habit not found: $id');
    }

    return updateHabit(id, habit.copyWith(isArchived: true));
  }

  /// Creates a copy with a habit unarchived
  HabitState unarchiveHabit(String id) {
    final habit = habitsById[id];
    if (habit == null) {
      return copyWith(errorMessage: 'Habit not found: $id');
    }

    return updateHabit(id, habit.copyWith(isArchived: false));
  }

  @override
  List<Object?> get props => [habits, habitsById, isLoading, errorMessage];

  @override
  String toString() {
    return 'HabitState(total: $totalCount, active: $activeCount, '
        'archived: $archivedCount, isLoading: $isLoading, '
        'error: $errorMessage)';
  }
}
