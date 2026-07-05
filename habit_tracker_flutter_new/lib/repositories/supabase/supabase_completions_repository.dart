import 'package:supabase_flutter/supabase_flutter.dart';

import '../interfaces/i_completions_repository.dart';

/// Supabase implementation of ICompletionsRepository
///
/// Stores completions in the public.completions table (see
/// supabase/schema.sql), one row per habit per day. Row Level Security
/// scopes every query to the signed-in user, and user_id is filled by
/// the database default (auth.uid()) on insert.
class SupabaseCompletionsRepository implements ICompletionsRepository {
  static const String _table = 'completions';

  /// Sentinel that matches no row; Postgrest requires a filter on delete
  static const String _nilUuid = '00000000-0000-0000-0000-000000000000';

  final SupabaseClient _client;

  SupabaseCompletionsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<void> init() async {
    // Connection lifecycle is managed by the Supabase SDK
  }

  @override
  Future<Map<String, Set<DateTime>>> loadCompletions() async {
    final rows = await _client.from(_table).select('habit_id, completed_on');
    return completionsFromRows(rows);
  }

  @override
  Future<void> addCompletion(String habitId, DateTime date) async {
    // Idempotent thanks to the (habit_id, completed_on) unique constraint
    await _client.from(_table).upsert(
      {
        'habit_id': habitId,
        'completed_on': formatDate(date),
      },
      onConflict: 'habit_id,completed_on',
      ignoreDuplicates: true,
    );
  }

  @override
  Future<void> removeCompletion(String habitId, DateTime date) async {
    await _client
        .from(_table)
        .delete()
        .eq('habit_id', habitId)
        .eq('completed_on', formatDate(date));
  }

  @override
  Future<Set<DateTime>> getCompletionsForHabit(String habitId) async {
    final rows = await _client
        .from(_table)
        .select('completed_on')
        .eq('habit_id', habitId);
    return rows
        .map((row) => parseDate(row['completed_on'] as String))
        .toSet();
  }

  @override
  Future<void> deleteCompletionsForHabit(String habitId) async {
    await _client.from(_table).delete().eq('habit_id', habitId);
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

  /// Groups completion rows into the habitId -> dates map the app uses
  ///
  /// Static and pure so it can be unit-tested without a client.
  static Map<String, Set<DateTime>> completionsFromRows(
    List<Map<String, dynamic>> rows,
  ) {
    final completions = <String, Set<DateTime>>{};
    for (final row in rows) {
      final habitId = row['habit_id'] as String;
      final date = parseDate(row['completed_on'] as String);
      completions.putIfAbsent(habitId, () => {}).add(date);
    }
    return completions;
  }

  /// Formats a date as the yyyy-MM-dd string Postgres `date` expects
  static String formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Parses a yyyy-MM-dd string to the normalized local DateTime the
  /// app uses as a completion key
  static DateTime parseDate(String value) {
    final parsed = DateTime.parse(value);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
