import '../models/planned_reminder.dart';
import 'interfaces/i_notification_service.dart';

/// No-op INotificationService for tests and platforms without
/// notification support (e.g. web). Mirrors NoopAuthService.
class NoopNotificationService implements INotificationService {
  @override
  Future<bool> init() async => true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> scheduleDailyReminder(PlannedReminder reminder) async {}

  @override
  Future<void> cancelAll() async {}
}
