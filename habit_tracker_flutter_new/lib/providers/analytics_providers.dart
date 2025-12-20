import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/providers/habits_notifier.dart';
import 'package:habit_tracker_flutter_new/providers/completions_notifier.dart';
import 'package:habit_tracker_flutter_new/services/services.dart';

/// Enum for time range selection
enum TimeRange {
  week('Week', 7),
  month('Month', 30),
  year('Year', 365),
  allTime('All Time', -1);

  final String label;
  final int days; // -1 means all time

  const TimeRange(this.label, this.days);
}

/// Selected time range provider
final selectedTimeRangeProvider = StateProvider<TimeRange>((ref) => TimeRange.month);

/// Date range model based on selected time range
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});

  /// Get all days in the range
  List<DateTime> get days {
    final daysList = <DateTime>[];
    var current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      daysList.add(current);
      current = current.add(const Duration(days: 1));
    }
    return daysList;
  }

  int get dayCount => days.length;
}

/// Effective date range provider based on selected time range
final effectiveDateRangeProvider = Provider<DateRange>((ref) {
  final timeRange = ref.watch(selectedTimeRangeProvider);
  final now = DateTime.now();
  
  DateTime start;
  final end = DateTime(now.year, now.month, now.day);
  
  if (timeRange == TimeRange.allTime) {
    // Get the earliest habit creation date
    final habits = ref.watch(habitsProvider).habits;
    if (habits.isEmpty) {
      start = end.subtract(const Duration(days: 30));
    } else {
      start = habits
          .map((h) => h.createdAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
    }
  } else {
    start = end.subtract(Duration(days: timeRange.days - 1));
  }
  
  return DateRange(start: start, end: end);
});

/// Category performance data
class CategoryPerformance {
  final String categoryName;
  final int totalHabits;
  final int totalScheduled;
  final int totalCompleted;
  final double completionRate;

  CategoryPerformance({
    required this.categoryName,
    required this.totalHabits,
    required this.totalScheduled,
    required this.totalCompleted,
  }) : completionRate = totalScheduled > 0 ? totalCompleted / totalScheduled : 0.0;
}

/// Category performance provider
final categoryPerformanceProvider = Provider<List<CategoryPerformance>>((ref) {
  final habits = ref.watch(habitsProvider).habits;
  final completions = ref.watch(completionsProvider).completions;
  final dateRange = ref.watch(effectiveDateRangeProvider);

  final categoryMap = <String, CategoryPerformance>{};

  for (final habit in habits) {
    final category = habit.category.displayName;
    
    int totalScheduled = 0;
    int totalCompleted = 0;

    for (final date in dateRange.days) {
      if (habit.isScheduledFor(date)) {
        totalScheduled++;
        final habitCompletions = completions[habit.id] ?? {};
        if (habitCompletions.contains(DateTime(date.year, date.month, date.day))) {
          totalCompleted++;
        }
      }
    }

    if (categoryMap.containsKey(category)) {
      final existing = categoryMap[category]!;
      categoryMap[category] = CategoryPerformance(
        categoryName: category,
        totalHabits: existing.totalHabits + 1,
        totalScheduled: existing.totalScheduled + totalScheduled,
        totalCompleted: existing.totalCompleted + totalCompleted,
      );
    } else {
      categoryMap[category] = CategoryPerformance(
        categoryName: category,
        totalHabits: 1,
        totalScheduled: totalScheduled,
        totalCompleted: totalCompleted,
      );
    }
  }

  // Sort by completion rate descending
  final list = categoryMap.values.toList()
    ..sort((a, b) => b.completionRate.compareTo(a.completionRate));

  return list;
});

/// Weekday performance data
class DayPerformance {
  final int weekday; // 1=Monday, 7=Sunday
  final int totalScheduled;
  final int totalCompleted;
  final double completionRate;

  DayPerformance({
    required this.weekday,
    required this.totalScheduled,
    required this.totalCompleted,
  }) : completionRate = totalScheduled > 0 ? totalCompleted / totalScheduled : 0.0;

  String get dayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String get fullDayName {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
}

/// Weekday performance provider
final weekdayPerformanceProvider = Provider<List<DayPerformance>>((ref) {
  final habits = ref.watch(habitsProvider).habits;
  final completions = ref.watch(completionsProvider).completions;
  final dateRange = ref.watch(effectiveDateRangeProvider);

  final weekdayMap = <int, DayPerformance>{};

  for (int weekday = 1; weekday <= 7; weekday++) {
    int totalScheduled = 0;
    int totalCompleted = 0;

    for (final date in dateRange.days) {
      if (date.weekday == weekday) {
        for (final habit in habits) {
          if (habit.isScheduledFor(date)) {
            totalScheduled++;
            final habitCompletions = completions[habit.id] ?? {};
            if (habitCompletions.contains(DateTime(date.year, date.month, date.day))) {
              totalCompleted++;
            }
          }
        }
      }
    }

    weekdayMap[weekday] = DayPerformance(
      weekday: weekday,
      totalScheduled: totalScheduled,
      totalCompleted: totalCompleted,
    );
  }

  return List.from(weekdayMap.values);
});

/// Completion trend data (daily completion rates)
final completionTrendProvider = Provider<List<CompletionTrendPoint>>((ref) {
  final habits = ref.watch(habitsProvider).habits;
  final completions = ref.watch(completionsProvider).completions;
  final dateRange = ref.watch(effectiveDateRangeProvider);

  final trendPoints = <CompletionTrendPoint>[];

  for (final date in dateRange.days) {
    int totalScheduled = 0;
    int totalCompleted = 0;

    for (final habit in habits) {
      if (habit.isScheduledFor(date)) {
        totalScheduled++;
        final habitCompletions = completions[habit.id] ?? {};
        if (habitCompletions.contains(DateTime(date.year, date.month, date.day))) {
          totalCompleted++;
        }
      }
    }

    final rate = totalScheduled > 0 ? totalCompleted / totalScheduled : 0.0;
    trendPoints.add(CompletionTrendPoint(
      date: date,
      completionRate: rate,
      totalScheduled: totalScheduled,
      totalCompleted: totalCompleted,
    ));
  }

  return trendPoints;
});

/// Single point in completion trend
class CompletionTrendPoint {
  final DateTime date;
  final double completionRate;
  final int totalScheduled;
  final int totalCompleted;

  CompletionTrendPoint({
    required this.date,
    required this.completionRate,
    required this.totalScheduled,
    required this.totalCompleted,
  });
}

/// Streak leaderboard data
class HabitStreak {
  final Habit habit;
  final int currentStreak;
  final int longestStreak;

  HabitStreak({
    required this.habit,
    required this.currentStreak,
    required this.longestStreak,
  });
}

/// Streak leaderboard provider (top 5 active streaks)
final streakLeaderboardProvider = Provider<List<HabitStreak>>((ref) {
  final habits = ref.watch(habitsProvider).habits;
  final completions = ref.watch(completionsProvider).completions;
  final streakCalculator = ref.watch(streakCalculatorProvider);

  final streaks = <HabitStreak>[];

  for (final habit in habits) {
    if (habit.isArchived) continue; // Skip archived habits
    
    final habitCompletions = completions[habit.id] ?? {};
    
    // Use the proper streak calculator service for consistency
    final streakData = streakCalculator.calculateStreak(habit, habitCompletions);
    
    streaks.add(HabitStreak(
      habit: habit,
      currentStreak: streakData.current,
      longestStreak: streakData.longest,
    ));
  }

  // Sort by current streak descending and take top 5
  streaks.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
  return streaks.take(5).toList();
});
