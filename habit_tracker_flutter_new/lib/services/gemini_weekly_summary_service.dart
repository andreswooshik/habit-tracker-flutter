import 'dart:convert';

import 'package:http/http.dart' as http;

import 'interfaces/i_weekly_summary_service.dart';

/// LLM-backed implementation of [IWeeklySummaryService] using the
/// Google Gemini API
///
/// Sends a single-turn request: a summary-writer system instruction
/// plus the week's stats serialized as the user message. Follows the
/// same retry/fallback strategy as [GeminiChatService]; the HTTP
/// client is injectable so tests can run without network access.
class GeminiWeeklySummaryService implements IWeeklySummaryService {
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

  GeminiWeeklySummaryService({
    required this.apiKey,
    this.model = 'gemini-2.5-flash',
    this.retryDelay = const Duration(milliseconds: 800),
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<String> generateSummary(WeeklySummaryContext context) async {
    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': _systemInstruction},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': _buildStatsPrompt(context)},
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
          final summary = _extractText(response.body);
          if (summary == null || summary.trim().isEmpty) {
            throw Exception('Gemini returned an empty summary');
          }
          return summary.trim();
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

  static const _systemInstruction =
      'You are a friendly habit coach writing a short weekly recap inside '
      'a habit tracker app. Write one upbeat paragraph of 3-5 sentences in '
      'plain text (no markdown, no lists, no headings). Mention the overall '
      'completion rate, celebrate the strongest habit or day, gently point '
      'out one habit that needs attention if any, and end with a concrete, '
      'encouraging suggestion for next week. Use only the data provided.';

  String _buildStatsPrompt(WeeklySummaryContext context) {
    final buffer = StringBuffer()
      ..writeln('Week: ${_formatDate(context.weekStart)} to '
          '${_formatDate(context.weekEnd)}')
      ..writeln('Overall: ${context.totalCompleted} of '
          '${context.totalScheduled} scheduled habit-days completed '
          '(${(context.completionRate * 100).round()}%)')
      ..writeln('Per habit:');
    for (final habit in context.habitStats) {
      buffer.writeln('- ${habit.name}: ${habit.completedCount} of '
          '${habit.scheduledCount} scheduled days');
    }
    buffer.writeln('Per day:');
    for (final day in context.dayStats) {
      buffer.writeln('- ${_formatDate(day.date)}: ${day.completedCount} of '
          '${day.scheduledCount} completed');
    }
    if (context.bestCurrentStreak > 0) {
      buffer.writeln('Best current streak: ${context.bestCurrentStreak} '
          'day(s)${context.bestStreakHabitName != null ? ' on "${context.bestStreakHabitName}"' : ''}');
    }
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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
