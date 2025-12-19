library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import 'providers.dart';

final calendarDataProvider = Provider.autoDispose
    .family<Map<DateTime, int>, ({String habitId, int year, int month})>(
        (ref, params) {
  final completionsState = ref.watch(completionsProvider);
  final habitCompletions = completionsState.completions[params.habitId] ?? {};

  // Generate all dates in the month
  final firstDay = DateTime(params.year, params.month, 1);
  final lastDay = DateTime(params.year, params.month + 1, 0);

  final calendarData = <DateTime, int>{};

  // Populate each day in the month
  for (int day = 1; day <= lastDay.day; day++) {
    final date = DateTime(params.year, params.month, day);
    final normalizedDate = _normalizeDate(date);

    // Check if habit was completed on this date
    final completionCount = habitCompletions.contains(normalizedDate) ? 1 : 0;
    calendarData[normalizedDate] = completionCount;
  }

  return calendarData;
});

final habitCompletionsInRangeProvider = Provider.autoDispose.family<
    Set<DateTime>,
    ({String habitId, DateTime startDate, DateTime endDate})>((ref, params) {
  final completionsState = ref.watch(completionsProvider);
  final habitCompletions = completionsState.completions[params.habitId] ?? {};

  final normalizedStart = _normalizeDate(params.startDate);
  final normalizedEnd = _normalizeDate(params.endDate);

  // Filter completions to date range
  return habitCompletions.where((date) {
    return !date.isBefore(normalizedStart) && !date.isAfter(normalizedEnd);
  }).toSet();
});

final habitsScheduledCountProvider =
    Provider.autoDispose.family<int, DateTime>((ref, date) {
  final habitState = ref.watch(habitsProvider);

  return habitState.habits
      .where((habit) => !habit.isArchived && habit.isScheduledFor(date))
      .length;
});

final habitsForDateProvider =
    Provider.autoDispose.family<List<Habit>, DateTime>((ref, date) {
  final habitState = ref.watch(habitsProvider);

  return habitState.habits
      .where((habit) => !habit.isArchived && habit.isScheduledFor(date))
      .toList();
});

final completionRateProvider = Provider.autoDispose
    .family<double, ({String habitId, DateTime startDate, DateTime endDate})>(
        (ref, params) {
  final habitState = ref.watch(habitsProvider);
  final habit = habitState.habitsById[params.habitId];

  if (habit == null) return 0.0;

  final completions = ref.watch(habitCompletionsInRangeProvider(params));

  // Count scheduled days in range
  final normalizedStart = _normalizeDate(params.startDate);
  final normalizedEnd = _normalizeDate(params.endDate);

  int scheduledDays = 0;
  DateTime current = normalizedStart;

  while (!current.isAfter(normalizedEnd)) {
    if (habit.isScheduledFor(current)) {
      scheduledDays++;
    }
    current = current.add(const Duration(days: 1));
  }

  if (scheduledDays == 0) return 0.0;

  return completions.length / scheduledDays;
});

/// Helper function to normalize dates to midnight (remove time component).
DateTime _normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

final calendarMonthProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});
