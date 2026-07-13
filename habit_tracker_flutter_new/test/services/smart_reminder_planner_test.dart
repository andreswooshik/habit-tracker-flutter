import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/services/smart_reminder_planner.dart';

void main() {
  final planner = SmartReminderPlanner();

  Habit makeHabit(String id, {String? name, bool isArchived = false}) {
    return Habit.create(id: id, name: name ?? 'Habit $id')
        .copyWith(isArchived: isArchived);
  }

  DateTime day(DateTime date) => DateTime(date.year, date.month, date.day);

  // A fixed "now" at 08:00, so a 09:00 reminder still fires today and a
  // 07:00 reminder fires tomorrow
  final now = DateTime(2026, 7, 10, 8, 0);
  final today = day(now);
  final yesterday = today.subtract(const Duration(days: 1));

  group('SmartReminderPlanner', () {
    test('skips habits already completed today when reminder is later today',
        () {
      final reminders = planner.plan(
        habits: [makeHabit('done'), makeHabit('open')],
        completions: {
          'done': {today},
        },
        now: now,
        hour: 9,
        minute: 0,
      );

      expect(reminders, hasLength(1));
      expect(reminders.single.title, 'Habit open');
      expect(reminders.single.hour, 9);
    });

    test(
        'includes habits completed today when reminder time already passed '
        '(next fire is tomorrow)', () {
      final reminders = planner.plan(
        habits: [makeHabit('done-today')],
        completions: {
          'done-today': {today},
        },
        now: now,
        hour: 7, // 07:00 already passed at now=08:00
        minute: 0,
      );

      expect(reminders, hasLength(1));
    });

    test('returns no reminders when everything is done', () {
      final reminders = planner.plan(
        habits: [makeHabit('a')],
        completions: {
          'a': {today},
        },
        now: now,
        hour: 9,
        minute: 0,
      );

      expect(reminders, isEmpty);
    });

    test('ignores archived habits', () {
      final reminders = planner.plan(
        habits: [makeHabit('gone', isArchived: true)],
        completions: const {},
        now: now,
        hour: 9,
        minute: 0,
      );

      expect(reminders, isEmpty);
    });

    test('uses streak-protection copy for habits on a streak', () {
      final completions = {
        'streaky': {
          yesterday,
          yesterday.subtract(const Duration(days: 1)),
          yesterday.subtract(const Duration(days: 2)),
          yesterday.subtract(const Duration(days: 3)),
        },
      };

      final reminders = planner.plan(
        habits: [makeHabit('streaky')],
        completions: completions,
        now: now,
        hour: 9,
        minute: 0,
      );

      expect(reminders, hasLength(1));
      expect(reminders.single.body, contains('streak'));
    });

    test('collapses many pending habits into a single digest', () {
      final reminders = planner.plan(
        habits: [for (var i = 0; i < 5; i++) makeHabit('$i')],
        completions: const {},
        now: now,
        hour: 9,
        minute: 0,
      );

      expect(reminders, hasLength(1));
      expect(reminders.single.id, SmartReminderPlanner.digestId);
      expect(reminders.single.title, contains('5'));
    });

    test('reminder ids are stable per habit and non-negative', () {
      final id1 = SmartReminderPlanner.reminderIdFor('habit-42');
      final id2 = SmartReminderPlanner.reminderIdFor('habit-42');

      expect(id1, id2);
      expect(id1, greaterThanOrEqualTo(0));
    });
  });
}
