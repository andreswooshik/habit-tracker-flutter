/// Per-habit statistics for one week
///
/// Plain value object assembled by the caller so summary services
/// stay decoupled from providers and repositories (DIP), mirroring
/// [ChatCoachContext].
class HabitWeekStats {
  /// Display name of the habit
  final String name;

  /// How many days this habit was scheduled during the week
  final int scheduledCount;

  /// How many of those scheduled days were completed
  final int completedCount;

  const HabitWeekStats({
    required this.name,
    required this.scheduledCount,
    required this.completedCount,
  });

  /// Fraction of scheduled days completed (0.0 when nothing scheduled)
  double get completionRate =>
      scheduledCount > 0 ? completedCount / scheduledCount : 0.0;
}

/// Completions on a single day of the week
class DayWeekStats {
  final DateTime date;

  /// Habits scheduled on this day
  final int scheduledCount;

  /// Habits completed on this day
  final int completedCount;

  const DayWeekStats({
    required this.date,
    required this.scheduledCount,
    required this.completedCount,
  });
}

/// Snapshot of one week of habit activity handed to a summary service
class WeeklySummaryContext {
  /// First day of the summarized week (inclusive)
  final DateTime weekStart;

  /// Last day of the summarized week (inclusive)
  final DateTime weekEnd;

  /// Stats for each active habit, in no particular order
  final List<HabitWeekStats> habitStats;

  /// Stats for each day of the week, oldest first
  final List<DayWeekStats> dayStats;

  /// The best current streak across all habits (in days)
  final int bestCurrentStreak;

  /// Name of the habit holding the best current streak, if any
  final String? bestStreakHabitName;

  const WeeklySummaryContext({
    required this.weekStart,
    required this.weekEnd,
    required this.habitStats,
    required this.dayStats,
    required this.bestCurrentStreak,
    this.bestStreakHabitName,
  });

  /// Total scheduled habit-days across the week
  int get totalScheduled =>
      habitStats.fold(0, (sum, h) => sum + h.scheduledCount);

  /// Total completed habit-days across the week
  int get totalCompleted =>
      habitStats.fold(0, (sum, h) => sum + h.completedCount);

  /// Overall completion rate for the week (0.0 when nothing scheduled)
  double get completionRate =>
      totalScheduled > 0 ? totalCompleted / totalScheduled : 0.0;

  /// Whether there was any habit activity to summarize
  bool get isEmpty => habitStats.isEmpty || totalScheduled == 0;
}

/// Interface for a service that writes a short narrative summary of
/// the user's week
///
/// Abstraction allows swapping the local rule-based generator for an
/// LLM-backed implementation without touching UI or state code.
abstract class IWeeklySummaryService {
  /// Generates a few sentences summarizing the week in [context]
  Future<String> generateSummary(WeeklySummaryContext context);
}
