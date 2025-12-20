/// Repository interface for completion data persistence
/// Following Repository Pattern and Dependency Inversion Principle
abstract class ICompletionsRepository {
  /// Initialize the repository (open database connection)
  Future<void> init();

  /// Load all completion records from storage
  /// Returns Map of habitId to Set of completedDates
  Future<Map<String, Set<DateTime>>> loadCompletions();

  /// Add a completion record
  Future<void> addCompletion(String habitId, DateTime date);

  /// Remove a completion record
  Future<void> removeCompletion(String habitId, DateTime date);

  /// Get completions for a specific habit
  Future<Set<DateTime>> getCompletionsForHabit(String habitId);

  /// Delete all completions for a specific habit
  Future<void> deleteCompletionsForHabit(String habitId);

  /// Clear all completion records (for testing/reset)
  Future<void> clearAll();

  /// Close the database connection
  Future<void> close();
}
