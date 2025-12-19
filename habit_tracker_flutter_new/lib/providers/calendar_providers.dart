/// Calendar-specific computed providers for heatmap and date range queries.
///
/// These providers use AutoDispose to efficiently manage memory for
/// monthly calendar data that changes frequently.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import 'providers.dart';

/// Family provider that generates monthly calendar heatmap data for a specific habit.
///
/// Parameters:
/// - habitId: The ID of the habit
/// - year: The year (e.g., 2024)
/// - month: The month (1-12)
///
/// Returns a Map<DateTime, int> where:
/// - Key: Date (normalized to midnight)
/// - Value: Completion count for that date (0 or 1 for single completions)
///
/// Uses AutoDispose to automatically clean up when no longer watched,
/// since calendar data changes frequently as users navigate months.
///
/// Example usage:
/// ```dart
/// // Show January 2024 calendar for habit
/// final calendarData = ref.watch(
///   calendarDataProvider((
///     habitId: 'abc',
///     year: 2024,
///     month: 1,
///   ))
/// );
///
/// // Build heatmap
/// for (final entry in calendarData.entries) {
///   final date = entry.key;
///   final isCompleted = entry.value > 0;
///   CalendarCell(date: date, isCompleted: isCompleted);
/// }
/// ```
///
/// Performance: Automatically disposed when month changes, preventing memory leaks.
final calendarDataProvider = Provider.autoDispose.family<
    Map<DateTime, int>,
    ({String habitId, int year, int month})>((ref, params) {
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

/// Family provider that returns completion dates for a habit in a date range.
///
/// Parameters:
/// - habitId: The ID of the habit
/// - startDate: Start of date range (inclusive)
/// - endDate: End of date range (inclusive)
///
/// Returns a Set<DateTime> of all dates the habit was completed within the range.
/// All dates are normalized to midnight.
///
/// Example usage:
/// ```dart
/// // Get last 30 days of completions
/// final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
/// final today = DateTime.now();
///
/// final completions = ref.watch(
///   habitCompletionsInRangeProvider((
///     habitId: 'abc',
///     startDate: thirtyDaysAgo,
///     endDate: today,
///   ))
/// );
///
/// print('Completed ${completions.length} times in last 30 days');
/// ```
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

/// Provider that returns the number of habits scheduled for a given date.
///
/// Uses AutoDispose as it's typically used for date-specific queries
/// that change frequently.
///
/// Example usage:
/// ```dart
/// final count = ref.watch(
///   habitsScheduledCountProvider(DateTime(2024, 1, 15))
/// );
/// Text('$count habits scheduled');
/// ```
final habitsScheduledCountProvider =
    Provider.autoDispose.family<int, DateTime>((ref, date) {
  final habitState = ref.watch(habitsProvider);

  return habitState.habits
      .where((habit) => !habit.isArchived && habit.isScheduledFor(date))
      .length;
});

/// Provider that returns all habits scheduled for a given date.
///
/// Similar to todaysHabitsProvider but for any date, not just selected date.
/// Uses AutoDispose for efficiency.
///
/// Example usage:
/// ```dart
/// final habits = ref.watch(
///   habitsForDateProvider(DateTime(2024, 1, 15))
/// );
/// for (final habit in habits) {
///   print(habit.name);
/// }
/// ```
final habitsForDateProvider =
    Provider.autoDispose.family<List<Habit>, DateTime>((ref, date) {
  final habitState = ref.watch(habitsProvider);

  return habitState.habits
      .where((habit) => !habit.isArchived && habit.isScheduledFor(date))
      .toList();
});

/// Provider that calculates completion rate for a habit over a date range.
///
/// Parameters:
/// - habitId: The ID of the habit
/// - startDate: Start of date range
/// - endDate: End of date range
///
/// Returns a value between 0.0 and 1.0 representing the completion rate.
/// Only counts days when the habit was scheduled (respects frequency).
///
/// Returns 0.0 if no scheduled days in range.
///
/// Example usage:
/// ```dart
/// final rate = ref.watch(
///   completionRateProvider((
///     habitId: 'abc',
///     startDate: thirtyDaysAgo,
///     endDate: today,
///   ))
/// );
/// Text('${(rate * 100).toInt()}% completion rate');
/// ```
final completionRateProvider = Provider.autoDispose.family<double,
    ({String habitId, DateTime startDate, DateTime endDate})>((ref, params) {
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

/// Provider that returns the current month and year for calendar navigation.
///
/// This is a simple state provider that can be used to track which
/// month is currently being viewed in a calendar widget.
///
/// Example usage:
/// ```dart
/// final currentMonth = ref.watch(calendarMonthProvider);
/// Text('${currentMonth.year}-${currentMonth.month}');
///
/// // Navigate to next month
/// ref.read(calendarMonthProvider.notifier).state =
///   DateTime(currentMonth.year, currentMonth.month + 1);
/// ```
final calendarMonthProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});
