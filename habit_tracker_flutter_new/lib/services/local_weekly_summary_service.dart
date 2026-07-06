import 'interfaces/i_weekly_summary_service.dart';

/// Local, rule-based implementation of [IWeeklySummaryService]
///
/// Builds a readable weekly recap directly from the stats — fully
/// offline and deterministic. Used when no Gemini API key is
/// configured, mirroring [HabitCoachChatService] for chat.
class LocalWeeklySummaryService implements IWeeklySummaryService {
  const LocalWeeklySummaryService();

  @override
  Future<String> generateSummary(WeeklySummaryContext context) async {
    if (context.isEmpty) {
      return 'No habit activity to summarize this week yet. '
          'Add a habit or check a few off, then come back for your recap!';
    }

    final parts = <String>[
      _overviewSentence(context),
      ..._habitHighlights(context),
      _bestDaySentence(context),
      _streakSentence(context),
      _closingSentence(context.completionRate),
    ];

    return parts.where((s) => s.isNotEmpty).join(' ');
  }

  String _overviewSentence(WeeklySummaryContext context) {
    final percent = (context.completionRate * 100).round();
    return 'This week you completed ${context.totalCompleted} of '
        '${context.totalScheduled} scheduled habits ($percent%).';
  }

  /// Calls out the strongest habit, and the weakest one when it lags
  List<String> _habitHighlights(WeeklySummaryContext context) {
    final ranked = context.habitStats
        .where((h) => h.scheduledCount > 0)
        .toList()
      ..sort((a, b) => b.completionRate.compareTo(a.completionRate));
    if (ranked.isEmpty) return const [];

    final highlights = <String>[];
    final best = ranked.first;
    if (best.completedCount > 0) {
      highlights.add(
        '"${best.name}" led the way with ${best.completedCount} of '
        '${best.scheduledCount} days done.',
      );
    }

    final worst = ranked.last;
    if (ranked.length > 1 && worst.completionRate < 0.5) {
      highlights.add(
        '"${worst.name}" could use some attention '
        '(${worst.completedCount} of ${worst.scheduledCount} days).',
      );
    }
    return highlights;
  }

  String _bestDaySentence(WeeklySummaryContext context) {
    final activeDays = context.dayStats.where((d) => d.completedCount > 0);
    if (activeDays.isEmpty) return '';

    final best = activeDays
        .reduce((a, b) => b.completedCount > a.completedCount ? b : a);
    return 'Your strongest day was ${_weekdayName(best.date.weekday)} '
        'with ${best.completedCount} '
        '${best.completedCount == 1 ? 'completion' : 'completions'}.';
  }

  String _streakSentence(WeeklySummaryContext context) {
    if (context.bestCurrentStreak <= 0) return '';
    final habit = context.bestStreakHabitName;
    return 'You\'re holding a ${context.bestCurrentStreak}-day streak'
        '${habit != null ? ' on "$habit"' : ''} — keep it alive!';
  }

  String _closingSentence(double rate) {
    if (rate >= 0.8) {
      return 'Outstanding week — this is what consistency looks like.';
    }
    if (rate >= 0.5) {
      return 'Solid effort — one or two more check-ins a day would make '
          'next week even better.';
    }
    return 'A fresh week is a fresh start — pick your easiest habit and '
        'build momentum from there.';
  }

  String _weekdayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }
}
