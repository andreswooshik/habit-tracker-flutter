import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_insights.dart';
import 'package:habit_tracker_flutter_new/models/streak_data.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/services/services.dart';

final habitInsightsProvider = Provider<HabitInsights>((ref) {
  final habitState = ref.watch(habitsProvider);
  final completionsState = ref.watch(completionsProvider);
  final streakCalculator = ref.watch(streakCalculatorProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  // Extract habits list from state
  final allHabits = habitState.habits;
  final completionsMap = completionsState.completions;

  // Filter active habits only
  final activeHabits = allHabits.where((h) => !h.isArchived).toList();

  if (activeHabits.isEmpty) {
    return HabitInsights.empty();
  }

  // Calculate total completions across all habits
  int totalCompletions = 0;
  for (final habit in activeHabits) {
    totalCompletions += completionsMap[habit.id]?.length ?? 0;
  }

  // Calculate streaks for all habits
  final streaks = <String, StreakData>{};
  for (final habit in activeHabits) {
    final habitCompletions = completionsMap[habit.id] ?? {};
    streaks[habit.id] =
        streakCalculator.calculateStreak(habit, habitCompletions);
  }

  // Find longest current streak
  int longestCurrentStreak = 0;
  String? topStreakHabitName;
  for (final habit in activeHabits) {
    final streak = streaks[habit.id]!.current;
    if (streak > longestCurrentStreak) {
      longestCurrentStreak = streak;
      topStreakHabitName = habit.name;
    }
  }

  // Calculate average streak
  double averageStreak = 0.0;
  if (activeHabits.isNotEmpty) {
    final totalStreak =
        streaks.values.fold(0, (sum, streak) => sum + streak.current);
    averageStreak = totalStreak / activeHabits.length;
  }

  // Find most completed habit
  String? mostCompletedHabitId;
  String? mostCompletedHabitName;
  int mostCompletedCount = 0;
  for (final habit in activeHabits) {
    final count = completionsMap[habit.id]?.length ?? 0;
    if (count > mostCompletedCount) {
      mostCompletedCount = count;
      mostCompletedHabitId = habit.id;
      mostCompletedHabitName = habit.name;
    }
  }

  // Calculate overall completion rate (last 30 days)
  double overallCompletionRate = _calculateOverallCompletionRate(
    activeHabits,
    completionsMap,
    selectedDate,
  );

  // Calculate weekly and monthly consistency
  final weeklyConsistency = _calculateConsistency(
    activeHabits,
    completionsMap,
    selectedDate,
    7,
  );
  final monthlyConsistency = _calculateConsistency(
    activeHabits,
    completionsMap,
    selectedDate,
    30,
  );

  // Identify habits at risk (missed yesterday)
  final habitsAtRisk = _findHabitsAtRisk(
    activeHabits,
    completionsMap,
    selectedDate,
  );

  // Calculate perfect days stats
  final perfectDaysStats = _calculatePerfectDaysStats(
    activeHabits,
    completionsMap,
    selectedDate,
  );

  // Calculate category performance
  final categoryStats = _calculateCategoryPerformance(
    activeHabits,
    completionsMap,
    selectedDate,
  );

  // Count achievements (placeholder for now - will be computed by achievementsProvider)
  int totalAchievements = 0;
  for (final streakData in streaks.values) {
    if (streakData.current >= 7) totalAchievements++;
    if (streakData.current >= 30) totalAchievements++;
    if (streakData.current >= 100) totalAchievements++;
  }

  return HabitInsights(
    totalActiveHabits: activeHabits.length,
    totalCompletions: totalCompletions,
    overallCompletionRate: overallCompletionRate,
    averageStreak: averageStreak,
    longestCurrentStreak: longestCurrentStreak,
    topStreakHabitName: topStreakHabitName,
    weeklyConsistency: weeklyConsistency,
    monthlyConsistency: monthlyConsistency,
    mostCompletedHabitId: mostCompletedHabitId,
    mostCompletedHabitName: mostCompletedHabitName,
    mostCompletedCount: mostCompletedCount,
    totalAchievements: totalAchievements,
    habitsAtRisk: habitsAtRisk,
    perfectDaysCount: perfectDaysStats['total']!,
    currentPerfectStreak: perfectDaysStats['current']!,
    bestCategory: categoryStats['best'],
    worstCategory: categoryStats['worst'],
  );
});

/// Calculates overall completion rate over the last 30 days
double _calculateOverallCompletionRate(
  List<Habit> habits,
  Map<String, Set<DateTime>> completions,
  DateTime referenceDate,
) {
  if (habits.isEmpty) return 0.0;

  final endDate =
      DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
  final startDate = endDate.subtract(const Duration(days: 30));

  int totalScheduled = 0;
  int totalCompleted = 0;

  for (final habit in habits) {
    for (var date = startDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(const Duration(days: 1))) {
      if (habit.isScheduledFor(date)) {
        totalScheduled++;
        final normalizedDate = DateTime(date.year, date.month, date.day);
        if (completions[habit.id]?.contains(normalizedDate) ?? false) {
          totalCompleted++;
        }
      }
    }
  }

  return totalScheduled > 0 ? totalCompleted / totalScheduled : 0.0;
}

/// Calculates consistency percentage over the specified number of days
double _calculateConsistency(
  List<Habit> habits,
  Map<String, Set<DateTime>> completions,
  DateTime referenceDate,
  int days,
) {
  if (habits.isEmpty) return 0.0;

  final endDate =
      DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
  final startDate = endDate.subtract(Duration(days: days - 1));

  int totalScheduled = 0;
  int totalCompleted = 0;

  for (final habit in habits) {
    for (var date = startDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(const Duration(days: 1))) {
      if (habit.isScheduledFor(date)) {
        totalScheduled++;
        final normalizedDate = DateTime(date.year, date.month, date.day);
        if (completions[habit.id]?.contains(normalizedDate) ?? false) {
          totalCompleted++;
        }
      }
    }
  }

  return totalScheduled > 0 ? totalCompleted / totalScheduled : 0.0;
}

/// Finds habits that were scheduled yesterday but not completed
List<String> _findHabitsAtRisk(
  List<Habit> habits,
  Map<String, Set<DateTime>> completions,
  DateTime referenceDate,
) {
  final yesterday = DateTime(
    referenceDate.year,
    referenceDate.month,
    referenceDate.day,
  ).subtract(const Duration(days: 1));

  final atRisk = <String>[];
  for (final habit in habits) {
    if (habit.isScheduledFor(yesterday)) {
      final normalizedYesterday =
          DateTime(yesterday.year, yesterday.month, yesterday.day);
      if (!(completions[habit.id]?.contains(normalizedYesterday) ?? false)) {
        atRisk.add(habit.id);
      }
    }
  }

  return atRisk;
}

/// Calculates perfect days statistics
/// Returns map with 'total' and 'current' perfect day counts
Map<String, int> _calculatePerfectDaysStats(
  List<Habit> habits,
  Map<String, Set<DateTime>> completions,
  DateTime referenceDate,
) {
  if (habits.isEmpty) {
    return {'total': 0, 'current': 0};
  }

  final today =
      DateTime(referenceDate.year, referenceDate.month, referenceDate.day);

  // Count total perfect days in last 90 days
  final startDate = today.subtract(const Duration(days: 90));
  int totalPerfectDays = 0;

  for (var date = startDate;
      date.isBefore(today) || date.isAtSameMomentAs(today);
      date = date.add(const Duration(days: 1))) {
    bool isPerfectDay = true;
    for (final habit in habits) {
      if (habit.isScheduledFor(date)) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        if (!(completions[habit.id]?.contains(normalizedDate) ?? false)) {
          isPerfectDay = false;
          break;
        }
      }
    }
    if (isPerfectDay) {
      totalPerfectDays++;
    }
  }

  // Calculate current consecutive perfect days
  int currentPerfectStreak = 0;
  for (var date = today;
      date.isAfter(startDate);
      date = date.subtract(const Duration(days: 1))) {
    bool isPerfectDay = true;
    for (final habit in habits) {
      if (habit.isScheduledFor(date)) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        if (!(completions[habit.id]?.contains(normalizedDate) ?? false)) {
          isPerfectDay = false;
          break;
        }
      }
    }
    if (isPerfectDay) {
      currentPerfectStreak++;
    } else {
      break;
    }
  }

  return {
    'total': totalPerfectDays,
    'current': currentPerfectStreak,
  };
}

/// Calculates performance by category
/// Returns map with 'best' and 'worst' category names
Map<String, String?> _calculateCategoryPerformance(
  List<Habit> habits,
  Map<String, Set<DateTime>> completions,
  DateTime referenceDate,
) {
  if (habits.isEmpty) {
    return {'best': null, 'worst': null};
  }

  final categoryRates = <HabitCategory, double>{};
  final categoryCounts = <HabitCategory, int>{};

  final endDate =
      DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
  final startDate = endDate.subtract(const Duration(days: 30));

  // Calculate completion rate for each category
  for (final category in HabitCategory.values) {
    final categoryHabits = habits.where((h) => h.category == category).toList();
    if (categoryHabits.isEmpty) continue;

    int scheduled = 0;
    int completed = 0;

    for (final habit in categoryHabits) {
      for (var date = startDate;
          date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
          date = date.add(const Duration(days: 1))) {
        if (habit.isScheduledFor(date)) {
          scheduled++;
          final normalizedDate = DateTime(date.year, date.month, date.day);
          if (completions[habit.id]?.contains(normalizedDate) ?? false) {
            completed++;
          }
        }
      }
    }

    if (scheduled > 0) {
      categoryRates[category] = completed / scheduled;
      categoryCounts[category] = categoryHabits.length;
    }
  }

  if (categoryRates.isEmpty) {
    return {'best': null, 'worst': null};
  }

  // Find best and worst categories
  HabitCategory? bestCategory;
  double bestRate = 0.0;
  HabitCategory? worstCategory;
  double worstRate = 1.0;

  for (final entry in categoryRates.entries) {
    if (entry.value > bestRate) {
      bestRate = entry.value;
      bestCategory = entry.key;
    }
    if (entry.value < worstRate) {
      worstRate = entry.value;
      worstCategory = entry.key;
    }
  }

  return {
    'best': bestCategory?.displayName,
    'worst': worstCategory?.displayName,
  };
}

final habitInsightsForHabitProvider =
    Provider.family<HabitInsights, String>((ref, habitId) {
  final habitState = ref.watch(habitsProvider);
  final completionsState = ref.watch(completionsProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  // Find the specific habit
  final habit = habitState.habits.firstWhere(
    (h) => h.id == habitId,
    orElse: () => throw Exception('Habit not found'),
  );

  // Get completions for this habit
  final habitCompletions = completionsState.completions[habitId] ?? {};

  // For a single habit, most insights values are simplified
  return HabitInsights(
    totalActiveHabits: 1,
    totalCompletions: habitCompletions.length,
    overallCompletionRate: _calculateOverallCompletionRate(
      [habit],
      {habitId: habitCompletions},
      selectedDate,
    ),
    averageStreak: 0.0,
    longestCurrentStreak: 0,
    topStreakHabitName: habit.name,
    weeklyConsistency: _calculateConsistency(
      [habit],
      {habitId: habitCompletions},
      selectedDate,
      7,
    ),
    monthlyConsistency: _calculateConsistency(
      [habit],
      {habitId: habitCompletions},
      selectedDate,
      30,
    ),
    mostCompletedHabitId: habitId,
    mostCompletedHabitName: habit.name,
    mostCompletedCount: habitCompletions.length,
    totalAchievements: 0,
    habitsAtRisk: [],
    perfectDaysCount: habitCompletions.length,
    currentPerfectStreak: 0,
    bestCategory: habit.category.displayName,
    worstCategory: null,
  );
});
