import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/providers/repository_providers.dart';

import 'mock_completions_repository.dart';
import 'mock_habits_repository.dart';

ProviderContainer createTestProviderContainer() {
  return ProviderContainer(
    overrides: [
      habitsRepositoryProvider.overrideWithValue(MockHabitsRepository()),
      completionsRepositoryProvider.overrideWithValue(
        MockCompletionsRepository(),
      ),
    ],
  );
}
