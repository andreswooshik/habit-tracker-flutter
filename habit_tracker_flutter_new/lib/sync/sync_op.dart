/// A single pending write that still has to be pushed to the cloud.
///
/// Ops are recorded while the device is offline (or a request fails) and
/// replayed in order by CloudSyncCoordinator once the network is back.
/// The payload is a plain JSON-safe map so the queue can be persisted.
class SyncOp {
  /// Which aggregate the op belongs to
  static const String entityHabit = 'habit';
  static const String entityCompletion = 'completion';

  /// What to do when replaying
  static const String actionSave = 'save';
  static const String actionDelete = 'delete';
  static const String actionArchive = 'archive';
  static const String actionAdd = 'add';
  static const String actionRemove = 'remove';
  static const String actionDeleteForHabit = 'deleteForHabit';
  static const String actionClearAll = 'clearAll';

  final String entity;
  final String action;
  final Map<String, dynamic> data;

  const SyncOp({
    required this.entity,
    required this.action,
    this.data = const {},
  });

  Map<String, dynamic> toMap() => {
        'entity': entity,
        'action': action,
        'data': data,
      };

  factory SyncOp.fromMap(Map<dynamic, dynamic> map) => SyncOp(
        entity: map['entity'] as String,
        action: map['action'] as String,
        data: Map<String, dynamic>.from(map['data'] as Map? ?? const {}),
      );

  @override
  String toString() => 'SyncOp($entity.$action, $data)';
}
