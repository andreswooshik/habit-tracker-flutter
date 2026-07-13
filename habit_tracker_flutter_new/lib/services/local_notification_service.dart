import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/planned_reminder.dart';
import 'interfaces/i_notification_service.dart';

/// INotificationService backed by flutter_local_notifications.
///
/// Handles the platform plumbing only (channels, permissions, timezone
/// math); deciding WHAT to remind about lives in SmartReminderPlanner.
class LocalNotificationService implements INotificationService {
  static const String _channelId = 'habit_reminders';
  static const String _channelName = 'Habit Reminders';
  static const String _channelDescription =
      'Daily reminders for habits you have not completed yet';

  final FlutterLocalNotificationsPlugin _plugin;

  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<bool> init() async {
    if (kIsWeb) {
      return false;
    }
    try {
      tz_data.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (e) {
        // Unknown zone — reminders still fire, at UTC wall-clock time
        debugPrint('Notifications: could not resolve local timezone: $e');
      }

      final initialized = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
          macOS: DarwinInitializationSettings(),
          linux: LinuxInitializationSettings(defaultActionName: 'Open'),
          windows: WindowsInitializationSettings(
            appName: 'TrackIt!',
            appUserModelId: 'com.example.habit_tracker_flutter_new',
            guid: 'c2c9f5e4-90e4-4b1c-9d6b-3a86f2f0b1d7',
          ),
        ),
      );
      return initialized ?? false;
    } catch (e) {
      // Platform without notification support — caller swaps in the noop
      debugPrint('Notifications unavailable: $e');
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? true;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
            true;
      }
      return true; // Desktop needs no runtime permission
    } catch (e) {
      debugPrint('Notifications: permission request failed: $e');
      return false;
    }
  }

  @override
  Future<void> scheduleDailyReminder(PlannedReminder reminder) async {
    try {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: _nextInstanceOf(reminder.hour, reminder.minute),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
          linux: LinuxNotificationDetails(),
        ),
        // Inexact avoids the Android 12+ exact-alarm permission; a habit
        // reminder does not need to-the-second delivery
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Notifications: could not schedule "${reminder.title}": $e');
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Notifications: cancelAll failed: $e');
    }
  }

  /// The next occurrence of hour:minute in the local timezone
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
