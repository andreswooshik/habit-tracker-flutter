import 'package:equatable/equatable.dart';

/// Immutable value object containing aggregated statistics and insights
/// across all habits
class HabitInsights extends Equatable {
  /// Total number of active habits
  final int totalActiveHabits;

  /// Total number of completions across all habits
  final int totalCompletions;

  /// Overall completion rate (0.0 to 1.0)
  final double overallCompletionRate;

  /// Average streak across all active habits
  final double averageStreak;

  /// Longest current streak among all habits
  final int longestCurrentStreak;

  /// Name of habit with longest current streak
  final String? topStreakHabitName;

  /// 7-day consistency score (0.0 to 1.0)
  final double weeklyConsistency;

  /// 30-day consistency score (0.0 to 1.0)
  final double monthlyConsistency;

  /// Most completed habit ID
  final String? mostCompletedHabitId;

  /// Most completed habit name
  final String? mostCompletedHabitName;

  /// Number of completions for most completed habit
  final int mostCompletedCount;

  /// Total number of achievements unlocked
  final int totalAchievements;

  /// List of habit IDs that are at risk (missed yesterday)
  final List<String> habitsAtRisk;

  /// Number of perfect days (all habits completed)
  final int perfectDaysCount;

  /// Current consecutive perfect days
  final int currentPerfectStreak;

  /// Best performing category (by completion rate)
  final String? bestCategory;

  /// Worst performing category (by completion rate)
  final String? worstCategory;

  const HabitInsights({
    required this.totalActiveHabits,
    required this.totalCompletions,
    required this.overallCompletionRate,
    required this.averageStreak,
    required this.longestCurrentStreak,
    this.topStreakHabitName,
    required this.weeklyConsistency,
    required this.monthlyConsistency,
    this.mostCompletedHabitId,
    this.mostCompletedHabitName,
    required this.mostCompletedCount,
    required this.totalAchievements,
    required this.habitsAtRisk,
    required this.perfectDaysCount,
    required this.currentPerfectStreak,
    this.bestCategory,
    this.worstCategory,
  });

  /// Factory constructor for empty insights
  factory HabitInsights.empty() {
    return const HabitInsights(
      totalActiveHabits: 0,
      totalCompletions: 0,
      overallCompletionRate: 0.0,
      averageStreak: 0.0,
      longestCurrentStreak: 0,
      topStreakHabitName: null,
      weeklyConsistency: 0.0,
      monthlyConsistency: 0.0,
      mostCompletedHabitId: null,
      mostCompletedHabitName: null,
      mostCompletedCount: 0,
      totalAchievements: 0,
      habitsAtRisk: [],
      perfectDaysCount: 0,
      currentPerfectStreak: 0,
      bestCategory: null,
      worstCategory: null,
    );
  }

  /// Whether there are any active habits
  bool get hasHabits => totalActiveHabits > 0;

  /// Whether overall performance is good (>70%)
  bool get isPerformingWell => overallCompletionRate >= 0.7;

  /// Whether weekly consistency is strong (>80%)
  bool get hasStrongWeeklyConsistency => weeklyConsistency >= 0.8;

  /// Whether there are habits needing attention
  bool get hasHabitsAtRisk => habitsAtRisk.isNotEmpty;

  /// Percentage of habits at risk
  double get atRiskPercentage {
    if (totalActiveHabits == 0) return 0.0;
    return habitsAtRisk.length / totalActiveHabits;
  }

  /// Returns a motivational message based on overall performance
  String get motivationalMessage {
    if (!hasHabits) {
      return 'Create your first habit to get started!';
    }

    if (overallCompletionRate >= 0.9) {
      return '🌟 Outstanding! You\'re crushing it!';
    } else if (overallCompletionRate >= 0.7) {
      return '💪 Great job! Keep up the momentum!';
    } else if (overallCompletionRate >= 0.5) {
      return '👍 You\'re making progress! Stay consistent!';
    } else {
      return '🎯 Every day is a new opportunity!';
    }
  }

  /// Returns performance grade (A+, A, B, C, D, F)
  String get performanceGrade {
    if (overallCompletionRate >= 0.97) return 'A+';
    if (overallCompletionRate >= 0.9) return 'A';
    if (overallCompletionRate >= 0.8) return 'B';
    if (overallCompletionRate >= 0.7) return 'C';
    if (overallCompletionRate >= 0.6) return 'D';
    return 'F';
  }

  /// Compares two time periods (e.g., this week vs last week)
  /// Returns positive number if improving, negative if declining
  double compareConsistency(double previousPeriod, double currentPeriod) {
    return currentPeriod - previousPeriod;
  }

  /// Whether consistency is improving
  bool get isImproving {
    // Compare weekly vs monthly consistency
    return weeklyConsistency > monthlyConsistency;
  }

  /// Average completions per day
  double get averageCompletionsPerDay {
    if (totalActiveHabits == 0) return 0.0;
    return totalCompletions / 30; // Based on 30-day window
  }

  /// Completion rate as percentage string
  String get completionRatePercentage {
    return '${(overallCompletionRate * 100).toStringAsFixed(1)}%';
  }

  /// Weekly consistency as percentage string
  String get weeklyConsistencyPercentage {
    return '${(weeklyConsistency * 100).toStringAsFixed(1)}%';
  }

  /// Monthly consistency as percentage string
  String get monthlyConsistencyPercentage {
    return '${(monthlyConsistency * 100).toStringAsFixed(1)}%';
  }

  /// Creates a copy of this insights object with updated fields
  HabitInsights copyWith({
    int? totalActiveHabits,
    int? totalCompletions,
    double? overallCompletionRate,
    double? averageStreak,
    int? longestCurrentStreak,
    String? topStreakHabitName,
    double? weeklyConsistency,
    double? monthlyConsistency,
    String? mostCompletedHabitId,
    String? mostCompletedHabitName,
    int? mostCompletedCount,
    int? totalAchievements,
    List<String>? habitsAtRisk,
    int? perfectDaysCount,
    int? currentPerfectStreak,
    String? bestCategory,
    String? worstCategory,
  }) {
    return HabitInsights(
      totalActiveHabits: totalActiveHabits ?? this.totalActiveHabits,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      overallCompletionRate: overallCompletionRate ?? this.overallCompletionRate,
      averageStreak: averageStreak ?? this.averageStreak,
      longestCurrentStreak: longestCurrentStreak ?? this.longestCurrentStreak,
      topStreakHabitName: topStreakHabitName ?? this.topStreakHabitName,
      weeklyConsistency: weeklyConsistency ?? this.weeklyConsistency,
      monthlyConsistency: monthlyConsistency ?? this.monthlyConsistency,
      mostCompletedHabitId: mostCompletedHabitId ?? this.mostCompletedHabitId,
      mostCompletedHabitName: mostCompletedHabitName ?? this.mostCompletedHabitName,
      mostCompletedCount: mostCompletedCount ?? this.mostCompletedCount,
      totalAchievements: totalAchievements ?? this.totalAchievements,
      habitsAtRisk: habitsAtRisk ?? this.habitsAtRisk,
      perfectDaysCount: perfectDaysCount ?? this.perfectDaysCount,
      currentPerfectStreak: currentPerfectStreak ?? this.currentPerfectStreak,
      bestCategory: bestCategory ?? this.bestCategory,
      worstCategory: worstCategory ?? this.worstCategory,
    );
  }

  @override
  List<Object?> get props => [
        totalActiveHabits,
        totalCompletions,
        overallCompletionRate,
        averageStreak,
        longestCurrentStreak,
        topStreakHabitName,
        weeklyConsistency,
        monthlyConsistency,
        mostCompletedHabitId,
        mostCompletedHabitName,
        mostCompletedCount,
        totalAchievements,
        habitsAtRisk,
        perfectDaysCount,
        currentPerfectStreak,
        bestCategory,
        worstCategory,
      ];

  @override
  String toString() {
    return 'HabitInsights(habits: $totalActiveHabits, '
        'completionRate: $completionRatePercentage, '
        'weeklyConsistency: $weeklyConsistencyPercentage, '
        'longestStreak: $longestCurrentStreak)';
  }
}
