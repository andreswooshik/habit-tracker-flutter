import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/achievement.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/services/services.dart';

/// **Phase 5: Achievements & Consistency Providers**
///
/// Provides achievement tracking and consistency metrics.

/// Generates all unlocked achievements based on current streaks
///
/// Returns a list of Achievement objects for all habits with unlocked milestones.
/// Achievements are determined by the current streak count.
///
/// Example:
/// ```dart
/// final achievements = ref.watch(achievementsProvider);
/// final unseenCount = achievements.where((a) => !a.isSeen).length;
/// print('New achievements: $unseenCount');
/// ```
final achievementsProvider = Provider<List<Achievement>>((ref) {
  final habitState = ref.watch(habitsProvider);
  final completionsState = ref.watch(completionsProvider);
  final streakCalculator = ref.watch(streakCalculatorProvider);

  final activeHabits = habitState.habits.where((h) => !h.isArchived).toList();
  final completionsMap = completionsState.completions;

  final achievements = <Achievement>[];
  
  for (final habit in activeHabits) {
    final habitCompletions = completionsMap[habit.id] ?? {};
    final streakData = streakCalculator.calculateStreak(habit, habitCompletions);
    
    // Get all achievement types that should be unlocked for this streak
    final unlockedTypes = Achievement.getUnlockedTypes(streakData.current);
    
    // Create achievement instances for each unlocked type
    for (final type in unlockedTypes) {
      final achievementId = '${habit.id}_${type.name}';
      achievements.add(
        Achievement.fromStreak(
          id: achievementId,
          type: type,
          habitId: habit.id,
          habitName: habit.name,
          streakCount: streakData.current,
        ),
      );
    }
  }

  // Sort by unlock date (most recent first)
  achievements.sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));

  return achievements;
});

/// Provides achievements for a specific habit
///
/// Returns all unlocked achievements for the given habit ID.
///
/// Example:
/// ```dart
/// final habitAchievements = ref.watch(habitAchievementsProvider('habit123'));
/// ```
final habitAchievementsProvider = Provider.family<List<Achievement>, String>((ref, habitId) {
  final allAchievements = ref.watch(achievementsProvider);
  return allAchievements.where((a) => a.habitId == habitId).toList();
});

/// Provides count of unseen achievements
///
/// Useful for displaying notification badges.
///
/// Example:
/// ```dart
/// final unseenCount = ref.watch(unseenAchievementsCountProvider);
/// if (unseenCount > 0) {
///   showBadge(unseenCount);
/// }
/// ```
final unseenAchievementsCountProvider = Provider<int>((ref) {
  final achievements = ref.watch(achievementsProvider);
  return achievements.where((a) => !a.isSeen).length;
});

/// Provides recent achievements (last 7 days)
///
/// Returns achievements unlocked within the past week.
///
/// Example:
/// ```dart
/// final recent = ref.watch(recentAchievementsProvider);
/// ```
final recentAchievementsProvider = Provider<List<Achievement>>((ref) {
  final achievements = ref.watch(achievementsProvider);
  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  
  return achievements
      .where((a) => a.unlockedAt.isAfter(weekAgo))
      .toList();
});

/// Calculates 7-day rolling consistency for each active habit
///
/// Returns a map of habit ID to consistency percentage (0.0 to 1.0).
/// Consistency is calculated as: (completions in last 7 days) / (scheduled days in last 7 days)
///
/// Example:
/// ```dart
/// final consistency = ref.watch(weeklyConsistencyProvider);
/// final habitConsistency = consistency['habit123'] ?? 0.0;
/// print('Habit consistency: ${(habitConsistency * 100).toStringAsFixed(1)}%');
/// ```
final weeklyConsistencyProvider = Provider<Map<String, double>>((ref) {
  final habitState = ref.watch(habitsProvider);
  final completionsState = ref.watch(completionsProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  final activeHabits = habitState.habits.where((h) => !h.isArchived).toList();
  final completionsMap = completionsState.completions;

  final consistency = <String, double>{};

  final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  final weekAgo = today.subtract(const Duration(days: 6)); // 7 days total including today

  for (final habit in activeHabits) {
    int scheduledDays = 0;
    int completedDays = 0;

    for (var date = weekAgo; 
         date.isBefore(today) || date.isAtSameMomentAs(today); 
         date = date.add(const Duration(days: 1))) {
      if (habit.isScheduledFor(date)) {
        scheduledDays++;
        final normalizedDate = DateTime(date.year, date.month, date.day);
        if (completionsMap[habit.id]?.contains(normalizedDate) ?? false) {
          completedDays++;
        }
      }
    }

    consistency[habit.id] = scheduledDays > 0 
        ? completedDays / scheduledDays 
        : 0.0;
  }

  return consistency;
});

/// Provides consistency for a specific habit
///
/// Returns the 7-day rolling consistency for the given habit ID.
///
/// Example:
/// ```dart
/// final consistency = ref.watch(habitConsistencyProvider('habit123'));
/// ```
final habitConsistencyProvider = Provider.family<double, String>((ref, habitId) {
  final allConsistency = ref.watch(weeklyConsistencyProvider);
  return allConsistency[habitId] ?? 0.0;
});

/// Provides habits grouped by consistency level
///
/// Returns a map with three keys:
/// - 'high': >= 80% consistency
/// - 'medium': 50-79% consistency
/// - 'low': < 50% consistency
///
/// Example:
/// ```dart
/// final grouped = ref.watch(habitsByConsistencyProvider);
/// final struggling = grouped['low'] ?? [];
/// ```
final habitsByConsistencyProvider = Provider<Map<String, List<Habit>>>((ref) {
  final habitState = ref.watch(habitsProvider);
  final consistency = ref.watch(weeklyConsistencyProvider);

  final activeHabits = habitState.habits.where((h) => !h.isArchived).toList();

  final high = <Habit>[];
  final medium = <Habit>[];
  final low = <Habit>[];

  for (final habit in activeHabits) {
    final rate = consistency[habit.id] ?? 0.0;
    if (rate >= 0.8) {
      high.add(habit);
    } else if (rate >= 0.5) {
      medium.add(habit);
    } else {
      low.add(habit);
    }
  }

  return {
    'high': high,
    'medium': medium,
    'low': low,
  };
});

/// Provides average consistency across all habits
///
/// Returns the mean 7-day consistency percentage.
///
/// Example:
/// ```dart
/// final avgConsistency = ref.watch(averageConsistencyProvider);
/// print('Overall: ${(avgConsistency * 100).toStringAsFixed(1)}%');
/// ```
final averageConsistencyProvider = Provider<double>((ref) {
  final consistency = ref.watch(weeklyConsistencyProvider);
  
  if (consistency.isEmpty) return 0.0;
  
  final total = consistency.values.reduce((a, b) => a + b);
  return total / consistency.length;
});
