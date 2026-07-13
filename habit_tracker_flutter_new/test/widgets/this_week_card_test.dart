import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/widgets/analytics/this_week_card.dart';

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
        home: Scaffold(body: SingleChildScrollView(child: ThisWeekCard())),
      ),
    );
  }

  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  group('ThisWeekCard', () {
    testWidgets('shows all seven day letters and the empty-today caption',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('This Week'), findsOneWidget);
      // Mon–Sun letters: M T W T F S S
      expect(find.text('M'), findsOneWidget);
      expect(find.text('T'), findsNWidgets(2));
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
      expect(find.text('S'), findsNWidgets(2));
      expect(find.text('Nothing scheduled today'), findsOneWidget);
    });

    testWidgets('today pip shows live progress once habits exist',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      final element = tester.element(find.byType(ThisWeekCard));
      final container = ProviderScope.containerOf(element);

      container.read(habitsProvider.notifier).addHabit(
            Habit(
              id: '1',
              name: 'Daily',
              frequency: HabitFrequency.everyDay,
              category: HabitCategory.health,
              createdAt: today(),
            ),
          );
      await tester.pump();

      expect(find.text('0/1'), findsOneWidget);
      expect(find.text('0 of 1 done so far today'), findsOneWidget);

      container.read(completionsProvider.notifier).markComplete('1', today());
      await tester.pump();

      expect(find.text('1/1'), findsOneWidget);
      expect(find.text('1 of 1 done so far today'), findsOneWidget);
    });

    testWidgets(
        'past days before the habit existed show as no-habits, not as 0%',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      final element = tester.element(find.byType(ThisWeekCard));
      final container = ProviderScope.containerOf(element);

      // Habit created today: any earlier weekdays this week must not
      // render a "0" verdict ring
      container.read(habitsProvider.notifier).addHabit(
            Habit(
              id: '1',
              name: 'Daily',
              frequency: HabitFrequency.everyDay,
              category: HabitCategory.health,
              createdAt: today(),
            ),
          );
      await tester.pump();

      expect(find.text('0'), findsNothing);
    });
  });
}
