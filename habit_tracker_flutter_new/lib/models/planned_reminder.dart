import 'package:equatable/equatable.dart';

/// A daily habit reminder ready to be handed to the notification service.
///
/// Produced by SmartReminderPlanner (pure logic) and consumed by
/// INotificationService implementations (platform plumbing), keeping the
/// two sides decoupled.
class PlannedReminder extends Equatable {
  /// Stable platform notification id (same habit → same id, so
  /// rescheduling replaces instead of duplicating)
  final int id;

  final String title;
  final String body;

  /// Local wall-clock time the reminder fires every day
  final int hour;
  final int minute;

  const PlannedReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
  });

  @override
  List<Object?> get props => [id, title, body, hour, minute];

  @override
  String toString() =>
      'PlannedReminder(#$id "$title" @ $hour:${minute.toString().padLeft(2, '0')})';
}
