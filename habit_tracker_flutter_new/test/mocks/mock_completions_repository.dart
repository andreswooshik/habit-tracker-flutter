import 'package:habit_tracker_flutter_new/repositories/interfaces/i_completions_repository.dart';

/// Mock implementation of ICompletionsRepository for testing
class MockCompletionsRepository implements ICompletionsRepository {
  final Map<String, Set<DateTime>> _completions = {};
  bool _isInitialized = false;

  @override
  Future<void> init() async {
    _isInitialized = true;
  }

  @override
  Future<Map<String, Set<DateTime>>> loadCompletions() async {
    return Map.from(_completions);
  }

  @override
  Future<void> addCompletion(String habitId, DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _completions.putIfAbsent(habitId, () => {}).add(normalizedDate);
  }

  @override
  Future<void> removeCompletion(String habitId, DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _completions[habitId]?.remove(normalizedDate);
  }

  @override
  Future<Set<DateTime>> getCompletionsForHabit(String habitId) async {
    return _completions[habitId] ?? {};
  }

  @override
  Future<void> deleteCompletionsForHabit(String habitId) async {
    _completions.remove(habitId);
  }

  @override
  Future<void> clearAll() async {
    _completions.clear();
  }

  @override
  Future<void> close() async {
    _isInitialized = false;
  }

  // Helper methods for testing
  bool get isInitialized => _isInitialized;
  int get completionCount => _completions.length;
}
