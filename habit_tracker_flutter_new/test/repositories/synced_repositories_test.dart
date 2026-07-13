import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/repositories/interfaces/i_completions_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/interfaces/i_habits_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/synced/synced_completions_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/synced/synced_habits_repository.dart';
import 'package:habit_tracker_flutter_new/sync/cloud_sync_coordinator.dart';
import 'package:habit_tracker_flutter_new/sync/i_sync_queue.dart';

import '../mocks/mock_completions_repository.dart';
import '../mocks/mock_habits_repository.dart';

/// Wraps a repository and throws on every call while [offline] is true,
/// simulating a device without a connection.
class FlakyHabitsRepository implements IHabitsRepository {
  final MockHabitsRepository inner = MockHabitsRepository();
  bool offline = false;

  void _checkConnection() {
    if (offline) throw Exception('network unreachable');
  }

  @override
  Future<void> init() => inner.init();

  @override
  Future<List<Habit>> loadHabits() {
    _checkConnection();
    return inner.loadHabits();
  }

  @override
  Future<List<Habit>> loadArchivedHabits() {
    _checkConnection();
    return inner.loadArchivedHabits();
  }

  @override
  Future<void> saveHabit(Habit habit) {
    _checkConnection();
    return inner.saveHabit(habit);
  }

  @override
  Future<void> updateHabit(Habit habit) {
    _checkConnection();
    return inner.updateHabit(habit);
  }

  @override
  Future<void> deleteHabit(String habitId) {
    _checkConnection();
    return inner.deleteHabit(habitId);
  }

  @override
  Future<void> archiveHabit(String habitId) {
    _checkConnection();
    return inner.archiveHabit(habitId);
  }

  @override
  Future<void> clearAll() {
    _checkConnection();
    return inner.clearAll();
  }

  @override
  Future<void> close() => inner.close();
}

class FlakyCompletionsRepository implements ICompletionsRepository {
  final MockCompletionsRepository inner = MockCompletionsRepository();
  bool offline = false;

  void _checkConnection() {
    if (offline) throw Exception('network unreachable');
  }

  @override
  Future<void> init() => inner.init();

  @override
  Future<Map<String, Set<DateTime>>> loadCompletions() {
    _checkConnection();
    return inner.loadCompletions();
  }

  @override
  Future<void> addCompletion(String habitId, DateTime date) {
    _checkConnection();
    return inner.addCompletion(habitId, date);
  }

  @override
  Future<void> removeCompletion(String habitId, DateTime date) {
    _checkConnection();
    return inner.removeCompletion(habitId, date);
  }

  @override
  Future<Set<DateTime>> getCompletionsForHabit(String habitId) {
    _checkConnection();
    return inner.getCompletionsForHabit(habitId);
  }

  @override
  Future<void> deleteCompletionsForHabit(String habitId) {
    _checkConnection();
    return inner.deleteCompletionsForHabit(habitId);
  }

  @override
  Future<void> clearAll() {
    _checkConnection();
    return inner.clearAll();
  }

  @override
  Future<void> close() => inner.close();
}

void main() {
  late MockHabitsRepository localHabits;
  late MockCompletionsRepository localCompletions;
  late FlakyHabitsRepository remoteHabits;
  late FlakyCompletionsRepository remoteCompletions;
  late InMemorySyncQueue queue;
  late CloudSyncCoordinator coordinator;
  late SyncedHabitsRepository habits;
  late SyncedCompletionsRepository completions;

  Habit makeHabit(String id) => Habit.create(id: id, name: 'Habit $id');

  setUp(() async {
    localHabits = MockHabitsRepository();
    localCompletions = MockCompletionsRepository();
    remoteHabits = FlakyHabitsRepository();
    remoteCompletions = FlakyCompletionsRepository();
    queue = InMemorySyncQueue();
    coordinator = CloudSyncCoordinator(
      queue: queue,
      remoteHabits: remoteHabits,
      remoteCompletions: remoteCompletions,
    );
    habits = SyncedHabitsRepository(
      local: localHabits,
      remote: remoteHabits,
      coordinator: coordinator,
    );
    completions = SyncedCompletionsRepository(
      local: localCompletions,
      remote: remoteCompletions,
      coordinator: coordinator,
    );
    await habits.init();
    await completions.init();
  });

  group('SyncedHabitsRepository', () {
    test('writes reach both local cache and cloud when online', () async {
      await habits.saveHabit(makeHabit('a'));

      expect(localHabits.habitCount, 1);
      expect(remoteHabits.inner.habitCount, 1);
      expect(coordinator.hasPendingOps, isFalse);
    });

    test('offline writes stay local and are queued', () async {
      remoteHabits.offline = true;

      await habits.saveHabit(makeHabit('a'));

      expect(localHabits.habitCount, 1);
      expect(remoteHabits.inner.habitCount, 0);
      expect(coordinator.pendingOpsCount, 1);
    });

    test('queued writes are pushed once the connection returns', () async {
      remoteHabits.offline = true;
      await habits.saveHabit(makeHabit('a'));
      expect(remoteHabits.inner.habitCount, 0);

      remoteHabits.offline = false;
      final loaded = await habits.loadHabits();

      expect(remoteHabits.inner.habitCount, 1);
      expect(loaded.map((h) => h.id), contains('a'));
      expect(coordinator.hasPendingOps, isFalse);
    });

    test('offline delete is replayed on the cloud when back online',
        () async {
      await habits.saveHabit(makeHabit('a'));
      expect(remoteHabits.inner.habitCount, 1);

      remoteHabits.offline = true;
      await habits.deleteHabit('a');
      expect(remoteHabits.inner.habitCount, 1); // cloud still has it

      remoteHabits.offline = false;
      await habits.loadHabits();
      expect(remoteHabits.inner.habitCount, 0);
    });

    test('loadHabits falls back to the local cache when offline', () async {
      await habits.saveHabit(makeHabit('a'));

      remoteHabits.offline = true;
      final loaded = await habits.loadHabits();

      expect(loaded.map((h) => h.id), contains('a'));
    });

    test('loadHabits refreshes the local cache from the cloud', () async {
      // Cloud data written on "another device"
      await remoteHabits.inner.saveHabit(makeHabit('cloud-only'));

      final loaded = await habits.loadHabits();

      expect(loaded.map((h) => h.id), contains('cloud-only'));
      expect(localHabits.habitCount, 1);
    });
  });

  group('SyncedCompletionsRepository', () {
    final date = DateTime(2026, 7, 10);

    test('habit created offline syncs before its completion (FIFO)', () async {
      remoteHabits.offline = true;
      remoteCompletions.offline = true;
      await habits.saveHabit(makeHabit('a'));
      await completions.addCompletion('a', date);
      expect(coordinator.pendingOpsCount, 2);

      remoteHabits.offline = false;
      remoteCompletions.offline = false;
      final loaded = await completions.loadCompletions();

      expect(remoteHabits.inner.habitCount, 1);
      expect(loaded['a'], contains(date));
      expect(coordinator.hasPendingOps, isFalse);
    });

    test('loadCompletions falls back to the local cache when offline',
        () async {
      await completions.addCompletion('a', date);

      remoteCompletions.offline = true;
      remoteHabits.offline = true;
      final loaded = await completions.loadCompletions();

      expect(loaded['a'], contains(date));
    });

    test('flush stops at the first failing op and retries later', () async {
      remoteCompletions.offline = true;
      await completions.addCompletion('a', date);
      await completions.removeCompletion('a', date);
      expect(coordinator.pendingOpsCount, 2);

      // Still offline: flushing keeps both ops
      await coordinator.flush();
      expect(coordinator.pendingOpsCount, 2);

      remoteCompletions.offline = false;
      await coordinator.flush();
      expect(coordinator.hasPendingOps, isFalse);
      final remote = await remoteCompletions.inner.loadCompletions();
      expect(remote['a'] ?? const <DateTime>{}, isEmpty);
    });
  });
}
