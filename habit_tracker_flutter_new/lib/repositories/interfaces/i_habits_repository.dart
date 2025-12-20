import '../../models/habit.dart';

/// Repository interface for habit data persistence
/// Following Repository Pattern and Dependency Inversion Principle
abstract class IHabitsRepository {
  /// Initialize the repository (open database connection)
  Future<void> init();

  /// Load all non-archived habits from storage
  Future<List<Habit>> loadHabits();

  /// Save a new habit to storage
  Future<void> saveHabit(Habit habit);

  /// Update an existing habit in storage
  Future<void> updateHabit(Habit habit);

  /// Delete a habit from storage (permanent deletion)
  Future<void> deleteHabit(String habitId);

  /// Archive a habit (soft delete)
  Future<void> archiveHabit(String habitId);

  /// Load archived habits
  Future<List<Habit>> loadArchivedHabits();

  /// Clear all habits from storage (for testing/reset)
  Future<void> clearAll();

  /// Close the database connection
  Future<void> close();
}
