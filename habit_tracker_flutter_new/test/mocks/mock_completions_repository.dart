import 'package:flutter/foundation.dart';
import 'package:habit_tracker_flutter_new/repositories/interfaces/i_completions_repository.dart';

/// Mock implementation of ICompletionsRepository for testing
class MockCompletionsRepository implements ICompletionsRepository {
  final Map<String, Set<DateTime>> _completions = {};
  bool _isInitialized = false;

  @override
  Future<void> init() {
    _isInitialized = true;
    return SynchronousFuture(null);
  }

  @override
  Future<Map<String, Set<DateTime>>> loadCompletions() {
    return SynchronousFuture(Map.from(_completions));
  }

  @override
  Future<void> addCompletion(String habitId, DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _completions.putIfAbsent(habitId, () => {}).add(normalizedDate);
    return SynchronousFuture(null);
  }

  @override
  Future<void> removeCompletion(String habitId, DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _completions[habitId]?.remove(normalizedDate);
    return SynchronousFuture(null);
  }

  @override
  Future<Set<DateTime>> getCompletionsForHabit(String habitId) {
    return SynchronousFuture(_completions[habitId] ?? {});
  }

  @override
  Future<void> deleteCompletionsForHabit(String habitId) {
    _completions.remove(habitId);
    return SynchronousFuture(null);
  }

  @override
  Future<void> clearAll() {
    _completions.clear();
    return SynchronousFuture(null);
  }

  @override
  Future<void> close() {
    _isInitialized = false;
    return SynchronousFuture(null);
  }

  // Helper methods for testing
  bool get isInitialized => _isInitialized;
  int get completionCount => _completions.length;
}
