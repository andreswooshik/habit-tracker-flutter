import '../../models/habit.dart';
import '../../sync/cloud_sync_coordinator.dart';
import '../interfaces/i_habits_repository.dart';

/// Offline-first habits repository (Decorator over local + remote).
///
/// Every write lands in the local Hive cache first — the app keeps
/// working with no connection — and is queued for the cloud through
/// [CloudSyncCoordinator]. Reads prefer the cloud (after pushing any
/// pending writes) and refresh the local cache, falling back to the
/// cache when the cloud is unreachable.
class SyncedHabitsRepository implements IHabitsRepository {
  final IHabitsRepository _local;
  final IHabitsRepository _remote;
  final CloudSyncCoordinator _coordinator;

  SyncedHabitsRepository({
    required IHabitsRepository local,
    required IHabitsRepository remote,
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
  Future<List<Habit>> loadHabits() async {
    // Push pending offline writes first so the cloud read reflects them
    final drained = await _coordinator.flush();
    if (drained) {
      try {
        final active = await _remote.loadHabits();
        final archived = await _remote.loadArchivedHabits();
        await _refreshLocalCache([...active, ...archived]);
        return active;
      } catch (_) {
        // Cloud unreachable — serve the local cache below
      }
    }
    return _local.loadHabits();
  }

  @override
  Future<List<Habit>> loadArchivedHabits() async {
    final drained = await _coordinator.flush();
    if (drained) {
      try {
        return await _remote.loadArchivedHabits();
      } catch (_) {
        // Cloud unreachable — serve the local cache below
      }
    }
    return _local.loadArchivedHabits();
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    await _local.saveHabit(habit);
    await _coordinator.record(CloudSyncCoordinator.habitSave(habit));
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    await _local.updateHabit(habit);
    // Remote upserts, so save and update replay identically
    await _coordinator.record(CloudSyncCoordinator.habitSave(habit));
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    await _local.deleteHabit(habitId);
    await _coordinator.record(CloudSyncCoordinator.habitDelete(habitId));
  }

  @override
  Future<void> archiveHabit(String habitId) async {
    await _local.archiveHabit(habitId);
    await _coordinator.record(CloudSyncCoordinator.habitArchive(habitId));
  }

  @override
  Future<void> clearAll() async {
    await _local.clearAll();
    await _coordinator.record(CloudSyncCoordinator.habitsClearAll());
  }

  @override
  Future<void> close() async {
    await _local.close();
    await _remote.close();
  }

  Future<void> _refreshLocalCache(List<Habit> habits) async {
    await _local.clearAll();
    for (final habit in habits) {
      await _local.saveHabit(habit);
    }
  }
}
