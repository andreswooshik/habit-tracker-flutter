import '../../models/planned_reminder.dart';

/// Interface for platform push/local notifications.
///
/// Follows the same pattern as the other service interfaces (IChatService,
/// IWeeklySummaryService...): the app depends on this abstraction, with a
/// real platform implementation and a no-op fallback for unsupported
/// platforms and tests — Dependency Inversion Principle.
abstract class INotificationService {
  /// Prepare the platform plugin.
  ///
  /// Returns false when notifications are unavailable on this platform;
  /// callers should then swap in the no-op implementation.
  Future<bool> init();

  /// Ask the OS for notification permission (Android 13+, iOS).
  ///
  /// Returns true when granted or not required.
  Future<bool> requestPermissions();

  /// Schedule a reminder that repeats every day at its wall-clock time
  Future<void> scheduleDailyReminder(PlannedReminder reminder);

  /// Cancel every scheduled reminder (called before rescheduling)
  Future<void> cancelAll();
}
