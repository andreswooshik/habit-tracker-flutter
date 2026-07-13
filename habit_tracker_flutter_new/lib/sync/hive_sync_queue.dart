import 'package:hive_flutter/hive_flutter.dart';

import 'i_sync_queue.dart';
import 'sync_op.dart';

/// Hive implementation of ISyncQueue
///
/// Ops survive app restarts, so a completion recorded offline is still
/// pushed to Supabase the next time the app opens with a connection.
/// Box auto-increment keys preserve insertion (FIFO) order.
class HiveSyncQueue implements ISyncQueue {
  static const String _boxName = 'sync_queue';
  Box<Map<dynamic, dynamic>>? _box;

  Box<Map<dynamic, dynamic>> get _queueBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError('SyncQueue not initialized. Call init() first.');
    }
    return _box!;
  }

  @override
  Future<void> init() async {
    _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
  }

  @override
  bool get isEmpty => _queueBox.isEmpty;

  @override
  int get length => _queueBox.length;

  int? get _firstKey {
    if (_queueBox.isEmpty) return null;
    final keys = _queueBox.keys.cast<int>().toList()..sort();
    return keys.first;
  }

  @override
  SyncOp? peek() {
    final key = _firstKey;
    if (key == null) return null;
    return SyncOp.fromMap(_queueBox.get(key)!);
  }

  @override
  Future<void> enqueue(SyncOp op) async {
    await _queueBox.add(op.toMap());
  }

  @override
  Future<void> removeFirst() async {
    final key = _firstKey;
    if (key != null) {
      await _queueBox.delete(key);
    }
  }

  @override
  Future<void> clear() async {
    await _queueBox.clear();
  }

  @override
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
