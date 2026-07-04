import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import 'interfaces/i_chat_service.dart';

/// LLM-backed implementation of [IChatService] using the Google Gemini API
///
/// Sends the conversation history plus a habit-coach system instruction
/// (personalized with the user's [ChatCoachContext]) to the Gemini
/// generateContent REST endpoint. The HTTP client is injectable so tests
/// can run without network access.
class GeminiChatService implements IChatService {
  final String apiKey;
  final String model;
  final Duration retryDelay;
  final http.Client _client;

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Tried in order when the primary model is overloaded (503) or
  /// rate-limited (429) — the free tier hits this during peak hours
  static const _fallbackModels = [
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash',
  ];

  GeminiChatService({
    required this.apiKey,
    this.model = 'gemini-2.5-flash',
    this.retryDelay = const Duration(milliseconds: 800),
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<String> generateReply({
    required String userMessage,
    required List<ChatMessage> history,
    required ChatCoachContext context,
  }) async {
    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': _buildSystemInstruction(context)},
        ],
      },
      // History already ends with the latest user message
      'contents': [
        for (final message in history)
          {
            'role': message.isUser ? 'user' : 'model',
            'parts': [
              {'text': message.text},
            ],
          },
      ],
      'generationConfig': {
        'temperature': 0.7,
      },
    });

    final models = [
      model,
      ..._fallbackModels.where((m) => m != model),
    ];

    Exception lastError = Exception('Gemini API unavailable');
    for (final currentModel in models) {
      // One retry per model before moving to the next one
      for (var attempt = 0; attempt < 2; attempt++) {
        final response = await _post(currentModel, body);

        if (response.statusCode == 200) {
          final reply = _extractText(response.body);
          if (reply == null || reply.trim().isEmpty) {
            throw Exception('Gemini returned an empty reply');
          }
          return reply.trim();
        }

        lastError = Exception(
          'Gemini API error ${response.statusCode}: '
          '${_errorMessage(response.body)}',
        );

        // Only overload/rate-limit errors are worth retrying;
        // anything else (bad key, malformed request) fails fast
        final isRetriable =
            response.statusCode == 429 || response.statusCode >= 500;
        if (!isRetriable) throw lastError;

        if (attempt == 0) await Future.delayed(retryDelay);
      }
    }
    throw lastError;
  }

  Future<http.Response> _post(String model, String body) {
    return _client
        .post(
          Uri.parse('$_baseUrl/$model:generateContent'),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));
  }

  String _buildSystemInstruction(ChatCoachContext context) {
    final habits = context.activeHabitNames.isEmpty
        ? 'none yet'
        : context.activeHabitNames.join(', ');
    final streak = context.bestCurrentStreak > 0
        ? '${context.bestCurrentStreak} day(s)'
            '${context.bestStreakHabitName != null ? ' on "${context.bestStreakHabitName}"' : ''}'
        : 'no active streak';

    return 'You are a friendly, encouraging habit coach inside a habit '
        'tracker app. Keep replies short (2-4 sentences), practical, and '
        'positive. Use the user\'s real data when relevant.\n'
        'User\'s current data:\n'
        '- Active habits: $habits\n'
        '- Today: ${context.completedTodayCount} of '
        '${context.todaysHabitsCount} scheduled habits completed\n'
        '- Best current streak: $streak';
  }

  /// Joins all text parts of the first candidate, or null if none
  String? _extractText(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return null;

    final content =
        (candidates.first as Map<String, dynamic>)['content']
            as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null) return null;

    return parts
        .map((part) => (part as Map<String, dynamic>)['text'] as String? ?? '')
        .join();
  }

  String _errorMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      return error?['message'] as String? ?? body;
    } catch (_) {
      return body;
    }
  }
}
