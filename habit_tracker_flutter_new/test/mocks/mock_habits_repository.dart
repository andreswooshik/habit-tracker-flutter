import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/repositories/interfaces/i_habits_repository.dart';

/// Mock implementation of IHabitsRepository for testing
class MockHabitsRepository implements IHabitsRepository {
  final Map<String, Habit> _habits = {};
  bool _isInitialized = false;

  @override
  Future<void> init() async {
    _isInitialized = true;
  }

  @override
  Future<List<Habit>> loadHabits() async {
    return _habits.values.toList();
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    _habits[habit.id] = habit;
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    _habits[habit.id] = habit;
  }

  @override
  Future<void> deleteHabit(String id) async {
    _habits.remove(id);
  }

  @override
  Future<void> archiveHabit(String id) async {
    final habit = _habits[id];
    if (habit != null) {
      _habits[id] = habit.copyWith(isArchived: true);
    }
  }

  @override
  Future<List<Habit>> loadArchivedHabits() async {
    return _habits.values.where((h) => h.isArchived).toList();
  }

  @override
  Future<void> clearAll() async {
    _habits.clear();
  }

  @override
  Future<void> close() async {
    _isInitialized = false;
  }

  // Helper methods for testing
  bool get isInitialized => _isInitialized;
  int get habitCount => _habits.length;
}
