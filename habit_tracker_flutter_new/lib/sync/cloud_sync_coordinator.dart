import 'package:flutter/foundation.dart';

import '../models/habit.dart';
import '../repositories/interfaces/i_completions_repository.dart';
import '../repositories/interfaces/i_habits_repository.dart';
import '../repositories/supabase/supabase_completions_repository.dart';
import '../repositories/supabase/supabase_habits_repository.dart';
import 'i_sync_queue.dart';
import 'sync_op.dart';

/// Replays queued offline writes against the cloud repositories.
///
/// The synced repositories record every write in the queue; this class
/// drains the queue in FIFO order (a completion added after its habit is
/// always pushed after that habit). If any op fails — offline, signed
/// out, server error — flushing stops and the remaining ops are retried
/// on the next flush, so no data is lost.
class CloudSyncCoordinator {
  final ISyncQueue _queue;
  final IHabitsRepository _remoteHabits;
  final ICompletionsRepository _remoteCompletions;

  /// Live count of writes waiting to reach the cloud — the app bar's
  /// sync indicator listens to this to show offline status
  final ValueNotifier<int> pendingCount;

  bool _flushing = false;

  CloudSyncCoordinator({
    required ISyncQueue queue,
    required IHabitsRepository remoteHabits,
    required ICompletionsRepository remoteCompletions,
  })  : _queue = queue,
        _remoteHabits = remoteHabits,
        _remoteCompletions = remoteCompletions,
        pendingCount = ValueNotifier(queue.length);

  /// Whether there are writes that have not reached the cloud yet
  bool get hasPendingOps => !_queue.isEmpty;

  /// Number of writes waiting to be pushed
  int get pendingOpsCount => _queue.length;

  /// Records a write and immediately tries to push it (and anything
  /// queued before it). Never throws — on failure the op stays queued.
  Future<void> record(SyncOp op) async {
    await _queue.enqueue(op);
    pendingCount.value = _queue.length;
    await flush();
  }

  /// Pushes queued ops to the cloud in order.
  ///
  /// Returns true when the queue was fully drained (the cloud is in
  /// sync), false when an op failed and ops remain queued.
  Future<bool> flush() async {
    if (_flushing) return false;
    _flushing = true;
    try {
      while (!_queue.isEmpty) {
        final op = _queue.peek()!;
        try {
          await _apply(op);
        } catch (e) {
          debugPrint('CloudSync: keeping ${_queue.length} pending op(s) — $e');
          return false;
        }
        await _queue.removeFirst();
        pendingCount.value = _queue.length;
      }
      return true;
    } finally {
      _flushing = false;
    }
  }

  Future<void> _apply(SyncOp op) async {
    switch ((op.entity, op.action)) {
      case (SyncOp.entityHabit, SyncOp.actionSave):
        final habit = SupabaseHabitsRepository.habitFromRow(op.data);
        await _remoteHabits.saveHabit(habit);
      case (SyncOp.entityHabit, SyncOp.actionDelete):
        await _remoteHabits.deleteHabit(op.data['id'] as String);
      case (SyncOp.entityHabit, SyncOp.actionArchive):
        await _remoteHabits.archiveHabit(op.data['id'] as String);
      case (SyncOp.entityHabit, SyncOp.actionClearAll):
        await _remoteHabits.clearAll();
      case (SyncOp.entityCompletion, SyncOp.actionAdd):
        await _remoteCompletions.addCompletion(
          op.data['habit_id'] as String,
          SupabaseCompletionsRepository.parseDate(
              op.data['completed_on'] as String),
        );
      case (SyncOp.entityCompletion, SyncOp.actionRemove):
        await _remoteCompletions.removeCompletion(
          op.data['habit_id'] as String,
          SupabaseCompletionsRepository.parseDate(
              op.data['completed_on'] as String),
        );
      case (SyncOp.entityCompletion, SyncOp.actionDeleteForHabit):
        await _remoteCompletions
            .deleteCompletionsForHabit(op.data['habit_id'] as String);
      case (SyncOp.entityCompletion, SyncOp.actionClearAll):
        await _remoteCompletions.clearAll();
      default:
        // Unknown op (e.g. written by a newer app version) — skip it
        // rather than blocking the queue forever.
        debugPrint('CloudSync: skipping unknown op $op');
    }
  }

  /// Convenience builders so repositories don't hand-assemble maps

  static SyncOp habitSave(Habit habit) => SyncOp(
        entity: SyncOp.entityHabit,
        action: SyncOp.actionSave,
        data: SupabaseHabitsRepository.habitToRow(habit),
      );

  static SyncOp habitDelete(String habitId) => SyncOp(
        entity: SyncOp.entityHabit,
        action: SyncOp.actionDelete,
        data: {'id': habitId},
      );

  static SyncOp habitArchive(String habitId) => SyncOp(
        entity: SyncOp.entityHabit,
        action: SyncOp.actionArchive,
        data: {'id': habitId},
      );

  static SyncOp habitsClearAll() => const SyncOp(
        entity: SyncOp.entityHabit,
        action: SyncOp.actionClearAll,
      );

  static SyncOp completionAdd(String habitId, DateTime date) => SyncOp(
        entity: SyncOp.entityCompletion,
        action: SyncOp.actionAdd,
        data: {
          'habit_id': habitId,
          'completed_on': SupabaseCompletionsRepository.formatDate(date),
        },
      );

  static SyncOp completionRemove(String habitId, DateTime date) => SyncOp(
        entity: SyncOp.entityCompletion,
        action: SyncOp.actionRemove,
        data: {
          'habit_id': habitId,
          'completed_on': SupabaseCompletionsRepository.formatDate(date),
        },
      );

  static SyncOp completionsDeleteForHabit(String habitId) => SyncOp(
        entity: SyncOp.entityCompletion,
        action: SyncOp.actionDeleteForHabit,
        data: {'habit_id': habitId},
      );

  static SyncOp completionsClearAll() => const SyncOp(
        entity: SyncOp.entityCompletion,
        action: SyncOp.actionClearAll,
      );
}
