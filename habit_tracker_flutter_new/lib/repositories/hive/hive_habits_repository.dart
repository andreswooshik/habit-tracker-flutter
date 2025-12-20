import 'package:hive_flutter/hive_flutter.dart';
import '../interfaces/i_habits_repository.dart';
import '../../models/habit.dart';
import '../../models/adapters/habit_adapter.dart';
import '../../models/adapters/habit_category_adapter.dart';
import '../../models/adapters/habit_frequency_adapter.dart';

/// Hive implementation of IHabitsRepository
/// Stores habits in a Hive box with efficient key-value access
class HiveHabitsRepository implements IHabitsRepository {
  static const String _boxName = 'habits';
  Box<Habit>? _box;

  /// Get the Hive box, ensuring it's initialized
  Box<Habit> get _habitsBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError('HabitsRepository not initialized. Call init() first.');
    }
    return _box!;
  }

  @override
  Future<void> init() async {
    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HabitAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HabitCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(HabitFrequencyAdapter());
    }

    // Open the box
    _box = await Hive.openBox<Habit>(_boxName);
  }

  @override
  Future<List<Habit>> loadHabits() async {
    final habits = _habitsBox.values.where((habit) => !habit.isArchived).toList();
    return habits;
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    await _habitsBox.put(habit.id, habit);
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    await _habitsBox.put(habit.id, habit);
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    await _habitsBox.delete(habitId);
  }

  @override
  Future<void> archiveHabit(String habitId) async {
    final habit = _habitsBox.get(habitId);
    if (habit != null) {
      final archivedHabit = habit.copyWith(isArchived: true);
      await _habitsBox.put(habitId, archivedHabit);
    }
  }

  @override
  Future<List<Habit>> loadArchivedHabits() async {
    final archivedHabits = _habitsBox.values.where((habit) => habit.isArchived).toList();
    return archivedHabits;
  }

  @override
  Future<void> clearAll() async {
    await _habitsBox.clear();
  }

  @override
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
