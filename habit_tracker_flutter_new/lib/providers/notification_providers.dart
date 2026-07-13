import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/interfaces/i_settings_repository.dart';
import '../services/interfaces/i_notification_service.dart';
import '../services/noop_notification_service.dart';
import '../services/smart_reminder_planner.dart';
import 'completions_notifier.dart';
import 'habits_notifier.dart';
import 'repository_providers.dart';

/// Immutable reminder preferences (persisted through ISettingsRepository)
class ReminderSettings extends Equatable {
  static const int defaultHour = 19;
  static const int defaultMinute = 0;

  final bool enabled;
  final int hour;
  final int minute;

  const ReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  @override
  List<Object?> get props => [enabled, hour, minute];
}

/// StateNotifier for reminder preferences
class ReminderSettingsNotifier extends StateNotifier<ReminderSettings> {
  static const String enabledKey = 'reminders_enabled';
  static const String hourKey = 'reminder_hour';
  static const String minuteKey = 'reminder_minute';

  final ISettingsRepository _settings;

  ReminderSettingsNotifier(this._settings) : super(_initial(_settings));

  static ReminderSettings _initial(ISettingsRepository settings) {
    return ReminderSettings(
      enabled: settings.getBool(enabledKey) ?? false,
      hour: settings.getInt(hourKey) ?? ReminderSettings.defaultHour,
      minute: settings.getInt(minuteKey) ?? ReminderSettings.defaultMinute,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    await _settings.setBool(enabledKey, enabled);
  }

  Future<void> setTime(int hour, int minute) async {
    state = state.copyWith(hour: hour, minute: minute);
    await _settings.setInt(hourKey, hour);
    await _settings.setInt(minuteKey, minute);
  }
}

/// Platform notification service.
///
/// Defaults to the no-op implementation (tests, unsupported platforms);
/// main.dart overrides it with LocalNotificationService when available.
final notificationServiceProvider = Provider<INotificationService>((ref) {
  return NoopNotificationService();
});

/// Global provider for reminder preferences
final reminderSettingsProvider =
    StateNotifierProvider<ReminderSettingsNotifier, ReminderSettings>((ref) {
  return ReminderSettingsNotifier(ref.watch(settingsRepositoryProvider));
});

/// Pure planning logic (which reminders, what copy)
final reminderPlannerProvider = Provider<SmartReminderPlanner>((ref) {
  return SmartReminderPlanner();
});

/// Applies the current plan to the platform: cancels everything and
/// reschedules from the latest habits + completions + preferences.
class ReminderScheduler {
  final Ref _ref;

  ReminderScheduler(this._ref);

  Future<void> reschedule() async {
    final service = _ref.read(notificationServiceProvider);
    final settings = _ref.read(reminderSettingsProvider);

    await service.cancelAll();
    if (!settings.enabled) {
      return;
    }

    final reminders = _ref.read(reminderPlannerProvider).plan(
          habits: _ref.read(habitsProvider).habits,
          completions: _ref.read(completionsProvider).completions,
          now: DateTime.now(),
          hour: settings.hour,
          minute: settings.minute,
        );
    for (final reminder in reminders) {
      await service.scheduleDailyReminder(reminder);
    }
  }
}

/// Global provider for the reminder scheduler
final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  return ReminderScheduler(ref);
});
