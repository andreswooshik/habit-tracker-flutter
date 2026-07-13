import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/providers/notification_providers.dart';
import 'package:habit_tracker_flutter_new/providers/repository_providers.dart';
import 'package:habit_tracker_flutter_new/providers/theme_providers.dart';
import 'package:habit_tracker_flutter_new/screens/settings_screen.dart';

import '../mocks/mock_completions_repository.dart';
import '../mocks/mock_habits_repository.dart';

void main() {
  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        habitsRepositoryProvider.overrideWithValue(MockHabitsRepository()),
        completionsRepositoryProvider
            .overrideWithValue(MockCompletionsRepository()),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SettingsScreen()),
      ),
    );
  }

  group('SettingsScreen', () {
    testWidgets('theme picker switches the app to dark mode', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('System default'), findsOneWidget);

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark mode').last);
      await tester.pumpAndSettle();

      // Subtitle now reflects the persisted choice
      expect(find.text('Dark mode'), findsOneWidget);

      final context = tester.element(find.byType(SettingsScreen));
      final container = ProviderScope.containerOf(context);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    testWidgets('daily reminders toggle reveals the time picker tile',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Reminder time'), findsNothing);

      await tester.tap(find.text('Daily reminders'));
      await tester.pumpAndSettle();

      expect(find.text('Reminder time'), findsOneWidget);

      final context = tester.element(find.byType(SettingsScreen));
      final container = ProviderScope.containerOf(context);
      expect(container.read(reminderSettingsProvider).enabled, isTrue);
    });
  });
}
