import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/providers/completions_notifier.dart';
import '../mocks/mock_completions_repository.dart';

void main() {
  group('CompletionsNotifier -', () {
    late CompletionsNotifier notifier;
    late MockCompletionsRepository mockRepository;
    late String testHabitId1;
    late String testHabitId2;
    late DateTime testDate1;
    late DateTime testDate2;
    late DateTime testDate3;

    setUp(() {
      mockRepository = MockCompletionsRepository();
      notifier = CompletionsNotifier(mockRepository);
      testHabitId1 = 'habit-1';
      testHabitId2 = 'habit-2';
      testDate1 = DateTime(2025, 12, 17);
      testDate2 = DateTime(2025, 12, 18);
      testDate3 = DateTime(2025, 12, 19);
    });

    group('Initial State -', () {
      test('should start with empty initial state', () {
        expect(notifier.state.isEmpty, true);
        expect(notifier.state.completions, isEmpty);
        expect(notifier.state.isLoading, false);
        expect(notifier.state.errorMessage, isNull);
        expect(notifier.state.totalCompletions, 0);
      });
    });

    group('markComplete -', () {
      test('should successfully mark a habit as complete', () {
        final result = notifier.markComplete(testHabitId1, testDate1);

        expect(result, true);
        expect(notifier.state.isCompletedOn(testHabitId1, testDate1), true);
        expect(notifier.state.getCompletionCount(testHabitId1), 1);
        expect(notifier.state.errorMessage, isNull);
      });

      test('should mark multiple dates as complete for same habit', () {
        notifier.markComplete(testHabitId1, testDate1);
        notifier.markComplete(testHabitId1, testDate2);
        notifier.markComplete(testHabitId1, testDate3);

        expect(notifier.state.getCompletionCount(testHabitId1), 3);
        expect(notifier.state.isCompletedOn(testHabitId1, testDate1), true);
        expect(notifier.state.isCompletedOn(testHabitId1, testDate2), true);
        expect(notifier.state.isCompletedOn(testHabitId1, testDate3), true);
      });

      test('should handle duplicate completions (idempotent)', () {
        notifier.markComplete(testHabitId1, testDate1);
        notifier.markComplete(testHabitId1, testDate1);
        notifier.markComplete(testHabitId1, testDate1);

        expect(notifier.state.getCompletionCount(testHabitId1), 1);
      });

      test('should fail with empty habit ID', () {
        final result = notifier.markComplete('', testDate1);

        expect(result, false);
        expect(notifier.state.errorMessage, contains('cannot be empty'));
      });

      test('should normalize dates (remove time component)', () {
        final dateWithTime = DateTime(2025, 12, 17, 14, 30, 45);
        notifier.markComplete(testHabitId1, dateWithTime);

        final dateWithoutTime = DateTime(2025, 12, 17);
        expect(notifier.state.isCompletedOn(testHabitId1, dateWithoutTime), true);
      });

      test('should track completions for multiple habits independently', () {
        notifier.markComplete(testHabitId1, testDate1);
        notifier.markComplete(testHabitId2, testDate1);

        expect(notifier.state.getCompletionCount(testHabitId1), 1);
        expect(notifier.state.getCompletionCount(testHabitId2), 1);
        expect(notifier.state.totalCompletions, 2);
      });
    });

    group('markIncomplete -', () {
      setUp(() {
        notifier.markComplete(testHabitId1, testDate1);
        notifier.markComplete(testHabitId1, testDate2);
      });

      test('should successfully mark a habit as incomplete', () {
        final result = notifier.markIncomplete(testHabitId1, testDate1);

        expect(result, true);
        expect(notifier.state.isCompletedOn(testHabitId1, testDate1), false);
        expect(notifier.state.getCompletionCount(testHabitId1), 1);
        expect(notifier.state.errorMessage, isNull);
      });

      test('should handle marking incomplete when not completed (idempotent)', () {
        final result = notifier.markIncomplete(testHabitId1, testDate3);

        expect(result, true);
        expect(notifier.state.getCompletionCount(testHabitId1), 2);
      });

      test('should remove habit from map when all completions removed', () {
        notifier.markIncomplete(testHabitId1, testDate1);
        notifier.markIncomplete(testHabitId1, testDate2);

        expect(notifier.state.completions.containsKey(testHabitId1), false);
        expect(notifier.state.getCompletionCount(testHabitId1), 0);
      });

      test('should fail with empty habit ID', () {
        final result = notifier.markIncomplete('', testDate1);

        expect(result, false);
        expect(notifier.state.errorMessage, contains('cannot be empty'));
      });

      test('should normalize dates when marking incomplete', () {
        final dateWithTime = DateTime(2025, 12, 17, 14, 30, 45);
        final result = notifier.markIncomplete(testHabitId1, dateWithTime);

        expect(result, true);
        expect(notifier.state.isCompletedOn(testHabitId1, testDate1), false);
      });

      test('should handle non-existent habit gracefully', () {
        final result = notifier.markIncomplete('non-existent-habit', testDate1);

        expect(result, true); // Should succeed (no-op)
        expect(notifier.state.errorMessage, isNull);
      });
    });

    group('toggleCompletion -', () {
      test('should toggle from incomplete to complete', () {
        final result = notifier.toggleCompletion(testHabitId1, testDate1);

        expect(result, true); // Returns new state (true = complete)
        expect(notifier.state.isCompletedOn(testHabitId1, testDate1), true);
      });

      test('should toggle from complete to incomplete', () {
        notifier.markComplete(testHabitId1, testDate1);
        final result = notifier.toggleCompletion(testHabitId1, testDate1);

        expect(result, false); // Returns new state (false = incomplete)
        expect(notifier.state.isCompletedOn(testHabitId1, testDate1), false);
      });

      test('should toggle multiple times correctly', () {
        notifier.toggleCompletion(testHabitId1, testDate1); // complete
        expect(notifier.state.isCompletedOn(testHabitId1, testDate1), true);

        notifier.toggleCompletion(testHabitId1, testDate1); // incomplete
        expect(notifier.state.isCompletedOn(testHabitId1, testDate1), false);

        notifier.toggleCompletion(testHabitId1, testDate1); // complete
        expect(notifier.state.isCompletedOn(testHabitId1, testDate1), true);
      });

      test('should fail with empty habit ID', () {
        final result = notifier.toggleCompletion('', testDate1);

        expect(result, false);
        expect(notifier.state.errorMessage, contains('cannot be empty'));
      });

      test('should normalize dates when toggling', () {
        final dateWithTime = DateTime(2025, 12, 17, 14, 30, 45);
        notifier.toggleCompletion(testHabitId1, dateWithTime);

        final dateWithoutTime = DateTime(2025, 12, 17);
        expect(notifier.state.isCompletedOn(testHabitId1, dateWithoutTime), true);
      });

      test('should remove habit from map when toggling off last completion', () {
        notifier.toggleCompletion(testHabitId1, testDate1); // complete
        notifier.toggleCompletion(testHabitId1, testDate1); // incomplete

        expect(notifier.state.completions.containsKey(testHabitId1), false);
      });
    });

    group('bulkComplete -', () {
      test('should mark multiple dates as complete in one operation', () {
        final dates = [testDate1, testDate2, testDate3];
        final count = notifier.bulkComplete(testHabitId1, dates);

        expect(count, 3);
        expect(notifier.state.getCompletionCount(testHabitId1), 3);
        expect(notifier.state.isCompletedOn(testHabitId1, testDate1), true);
        expect(notifier.state.isCompletedOn(testHabitId1, testDate2), true);
        expect(notifier.state.isCompletedOn(testHabitId1, testDate3), true);
      });

      test('should handle empty date list', () {
        final count = notifier.bulkComplete(testHabitId1, []);

        expect(count, 0);
        expect(notifier.state.getCompletionCount(testHabitId1), 0);
      });

      test('should handle duplicate dates in bulk operation', () {
        final dates = [testDate1, testDate1, testDate2, testDate2];
        final count = notifier.bulkComplete(testHabitId1, dates);

        expect(count, 2); // Only 2 unique dates
        expect(notifier.state.getCompletionCount(testHabitId1), 2);
      });

      test('should fail with empty habit ID', () {
        final count = notifier.bulkComplete('', [testDate1]);

        expect(count, 0);
        expect(notifier.state.errorMessage, contains('cannot be empty'));
      });

      test('should normalize all dates in bulk operation', () {
        final datesWithTime = [
          DateTime(2025, 12, 17, 10, 30),
          DateTime(2025, 12, 18, 14, 45),
          DateTime(2025, 12, 19, 20, 15),
        ];
        notifier.bulkComplete(testHabitId1, datesWithTime);

        expect(notifier.state.isCompletedOn(testHabitId1, DateTime(2025, 12, 17)), true);
        expect(notifier.state.isCompletedOn(testHabitId1, DateTime(2025, 12, 18)), true);
        expect(notifier.state.isCompletedOn(testHabitId1, DateTime(2025, 12, 19)), true);
      });

      test('should merge with existing completions', () {
        notifier.markComplete(testHabitId1, testDate1);
        final count = notifier.bulkComplete(testHabitId1, [testDate2, testDate3]);

        expect(count, 2);
        expect(notifier.state.getCompletionCount(testHabitId1), 3);
      });

      test('should handle large bulk operations efficiently', () {
        final dates = List.generate(100, (index) => DateTime(2025, 1, 1).add(Duration(days: index)));
        final count = notifier.bulkComplete(testHabitId1, dates);

        expect(count, 100);
        expect(notifier.state.getCompletionCount(testHabitId1), 100);
      });
    });

    group('bulkIncomplete -', () {
      setUp(() {
        notifier.bulkComplete(testHabitId1, [testDate1, testDate2, testDate3]);
      });

      test('should mark multiple dates as incomplete in one operation', () {
        final count = notifier.bulkIncomplete(testHabitId1, [testDate1, testDate2]);

        expect(count, 2);
        expect(notifier.state.getCompletionCount(testHabitId1), 1);
        expect(notifier.state.isCompletedOn(testHabitId1, testDate1), false);
        expect(notifier.state.isCompletedOn(testHabitId1, testDate2), false);
        expect(notifier.state.isCompletedOn(testHabitId1, testDate3), true);
      });

      test('should handle empty date list', () {
        final count = notifier.bulkIncomplete(testHabitId1, []);

        expect(count, 0);
        expect(notifier.state.getCompletionCount(testHabitId1), 3);
      });

      test('should handle non-existent completions gracefully', () {
        final nonExistentDate = DateTime(2025, 1, 1);
        final count = notifier.bulkIncomplete(testHabitId1, [nonExistentDate]);

        expect(count, 0);
        expect(notifier.state.getCompletionCount(testHabitId1), 3);
      });

      test('should fail with empty habit ID', () {
        final count = notifier.bulkIncomplete('', [testDate1]);

        expect(count, 0);
        expect(notifier.state.errorMessage, contains('cannot be empty'));
      });

      test('should remove habit from map when all completions removed', () {
        final count = notifier.bulkIncomplete(testHabitId1, [testDate1, testDate2, testDate3]);

        expect(count, 3);
        expect(notifier.state.completions.containsKey(testHabitId1), false);
      });

      test('should handle non-existent habit gracefully', () {
        final count = notifier.bulkIncomplete('non-existent-habit', [testDate1]);

        expect(count, 0);
        expect(notifier.state.errorMessage, isNull);
      });

      test('should normalize dates in bulk incomplete operation', () {
        final datesWithTime = [
          DateTime(2025, 12, 17, 10, 30),
          DateTime(2025, 12, 18, 14, 45),
        ];
        final count = notifier.bulkIncomplete(testHabitId1, datesWithTime);

        expect(count, 2);
        expect(notifier.state.getCompletionCount(testHabitId1), 1);
      });
    });

    group('Date Normalization -', () {
      test('should normalize dates with different time components to same date', () {
        final morning = DateTime(2025, 12, 17, 8, 0, 0);
        final afternoon = DateTime(2025, 12, 17, 14, 30, 45);
        final evening = DateTime(2025, 12, 17, 23, 59, 59);

        notifier.markComplete(testHabitId1, morning);
        
        expect(notifier.state.isCompletedOn(testHabitId1, afternoon), true);
        expect(notifier.state.isCompletedOn(testHabitId1, evening), true);
        expect(notifier.state.getCompletionCount(testHabitId1), 1);
      });

      test('should treat dates with milliseconds and microseconds as same date', () {
        final date1 = DateTime(2025, 12, 17, 12, 30, 45, 123, 456);
        final date2 = DateTime(2025, 12, 17, 18, 45, 30, 789, 123);

        notifier.markComplete(testHabitId1, date1);
        notifier.markComplete(testHabitId1, date2);

        expect(notifier.state.getCompletionCount(testHabitId1), 1);
      });

      test('should preserve different dates even with same time components', () {
        final date1 = DateTime(2025, 12, 17, 14, 30, 45);
        final date2 = DateTime(2025, 12, 18, 14, 30, 45);
        final date3 = DateTime(2025, 12, 19, 14, 30, 45);

        notifier.bulkComplete(testHabitId1, [date1, date2, date3]);

        expect(notifier.state.getCompletionCount(testHabitId1), 3);
      });

      test('should handle UTC and local time correctly', () {
        final localDate = DateTime(2025, 12, 17, 14, 30);
        final utcDate = DateTime.utc(2025, 12, 17, 14, 30);

        notifier.markComplete(testHabitId1, localDate);

        // Both should be treated as same date (2025-12-17)
        expect(notifier.state.isCompletedOn(testHabitId1, utcDate), true);
      });
    });

    group('removeHabitCompletions -', () {
      setUp(() {
        notifier.bulkComplete(testHabitId1, [testDate1, testDate2, testDate3]);
        notifier.bulkComplete(testHabitId2, [testDate1]);
      });

      test('should remove all completions for a specific habit', () {
        notifier.removeHabitCompletions(testHabitId1);

        expect(notifier.state.completions.containsKey(testHabitId1), false);
        expect(notifier.state.getCompletionCount(testHabitId1), 0);
        expect(notifier.state.getCompletionCount(testHabitId2), 1);
      });

      test('should handle non-existent habit gracefully', () {
        notifier.removeHabitCompletions('non-existent-habit');

        expect(notifier.state.errorMessage, isNull);
        expect(notifier.state.totalCompletions, 4);
      });

      test('should work when habit has no completions', () {
        notifier.removeHabitCompletions('habit-with-no-completions');

        expect(notifier.state.errorMessage, isNull);
      });
    });

    group('loadCompletions -', () {
      test('should load completions from map', () {
        final completions = {
          testHabitId1: {testDate1, testDate2},
          testHabitId2: {testDate3},
        };

        notifier.loadCompletions(completions);

        expect(notifier.state.getCompletionCount(testHabitId1), 2);
        expect(notifier.state.getCompletionCount(testHabitId2), 1);
        expect(notifier.state.totalCompletions, 3);
      });

      test('should normalize dates when loading', () {
        final datesWithTime = {
          DateTime(2025, 12, 17, 10, 30),
          DateTime(2025, 12, 18, 14, 45),
        };
        final completions = {testHabitId1: datesWithTime};

        notifier.loadCompletions(completions);

        expect(notifier.state.isCompletedOn(testHabitId1, DateTime(2025, 12, 17)), true);
        expect(notifier.state.isCompletedOn(testHabitId1, DateTime(2025, 12, 18)), true);
      });

      test('should replace existing completions', () {
        notifier.markComplete(testHabitId1, testDate1);
        
        final newCompletions = {testHabitId2: {testDate2}};
        notifier.loadCompletions(newCompletions);

        expect(notifier.state.completions.containsKey(testHabitId1), false);
        expect(notifier.state.getCompletionCount(testHabitId2), 1);
      });

      test('should handle empty completions', () {
        notifier.loadCompletions({});

        expect(notifier.state.isEmpty, true);
        expect(notifier.state.totalCompletions, 0);
      });

      test('should filter out habits with empty date sets', () {
        final completions = {
          testHabitId1: {testDate1},
          testHabitId2: <DateTime>{}, // Empty set
        };

        notifier.loadCompletions(completions);

        expect(notifier.state.completions.containsKey(testHabitId1), true);
        expect(notifier.state.completions.containsKey(testHabitId2), false);
      });
    });

    group('clearAllCompletions -', () {
      test('should clear all completions', () {
        notifier.bulkComplete(testHabitId1, [testDate1, testDate2]);
        notifier.bulkComplete(testHabitId2, [testDate3]);

        notifier.clearAllCompletions();

        expect(notifier.state.isEmpty, true);
        expect(notifier.state.completions, isEmpty);
        expect(notifier.state.errorMessage, isNull);
      });

      test('should work on empty state', () {
        notifier.clearAllCompletions();

        expect(notifier.state.isEmpty, true);
      });
    });

    group('clearError -', () {
      test('should clear error message', () {
        notifier.markComplete('', testDate1); // Causes error

        expect(notifier.state.errorMessage, isNotNull);

        notifier.clearError();

        expect(notifier.state.errorMessage, isNull);
      });

      test('should not affect completions when clearing error', () {
        notifier.markComplete(testHabitId1, testDate1);
        notifier.markComplete('', testDate2); // Causes error

        final completionsBefore = notifier.state.getCompletionCount(testHabitId1);
        notifier.clearError();

        expect(notifier.state.getCompletionCount(testHabitId1), completionsBefore);
      });
    });

    group('CompletionsState Helpers -', () {
      test('getCompletionsForHabit should return empty set for non-existent habit', () {
        final completions = notifier.state.getCompletionsForHabit('non-existent');

        expect(completions, isEmpty);
      });

      test('getCompletionsForHabit should return all dates for habit', () {
        notifier.bulkComplete(testHabitId1, [testDate1, testDate2, testDate3]);
        
        final completions = notifier.state.getCompletionsForHabit(testHabitId1);

        expect(completions.length, 3);
        expect(completions.contains(testDate1), true);
        expect(completions.contains(testDate2), true);
        expect(completions.contains(testDate3), true);
      });

      test('totalCompletions should sum all completions across habits', () {
        notifier.bulkComplete(testHabitId1, [testDate1, testDate2]);
        notifier.bulkComplete(testHabitId2, [testDate1, testDate2, testDate3]);

        expect(notifier.state.totalCompletions, 5);
      });

      test('isEmpty should be false when completions exist', () {
        notifier.markComplete(testHabitId1, testDate1);

        expect(notifier.state.isEmpty, false);
      });
    });

    group('State Immutability -', () {
      test('state changes should not affect old references', () {
        notifier.markComplete(testHabitId1, testDate1);
        final state1 = notifier.state;
        final count1 = state1.totalCompletions;

        notifier.markComplete(testHabitId1, testDate2);
        final state2 = notifier.state;

        expect(state1.totalCompletions, count1);
        expect(state2.totalCompletions, count1 + 1);
        expect(state1, isNot(same(state2)));
      });

      test('all operations should create new state instances', () {
        notifier.markComplete(testHabitId1, testDate1);
        final state1 = notifier.state;

        notifier.markIncomplete(testHabitId1, testDate1);
        final state2 = notifier.state;

        notifier.toggleCompletion(testHabitId1, testDate1);
        final state3 = notifier.state;

        notifier.bulkComplete(testHabitId1, [testDate2, testDate3]);
        final state4 = notifier.state;

        expect(state1, isNot(same(state2)));
        expect(state2, isNot(same(state3)));
        expect(state3, isNot(same(state4)));
      });
    });

    group('Integration Tests -', () {
      test('complete workflow with multiple habits and dates', () {
        // Add completions for multiple habits
        notifier.markComplete(testHabitId1, testDate1);
        notifier.markComplete(testHabitId1, testDate2);
        notifier.bulkComplete(testHabitId2, [testDate1, testDate2, testDate3]);

        expect(notifier.state.totalCompletions, 5);

        // Toggle some completions
        notifier.toggleCompletion(testHabitId1, testDate1);
        expect(notifier.state.getCompletionCount(testHabitId1), 1);

        // Remove some via bulk incomplete
        notifier.bulkIncomplete(testHabitId2, [testDate2, testDate3]);
        expect(notifier.state.getCompletionCount(testHabitId2), 1);

        // Verify final state
        expect(notifier.state.totalCompletions, 2);
      });

      test('should maintain consistency across operations', () {
        final dates = List.generate(10, (i) => DateTime(2025, 12, i + 1));
        
        notifier.bulkComplete(testHabitId1, dates);
        expect(notifier.state.getCompletionCount(testHabitId1), 10);

        // Remove half
        notifier.bulkIncomplete(testHabitId1, dates.sublist(0, 5));
        expect(notifier.state.getCompletionCount(testHabitId1), 5);

        // Add back with toggle
        for (var date in dates.sublist(0, 3)) {
          notifier.toggleCompletion(testHabitId1, date);
        }
        expect(notifier.state.getCompletionCount(testHabitId1), 8);
      });
    });
  });
}
