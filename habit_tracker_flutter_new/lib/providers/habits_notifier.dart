import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/habit_state.dart';
import '../repositories/interfaces/i_habits_repository.dart';
import '../main.dart' show habitsRepositoryProvider;

/// StateNotifier for managing habits state
/// 
/// Implements CRUD operations following SOLID principles:
/// - Single Responsibility: Only manages habit state
/// - Open/Closed: Can be extended without modifying existing code
/// - Liskov Substitution: Maintains StateNotifier contract
/// - Interface Segregation: Exposes only necessary operations
/// - Dependency Inversion: Depends on abstractions (models), not concrete implementations
class HabitsNotifier extends StateNotifier<HabitState> {
  final IHabitsRepository _repository;
  
  HabitsNotifier(this._repository) : super(HabitState.initial()) {
    _loadHabitsFromRepository();
  }

  /// Loads habits from repository on initialization
  Future<void> _loadHabitsFromRepository() async {
    try {
      final habits = await _repository.loadHabits();
      state = HabitState.fromHabits(habits);
    } catch (e) {
      state = HabitState.error('Failed to load habits: ${e.toString()}');
    }
  }

  /// Adds a new habit to the state
  /// 
  /// Validates the habit before adding and handles errors gracefully.
  /// Returns true if successful, false otherwise.
  Future<bool> addHabit(Habit habit) async {
    try {
      // Validate habit
      if (!habit.isValid) {
        state = state.copyWith(
          errorMessage: 'Invalid habit: Name cannot be empty and target days must be positive',
        );
        return false;
      }

      // Check for duplicate ID
      if (state.habitsById.containsKey(habit.id)) {
        state = state.copyWith(
          errorMessage: 'Habit with ID ${habit.id} already exists',
        );
        return false;
      }

      // Save to repository first
      await _repository.saveHabit(habit);
      
      // Add the habit using the state's addHabit method
      state = state.addHabit(habit);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to add habit: ${e.toString()}',
      );
      return false;
    }
  }

  /// Updates an existing habit
  /// 
  /// Validates both the habit ID existence and the updated habit data.
  /// Returns true if successful, false otherwise.
  Future<bool> updateHabit(String id, Habit updatedHabit) async {
    try {
      // Check if habit exists
      if (!state.habitsById.containsKey(id)) {
        state = state.copyWith(
          errorMessage: 'Cannot update: Habit with ID $id not found',
        );
        return false;
      }

      // Validate updated habit
      if (!updatedHabit.isValid) {
        state = state.copyWith(
          errorMessage: 'Invalid habit update: Name cannot be empty and target days must be positive',
        );
        return false;
      }

      // Ensure the updated habit has the same ID
      if (updatedHabit.id != id) {
        state = state.copyWith(
          errorMessage: 'Cannot change habit ID during update',
        );
        return false;
      }

      // Update in repository first
      await _repository.updateHabit(updatedHabit);
      
      // Update the habit using the state's updateHabit method
      state = state.updateHabit(id, updatedHabit);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update habit: ${e.toString()}',
      );
      return false;
    }
  }

  /// Deletes a habit permanently
  /// 
  /// This is a hard delete. Consider using archiveHabit() for soft delete.
  /// Returns true if successful, false otherwise.
  Future<bool> deleteHabit(String id) async {
    try {
      // Check if habit exists
      if (!state.habitsById.containsKey(id)) {
        state = state.copyWith(
          errorMessage: 'Cannot delete: Habit with ID $id not found',
        );
        return false;
      }

      // Delete from repository first
      await _repository.deleteHabit(id);
      
      // Remove the habit using the state's removeHabit method
      state = state.removeHabit(id);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete habit: ${e.toString()}',
      );
      return false;
    }
  }

  /// Archives a habit (soft delete)
  /// 
  /// Archived habits are not shown in active views but can be unarchived later.
  /// Returns true if successful, false otherwise.
  Future<bool> archiveHabit(String id) async {
    try {
      // Check if habit exists
      if (!state.habitsById.containsKey(id)) {
        state = state.copyWith(
          errorMessage: 'Cannot archive: Habit with ID $id not found',
        );
        return false;
      }

      // Check if already archived
      final habit = state.habitsById[id]!;
      if (habit.isArchived) {
        state = state.copyWith(
          errorMessage: 'Habit with ID $id is already archived',
        );
        return false;
      }

      // Archive in repository first
      await _repository.archiveHabit(id);
      
      // Archive the habit using the state's archiveHabit method
      state = state.archiveHabit(id);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to archive habit: ${e.toString()}',
      );
      return false;
    }
  }

  /// Unarchives a previously archived habit
  /// 
  /// Returns the habit to active status.
  /// Returns true if successful, false otherwise.
  Future<bool> unarchiveHabit(String id) async {
    try {
      // Check if habit exists
      if (!state.habitsById.containsKey(id)) {
        state = state.copyWith(
          errorMessage: 'Cannot unarchive: Habit with ID $id not found',
        );
        return false;
      }

      // Check if already active
      final habit = state.habitsById[id]!;
      if (!habit.isArchived) {
        state = state.copyWith(
          errorMessage: 'Habit with ID $id is already active',
        );
        return false;
      }

      // Unarchive in repository
      final unarchivedHabit = habit.copyWith(isArchived: false);
      await _repository.updateHabit(unarchivedHabit);
      
      // Unarchive the habit using the state's unarchiveHabit method
      state = state.unarchiveHabit(id);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to unarchive habit: ${e.toString()}',
      );
      return false;
    }
  }

  /// Clears any error message from the state
  void clearError() {
    if (state.errorMessage != null) {
      state = HabitState(
        habits: state.habits,
        habitsById: state.habitsById,
        isLoading: state.isLoading,
        errorMessage: null,
      );
    }
  }

  /// Loads habits from a list (useful for initialization or restoration)
  void loadHabits(List<Habit> habits) {
    try {
      state = HabitState.fromHabits(habits);
    } catch (e) {
      state = HabitState.error('Failed to load habits: ${e.toString()}');
    }
  }

  /// Clears all habits (use with caution)
  Future<void> clearAllHabits() async {
    await _repository.clearAll();
    state = HabitState.initial();
  }
}

/// Global provider for HabitsNotifier
/// 
/// This is the single source of truth for habit state in the application.
/// Use this provider throughout the app to access and modify habit data.
final habitsProvider = StateNotifierProvider<HabitsNotifier, HabitState>((ref) {
  final repository = ref.watch(habitsRepositoryProvider);
  return HabitsNotifier(repository);
});

