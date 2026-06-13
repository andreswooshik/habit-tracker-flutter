import 'package:flutter/foundation.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/repositories/interfaces/i_habits_repository.dart';

/// Mock implementation of IHabitsRepository for testing
class MockHabitsRepository implements IHabitsRepository {
  final Map<String, Habit> _habits = {};
  bool _isInitialized = false;

  @override
  Future<void> init() {
    _isInitialized = true;
    return SynchronousFuture(null);
  }

  @override
  Future<List<Habit>> loadHabits() {
    return SynchronousFuture(_habits.values.toList());
  }

  @override
  Future<void> saveHabit(Habit habit) {
    _habits[habit.id] = habit;
    return SynchronousFuture(null);
  }

  @override
  Future<void> updateHabit(Habit habit) {
    _habits[habit.id] = habit;
    return SynchronousFuture(null);
  }

  @override
  Future<void> deleteHabit(String id) {
    _habits.remove(id);
    return SynchronousFuture(null);
  }

  @override
  Future<void> archiveHabit(String id) {
    final habit = _habits[id];
    if (habit != null) {
      _habits[id] = habit.copyWith(isArchived: true);
    }
    return SynchronousFuture(null);
  }

  @override
  Future<List<Habit>> loadArchivedHabits() {
    return SynchronousFuture(
        _habits.values.where((h) => h.isArchived).toList());
  }

  @override
  Future<void> clearAll() {
    _habits.clear();
    return SynchronousFuture(null);
  }

  @override
  Future<void> close() {
    _isInitialized = false;
    return SynchronousFuture(null);
  }

  // Helper methods for testing
  bool get isInitialized => _isInitialized;
  int get habitCount => _habits.length;
}
