import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/repositories/supabase/supabase_completions_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/supabase/supabase_habits_repository.dart';

void main() {
  group('SupabaseHabitsRepository mapping', () {
    final habit = Habit(
      id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      name: 'Morning Run',
      description: 'Run before work',
      icon: '🏃',
      frequency: HabitFrequency.custom,
      customDays: const [1, 3, 5],
      category: HabitCategory.fitness,
      targetDays: 60,
      hasGracePeriod: true,
      isArchived: false,
      createdAt: DateTime(2026, 7, 1, 8, 30),
      notes: 'Start slow',
    );

    test('habitToRow serializes enums by name and omits user_id', () {
      final row = SupabaseHabitsRepository.habitToRow(habit);

      expect(row['id'], habit.id);
      expect(row['frequency'], 'custom');
      expect(row['category'], 'fitness');
      expect(row['custom_days'], [1, 3, 5]);
      expect(row['target_days'], 60);
      expect(row['has_grace_period'], true);
      // user_id is filled by the database default (auth.uid())
      expect(row.containsKey('user_id'), isFalse);
    });

    test('habitFromRow round-trips habitToRow', () {
      final restored =
          SupabaseHabitsRepository.habitFromRow(
        SupabaseHabitsRepository.habitToRow(habit),
      );

      expect(restored, habit);
    });

    test('habitFromRow handles nullable columns', () {
      final restored = SupabaseHabitsRepository.habitFromRow({
        'id': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        'name': 'Meditate',
        'description': null,
        'icon': null,
        'frequency': 'everyDay',
        'custom_days': null,
        'category': 'mindfulness',
        'target_days': 30,
        'has_grace_period': false,
        'is_archived': true,
        'created_at': '2026-07-01T00:30:00+00:00',
        'notes': null,
      });

      expect(restored.description, isNull);
      expect(restored.customDays, isNull);
      expect(restored.frequency, HabitFrequency.everyDay);
      expect(restored.isArchived, isTrue);
    });
  });

  group('SupabaseCompletionsRepository mapping', () {
    test('formatDate produces the yyyy-MM-dd string Postgres expects', () {
      expect(
        SupabaseCompletionsRepository.formatDate(DateTime(2026, 7, 5)),
        '2026-07-05',
      );
      expect(
        SupabaseCompletionsRepository.formatDate(DateTime(2026, 11, 30)),
        '2026-11-30',
      );
    });

    test('parseDate returns the normalized local date key', () {
      expect(
        SupabaseCompletionsRepository.parseDate('2026-07-05'),
        DateTime(2026, 7, 5),
      );
    });

    test('completionsFromRows groups rows by habit', () {
      final completions = SupabaseCompletionsRepository.completionsFromRows([
        {'habit_id': 'habit-1', 'completed_on': '2026-07-03'},
        {'habit_id': 'habit-1', 'completed_on': '2026-07-04'},
        {'habit_id': 'habit-2', 'completed_on': '2026-07-04'},
      ]);

      expect(completions, hasLength(2));
      expect(
        completions['habit-1'],
        {DateTime(2026, 7, 3), DateTime(2026, 7, 4)},
      );
      expect(completions['habit-2'], {DateTime(2026, 7, 4)});
    });
  });
}
