import 'package:flutter_riverpod/flutter_riverpod.dart';

/// StateProvider for the currently selected date in the app
/// 
/// This provider manages the date that the user is currently viewing.
/// By default, it's initialized to today's date with the time normalized
/// to midnight (00:00:00).
/// 
/// This is used throughout the app to determine which date's habits
/// and completions to display.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return _normalizeDate(DateTime.now());
});

/// Normalizes a date by removing the time component
DateTime _normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

/// Extension on WidgetRef to provide convenient date navigation methods
extension DateNavigationExtension on WidgetRef {
  /// Gets the currently selected date
  DateTime get selectedDate => read(selectedDateProvider);

  /// Navigates to today's date
  void goToToday() {
    read(selectedDateProvider.notifier).state = _normalizeDate(DateTime.now());
  }

  /// Navigates to the previous day
  void goToPreviousDay() {
    final current = read(selectedDateProvider);
    read(selectedDateProvider.notifier).state = current.subtract(const Duration(days: 1));
  }

  /// Navigates to the next day
  void goToNextDay() {
    final current = read(selectedDateProvider);
    read(selectedDateProvider.notifier).state = current.add(const Duration(days: 1));
  }

  /// Navigates to a specific date
  void goToDate(DateTime date) {
    read(selectedDateProvider.notifier).state = _normalizeDate(date);
  }

  /// Navigates to the previous week (7 days back)
  void goToPreviousWeek() {
    final current = read(selectedDateProvider);
    read(selectedDateProvider.notifier).state = current.subtract(const Duration(days: 7));
  }

  /// Navigates to the next week (7 days forward)
  void goToNextWeek() {
    final current = read(selectedDateProvider);
    read(selectedDateProvider.notifier).state = current.add(const Duration(days: 7));
  }

  /// Navigates to the previous month
  void goToPreviousMonth() {
    final current = read(selectedDateProvider);
    final newDate = DateTime(
      current.year,
      current.month - 1,
      current.day,
    );
    read(selectedDateProvider.notifier).state = newDate;
  }

  /// Navigates to the next month
  void goToNextMonth() {
    final current = read(selectedDateProvider);
    final newDate = DateTime(
      current.year,
      current.month + 1,
      current.day,
    );
    read(selectedDateProvider.notifier).state = newDate;
  }

  /// Checks if the selected date is today
  bool get isSelectedDateToday {
    final today = _normalizeDate(DateTime.now());
    final selected = read(selectedDateProvider);
    return selected.year == today.year &&
        selected.month == today.month &&
        selected.day == today.day;
  }

  /// Checks if the selected date is in the future
  bool get isSelectedDateInFuture {
    final today = _normalizeDate(DateTime.now());
    final selected = read(selectedDateProvider);
    return selected.isAfter(today);
  }

  /// Checks if the selected date is in the past
  bool get isSelectedDateInPast {
    final today = _normalizeDate(DateTime.now());
    final selected = read(selectedDateProvider);
    return selected.isBefore(today);
  }

  /// Gets the day of week for the selected date (1 = Monday, 7 = Sunday)
  int get selectedDayOfWeek {
    return read(selectedDateProvider).weekday;
  }
}

/// Helper functions for date operations (can be used outside of widgets)
class DateNavigationHelpers {
  /// Normalizes a date by removing the time component
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Checks if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Checks if a date is today
  static bool isToday(DateTime date) {
    final today = normalizeDate(DateTime.now());
    return isSameDay(date, today);
  }

  /// Checks if a date is in the future
  static bool isFuture(DateTime date) {
    final today = normalizeDate(DateTime.now());
    return normalizeDate(date).isAfter(today);
  }

  /// Checks if a date is in the past
  static bool isPast(DateTime date) {
    final today = normalizeDate(DateTime.now());
    return normalizeDate(date).isBefore(today);
  }

  /// Gets the start of the week (Monday) for a given date
  static DateTime getWeekStart(DateTime date) {
    final normalized = normalizeDate(date);
    final weekday = normalized.weekday;
    return normalized.subtract(Duration(days: weekday - 1));
  }

  /// Gets the end of the week (Sunday) for a given date
  static DateTime getWeekEnd(DateTime date) {
    final normalized = normalizeDate(date);
    final weekday = normalized.weekday;
    return normalized.add(Duration(days: 7 - weekday));
  }

  /// Gets the start of the month for a given date
  static DateTime getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Gets the end of the month for a given date
  static DateTime getMonthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Gets the number of days in a month
  static int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  /// Gets a list of dates for a week starting from the given date
  static List<DateTime> getWeekDates(DateTime startDate) {
    final normalized = normalizeDate(startDate);
    return List.generate(
      7,
      (index) => normalized.add(Duration(days: index)),
    );
  }

  /// Gets a list of dates for a month
  static List<DateTime> getMonthDates(DateTime date) {
    final start = getMonthStart(date);
    final daysInMonth = getDaysInMonth(date);
    return List.generate(
      daysInMonth,
      (index) => start.add(Duration(days: index)),
    );
  }

  /// Calculates the difference in days between two dates
  static int daysBetween(DateTime date1, DateTime date2) {
    final normalized1 = normalizeDate(date1);
    final normalized2 = normalizeDate(date2);
    return normalized2.difference(normalized1).inDays;
  }

  /// Gets the date for N days ago from today
  static DateTime daysAgo(int days) {
    final today = normalizeDate(DateTime.now());
    return today.subtract(Duration(days: days));
  }

  /// Gets the date for N days from today
  static DateTime daysFromNow(int days) {
    final today = normalizeDate(DateTime.now());
    return today.add(Duration(days: days));
  }
}
