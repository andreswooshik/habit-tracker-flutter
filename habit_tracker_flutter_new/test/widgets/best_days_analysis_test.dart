import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/widgets/analytics/best_days_analysis.dart';

import '../mocks/mock_completions_repository.dart';
import '../mocks/mock_habits_repository.dart';

void main() {
  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        habitsRepositoryProvider.overrideWithValue(MockHabitsRepository()),
        completionsRepositoryProvider.overrideWithValue(
          MockCompletionsRepository(),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: BestDaysAnalysis())),
      ),
    );
  }

  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  group('BestDaysAnalysis', () {
    testWidgets('shows the empty state when no day has data',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('No weekday data available'), findsOneWidget);
    });

    testWidgets(
        'averages only days with scheduled habits — a habit created and '
        'completed today shows 100%, not 100/7', (tester) async {
      await tester.pumpWidget(buildTestApp());

      final element = tester.element(find.byType(BestDaysAnalysis));
      final container = ProviderScope.containerOf(element);

      // Habit created today: only today's weekday has any data
      container.read(habitsProvider.notifier).addHabit(
            Habit(
              id: '1',
              name: 'Daily',
              frequency: HabitFrequency.everyDay,
              category: HabitCategory.health,
              createdAt: today(),
            ),
          );
      container.read(completionsProvider.notifier).markComplete('1', today());
      await tester.pump();

      // Average across the week is 100% (1 day of data, fully done),
      // not ~14% from six no-data days averaged in as zeros
      expect(find.text('100%'), findsWidgets);
      expect(find.text('14%'), findsNothing);
    });
  });
}
