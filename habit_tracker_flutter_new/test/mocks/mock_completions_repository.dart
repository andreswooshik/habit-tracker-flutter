import 'package:habit_tracker_flutter_new/models/adapters/completion_record.dart';
import 'package:habit_tracker_flutter_new/repositories/interfaces/i_completions_repository.dart';

/// Mock implementation of ICompletionsRepository for testing
class MockCompletionsRepository implements ICompletionsRepository {
  final Map<String, CompletionRecord> _completions = {};
  bool _isInitialized = false;

  @override
  Future<void> init() async {
    _isInitialized = true;
  }

  @override
  Future<List<CompletionRecord>> loadCompletions() async {
    return _completions.values.toList();
  }

  @override
  Future<void> addCompletion(CompletionRecord completion) async {
    final key = '${completion.habitId}_${completion.completedAt.millisecondsSinceEpoch}';
    _completions[key] = completion;
  }

  @override
  Future<void> removeCompletion(String habitId, DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final key = '${habitId}_${normalizedDate.millisecondsSinceEpoch}';
    _completions.remove(key);
  }

  @override
  Future<List<CompletionRecord>> getCompletionsForHabit(String habitId) async {
    return _completions.values.where((c) => c.habitId == habitId).toList();
  }

  @override
  Future<void> deleteCompletionsForHabit(String habitId) async {
    _completions.removeWhere((key, completion) => completion.habitId == habitId);
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
