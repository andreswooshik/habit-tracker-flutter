import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/planned_reminder.dart';
import 'package:habit_tracker_flutter_new/providers/habits_notifier.dart';
import 'package:habit_tracker_flutter_new/providers/notification_providers.dart';
import 'package:habit_tracker_flutter_new/providers/repository_providers.dart';
import 'package:habit_tracker_flutter_new/providers/theme_providers.dart';
import 'package:habit_tracker_flutter_new/repositories/interfaces/i_settings_repository.dart';
import 'package:habit_tracker_flutter_new/services/interfaces/i_notification_service.dart';

import '../mocks/mock_completions_repository.dart';
import '../mocks/mock_habits_repository.dart';

/// Records scheduling calls instead of touching platform plugins
class FakeNotificationService implements INotificationService {
  final List<PlannedReminder> scheduled = [];
  int cancelAllCalls = 0;

  @override
  Future<bool> init() async => true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> scheduleDailyReminder(PlannedReminder reminder) async {
    scheduled.add(reminder);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    scheduled.clear();
  }
}

void main() {
  group('ThemeModeNotifier', () {
    test('defaults to system mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('persists the chosen mode and restores it', () async {
      final settings = InMemorySettingsRepository();
      final container = ProviderContainer(overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
      ]);
      addTearDown(container.dispose);

      await container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      // A fresh container (fresh app start) with the same storage
      final restarted = ProviderContainer(overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
      ]);
      addTearDown(restarted.dispose);

      expect(restarted.read(themeModeProvider), ThemeMode.dark);
    });
  });

  group('ReminderSettingsNotifier', () {
    test('defaults to disabled at 19:00', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(reminderSettingsProvider);
      expect(settings.enabled, isFalse);
      expect(settings.hour, ReminderSettings.defaultHour);
      expect(settings.minute, ReminderSettings.defaultMinute);
    });

    test('persists enabled flag and time', () async {
      final storage = InMemorySettingsRepository();
      final container = ProviderContainer(overrides: [
        settingsRepositoryProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(reminderSettingsProvider.notifier);
      await notifier.setEnabled(true);
      await notifier.setTime(7, 30);

      final restarted = ProviderContainer(overrides: [
        settingsRepositoryProvider.overrideWithValue(storage),
      ]);
      addTearDown(restarted.dispose);

      final restored = restarted.read(reminderSettingsProvider);
      expect(restored.enabled, isTrue);
      expect(restored.hour, 7);
      expect(restored.minute, 30);
    });
  });

  group('ReminderScheduler', () {
    ProviderContainer buildContainer(
      FakeNotificationService service, {
      required bool enabled,
    }) {
      final storage = InMemorySettingsRepository();
      final habitsRepository = MockHabitsRepository();
      final container = ProviderContainer(overrides: [
        settingsRepositoryProvider.overrideWithValue(storage),
        notificationServiceProvider.overrideWithValue(service),
        habitsRepositoryProvider.overrideWithValue(habitsRepository),
        completionsRepositoryProvider
            .overrideWithValue(MockCompletionsRepository()),
      ]);
      habitsRepository.saveHabit(Habit.create(id: 'a', name: 'Read'));
      if (enabled) {
        storage.setBool(ReminderSettingsNotifier.enabledKey, true);
      }
      return container;
    }

    test('schedules reminders for pending habits when enabled', () async {
      final service = FakeNotificationService();
      final container = buildContainer(service, enabled: true);
      addTearDown(container.dispose);

      // Materialize the notifier so habits are loaded from the repository
      container.read(habitsProvider);
      await container.read(reminderSchedulerProvider).reschedule();

      expect(service.cancelAllCalls, 1);
      expect(service.scheduled, hasLength(1));
      expect(service.scheduled.single.title, 'Read');
    });

    test('only cancels when reminders are disabled', () async {
      final service = FakeNotificationService();
      final container = buildContainer(service, enabled: false);
      addTearDown(container.dispose);

      await container.read(reminderSchedulerProvider).reschedule();

      expect(service.cancelAllCalls, 1);
      expect(service.scheduled, isEmpty);
    });
  });
}
