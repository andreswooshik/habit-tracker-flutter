import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/models/habit_recommendation.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/services/interfaces/i_recommendation_service.dart';
import 'package:habit_tracker_flutter_new/widgets/dashboard/smart_recommendations_card.dart';

import '../mocks/mock_completions_repository.dart';
import '../mocks/mock_habits_repository.dart';

const _sampleRecommendations = [
  HabitRecommendation(
    name: 'Evening stretch',
    description: 'Wind down with light stretching',
    category: HabitCategory.fitness,
    frequency: HabitFrequency.everyDay,
    reason: 'An easy way to relax',
  ),
  HabitRecommendation(
    name: 'Budget check-in',
    description: 'Review spending for 5 minutes',
    category: HabitCategory.finance,
    frequency: HabitFrequency.weekdays,
    reason: 'You have no finance habits yet',
  ),
];

/// Fake recommendation service with a controllable result, so tests
/// can observe the loading indicator before suggestions arrive
class FakeRecommendationService implements IRecommendationService {
  Completer<List<HabitRecommendation>>? pending;
  RecommendationContext? lastContext;

  @override
  Future<List<HabitRecommendation>> generateRecommendations(
    RecommendationContext context,
  ) {
    lastContext = context;
    final completer = Completer<List<HabitRecommendation>>();
    pending = completer;
    return completer.future;
  }
}

void main() {
  late FakeRecommendationService fakeService;

  Widget buildTestApp() {
    fakeService = FakeRecommendationService();
    return ProviderScope(
      overrides: [
        habitsRepositoryProvider.overrideWithValue(MockHabitsRepository()),
        completionsRepositoryProvider.overrideWithValue(
          MockCompletionsRepository(),
        ),
        recommendationServiceProvider.overrideWithValue(fakeService),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SmartRecommendationsCard()),
      ),
    );
  }

  Future<void> generateSuggestions(WidgetTester tester) async {
    await tester.tap(find.text('Suggest Habits'));
    await tester.pump();
    fakeService.pending!.complete(_sampleRecommendations);
    await tester.pump();
  }

  group('SmartRecommendationsCard', () {
    testWidgets('shows the suggest button before anything is generated',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('Smart Recommendations'), findsOneWidget);
      expect(find.text('Suggest Habits'), findsOneWidget);
    });

    testWidgets('shows loading indicator, then the suggestions',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Suggest Habits'));
      await tester.pump();

      expect(find.text('Finding ideas for you...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      fakeService.pending!.complete(_sampleRecommendations);
      await tester.pump();

      expect(find.text('Evening stretch'), findsOneWidget);
      expect(find.text('Budget check-in'), findsOneWidget);
      expect(find.text('You have no finance habits yet'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Add'), findsNWidgets(2));
    });

    testWidgets('adding a suggestion creates the habit and removes the tile',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await generateSuggestions(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Add').first);
      await tester.pump();

      // Tile removed, snackbar confirms, habit exists in state
      expect(find.text('Evening stretch'), findsNothing);
      expect(
        find.text('"Evening stretch" added to your habits'),
        findsOneWidget,
      );

      final element = tester.element(find.byType(SmartRecommendationsCard));
      final habits = ProviderScope.containerOf(element)
          .read(habitsProvider)
          .habits;
      expect(habits.map((h) => h.name), contains('Evening stretch'));
      expect(
        habits.firstWhere((h) => h.name == 'Evening stretch').category,
        HabitCategory.fitness,
      );
    });

    testWidgets('adding every suggestion shows the all-done state',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await generateSuggestions(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Add').first);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Add').first);
      await tester.pump();

      expect(find.text('All suggestions added — nice!'), findsOneWidget);
      expect(find.text('Suggest More'), findsOneWidget);
    });

    testWidgets('shows an error with retry when generation fails',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Suggest Habits'));
      await tester.pump();
      fakeService.pending!.completeError(Exception('boom'));
      await tester.pump();

      expect(
        find.text('Could not load suggestions. Please try again.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Try Again'));
      await tester.pump();
      fakeService.pending!.complete(_sampleRecommendations);
      await tester.pump();

      expect(find.text('Evening stretch'), findsOneWidget);
    });
  });
}
