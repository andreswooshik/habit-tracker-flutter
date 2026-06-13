import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/main.dart';
import 'package:habit_tracker_flutter_new/providers/repository_providers.dart';

import 'mocks/mock_completions_repository.dart';
import 'mocks/mock_habits_repository.dart';

void main() {
  testWidgets('renders dashboard smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsRepositoryProvider.overrideWithValue(MockHabitsRepository()),
          completionsRepositoryProvider.overrideWithValue(
            MockCompletionsRepository(),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Create your first habit'), findsOneWidget);
    expect(find.text('Today\'s Progress'), findsWidgets);
  });
}
