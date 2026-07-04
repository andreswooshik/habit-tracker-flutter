import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:habit_tracker_flutter_new/models/chat_message.dart';
import 'package:habit_tracker_flutter_new/services/gemini_chat_service.dart';
import 'package:habit_tracker_flutter_new/services/interfaces/i_chat_service.dart';

void main() {
  const context = ChatCoachContext(
    activeHabitNames: ['Drink Water', 'Read'],
    todaysHabitsCount: 2,
    completedTodayCount: 1,
    bestCurrentStreak: 5,
    bestStreakHabitName: 'Drink Water',
  );

  final history = [
    ChatMessage(
      id: '1',
      sender: ChatSender.user,
      text: 'hello',
      timestamp: DateTime(2026, 7, 4, 10),
    ),
    ChatMessage(
      id: '2',
      sender: ChatSender.assistant,
      text: 'hi there!',
      timestamp: DateTime(2026, 7, 4, 10, 1),
    ),
    ChatMessage(
      id: '3',
      sender: ChatSender.user,
      text: 'how am I doing?',
      timestamp: DateTime(2026, 7, 4, 10, 2),
    ),
  ];

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

  group('GeminiChatService', () {
    test('sends history, system instruction, and API key; returns reply',
        () async {
      late http.Request captured;
      final service = GeminiChatService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          captured = request;
          return http.Response(successBody('You are doing great!'), 200);
        }),
      );

      final reply = await service.generateReply(
        userMessage: 'how am I doing?',
        history: history,
        context: context,
      );

      expect(reply, 'You are doing great!');
      expect(captured.url.path, contains('gemini-2.5-flash:generateContent'));
      expect(captured.headers['x-goog-api-key'], 'test-key');

      final body = jsonDecode(captured.body) as Map<String, dynamic>;

      // History mapped to Gemini roles, in order
      final contents = body['contents'] as List<dynamic>;
      expect(contents, hasLength(3));
      expect(contents[0]['role'], 'user');
      expect(contents[1]['role'], 'model');
      expect(contents[2]['role'], 'user');
      expect(contents[2]['parts'][0]['text'], 'how am I doing?');

      // System instruction carries the habit context
      final systemText =
          body['systemInstruction']['parts'][0]['text'] as String;
      expect(systemText, contains('Drink Water'));
      expect(systemText, contains('1 of 2'));
      expect(systemText, contains('5 day'));
    });

    test('joins multiple text parts in the reply', () async {
      final service = GeminiChatService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Part one. '},
                      {'text': 'Part two.'},
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }),
      );

      final reply = await service.generateReply(
        userMessage: 'hi',
        history: history,
        context: context,
      );

      expect(reply, 'Part one. Part two.');
    });

    test('throws with the API error message on non-200 response', () async {
      final service = GeminiChatService(
        apiKey: 'bad-key',
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'error': {'code': 400, 'message': 'API key not valid'},
            }),
            400,
          );
        }),
      );

      expect(
        () => service.generateReply(
          userMessage: 'hi',
          history: history,
          context: context,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            allOf(contains('400'), contains('API key not valid')),
          ),
        ),
      );
    });

    test('retries and falls back to another model on 503 overload', () async {
      final requestedModels = <String>[];
      final service = GeminiChatService(
        apiKey: 'test-key',
        retryDelay: Duration.zero,
        client: MockClient((request) async {
          requestedModels.add(request.url.path.split('/').last.split(':').first);
          // Primary model overloaded; first fallback succeeds
          if (requestedModels.length <= 2) {
            return http.Response(
              jsonEncode({
                'error': {'code': 503, 'message': 'high demand'},
              }),
              503,
            );
          }
          return http.Response(successBody('Fallback reply'), 200);
        }),
      );

      final reply = await service.generateReply(
        userMessage: 'hi',
        history: history,
        context: context,
      );

      expect(reply, 'Fallback reply');
      // Two attempts on the primary, then the fallback model
      expect(requestedModels,
          ['gemini-2.5-flash', 'gemini-2.5-flash', 'gemini-2.5-flash-lite']);
    });

    test('does not retry on non-retriable errors like 400', () async {
      var callCount = 0;
      final service = GeminiChatService(
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
        service.generateReply(
          userMessage: 'hi',
          history: history,
          context: context,
        ),
        throwsA(isA<Exception>()),
      );
      expect(callCount, 1);
    });

    test('throws when the response has no candidates (blocked prompt)',
        () async {
      final service = GeminiChatService(
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
        () => service.generateReply(
          userMessage: 'hi',
          history: history,
          context: context,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
