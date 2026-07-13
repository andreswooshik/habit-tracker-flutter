import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/providers/repository_providers.dart';
import 'package:habit_tracker_flutter_new/widgets/dashboard/weekly_performance_chart.dart';

import '../mocks/mock_completions_repository.dart';
import '../mocks/mock_habits_repository.dart';

void main() {
  late MockHabitsRepository habitsRepository;
  late MockCompletionsRepository completionsRepository;

  setUp(() {
    habitsRepository = MockHabitsRepository();
    completionsRepository = MockCompletionsRepository();
  });

  Widget buildChart() {
    return ProviderScope(
      overrides: [
        habitsRepositoryProvider.overrideWithValue(habitsRepository),
        completionsRepositoryProvider.overrideWithValue(completionsRepository),
      ],
      child: const MaterialApp(
        home: Scaffold(body: WeeklyPerformanceChart()),
      ),
    );
  }

  DateTime daysAgo(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days));
  }

  group('WeeklyPerformanceChart trend indicator', () {
    testWidgets(
        'shows percentage-point change vs last week (regression: was '
        'multiplied by 100 into values like 1905%)', (tester) async {
      // Habit existed for both weeks: last week perfect (7/7 days),
      // this week only today — a drop of ~86 percentage points
      final habit = Habit.create(id: 'a', name: 'Read')
          .copyWith(createdAt: daysAgo(20));
      await habitsRepository.saveHabit(habit);
      for (var i = 7; i <= 13; i++) {
        await completionsRepository.addCompletion('a', daysAgo(i));
      }
      await completionsRepository.addCompletion('a', daysAgo(0));

      await tester.pumpWidget(buildChart());
      await tester.pumpAndSettle();

      expect(find.text('-86%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
      // The old double-multiplied value must be gone
      expect(find.textContaining('8571'), findsNothing);
    });

    testWidgets('hides the badge when last week has no data to compare',
        (tester) async {
      // Habit created today: previous week had no habits at all
      final habit = Habit.create(id: 'a', name: 'Read');
      await habitsRepository.saveHabit(habit);
      await completionsRepository.addCompletion('a', daysAgo(0));

      await tester.pumpWidget(buildChart());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.trending_up), findsNothing);
      expect(find.byIcon(Icons.trending_down), findsNothing);
    });
  });
}
