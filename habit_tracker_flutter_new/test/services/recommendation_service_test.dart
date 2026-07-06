import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/services/gemini_recommendation_service.dart';
import 'package:habit_tracker_flutter_new/services/local_recommendation_service.dart';
import 'package:habit_tracker_flutter_new/services/interfaces/i_recommendation_service.dart';

void main() {
  const emptyContext = RecommendationContext(
    activeHabitNames: [],
    habitCountByCategory: {},
    recentCompletionRate: 0.0,
  );

  group('LocalRecommendationService', () {
    const service = LocalRecommendationService();

    test('returns 3 starter suggestions for a new user', () async {
      final recommendations =
          await service.generateRecommendations(emptyContext);

      expect(recommendations, hasLength(3));
      for (final rec in recommendations) {
        expect(rec.name, isNotEmpty);
        expect(rec.reason, contains('get your tracker started'));
      }
    });

    test('skips suggestions similar to existing habits', () async {
      const context = RecommendationContext(
        activeHabitNames: ['Drink water every morning', 'Read before bed'],
        habitCountByCategory: {
          HabitCategory.health: 1,
          HabitCategory.learning: 1,
        },
        recentCompletionRate: 0.8,
      );

      final recommendations =
          await service.generateRecommendations(context);

      final names = recommendations.map((r) => r.name).toList();
      expect(names, isNot(contains('Drink 8 glasses of water')));
      expect(names, isNot(contains('Read 10 pages')));
    });

    test('prefers categories the user has not explored yet', () async {
      // Heavy on fitness/health; unexplored categories should win
      const context = RecommendationContext(
        activeHabitNames: ['Gym session', 'Morning jog', 'Eat vegetables'],
        habitCountByCategory: {
          HabitCategory.fitness: 2,
          HabitCategory.health: 1,
        },
        recentCompletionRate: 0.8,
      );

      final recommendations =
          await service.generateRecommendations(context);

      expect(recommendations, hasLength(3));
      for (final rec in recommendations) {
        expect(rec.category, isNot(HabitCategory.fitness));
        expect(rec.category, isNot(HabitCategory.health));
        expect(rec.reason, contains('don\'t have any'));
      }
    });

    test('encourages an easy win when the user is struggling', () async {
      // All categories covered so the low-completion branch is reached
      final context = RecommendationContext(
        activeHabitNames: const ['Something unrelated'],
        habitCountByCategory: {
          for (final category in HabitCategory.values) category: 1,
        },
        recentCompletionRate: 0.2,
      );

      final recommendations =
          await service.generateRecommendations(context);

      expect(recommendations, isNotEmpty);
      expect(recommendations.first.reason, contains('rebuild momentum'));
    });
  });

  group('GeminiRecommendationService', () {
    String successBody(Object json) => jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': jsonEncode(json)},
                ],
                'role': 'model',
              },
            },
          ],
        });

    const sampleRecommendations = [
      {
        'name': 'Evening stretch',
        'description': 'Wind down with light stretching',
        'category': 'fitness',
        'frequency': 'everyDay',
        'reason': 'Complements your routine',
      },
      {
        'name': 'Budget check-in',
        'description': 'Review spending for 5 minutes',
        'category': 'finance',
        'frequency': 'weekdays',
        'reason': 'You have no finance habits yet',
      },
      {
        'name': 'Call a friend',
        'description': 'Stay connected',
        'category': 'social',
        'frequency': 'weekends',
        'reason': 'Balance out your week',
      },
    ];

    test('sends context and JSON mime type; parses recommendations',
        () async {
      late http.Request captured;
      final service = GeminiRecommendationService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          captured = request;
          return http.Response(successBody(sampleRecommendations), 200);
        }),
      );

      const context = RecommendationContext(
        activeHabitNames: ['Morning run'],
        habitCountByCategory: {HabitCategory.fitness: 1},
        recentCompletionRate: 0.75,
      );

      final recommendations =
          await service.generateRecommendations(context);

      expect(recommendations, hasLength(3));
      expect(recommendations[0].name, 'Evening stretch');
      expect(recommendations[0].category, HabitCategory.fitness);
      expect(recommendations[1].frequency, HabitFrequency.weekdays);

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['generationConfig']['responseMimeType'],
          'application/json');
      final prompt = body['contents'][0]['parts'][0]['text'] as String;
      expect(prompt, contains('Morning run'));
      expect(prompt, contains('75%'));
    });

    test('throws when the model returns an empty array', () async {
      final service = GeminiRecommendationService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          return http.Response(successBody([]), 200);
        }),
      );

      expect(
        () => service.generateRecommendations(emptyContext),
        throwsA(isA<Exception>()),
      );
    });

    group('parseRecommendations', () {
      test('accepts an object wrapping the array', () {
        final parsed = GeminiRecommendationService.parseRecommendations(
          jsonEncode({'recommendations': sampleRecommendations}),
        );

        expect(parsed, hasLength(3));
        expect(parsed[2].name, 'Call a friend');
      });

      test('coerces unknown category and frequency to safe defaults', () {
        final parsed = GeminiRecommendationService.parseRecommendations(
          jsonEncode([
            {
              'name': 'Mystery habit',
              'description': 'Testing',
              'category': 'astrology',
              'frequency': 'custom',
              'reason': 'Testing',
            },
          ]),
        );

        expect(parsed, hasLength(1));
        expect(parsed.first.category, HabitCategory.other);
        expect(parsed.first.frequency, HabitFrequency.everyDay);
      });

      test('skips entries without a name and caps at 3', () {
        final parsed = GeminiRecommendationService.parseRecommendations(
          jsonEncode([
            {'description': 'no name'},
            ...sampleRecommendations,
            {
              'name': 'Fourth habit',
              'category': 'health',
              'frequency': 'everyDay',
            },
          ]),
        );

        expect(parsed, hasLength(3));
        expect(parsed.map((r) => r.name), isNot(contains('Fourth habit')));
      });

      test('throws FormatException on unparseable JSON', () {
        expect(
          () => GeminiRecommendationService.parseRecommendations(
              'not json at all'),
          throwsFormatException,
        );
      });
    });
  });
}
