import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/services/interfaces/i_weekly_summary_service.dart';
import 'package:habit_tracker_flutter_new/widgets/analytics/weekly_summary_card.dart';

import '../mocks/mock_completions_repository.dart';
import '../mocks/mock_habits_repository.dart';

/// Fake summary service with a controllable result, so tests can
/// observe the loading indicator before the summary arrives
class FakeWeeklySummaryService implements IWeeklySummaryService {
  Completer<String>? pendingSummary;
  WeeklySummaryContext? lastContext;

  @override
  Future<String> generateSummary(WeeklySummaryContext context) {
    lastContext = context;
    final completer = Completer<String>();
    pendingSummary = completer;
    return completer.future;
  }
}

void main() {
  late FakeWeeklySummaryService fakeService;

  Widget buildTestApp() {
    fakeService = FakeWeeklySummaryService();
    return ProviderScope(
      overrides: [
        habitsRepositoryProvider.overrideWithValue(MockHabitsRepository()),
        completionsRepositoryProvider.overrideWithValue(
          MockCompletionsRepository(),
        ),
        weeklySummaryServiceProvider.overrideWithValue(fakeService),
      ],
      child: const MaterialApp(
        home: Scaffold(body: WeeklySummaryCard()),
      ),
    );
  }

  group('WeeklySummaryCard', () {
    testWidgets('shows the generate button before any summary exists',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('AI Weekly Summary'), findsOneWidget);
      expect(find.text('Generate Summary'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('shows loading indicator, then the generated summary',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Generate Summary'));
      await tester.pump();

      expect(find.text('Writing your recap...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(fakeService.lastContext, isNotNull);

      fakeService.pendingSummary!.complete('You had a great week!');
      await tester.pump();

      expect(find.text('You had a great week!'), findsOneWidget);
      expect(find.text('Generate Summary'), findsNothing);
      // Regenerate becomes available once a summary exists
      expect(find.byTooltip('Regenerate'), findsOneWidget);
    });

    testWidgets('regenerate replaces the previous summary', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Generate Summary'));
      await tester.pump();
      fakeService.pendingSummary!.complete('First summary');
      await tester.pump();

      await tester.tap(find.byTooltip('Regenerate'));
      await tester.pump();
      fakeService.pendingSummary!.complete('Second summary');
      await tester.pump();

      expect(find.text('Second summary'), findsOneWidget);
      expect(find.text('First summary'), findsNothing);
    });

    testWidgets('shows an error with retry when generation fails',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Generate Summary'));
      await tester.pump();
      fakeService.pendingSummary!.completeError(Exception('boom'));
      await tester.pump();

      expect(
        find.text('Could not generate your summary. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Try Again'), findsOneWidget);

      // Retry succeeds and clears the error
      await tester.tap(find.text('Try Again'));
      await tester.pump();
      fakeService.pendingSummary!.complete('Recovered summary');
      await tester.pump();

      expect(find.text('Recovered summary'), findsOneWidget);
      expect(find.text('Try Again'), findsNothing);
    });
  });
}
