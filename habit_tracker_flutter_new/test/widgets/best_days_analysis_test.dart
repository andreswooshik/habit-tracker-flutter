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

  Habit dailyHabit({required DateTime createdAt}) {
    return Habit(
      id: '1',
      name: 'Daily',
      frequency: HabitFrequency.everyDay,
      category: HabitCategory.health,
      createdAt: createdAt,
    );
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

      container
          .read(habitsProvider.notifier)
          .addHabit(dailyHabit(createdAt: today()));
      container.read(completionsProvider.notifier).markComplete('1', today());
      await tester.pump();

      expect(find.text('100%'), findsWidgets);
      expect(find.text('14%'), findsNothing);
    });

    testWidgets(
        'shows the low-confidence banner while under a week of data',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      final element = tester.element(find.byType(BestDaysAnalysis));
      final container = ProviderScope.containerOf(element);

      container
          .read(habitsProvider.notifier)
          .addHabit(dailyHabit(createdAt: today()));
      container.read(completionsProvider.notifier).markComplete('1', today());
      await tester.pump();

      expect(
        find.textContaining('just getting started'),
        findsOneWidget,
      );
      // With a single tracked day there is no Focus tile yet
      expect(find.text('Focus day'), findsNothing);
      expect(find.text('Average'), findsOneWidget);
    });

    testWidgets(
        'with an established history shows the strongest/slip sentence '
        'and Best/Focus tiles, without the banner', (tester) async {
      await tester.pumpWidget(buildTestApp());

      final element = tester.element(find.byType(BestDaysAnalysis));
      final container = ProviderScope.containerOf(element);

      // 10 days of history; only yesterday completed → yesterday's
      // weekday is the best day, everything else trails
      container.read(habitsProvider.notifier).addHabit(
            dailyHabit(
              createdAt: today().subtract(const Duration(days: 9)),
            ),
          );
      container.read(completionsProvider.notifier).loadCompletions({
        '1': {today().subtract(const Duration(days: 1))},
      });
      await tester.pump();

      expect(find.textContaining("You're strongest on"), findsOneWidget);
      expect(find.text('Best day'), findsOneWidget);
      expect(find.text('Focus day'), findsOneWidget);
      expect(find.textContaining('just getting started'), findsNothing);
      // The historical card carries no weekday bar list anymore —
      // day names appear only in the tiles (at most best + focus)
      expect(
        tester.widgetList(find.text('Mon')).length +
            tester.widgetList(find.text('Tue')).length +
            tester.widgetList(find.text('Wed')).length,
        lessThanOrEqualTo(2),
      );
    });
  });
}
