import '../../sync/cloud_sync_coordinator.dart';
import '../interfaces/i_completions_repository.dart';

/// Offline-first completions repository (Decorator over local + remote).
///
/// Same strategy as SyncedHabitsRepository: writes hit the local Hive
/// cache immediately and are queued for the cloud; the full load prefers
/// the cloud and refreshes the cache, falling back to the cache offline.
/// Per-habit reads are served from the cache — it was refreshed by the
/// last successful loadCompletions(), which the app calls on startup.
class SyncedCompletionsRepository implements ICompletionsRepository {
  final ICompletionsRepository _local;
  final ICompletionsRepository _remote;
  final CloudSyncCoordinator _coordinator;

  SyncedCompletionsRepository({
    required ICompletionsRepository local,
    required ICompletionsRepository remote,
    required CloudSyncCoordinator coordinator,
  })  : _local = local,
        _remote = remote,
        _coordinator = coordinator;

  @override
  Future<void> init() async {
    await _local.init();
    await _remote.init();
  }

  @override
  Future<Map<String, Set<DateTime>>> loadCompletions() async {
    final drained = await _coordinator.flush();
    if (drained) {
      try {
        final completions = await _remote.loadCompletions();
        await _refreshLocalCache(completions);
        return completions;
      } catch (_) {
        // Cloud unreachable — serve the local cache below
      }
    }
    return _local.loadCompletions();
  }

  @override
  Future<void> addCompletion(String habitId, DateTime date) async {
    await _local.addCompletion(habitId, date);
    await _coordinator
        .record(CloudSyncCoordinator.completionAdd(habitId, date));
  }

  @override
  Future<void> removeCompletion(String habitId, DateTime date) async {
    await _local.removeCompletion(habitId, date);
    await _coordinator
        .record(CloudSyncCoordinator.completionRemove(habitId, date));
  }

  @override
  Future<Set<DateTime>> getCompletionsForHabit(String habitId) {
    return _local.getCompletionsForHabit(habitId);
  }

  @override
  Future<void> deleteCompletionsForHabit(String habitId) async {
    await _local.deleteCompletionsForHabit(habitId);
    await _coordinator
        .record(CloudSyncCoordinator.completionsDeleteForHabit(habitId));
  }

  @override
  Future<void> clearAll() async {
    await _local.clearAll();
    await _coordinator.record(CloudSyncCoordinator.completionsClearAll());
  }

  @override
  Future<void> close() async {
    await _local.close();
    await _remote.close();
  }

  Future<void> _refreshLocalCache(Map<String, Set<DateTime>> completions) async {
    await _local.clearAll();
    for (final entry in completions.entries) {
      for (final date in entry.value) {
        await _local.addCompletion(entry.key, date);
      }
    }
  }
}
