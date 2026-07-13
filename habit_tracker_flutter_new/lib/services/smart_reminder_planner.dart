import '../models/habit.dart';
import '../models/planned_reminder.dart';
import 'interfaces/i_streak_calculator.dart';
import 'streak_calculator.dart';

/// Decides which habit reminders to schedule — the "smart" in Smart
/// Push Notifications. Pure Dart (no plugins), so fully unit-testable.
///
/// Rules:
/// - Only habits still pending at the next fire time get a reminder:
///   if the reminder time hasn't passed today, habits already completed
///   today are skipped; if it has passed, the reminder is for tomorrow
///   and every active habit counts.
/// - Habits with a streak of [streakAlertThreshold]+ days get a
///   streak-protection message (losing a long streak hurts the most).
/// - More than [maxIndividualReminders] pending habits collapse into a
///   single digest so the user isn't spammed.
class SmartReminderPlanner {
  /// Streak length from which reminders switch to streak-protection copy
  static const int streakAlertThreshold = 3;

  /// Above this many pending habits, send one digest instead
  static const int maxIndividualReminders = 3;

  /// Fixed id for the digest notification
  static const int digestId = 0;

  final IStreakCalculator _streakCalculator;

  SmartReminderPlanner({IStreakCalculator? streakCalculator})
      : _streakCalculator = streakCalculator ?? BasicStreakCalculator();

  /// Stable notification id per habit so rescheduling replaces the old one
  static int reminderIdFor(String habitId) => habitId.hashCode & 0x7fffffff;

  List<PlannedReminder> plan({
    required List<Habit> habits,
    required Map<String, Set<DateTime>> completions,
    required DateTime now,
    required int hour,
    required int minute,
  }) {
    final reminderTimeToday =
        DateTime(now.year, now.month, now.day, hour, minute);
    final firesToday = reminderTimeToday.isAfter(now);
    final fireDay = firesToday
        ? DateTime(now.year, now.month, now.day)
        : DateTime(now.year, now.month, now.day + 1);

    final pending = habits
        .where((habit) => !habit.isArchived)
        .where((habit) => !_isCompletedOn(completions, habit.id, fireDay))
        .toList();

    if (pending.isEmpty) {
      return const [];
    }

    // Longest streaks first — they are the most painful to lose
    final streaks = {
      for (final habit in pending)
        habit.id: _streakCalculator
            .calculateStreak(habit, completions[habit.id] ?? const {})
            .current,
    };
    pending.sort((a, b) => streaks[b.id]!.compareTo(streaks[a.id]!));

    if (pending.length > maxIndividualReminders) {
      return [_digest(pending, hour, minute)];
    }

    return [
      for (final habit in pending)
        PlannedReminder(
          id: reminderIdFor(habit.id),
          title: habit.name,
          body: _bodyFor(habit, streaks[habit.id]!),
          hour: hour,
          minute: minute,
        ),
    ];
  }

  String _bodyFor(Habit habit, int streak) {
    if (streak >= streakAlertThreshold) {
      return 'You\'re on a $streak-day streak — complete it today to keep '
          'the fire going! 🔥';
    }
    return 'A quick check-in: "${habit.name}" is still open today. 💪';
  }

  PlannedReminder _digest(List<Habit> pending, int hour, int minute) {
    final names = pending.map((habit) => habit.name).take(3).join(', ');
    final more = pending.length > 3 ? ' and ${pending.length - 3} more' : '';
    return PlannedReminder(
      id: digestId,
      title: '${pending.length} habits are waiting for you',
      body: '$names$more. A few minutes is all it takes! ✅',
      hour: hour,
      minute: minute,
    );
  }

  bool _isCompletedOn(
    Map<String, Set<DateTime>> completions,
    String habitId,
    DateTime day,
  ) {
    final normalized = DateTime(day.year, day.month, day.day);
    return completions[habitId]?.contains(normalized) ?? false;
  }
}
