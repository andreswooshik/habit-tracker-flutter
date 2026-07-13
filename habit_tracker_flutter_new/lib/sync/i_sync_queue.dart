import 'sync_op.dart';

/// FIFO queue of writes waiting to be pushed to the cloud.
///
/// Abstracted so the app can persist it (Hive) while tests use an
/// in-memory implementation — Dependency Inversion Principle.
abstract class ISyncQueue {
  /// Open the underlying storage
  Future<void> init();

  /// Whether there is nothing left to push
  bool get isEmpty;

  /// Number of pending ops
  int get length;

  /// The oldest pending op, or null when empty
  SyncOp? peek();

  /// Append an op to the end of the queue
  Future<void> enqueue(SyncOp op);

  /// Drop the oldest op (after it was applied remotely)
  Future<void> removeFirst();

  /// Drop everything (e.g. after a full re-upload)
  Future<void> clear();

  /// Close the underlying storage
  Future<void> close();
}

/// In-memory queue for tests and as a safe fallback.
class InMemorySyncQueue implements ISyncQueue {
  final List<SyncOp> _ops = [];

  @override
  Future<void> init() async {}

  @override
  bool get isEmpty => _ops.isEmpty;

  @override
  int get length => _ops.length;

  @override
  SyncOp? peek() => _ops.isEmpty ? null : _ops.first;

  @override
  Future<void> enqueue(SyncOp op) async {
    _ops.add(op);
  }

  @override
  Future<void> removeFirst() async {
    if (_ops.isNotEmpty) {
      _ops.removeAt(0);
    }
  }

  @override
  Future<void> clear() async {
    _ops.clear();
  }

  @override
  Future<void> close() async {}
}
