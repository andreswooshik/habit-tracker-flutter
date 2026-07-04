import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/widgets/habit_detail/heatmap_calendar.dart';

import '../mocks/mock_completions_repository.dart';
import '../mocks/mock_habits_repository.dart';

void main() {
  final testHabit = Habit.create(
    id: 'habit-1',
    name: 'Drink Water',
  );

  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        habitsRepositoryProvider.overrideWithValue(MockHabitsRepository()),
        completionsRepositoryProvider.overrideWithValue(
          MockCompletionsRepository(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HeatmapCalendar(
              habit: testHabit,
              selectedDate: DateTime.now(),
            ),
          ),
        ),
      ),
    );
  }

  group('HeatmapCalendar', () {
    testWidgets('renders exactly 30 day cells', (tester) async {
      await tester.pumpWidget(buildTestApp());

      // Each day cell keeps a 1:1 aspect ratio; filler slots do not
      expect(find.byType(AspectRatio), findsNWidgets(30));
    });

    testWidgets('all day cells are the same size, including the last row',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      final cellSizes = find
          .byType(AspectRatio)
          .evaluate()
          .map((element) => element.size)
          .toList();

      final firstSize = cellSizes.first!;
      for (final size in cellSizes) {
        // The last row used to stretch its cells across the full width
        expect(size!.width, moreOrLessEquals(firstSize.width, epsilon: 0.5));
        expect(size.height, moreOrLessEquals(firstSize.height, epsilon: 0.5));
      }
    });
  });
}
