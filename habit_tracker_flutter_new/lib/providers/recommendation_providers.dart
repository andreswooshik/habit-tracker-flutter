import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_keys.dart';
import '../models/habit_category.dart';
import '../models/habit_recommendation.dart';
import '../models/recommendations_state.dart';
import '../services/gemini_recommendation_service.dart';
import '../services/local_recommendation_service.dart';
import '../services/interfaces/i_recommendation_service.dart';
import 'providers.dart';

/// Provider for the recommendation service implementation
///
/// Uses the Gemini LLM when an API key is provided (see
/// lib/config/api_keys.dart), and falls back to the offline
/// catalog-based generator otherwise (Dependency Inversion — the
/// notifier and UI never know which one they're talking to).
final recommendationServiceProvider = Provider<IRecommendationService>((ref) {
  if (ApiKeys.gemini.isNotEmpty) {
    return GeminiRecommendationService(apiKey: ApiKeys.gemini);
  }
  return const LocalRecommendationService();
});

/// Builds a [RecommendationContext] snapshot from current habit state
///
/// Derived state only — recomputes automatically when habits or
/// completions change.
final recommendationContextProvider = Provider<RecommendationContext>((ref) {
  final habitState = ref.watch(habitsProvider);
  final completions = ref.watch(completionsProvider).completions;

  final activeHabits =
      habitState.habits.where((h) => !h.isArchived).toList();

  final countByCategory = <HabitCategory, int>{};
  for (final habit in activeHabits) {
    countByCategory[habit.category] =
        (countByCategory[habit.category] ?? 0) + 1;
  }

  // Completion rate over the last 7 days (date-only arithmetic so the
  // window stays midnight-aligned across DST transitions)
  final now = DateTime.now();
  final days = [
    for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day - i),
  ];
  var scheduled = 0;
  var completed = 0;
  for (final habit in activeHabits) {
    final habitCompletions = completions[habit.id] ?? {};
    for (final day in days) {
      if (!habit.isScheduledFor(day)) continue;
      scheduled++;
      if (habitCompletions.contains(day)) completed++;
    }
  }

  return RecommendationContext(
    activeHabitNames: activeHabits.map((h) => h.name).toList(),
    habitCountByCategory: countByCategory,
    recentCompletionRate: scheduled > 0 ? completed / scheduled : 0.0,
  );
});

/// StateNotifier managing smart habit recommendations
///
/// Single Responsibility: only owns recommendation state. Suggestion
/// generation is delegated to an [IRecommendationService], and habit
/// data is injected as a [RecommendationContext] snapshot at
/// generation time.
class RecommendationsNotifier extends StateNotifier<RecommendationsState> {
  final IRecommendationService _recommendationService;
  final RecommendationContext Function() _readContext;

  RecommendationsNotifier(this._recommendationService, this._readContext)
      : super(RecommendationsState.initial());

  /// Generates (or regenerates) suggestions for the current habits
  ///
  /// Ignores re-entrant calls while a generation is pending.
  Future<void> generate() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final recommendations =
          await _recommendationService.generateRecommendations(_readContext());

      if (!mounted) return;
      state = state.copyWith(
        recommendations: recommendations,
        isLoading: false,
        hasGenerated: true,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load suggestions. Please try again.',
      );
    }
  }

  /// Removes a suggestion from the list (after the user adds it)
  void dismiss(HabitRecommendation recommendation) {
    state = state.copyWith(
      recommendations:
          state.recommendations.where((r) => r != recommendation).toList(),
    );
  }
}

/// Global provider for the smart recommendations state
final recommendationsProvider =
    StateNotifierProvider<RecommendationsNotifier, RecommendationsState>(
        (ref) {
  final service = ref.watch(recommendationServiceProvider);
  return RecommendationsNotifier(
    service,
    () => ref.read(recommendationContextProvider),
  );
});
