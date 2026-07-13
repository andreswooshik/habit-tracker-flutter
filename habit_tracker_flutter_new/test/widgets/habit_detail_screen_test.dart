import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/screens/habit_detail_screen.dart';
import 'package:habit_tracker_flutter_new/widgets/habit_card.dart';

import '../mocks/mock_completions_repository.dart';
import '../mocks/mock_habits_repository.dart';

void main() {
  final testHabit = Habit.create(
    id: 'habit-1',
    name: 'Drink Water',
  );

  Widget buildTestApp() {
    // Seed the repository so providers that look the habit up by id find it
    final habitsRepository = MockHabitsRepository();
    habitsRepository.saveHabit(testHabit);

    return ProviderScope(
      overrides: [
        habitsRepositoryProvider.overrideWithValue(habitsRepository),
        completionsRepositoryProvider.overrideWithValue(
          MockCompletionsRepository(),
        ),
      ],
      child: MaterialApp(home: HabitDetailScreen(habitId: testHabit.id)),
    );
  }

  group('HabitDetailScreen', () {
    testWidgets('renders header, streak card, and heatmap', (tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('Drink Water'), findsOneWidget);
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsOneWidget);
    });

    testWidgets('hero pairs with the habit card via the header icon',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, 'habit_card_habit-1');
      // The hero must wrap only the icon — never the whole Scaffold
      expect(
        find.descendant(of: find.byType(Hero), matching: find.byType(Scaffold)),
        findsNothing,
      );
    });

    testWidgets('showing a snackbar does not crash (nested Hero regression)',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      // SnackBars insert their own Hero into the Scaffold. This threw
      // "A Hero widget cannot be the descendant of another Hero widget"
      // when the whole Scaffold was wrapped in a Hero.
      final context = tester.element(find.byType(CustomScrollView));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drink Water added')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('Drink Water added'), findsOneWidget);
    });

    testWidgets('reflects an edit made elsewhere (no stale snapshot)',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      expect(find.text('Drink Water'), findsOneWidget);

      final context = tester.element(find.byType(HabitDetailScreen));
      final container = ProviderScope.containerOf(context);
      await container
          .read(habitsProvider.notifier)
          .updateHabit('habit-1', testHabit.copyWith(name: 'Drink More Water'));
      await tester.pump();

      expect(find.text('Drink Water'), findsNothing);
      expect(find.text('Drink More Water'), findsOneWidget);
    });

    testWidgets('shows a fallback instead of crashing when the habit is gone',
        (tester) async {
      final habitsRepository = MockHabitsRepository();
      // Deliberately not seeded — habitId matches nothing

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitsRepositoryProvider.overrideWithValue(habitsRepository),
            completionsRepositoryProvider
                .overrideWithValue(MockCompletionsRepository()),
          ],
          child: const MaterialApp(
            home: HabitDetailScreen(habitId: 'does-not-exist'),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('This habit no longer exists'), findsOneWidget);
    });

    testWidgets(
        'two HabitCards for the same habit on different surfaces use '
        'distinct hero tags, so opening detail from either does not crash',
        (tester) async {
      final habitsRepository = MockHabitsRepository();
      await habitsRepository.saveHabit(testHabit);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitsRepositoryProvider.overrideWithValue(habitsRepository),
            completionsRepositoryProvider
                .overrideWithValue(MockCompletionsRepository()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  HabitCard(
                    habit: testHabit,
                    selectedDate: DateTime.now(),
                    heroTag: 'today_habit_${testHabit.id}',
                  ),
                  HabitCard(
                    habit: testHabit,
                    selectedDate: DateTime.now(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final heroes = tester.widgetList<Hero>(find.byType(Hero)).toList();
      expect(heroes.map((h) => h.tag).toSet(), hasLength(heroes.length));

      // Navigate from the second (Habits-tab-style) card and confirm no
      // "multiple heroes share the same tag" exception on the way in
      await tester.tap(find.byType(HabitCard).last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HabitDetailScreen), findsOneWidget);
    });
  });
}
