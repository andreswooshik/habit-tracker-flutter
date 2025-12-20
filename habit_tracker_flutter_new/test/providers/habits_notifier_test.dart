import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/providers/habits_notifier.dart';

void main() {
  group('HabitsNotifier -', () {
    late HabitsNotifier notifier;
    late Habit testHabit1;
    late Habit testHabit2;

    setUp(() {
      notifier = HabitsNotifier();
      
      testHabit1 = Habit.create(
        id: 'habit-1',
        name: 'Morning Exercise',
        description: 'Do 30 minutes of exercise',
        frequency: HabitFrequency.everyDay,
        category: HabitCategory.health,
        targetDays: 30,
      );

      testHabit2 = Habit.create(
        id: 'habit-2',
        name: 'Read a Book',
        description: 'Read for 20 minutes',
        frequency: HabitFrequency.everyDay,
        category: HabitCategory.learning,
        targetDays: 21,
      );
    });

    group('Initial State -', () {
      test('should start with empty initial state', () {
        expect(notifier.state.isEmpty, true);
        expect(notifier.state.habits, isEmpty);
        expect(notifier.state.habitsById, isEmpty);
        expect(notifier.state.isLoading, false);
        expect(notifier.state.errorMessage, isNull);
      });
    });

    group('addHabit -', () {
      test('should successfully add a valid habit', () {
        final result = notifier.addHabit(testHabit1);

        expect(result, true);
        expect(notifier.state.habits.length, 1);
        expect(notifier.state.habits.first, testHabit1);
        expect(notifier.state.habitsById[testHabit1.id], testHabit1);
        expect(notifier.state.errorMessage, isNull);
      });

      test('should add multiple habits', () {
        notifier.addHabit(testHabit1);
        final result = notifier.addHabit(testHabit2);

        expect(result, true);
        expect(notifier.state.habits.length, 2);
        expect(notifier.state.habitsById.length, 2);
        expect(notifier.state.habitsById[testHabit1.id], testHabit1);
        expect(notifier.state.habitsById[testHabit2.id], testHabit2);
      });

      test('should fail to add habit with duplicate ID', () {
        notifier.addHabit(testHabit1);
        final result = notifier.addHabit(testHabit1);

        expect(result, false);
        expect(notifier.state.habits.length, 1);
        expect(notifier.state.errorMessage, contains('already exists'));
      });

      test('should fail to add invalid habit (empty name)', () {
        final invalidHabit = Habit(
          id: 'invalid-1',
          name: '',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.other,
          createdAt: DateTime.now(),
        );

        final result = notifier.addHabit(invalidHabit);

        expect(result, false);
        expect(notifier.state.habits, isEmpty);
        expect(notifier.state.errorMessage, contains('Invalid habit'));
      });

      test('should fail to add invalid habit (negative target days)', () {
        final invalidHabit = Habit(
          id: 'invalid-2',
          name: 'Test Habit',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.other,
          targetDays: -5,
          createdAt: DateTime.now(),
        );

        final result = notifier.addHabit(invalidHabit);

        expect(result, false);
        expect(notifier.state.habits, isEmpty);
        expect(notifier.state.errorMessage, contains('Invalid habit'));
      });

      test('should maintain state immutability', () {
        final stateBefore = notifier.state;
        notifier.addHabit(testHabit1);
        final stateAfter = notifier.state;

        expect(stateBefore, isNot(same(stateAfter)));
        expect(stateBefore.habits, isEmpty);
        expect(stateAfter.habits.length, 1);
      });
    });

    group('updateHabit -', () {
      setUp(() {
        notifier.addHabit(testHabit1);
      });

      test('should successfully update an existing habit', () {
        final updatedHabit = testHabit1.copyWith(
          name: 'Evening Exercise',
          description: 'Updated description',
        );

        final result = notifier.updateHabit(testHabit1.id, updatedHabit);

        expect(result, true);
        expect(notifier.state.habits.length, 1);
        expect(notifier.state.habitsById[testHabit1.id]?.name, 'Evening Exercise');
        expect(notifier.state.habitsById[testHabit1.id]?.description, 'Updated description');
        expect(notifier.state.errorMessage, isNull);
      });

      test('should fail to update non-existent habit', () {
        final result = notifier.updateHabit('non-existent-id', testHabit2);

        expect(result, false);
        expect(notifier.state.errorMessage, contains('not found'));
      });

      test('should fail to update with invalid habit data', () {
        final invalidHabit = testHabit1.copyWith(name: '');

        final result = notifier.updateHabit(testHabit1.id, invalidHabit);

        expect(result, false);
        expect(notifier.state.errorMessage, contains('Invalid habit'));
        // Original habit should remain unchanged
        expect(notifier.state.habitsById[testHabit1.id]?.name, testHabit1.name);
      });

      test('should fail to update with mismatched ID', () {
        final mismatchedHabit = testHabit1.copyWith(id: 'different-id');

        final result = notifier.updateHabit(testHabit1.id, mismatchedHabit);

        expect(result, false);
        expect(notifier.state.errorMessage, contains('Cannot change habit ID'));
      });

      test('should maintain state immutability on update', () {
        final stateBefore = notifier.state;
        final updatedHabit = testHabit1.copyWith(name: 'Updated Name');
        notifier.updateHabit(testHabit1.id, updatedHabit);
        final stateAfter = notifier.state;

        expect(stateBefore, isNot(same(stateAfter)));
        expect(stateBefore.habitsById[testHabit1.id]?.name, testHabit1.name);
        expect(stateAfter.habitsById[testHabit1.id]?.name, 'Updated Name');
      });

      test('should maintain Map and List consistency after update', () {
        final updatedHabit = testHabit1.copyWith(name: 'Updated Name');
        notifier.updateHabit(testHabit1.id, updatedHabit);

        final habitFromList = notifier.state.habits.first;
        final habitFromMap = notifier.state.habitsById[testHabit1.id];

        expect(habitFromList, habitFromMap);
        expect(habitFromList.name, 'Updated Name');
      });
    });

    group('deleteHabit -', () {
      setUp(() {
        notifier.addHabit(testHabit1);
        notifier.addHabit(testHabit2);
      });

      test('should successfully delete an existing habit', () {
        final result = notifier.deleteHabit(testHabit1.id);

        expect(result, true);
        expect(notifier.state.habits.length, 1);
        expect(notifier.state.habitsById.containsKey(testHabit1.id), false);
        expect(notifier.state.habitsById.containsKey(testHabit2.id), true);
        expect(notifier.state.errorMessage, isNull);
      });

      test('should fail to delete non-existent habit', () {
        final result = notifier.deleteHabit('non-existent-id');

        expect(result, false);
        expect(notifier.state.habits.length, 2);
        expect(notifier.state.errorMessage, contains('not found'));
      });

      test('should delete all habits', () {
        notifier.deleteHabit(testHabit1.id);
        notifier.deleteHabit(testHabit2.id);

        expect(notifier.state.habits, isEmpty);
        expect(notifier.state.habitsById, isEmpty);
      });

      test('should maintain state immutability on delete', () {
        final stateBefore = notifier.state;
        notifier.deleteHabit(testHabit1.id);
        final stateAfter = notifier.state;

        expect(stateBefore, isNot(same(stateAfter)));
        expect(stateBefore.habits.length, 2);
        expect(stateAfter.habits.length, 1);
      });

      test('should maintain Map and List consistency after delete', () {
        notifier.deleteHabit(testHabit1.id);

        expect(notifier.state.habits.length, notifier.state.habitsById.length);
        expect(notifier.state.habits.first.id, testHabit2.id);
        expect(notifier.state.habitsById[testHabit2.id], isNotNull);
      });
    });

    group('archiveHabit -', () {
      setUp(() {
        notifier.addHabit(testHabit1);
      });

      test('should successfully archive an active habit', () {
        final result = notifier.archiveHabit(testHabit1.id);

        expect(result, true);
        expect(notifier.state.habitsById[testHabit1.id]?.isArchived, true);
        expect(notifier.state.activeHabits, isEmpty);
        expect(notifier.state.archivedHabits.length, 1);
        expect(notifier.state.errorMessage, isNull);
      });

      test('should fail to archive non-existent habit', () {
        final result = notifier.archiveHabit('non-existent-id');

        expect(result, false);
        expect(notifier.state.errorMessage, contains('not found'));
      });

      test('should fail to archive already archived habit', () {
        notifier.archiveHabit(testHabit1.id);
        final result = notifier.archiveHabit(testHabit1.id);

        expect(result, false);
        expect(notifier.state.errorMessage, contains('already archived'));
      });

      test('should maintain state immutability on archive', () {
        final stateBefore = notifier.state;
        notifier.archiveHabit(testHabit1.id);
        final stateAfter = notifier.state;

        expect(stateBefore, isNot(same(stateAfter)));
        expect(stateBefore.habitsById[testHabit1.id]?.isArchived, false);
        expect(stateAfter.habitsById[testHabit1.id]?.isArchived, true);
      });

      test('should keep habit in list but mark as archived', () {
        notifier.archiveHabit(testHabit1.id);

        expect(notifier.state.habits.length, 1);
        expect(notifier.state.habits.first.isArchived, true);
      });
    });

    group('unarchiveHabit -', () {
      setUp(() {
        notifier.addHabit(testHabit1);
        notifier.archiveHabit(testHabit1.id);
      });

      test('should successfully unarchive an archived habit', () {
        final result = notifier.unarchiveHabit(testHabit1.id);

        expect(result, true);
        expect(notifier.state.habitsById[testHabit1.id]?.isArchived, false);
        expect(notifier.state.activeHabits.length, 1);
        expect(notifier.state.archivedHabits, isEmpty);
        expect(notifier.state.errorMessage, isNull);
      });

      test('should fail to unarchive non-existent habit', () {
        final result = notifier.unarchiveHabit('non-existent-id');

        expect(result, false);
        expect(notifier.state.errorMessage, contains('not found'));
      });

      test('should fail to unarchive already active habit', () {
        notifier.unarchiveHabit(testHabit1.id);
        final result = notifier.unarchiveHabit(testHabit1.id);

        expect(result, false);
        expect(notifier.state.errorMessage, contains('already active'));
      });

      test('should maintain state immutability on unarchive', () {
        final stateBefore = notifier.state;
        notifier.unarchiveHabit(testHabit1.id);
        final stateAfter = notifier.state;

        expect(stateBefore, isNot(same(stateAfter)));
        expect(stateBefore.habitsById[testHabit1.id]?.isArchived, true);
        expect(stateAfter.habitsById[testHabit1.id]?.isArchived, false);
      });
    });

    group('Error Handling -', () {
      test('should clear error message', () {
        notifier.addHabit(testHabit1);
        notifier.addHabit(testHabit1); // Duplicate, causes error

        expect(notifier.state.errorMessage, isNotNull);

        notifier.clearError();

        expect(notifier.state.errorMessage, isNull);
      });

      test('should handle errors in addHabit gracefully', () {
        final invalidHabit = Habit(
          id: 'test',
          name: '',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.other,
          createdAt: DateTime.now(),
        );

        final result = notifier.addHabit(invalidHabit);

        expect(result, false);
        expect(notifier.state.errorMessage, isNotNull);
        expect(notifier.state.habits, isEmpty);
      });

      test('should preserve state after failed operation', () {
        notifier.addHabit(testHabit1);
        final stateBeforeError = notifier.state;

        notifier.deleteHabit('non-existent-id');

        expect(notifier.state.habits, stateBeforeError.habits);
        expect(notifier.state.habitsById, stateBeforeError.habitsById);
      });
    });

    group('loadHabits -', () {
      test('should load habits from list', () {
        final habits = [testHabit1, testHabit2];
        notifier.loadHabits(habits);

        expect(notifier.state.habits.length, 2);
        expect(notifier.state.habitsById.length, 2);
        expect(notifier.state.habitsById[testHabit1.id], testHabit1);
        expect(notifier.state.habitsById[testHabit2.id], testHabit2);
      });

      test('should replace existing habits when loading', () {
        notifier.addHabit(testHabit1);
        final newHabits = [testHabit2];
        notifier.loadHabits(newHabits);

        expect(notifier.state.habits.length, 1);
        expect(notifier.state.habitsById.containsKey(testHabit1.id), false);
        expect(notifier.state.habitsById.containsKey(testHabit2.id), true);
      });

      test('should load empty list', () {
        notifier.addHabit(testHabit1);
        notifier.loadHabits([]);

        expect(notifier.state.habits, isEmpty);
        expect(notifier.state.habitsById, isEmpty);
      });
    });

    group('clearAllHabits -', () {
      test('should clear all habits', () {
        notifier.addHabit(testHabit1);
        notifier.addHabit(testHabit2);

        notifier.clearAllHabits();

        expect(notifier.state.habits, isEmpty);
        expect(notifier.state.habitsById, isEmpty);
        expect(notifier.state.errorMessage, isNull);
      });

      test('should work on empty state', () {
        notifier.clearAllHabits();

        expect(notifier.state.habits, isEmpty);
        expect(notifier.state.habitsById, isEmpty);
      });
    });

    group('State Immutability -', () {
      test('habits list should be immutable - state changes should not affect old references', () {
        notifier.addHabit(testHabit1);
        final habitsList = notifier.state.habits;
        final habitsLength = habitsList.length;

        // Add another habit
        notifier.addHabit(testHabit2);

        // Original reference should remain unchanged
        expect(habitsList.length, habitsLength);
        expect(notifier.state.habits.length, habitsLength + 1);
        expect(habitsList, isNot(same(notifier.state.habits)));
      });

      test('habitsById map should be immutable - state changes should not affect old references', () {
        notifier.addHabit(testHabit1);
        final habitsMap = notifier.state.habitsById;
        final mapLength = habitsMap.length;

        // Add another habit
        notifier.addHabit(testHabit2);

        // Original reference should remain unchanged
        expect(habitsMap.length, mapLength);
        expect(notifier.state.habitsById.length, mapLength + 1);
        expect(habitsMap, isNot(same(notifier.state.habitsById)));
      });

      test('all operations should create new state instances', () {
        notifier.addHabit(testHabit1);
        final state1 = notifier.state;

        notifier.addHabit(testHabit2);
        final state2 = notifier.state;

        notifier.updateHabit(testHabit1.id, testHabit1.copyWith(name: 'Updated'));
        final state3 = notifier.state;

        notifier.archiveHabit(testHabit1.id);
        final state4 = notifier.state;

        notifier.deleteHabit(testHabit2.id);
        final state5 = notifier.state;

        // All states should be different instances
        expect(state1, isNot(same(state2)));
        expect(state2, isNot(same(state3)));
        expect(state3, isNot(same(state4)));
        expect(state4, isNot(same(state5)));
      });
    });

    group('Integration Tests -', () {
      test('complete CRUD workflow', () {
        // Create
        expect(notifier.addHabit(testHabit1), true);
        expect(notifier.state.habits.length, 1);

        // Read
        expect(notifier.state.habitsById[testHabit1.id], isNotNull);

        // Update
        final updated = testHabit1.copyWith(name: 'Updated Habit');
        expect(notifier.updateHabit(testHabit1.id, updated), true);
        expect(notifier.state.habitsById[testHabit1.id]?.name, 'Updated Habit');

        // Delete
        expect(notifier.deleteHabit(testHabit1.id), true);
        expect(notifier.state.habits, isEmpty);
      });

      test('archive and unarchive workflow', () {
        notifier.addHabit(testHabit1);
        expect(notifier.state.activeHabits.length, 1);

        notifier.archiveHabit(testHabit1.id);
        expect(notifier.state.activeHabits, isEmpty);
        expect(notifier.state.archivedHabits.length, 1);

        notifier.unarchiveHabit(testHabit1.id);
        expect(notifier.state.activeHabits.length, 1);
        expect(notifier.state.archivedHabits, isEmpty);
      });

      test('complex state management scenario', () {
        // Add multiple habits
        notifier.addHabit(testHabit1);
        notifier.addHabit(testHabit2);
        
        final testHabit3 = Habit.create(
          id: 'habit-3',
          name: 'Meditation',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.health,
        );
        notifier.addHabit(testHabit3);

        expect(notifier.state.habits.length, 3);

        // Archive one
        notifier.archiveHabit(testHabit2.id);
        expect(notifier.state.activeCount, 2);
        expect(notifier.state.archivedCount, 1);

        // Update one
        notifier.updateHabit(testHabit1.id, testHabit1.copyWith(name: 'New Name'));
        expect(notifier.state.habitsById[testHabit1.id]?.name, 'New Name');

        // Delete one
        notifier.deleteHabit(testHabit3.id);
        expect(notifier.state.totalCount, 2);

        // Verify consistency
        expect(notifier.state.habits.length, notifier.state.habitsById.length);
      });
    });
  });
}
