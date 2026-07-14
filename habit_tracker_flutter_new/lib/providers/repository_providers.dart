import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/interfaces/i_completions_repository.dart';
import '../repositories/interfaces/i_habits_repository.dart';
import '../repositories/interfaces/i_photos_repository.dart';
import '../repositories/interfaces/i_settings_repository.dart';
import '../repositories/noop_photos_repository.dart';

final habitsRepositoryProvider = Provider<IHabitsRepository>((ref) {
  throw UnimplementedError('Repository must be overridden in ProviderScope');
});

final completionsRepositoryProvider = Provider<ICompletionsRepository>((ref) {
  throw UnimplementedError('Repository must be overridden in ProviderScope');
});

/// Habit completion photos (Supabase Storage + habit_photos table).
///
/// Defaults to a no-op so tests and local-only mode work without cloud
/// storage; main.dart overrides it with the Supabase implementation when
/// configured.
final photosRepositoryProvider = Provider<IPhotosRepository>((ref) {
  return const NoopPhotosRepository();
});

/// User preferences (theme mode, reminder settings, ...).
///
/// Defaults to an in-memory store so tests work without overrides;
/// main.dart overrides it with the Hive-backed implementation.
final settingsRepositoryProvider = Provider<ISettingsRepository>((ref) {
  return InMemorySettingsRepository();
});
