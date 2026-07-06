import 'package:http/http.dart' as http;

import 'gemini_client.dart';
import 'interfaces/i_weekly_summary_service.dart';

/// LLM-backed implementation of [IWeeklySummaryService] using the
/// Google Gemini API
///
/// Sends a single-turn request — a summary-writer system instruction
/// plus the week's stats serialized as the user message — through the
/// shared [GeminiClient], which handles retries, model fallback, and
/// parsing.
class GeminiWeeklySummaryService implements IWeeklySummaryService {
  final GeminiClient _gemini;

  GeminiWeeklySummaryService({
    required String apiKey,
    String model = 'gemini-2.5-flash',
    Duration retryDelay = const Duration(milliseconds: 800),
    http.Client? client,
  }) : _gemini = GeminiClient(
          apiKey: apiKey,
          model: model,
          retryDelay: retryDelay,
          client: client,
        );

  @override
  Future<String> generateSummary(WeeklySummaryContext context) {
    return _gemini.generateText(
      systemInstruction: _systemInstruction,
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': _buildStatsPrompt(context)},
          ],
        },
      ],
    );
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
}
