import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_keys.dart';
import '../models/weekly_summary_state.dart';
import '../services/gemini_weekly_summary_service.dart';
import '../services/local_weekly_summary_service.dart';
import '../services/interfaces/i_weekly_summary_service.dart';
import '../services/services.dart';
import 'providers.dart';

/// Provider for the weekly summary service implementation
///
/// Uses the Gemini LLM when an API key is provided (see
/// lib/config/api_keys.dart), and falls back to the offline rule-based
/// generator otherwise (Dependency Inversion — the notifier and UI
/// never know which one they're talking to).
final weeklySummaryServiceProvider = Provider<IWeeklySummaryService>((ref) {
  if (ApiKeys.gemini.isNotEmpty) {
    return GeminiWeeklySummaryService(apiKey: ApiKeys.gemini);
  }
  return const LocalWeeklySummaryService();
});

/// Builds a [WeeklySummaryContext] for the last 7 days ending today
///
/// Derived state only — recomputes automatically when habits,
/// completions, or streaks change.
final weeklySummaryContextProvider = Provider<WeeklySummaryContext>((ref) {
  final habitState = ref.watch(habitsProvider);
  final completions = ref.watch(completionsProvider).completions;

  final now = DateTime.now();
  final weekEnd = DateTime(now.year, now.month, now.day);
  final weekStart = DateTime(weekEnd.year, weekEnd.month, weekEnd.day - 6);
  final days = [
    for (var i = 0; i < 7; i++)
      DateTime(weekStart.year, weekStart.month, weekStart.day + i),
  ];

  final activeHabits =
      habitState.habits.where((h) => !h.isArchived).toList();

  final habitStats = <HabitWeekStats>[];
  for (final habit in activeHabits) {
    final habitCompletions = completions[habit.id] ?? {};
    var scheduled = 0;
    var completed = 0;
    for (final day in days) {
      if (!habit.isScheduledFor(day)) continue;
      scheduled++;
      if (habitCompletions.contains(day)) completed++;
    }
    habitStats.add(HabitWeekStats(
      name: habit.name,
      scheduledCount: scheduled,
      completedCount: completed,
    ));
  }

  final dayStats = <DayWeekStats>[];
  for (final day in days) {
    var scheduled = 0;
    var completed = 0;
    for (final habit in activeHabits) {
      if (!habit.isScheduledFor(day)) continue;
      scheduled++;
      if ((completions[habit.id] ?? {}).contains(day)) completed++;
    }
    dayStats.add(DayWeekStats(
      date: day,
      scheduledCount: scheduled,
      completedCount: completed,
    ));
  }

  final streaks = ref.watch(allStreaksProvider);
  var bestCurrentStreak = 0;
  String? bestStreakHabitName;
  streaks.forEach((habitId, streakData) {
    if (streakData.current > bestCurrentStreak) {
      bestCurrentStreak = streakData.current;
      bestStreakHabitName = habitState.habitsById[habitId]?.name;
    }
  });

  return WeeklySummaryContext(
    weekStart: weekStart,
    weekEnd: weekEnd,
    habitStats: habitStats,
    dayStats: dayStats,
    bestCurrentStreak: bestCurrentStreak,
    bestStreakHabitName: bestStreakHabitName,
  );
});

/// StateNotifier managing the AI weekly summary
///
/// Single Responsibility: only owns summary state. The text generation
/// is delegated to an [IWeeklySummaryService], and habit data is
/// injected as a [WeeklySummaryContext] snapshot at generation time.
class WeeklySummaryNotifier extends StateNotifier<WeeklySummaryState> {
  final IWeeklySummaryService _summaryService;
  final WeeklySummaryContext Function() _readContext;

  WeeklySummaryNotifier(this._summaryService, this._readContext)
      : super(WeeklySummaryState.initial());

  /// Generates (or regenerates) the summary for the current week
  ///
  /// Ignores re-entrant calls while a generation is pending.
  Future<void> generate() async {
    if (state.isGenerating) return;

    state = state.copyWith(isGenerating: true, clearError: true);

    try {
      final summary = await _summaryService.generateSummary(_readContext());

      if (!mounted) return;
      state = state.copyWith(
        summary: summary,
        generatedAt: DateTime.now(),
        isGenerating: false,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isGenerating: false,
        errorMessage: 'Could not generate your summary. Please try again.',
      );
    }
  }
}

/// Global provider for the AI weekly summary state
final weeklySummaryProvider =
    StateNotifierProvider<WeeklySummaryNotifier, WeeklySummaryState>((ref) {
  final service = ref.watch(weeklySummaryServiceProvider);
  return WeeklySummaryNotifier(
    service,
    () => ref.read(weeklySummaryContextProvider),
  );
});
