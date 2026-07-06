import 'package:supabase_flutter/supabase_flutter.dart';

import '../interfaces/i_habits_repository.dart';
import '../../models/habit.dart';
import '../../models/habit_category.dart';
import '../../models/habit_frequency.dart';

/// Supabase implementation of IHabitsRepository
///
/// Stores habits in the public.habits table (see supabase/schema.sql).
/// Row Level Security scopes every query to the signed-in user, and
/// user_id is filled by the database default (auth.uid()) on insert.
class SupabaseHabitsRepository implements IHabitsRepository {
  static const String _table = 'habits';

  /// Sentinel that matches no row; Postgrest requires a filter on delete
  static const String _nilUuid = '00000000-0000-0000-0000-000000000000';

  final SupabaseClient _client;

  SupabaseHabitsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<void> init() async {
    // Connection lifecycle is managed by the Supabase SDK
  }

  @override
  Future<List<Habit>> loadHabits() async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('is_archived', false)
        .order('created_at', ascending: true);
    return rows.map(habitFromRow).toList();
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    await _client.from(_table).upsert(habitToRow(habit));
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    await _client.from(_table).upsert(habitToRow(habit));
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    await _client.from(_table).delete().eq('id', habitId);
  }

  @override
  Future<void> archiveHabit(String habitId) async {
    await _client.from(_table).update({'is_archived': true}).eq('id', habitId);
  }

  @override
  Future<List<Habit>> loadArchivedHabits() async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('is_archived', true)
        .order('created_at', ascending: true);
    return rows.map(habitFromRow).toList();
  }

  @override
  Future<void> clearAll() async {
    // RLS limits the delete to the signed-in user's rows
    await _client.from(_table).delete().neq('id', _nilUuid);
  }

  @override
  Future<void> close() async {
    // Connection lifecycle is managed by the Supabase SDK
  }

  /// Maps a public.habits row to a [Habit]
  ///
  /// Static and pure so it can be unit-tested without a client.
  static Habit habitFromRow(Map<String, dynamic> row) {
    return Habit(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      icon: row['icon'] as String?,
      frequency: HabitFrequency.values.byName(row['frequency'] as String),
      customDays: (row['custom_days'] as List?)?.cast<int>(),
      category: HabitCategory.values.byName(row['category'] as String),
      targetDays: row['target_days'] as int,
      hasGracePeriod: row['has_grace_period'] as bool,
      isArchived: row['is_archived'] as bool,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      notes: row['notes'] as String?,
    );
  }

  /// Maps a [Habit] to a public.habits row
  ///
  /// user_id is intentionally omitted — the database default
  /// (auth.uid()) fills it on insert.
  static Map<String, dynamic> habitToRow(Habit habit) {
    return {
      'id': habit.id,
      'name': habit.name,
      'description': habit.description,
      'icon': habit.icon,
      'frequency': habit.frequency.name,
      'custom_days': habit.customDays,
      'category': habit.category.name,
      'target_days': habit.targetDays,
      'has_grace_period': habit.hasGracePeriod,
      'is_archived': habit.isArchived,
      'notes': habit.notes,
      'created_at': habit.createdAt.toUtc().toIso8601String(),
    };
  }
}
