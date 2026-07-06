import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/habit_category.dart';
import '../models/habit_frequency.dart';
import '../models/habit_recommendation.dart';
import 'gemini_client.dart';
import 'interfaces/i_recommendation_service.dart';

/// LLM-backed implementation of [IRecommendationService] using the
/// Google Gemini API
///
/// Requests structured JSON output (responseMimeType) through the
/// shared [GeminiClient] and parses it defensively: unknown categories
/// or frequencies are coerced to safe defaults, and malformed entries
/// are skipped rather than failing the whole batch.
class GeminiRecommendationService implements IRecommendationService {
  final GeminiClient _gemini;

  GeminiRecommendationService({
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

  static const _systemInstruction =
      'You suggest new habits inside a habit tracker app. Respond ONLY '
      'with a JSON array of exactly 3 objects, each with these keys: '
      '"name" (short imperative habit name, max 40 characters), '
      '"description" (one short sentence), '
      '"category" (one of: health, productivity, fitness, mindfulness, '
      'learning, social, creativity, finance, other), '
      '"frequency" (one of: everyDay, weekdays, weekends), '
      '"reason" (one short sentence explaining why this fits this user). '
      'Never suggest habits the user already has or close variations of '
      'them. Keep suggestions small and achievable.';

  @override
  Future<List<HabitRecommendation>> generateRecommendations(
    RecommendationContext context,
  ) async {
    final text = await _gemini.generateText(
      systemInstruction: _systemInstruction,
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': _buildPrompt(context)},
          ],
        },
      ],
      // A bit more creative than chat/summaries, still grounded
      temperature: 0.9,
      responseMimeType: 'application/json',
    );

    final recommendations = parseRecommendations(text);
    if (recommendations.isEmpty) {
      throw Exception('Gemini returned no usable recommendations');
    }
    return recommendations;
  }

  String _buildPrompt(RecommendationContext context) {
    final buffer = StringBuffer();
    if (context.hasHabits) {
      buffer.writeln('My current habits: '
          '${context.activeHabitNames.join(', ')}');
      final categories = context.habitCountByCategory.entries
          .where((e) => e.value > 0)
          .map((e) => '${e.key.name} (${e.value})')
          .join(', ');
      buffer.writeln('Habits per category: $categories');
      buffer.writeln('My completion rate over the last 7 days: '
          '${(context.recentCompletionRate * 100).round()}%');
    } else {
      buffer.writeln('I have no habits yet — I\'m just getting started.');
    }
    buffer.writeln('Suggest 3 new habits for me.');
    return buffer.toString();
  }

  /// Parses the model's JSON into recommendations, skipping bad entries
  ///
  /// Accepts either a bare array or an object wrapping one (models
  /// sometimes return {"recommendations": [...]}). Static and pure so
  /// it can be unit-tested without a client. Throws [FormatException]
  /// on unparseable JSON.
  static List<HabitRecommendation> parseRecommendations(String text) {
    dynamic decoded = jsonDecode(text);

    if (decoded is Map<String, dynamic>) {
      // Unwrap shapes like {"recommendations": [...]}
      List<dynamic>? wrapped;
      for (final value in decoded.values) {
        if (value is List<dynamic>) {
          wrapped = value;
          break;
        }
      }
      decoded = wrapped;
    }
    if (decoded is! List<dynamic>) return const [];

    final recommendations = <HabitRecommendation>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final name = (item['name'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;

      recommendations.add(HabitRecommendation(
        name: name,
        description: (item['description'] as String?)?.trim() ?? '',
        category: _categoryFrom(item['category']),
        frequency: _frequencyFrom(item['frequency']),
        reason: (item['reason'] as String?)?.trim() ?? '',
      ));
      if (recommendations.length == 3) break;
    }
    return recommendations;
  }

  static HabitCategory _categoryFrom(Object? value) {
    if (value is String) {
      for (final category in HabitCategory.values) {
        if (category.name == value) return category;
      }
    }
    return HabitCategory.other;
  }

  /// Custom frequency needs custom days the model can't reliably
  /// provide, so only the simple schedules are accepted
  static HabitFrequency _frequencyFrom(Object? value) {
    const allowed = [
      HabitFrequency.everyDay,
      HabitFrequency.weekdays,
      HabitFrequency.weekends,
    ];
    if (value is String) {
      for (final frequency in allowed) {
        if (frequency.name == value) return frequency;
      }
    }
    return HabitFrequency.everyDay;
  }
}
