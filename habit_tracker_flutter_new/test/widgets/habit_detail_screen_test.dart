import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/screens/habit_detail_screen.dart';

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
      child: MaterialApp(home: HabitDetailScreen(habit: testHabit)),
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
  });
}
