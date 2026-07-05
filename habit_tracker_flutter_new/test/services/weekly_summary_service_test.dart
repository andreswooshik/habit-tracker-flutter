import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:habit_tracker_flutter_new/services/gemini_weekly_summary_service.dart';
import 'package:habit_tracker_flutter_new/services/local_weekly_summary_service.dart';
import 'package:habit_tracker_flutter_new/services/interfaces/i_weekly_summary_service.dart';

void main() {
  // Mon 2026-06-29 .. Sun 2026-07-05; 2026-07-01 is a Wednesday
  final context = WeeklySummaryContext(
    weekStart: DateTime(2026, 6, 29),
    weekEnd: DateTime(2026, 7, 5),
    habitStats: const [
      HabitWeekStats(name: 'Read', scheduledCount: 7, completedCount: 6),
      HabitWeekStats(name: 'Exercise', scheduledCount: 5, completedCount: 1),
    ],
    dayStats: [
      DayWeekStats(
          date: DateTime(2026, 6, 29), scheduledCount: 2, completedCount: 1),
      DayWeekStats(
          date: DateTime(2026, 6, 30), scheduledCount: 2, completedCount: 1),
      DayWeekStats(
          date: DateTime(2026, 7, 1), scheduledCount: 2, completedCount: 2),
      DayWeekStats(
          date: DateTime(2026, 7, 2), scheduledCount: 2, completedCount: 1),
      DayWeekStats(
          date: DateTime(2026, 7, 3), scheduledCount: 2, completedCount: 1),
      DayWeekStats(
          date: DateTime(2026, 7, 4), scheduledCount: 1, completedCount: 0),
      DayWeekStats(
          date: DateTime(2026, 7, 5), scheduledCount: 1, completedCount: 1),
    ],
    bestCurrentStreak: 4,
    bestStreakHabitName: 'Read',
  );

  final emptyContext = WeeklySummaryContext(
    weekStart: DateTime(2026, 6, 29),
    weekEnd: DateTime(2026, 7, 5),
    habitStats: const [],
    dayStats: const [],
    bestCurrentStreak: 0,
  );

  group('WeeklySummaryContext', () {
    test('computes totals and completion rate from habit stats', () {
      expect(context.totalScheduled, 12);
      expect(context.totalCompleted, 7);
      expect(context.completionRate, closeTo(7 / 12, 0.001));
      expect(context.isEmpty, isFalse);
    });

    test('is empty when there are no habits', () {
      expect(emptyContext.isEmpty, isTrue);
      expect(emptyContext.completionRate, 0.0);
    });
  });

  group('LocalWeeklySummaryService', () {
    const service = LocalWeeklySummaryService();

    test('summarizes totals, best and struggling habits, best day, streak',
        () async {
      final summary = await service.generateSummary(context);

      expect(summary, contains('7 of 12'));
      expect(summary, contains('58%'));
      expect(summary, contains('"Read" led the way with 6 of 7'));
      expect(summary, contains('"Exercise" could use some attention'));
      expect(summary, contains('Wednesday'));
      expect(summary, contains('4-day streak'));
      // 58% falls in the middle encouragement bucket
      expect(summary, contains('Solid effort'));
    });

    test('returns a friendly message when there is no activity', () async {
      final summary = await service.generateSummary(emptyContext);

      expect(summary, contains('No habit activity'));
    });

    test('omits streak and struggling-habit callouts when not applicable',
        () async {
      final greatWeek = WeeklySummaryContext(
        weekStart: DateTime(2026, 6, 29),
        weekEnd: DateTime(2026, 7, 5),
        habitStats: const [
          HabitWeekStats(name: 'Read', scheduledCount: 7, completedCount: 7),
        ],
        dayStats: [
          DayWeekStats(
              date: DateTime(2026, 7, 1), scheduledCount: 1, completedCount: 1),
        ],
        bestCurrentStreak: 0,
      );

      final summary = await service.generateSummary(greatWeek);

      expect(summary, contains('7 of 7'));
      expect(summary, isNot(contains('could use some attention')));
      expect(summary, isNot(contains('streak')));
      // 100% falls in the top encouragement bucket
      expect(summary, contains('Outstanding week'));
    });
  });

  group('GeminiWeeklySummaryService', () {
    String successBody(String text) => jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': text},
                ],
                'role': 'model',
              },
            },
          ],
        });

    test('sends stats, system instruction, and API key; returns summary',
        () async {
      late http.Request captured;
      final service = GeminiWeeklySummaryService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          captured = request;
          return http.Response(successBody('What a week!'), 200);
        }),
      );

      final summary = await service.generateSummary(context);

      expect(summary, 'What a week!');
      expect(captured.url.path, contains('gemini-2.5-flash:generateContent'));
      expect(captured.headers['x-goog-api-key'], 'test-key');

      final body = jsonDecode(captured.body) as Map<String, dynamic>;

      // Single-turn user message carries the week's stats
      final contents = body['contents'] as List<dynamic>;
      expect(contents, hasLength(1));
      expect(contents[0]['role'], 'user');
      final statsText = contents[0]['parts'][0]['text'] as String;
      expect(statsText, contains('2026-06-29 to 2026-07-05'));
      expect(statsText, contains('7 of 12'));
      expect(statsText, contains('Read: 6 of 7'));
      expect(statsText, contains('Best current streak: 4'));

      // System instruction asks for a weekly recap
      final systemText =
          body['systemInstruction']['parts'][0]['text'] as String;
      expect(systemText, contains('weekly recap'));
    });

    test('throws with the API error message on non-retriable errors',
        () async {
      var callCount = 0;
      final service = GeminiWeeklySummaryService(
        apiKey: 'bad-key',
        retryDelay: Duration.zero,
        client: MockClient((request) async {
          callCount++;
          return http.Response(
            jsonEncode({
              'error': {'code': 400, 'message': 'API key not valid'},
            }),
            400,
          );
        }),
      );

      await expectLater(
        service.generateSummary(context),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            allOf(contains('400'), contains('API key not valid')),
          ),
        ),
      );
      expect(callCount, 1);
    });

    test('retries and falls back to another model on 503 overload', () async {
      final requestedModels = <String>[];
      final service = GeminiWeeklySummaryService(
        apiKey: 'test-key',
        retryDelay: Duration.zero,
        client: MockClient((request) async {
          requestedModels
              .add(request.url.path.split('/').last.split(':').first);
          // Primary model overloaded; first fallback succeeds
          if (requestedModels.length <= 2) {
            return http.Response(
              jsonEncode({
                'error': {'code': 503, 'message': 'high demand'},
              }),
              503,
            );
          }
          return http.Response(successBody('Fallback summary'), 200);
        }),
      );

      final summary = await service.generateSummary(context);

      expect(summary, 'Fallback summary');
      expect(requestedModels,
          ['gemini-2.5-flash', 'gemini-2.5-flash', 'gemini-2.5-flash-lite']);
    });

    test('throws when the response has no candidates (blocked prompt)',
        () async {
      final service = GeminiWeeklySummaryService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'promptFeedback': {'blockReason': 'SAFETY'},
            }),
            200,
          );
        }),
      );

      expect(
        () => service.generateSummary(context),
        throwsA(isA<Exception>()),
      );
    });
  });
}
