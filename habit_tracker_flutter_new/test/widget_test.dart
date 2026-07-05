import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/config/app_theme.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/screens/app_shell_screen.dart';
import 'package:habit_tracker_flutter_new/services/noop_auth_service.dart';

import 'mocks/mock_completions_repository.dart';
import 'mocks/mock_habits_repository.dart';

void main() {
  testWidgets('renders dashboard smoke test', (WidgetTester tester) async {
    // Pump the shell directly so the test doesn't depend on whether
    // the developer's local api_keys.dart has Supabase configured
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsRepositoryProvider.overrideWithValue(MockHabitsRepository()),
          completionsRepositoryProvider.overrideWithValue(
            MockCompletionsRepository(),
          ),
          authServiceProvider.overrideWithValue(const NoopAuthService()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AppShellScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Create your first habit'), findsOneWidget);
    expect(find.text('Today\'s Progress'), findsWidgets);
  });
}
