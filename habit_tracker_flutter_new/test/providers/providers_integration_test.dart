import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';

void main() {
  group('Provider Integration Tests -', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('HabitsNotifier + CompletionsNotifier Integration -', () {
      test('should track completions for created habits', () {
        final habitsNotifier = container.read(habitsProvider.notifier);
        final completionsNotifier = container.read(completionsProvider.notifier);

        // Create a habit
        final habit = Habit.create(
          id: 'habit-1',
          name: 'Morning Exercise',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.health,
        );
        habitsNotifier.addHabit(habit);

        // Mark it complete
        final date = DateTime(2025, 12, 18);
        completionsNotifier.markComplete(habit.id, date);

        // Verify both states
        final habitState = container.read(habitsProvider);
        final completionsState = container.read(completionsProvider);

        expect(habitState.habitsById[habit.id], isNotNull);
        expect(completionsState.isCompletedOn(habit.id, date), true);
      });

      test('should handle multiple habits with different completion patterns', () {
        final habitsNotifier = container.read(habitsProvider.notifier);
        final completionsNotifier = container.read(completionsProvider.notifier);

        // Create multiple habits
        final habit1 = Habit.create(
          id: 'habit-1',
          name: 'Exercise',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.health,
        );
        final habit2 = Habit.create(
          id: 'habit-2',
          name: 'Read',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.learning,
        );

        habitsNotifier.addHabit(habit1);
        habitsNotifier.addHabit(habit2);

        // Complete them on different dates
        final date1 = DateTime(2025, 12, 18);
        final date2 = DateTime(2025, 12, 19);

        completionsNotifier.markComplete(habit1.id, date1);
        completionsNotifier.markComplete(habit1.id, date2);
        completionsNotifier.markComplete(habit2.id, date1);

        final completionsState = container.read(completionsProvider);

        expect(completionsState.getCompletionCount(habit1.id), 2);
        expect(completionsState.getCompletionCount(habit2.id), 1);
        expect(completionsState.totalCompletions, 3);
      });

      test('should maintain completions after habit update', () {
        final habitsNotifier = container.read(habitsProvider.notifier);
        final completionsNotifier = container.read(completionsProvider.notifier);

        final habit = Habit.create(
          id: 'habit-1',
          name: 'Exercise',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.health,
        );

        habitsNotifier.addHabit(habit);
        
        final date = DateTime(2025, 12, 18);
        completionsNotifier.markComplete(habit.id, date);

        // Update habit
        final updatedHabit = habit.copyWith(name: 'Morning Exercise');
        habitsNotifier.updateHabit(habit.id, updatedHabit);

        // Completions should still exist
        final completionsState = container.read(completionsProvider);
        expect(completionsState.isCompletedOn(habit.id, date), true);
      });

      test('should clean up completions when habit is deleted', () {
        final habitsNotifier = container.read(habitsProvider.notifier);
        final completionsNotifier = container.read(completionsProvider.notifier);

        final habit = Habit.create(
          id: 'habit-1',
          name: 'Exercise',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.health,
        );

        habitsNotifier.addHabit(habit);
        completionsNotifier.markComplete(habit.id, DateTime(2025, 12, 18));

        // Delete habit and remove its completions
        habitsNotifier.deleteHabit(habit.id);
        completionsNotifier.removeHabitCompletions(habit.id);

        final habitState = container.read(habitsProvider);
        final completionsState = container.read(completionsProvider);

        expect(habitState.habitsById.containsKey(habit.id), false);
        expect(completionsState.getCompletionCount(habit.id), 0);
      });

      test('should handle archived habits separately from active completions', () {
        final habitsNotifier = container.read(habitsProvider.notifier);
        final completionsNotifier = container.read(completionsProvider.notifier);

        final habit = Habit.create(
          id: 'habit-1',
          name: 'Exercise',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.health,
        );

        habitsNotifier.addHabit(habit);
        completionsNotifier.markComplete(habit.id, DateTime(2025, 12, 18));

        // Archive habit
        habitsNotifier.archiveHabit(habit.id);

        final habitState = container.read(habitsProvider);
        final completionsState = container.read(completionsProvider);

        // Habit is archived but completions remain
        expect(habitState.habitsById[habit.id]?.isArchived, true);
        expect(completionsState.getCompletionCount(habit.id), 1);
      });
    });

    group('SelectedDateProvider Integration -', () {
      test('should initialize to today with normalized time', () {
        final selectedDate = container.read(selectedDateProvider);
        final today = DateTime.now();

        expect(selectedDate.year, today.year);
        expect(selectedDate.month, today.month);
        expect(selectedDate.day, today.day);
        expect(selectedDate.hour, 0);
        expect(selectedDate.minute, 0);
        expect(selectedDate.second, 0);
      });

      test('should filter habits by selected date', () {
        final habitsNotifier = container.read(habitsProvider.notifier);
        
        final dailyHabit = Habit.create(
          id: 'daily-1',
          name: 'Daily Exercise',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.health,
        );

        final weekdayHabit = Habit.create(
          id: 'weekday-1',
          name: 'Work Task',
          frequency: HabitFrequency.weekdays,
          category: HabitCategory.productivity,
        );

        habitsNotifier.addHabit(dailyHabit);
        habitsNotifier.addHabit(weekdayHabit);

        // Set selected date to a Monday
        final monday = DateTime(2025, 12, 15); // This is a Monday
        container.read(selectedDateProvider.notifier).state = monday;

        final habitState = container.read(habitsProvider);
        final selectedDate = container.read(selectedDateProvider);
        final habitsForDate = habitState.getHabitsForDate(selectedDate);

        // Both should be scheduled on a Monday
        expect(habitsForDate.length, 2);
      });

      test('should show relevant completions for selected date', () {
        final completionsNotifier = container.read(completionsProvider.notifier);

        final habitId = 'habit-1';
        final date1 = DateTime(2025, 12, 18);
        final date2 = DateTime(2025, 12, 19);

        completionsNotifier.markComplete(habitId, date1);
        completionsNotifier.markComplete(habitId, date2);

        // Check completion for date1
        container.read(selectedDateProvider.notifier).state = date1;
        var completionsState = container.read(completionsProvider);
        var selectedDate = container.read(selectedDateProvider);
        expect(completionsState.isCompletedOn(habitId, selectedDate), true);

        // Check completion for date2
        container.read(selectedDateProvider.notifier).state = date2;
        completionsState = container.read(completionsProvider);
        selectedDate = container.read(selectedDateProvider);
        expect(completionsState.isCompletedOn(habitId, selectedDate), true);

        // Check non-completed date
        container.read(selectedDateProvider.notifier).state = DateTime(2025, 12, 20);
        completionsState = container.read(completionsProvider);
        selectedDate = container.read(selectedDateProvider);
        expect(completionsState.isCompletedOn(habitId, selectedDate), false);
      });
    });

    group('Complete Workflow Integration -', () {
      test('should handle complete habit lifecycle', () {
        final habitsNotifier = container.read(habitsProvider.notifier);
        final completionsNotifier = container.read(completionsProvider.notifier);

        // 1. Create habit
        final habit = Habit.create(
          id: 'habit-1',
          name: 'Morning Exercise',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.health,
        );
        expect(habitsNotifier.addHabit(habit), true);

        // 2. Complete habit on multiple dates
        final dates = [
          DateTime(2025, 12, 15),
          DateTime(2025, 12, 16),
          DateTime(2025, 12, 17),
        ];
        completionsNotifier.bulkComplete(habit.id, dates);

        var completionsState = container.read(completionsProvider);
        expect(completionsState.getCompletionCount(habit.id), 3);

        // 3. Update habit
        final updatedHabit = habit.copyWith(
          name: 'Evening Exercise',
          targetDays: 60,
        );
        expect(habitsNotifier.updateHabit(habit.id, updatedHabit), true);

        var habitState = container.read(habitsProvider);
        expect(habitState.habitsById[habit.id]?.name, 'Evening Exercise');
        expect(habitState.habitsById[habit.id]?.targetDays, 60);

        // 4. Completions still intact
        completionsState = container.read(completionsProvider);
        expect(completionsState.getCompletionCount(habit.id), 3);

        // 5. Archive habit
        expect(habitsNotifier.archiveHabit(habit.id), true);

        habitState = container.read(habitsProvider);
        expect(habitState.habitsById[habit.id]?.isArchived, true);
        expect(habitState.activeCount, 0);
        expect(habitState.archivedCount, 1);

        // 6. Unarchive habit
        expect(habitsNotifier.unarchiveHabit(habit.id), true);

        habitState = container.read(habitsProvider);
        expect(habitState.habitsById[habit.id]?.isArchived, false);
        expect(habitState.activeCount, 1);

        // 7. Delete habit and clean up
        expect(habitsNotifier.deleteHabit(habit.id), true);
        completionsNotifier.removeHabitCompletions(habit.id);

        habitState = container.read(habitsProvider);
        completionsState = container.read(completionsProvider);
        expect(habitState.habitsById.containsKey(habit.id), false);
        expect(completionsState.getCompletionCount(habit.id), 0);
      });

      test('should handle multiple habits with various operations', () {
        final habitsNotifier = container.read(habitsProvider.notifier);
        final completionsNotifier = container.read(completionsProvider.notifier);

        // Create multiple habits
        final habits = [
          Habit.create(
            id: 'habit-1',
            name: 'Exercise',
            frequency: HabitFrequency.everyDay,
            category: HabitCategory.health,
          ),
          Habit.create(
            id: 'habit-2',
            name: 'Read',
            frequency: HabitFrequency.everyDay,
            category: HabitCategory.learning,
          ),
          Habit.create(
            id: 'habit-3',
            name: 'Meditate',
            frequency: HabitFrequency.everyDay,
            category: HabitCategory.health,
          ),
        ];

        for (var habit in habits) {
          habitsNotifier.addHabit(habit);
        }

        var habitState = container.read(habitsProvider);
        expect(habitState.totalCount, 3);

        // Complete them on various dates
        final today = DateTime(2025, 12, 18);
        completionsNotifier.markComplete('habit-1', today);
        completionsNotifier.markComplete('habit-2', today);
        completionsNotifier.markComplete('habit-3', today);

        final yesterday = today.subtract(const Duration(days: 1));
        completionsNotifier.markComplete('habit-1', yesterday);
        completionsNotifier.markComplete('habit-2', yesterday);

        var completionsState = container.read(completionsProvider);
        expect(completionsState.totalCompletions, 5);

        // Archive one habit
        habitsNotifier.archiveHabit('habit-3');
        habitState = container.read(habitsProvider);
        expect(habitState.activeCount, 2);
        expect(habitState.archivedCount, 1);

        // Delete another habit
        habitsNotifier.deleteHabit('habit-2');
        completionsNotifier.removeHabitCompletions('habit-2');

        habitState = container.read(habitsProvider);
        completionsState = container.read(completionsProvider);
        expect(habitState.totalCount, 2);
        expect(completionsState.totalCompletions, 3); // Only habit-1 and habit-3 completions remain
      });

      test('should maintain data integrity across provider operations', () {
        final habitsNotifier = container.read(habitsProvider.notifier);
        final completionsNotifier = container.read(completionsProvider.notifier);

        final habit = Habit.create(
          id: 'habit-1',
          name: 'Exercise',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.health,
        );

        // Add habit
        habitsNotifier.addHabit(habit);
        
        // Add completions
        final dates = List.generate(7, (i) => DateTime(2025, 12, 11 + i));
        completionsNotifier.bulkComplete(habit.id, dates);

        // Verify counts
        var habitState = container.read(habitsProvider);
        var completionsState = container.read(completionsProvider);
        expect(habitState.totalCount, 1);
        expect(completionsState.getCompletionCount(habit.id), 7);

        // Remove some completions
        completionsNotifier.bulkIncomplete(habit.id, dates.sublist(0, 3));
        completionsState = container.read(completionsProvider);
        expect(completionsState.getCompletionCount(habit.id), 4);

        // Update habit
        final updatedHabit = habit.copyWith(name: 'Updated Exercise');
        habitsNotifier.updateHabit(habit.id, updatedHabit);

        // Both states should be consistent
        habitState = container.read(habitsProvider);
        completionsState = container.read(completionsProvider);
        expect(habitState.habitsById[habit.id]?.name, 'Updated Exercise');
        expect(completionsState.getCompletionCount(habit.id), 4);
      });
    });

    group('State Update Cascade Tests -', () {
      test('should notify listeners when habits state changes', () {
        final habitsNotifier = container.read(habitsProvider.notifier);
        
        var notificationCount = 0;
        final subscription = container.listen(
          habitsProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        final habit = Habit.create(
          id: 'habit-1',
          name: 'Exercise',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.health,
        );

        habitsNotifier.addHabit(habit);
        expect(notificationCount, 1);

        habitsNotifier.updateHabit(habit.id, habit.copyWith(name: 'New Name'));
        expect(notificationCount, 2);

        habitsNotifier.archiveHabit(habit.id);
        expect(notificationCount, 3);

        subscription.close();
      });

      test('should notify listeners when completions state changes', () {
        final completionsNotifier = container.read(completionsProvider.notifier);
        
        var notificationCount = 0;
        final subscription = container.listen(
          completionsProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        final habitId = 'habit-1';
        final date = DateTime(2025, 12, 18);

        completionsNotifier.markComplete(habitId, date);
        expect(notificationCount, 1);

        completionsNotifier.toggleCompletion(habitId, date);
        expect(notificationCount, 2);

        completionsNotifier.toggleCompletion(habitId, date);
        expect(notificationCount, 3);

        subscription.close();
      });

      test('should notify listeners when selected date changes', () {
        var notificationCount = 0;
        final subscription = container.listen(
          selectedDateProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        container.read(selectedDateProvider.notifier).state = DateTime(2025, 12, 18);
        expect(notificationCount, 1);

        container.read(selectedDateProvider.notifier).state = DateTime(2025, 12, 19);
        expect(notificationCount, 2);

        subscription.close();
      });

      test('should handle multiple simultaneous state changes', () {
        final habitsNotifier = container.read(habitsProvider.notifier);
        final completionsNotifier = container.read(completionsProvider.notifier);

        var habitsUpdateCount = 0;
        var completionsUpdateCount = 0;

        final habitsSubscription = container.listen(
          habitsProvider,
          (previous, next) {
            habitsUpdateCount++;
          },
        );

        final completionsSubscription = container.listen(
          completionsProvider,
          (previous, next) {
            completionsUpdateCount++;
          },
        );

        // Perform multiple operations
        final habit = Habit.create(
          id: 'habit-1',
          name: 'Exercise',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.health,
        );

        habitsNotifier.addHabit(habit);
        completionsNotifier.markComplete(habit.id, DateTime(2025, 12, 18));
        completionsNotifier.markComplete(habit.id, DateTime(2025, 12, 19));

        expect(habitsUpdateCount, 1);
        expect(completionsUpdateCount, 2);

        habitsSubscription.close();
        completionsSubscription.close();
      });
    });

    group('Error Handling Integration -', () {
      test('should handle errors in one provider without affecting others', () {
        final habitsNotifier = container.read(habitsProvider.notifier);
        final completionsNotifier = container.read(completionsProvider.notifier);

        final habit = Habit.create(
          id: 'habit-1',
          name: 'Exercise',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.health,
        );

        habitsNotifier.addHabit(habit);
        completionsNotifier.markComplete(habit.id, DateTime(2025, 12, 18));

        // Cause an error in habits
        final invalidHabit = Habit(
          id: 'invalid',
          name: '',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.health,
          createdAt: DateTime.now(),
        );
        habitsNotifier.addHabit(invalidHabit);

        final habitState = container.read(habitsProvider);
        final completionsState = container.read(completionsProvider);

        // Habits should have error
        expect(habitState.errorMessage, isNotNull);
        
        // Completions should be unaffected
        expect(completionsState.errorMessage, isNull);
        expect(completionsState.isCompletedOn(habit.id, DateTime(2025, 12, 18)), true);
      });

      test('should recover from errors gracefully', () {
        final habitsNotifier = container.read(habitsProvider.notifier);

        // Cause an error
        habitsNotifier.deleteHabit('non-existent-id');
        var habitState = container.read(habitsProvider);
        expect(habitState.errorMessage, isNotNull);

        // Clear error
        habitsNotifier.clearError();
        habitState = container.read(habitsProvider);
        expect(habitState.errorMessage, isNull);

        // Should be able to perform operations normally
        final habit = Habit.create(
          id: 'habit-1',
          name: 'Exercise',
          frequency: HabitFrequency.everyDay,
          category: HabitCategory.health,
        );
        expect(habitsNotifier.addHabit(habit), true);
      });
    });
  });
}
