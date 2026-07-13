import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:habit_tracker_flutter_new/config/api_keys.dart';
import 'package:habit_tracker_flutter_new/config/app_theme.dart';
import 'package:habit_tracker_flutter_new/providers/repository_providers.dart';
import 'package:habit_tracker_flutter_new/providers/notification_providers.dart';
import 'package:habit_tracker_flutter_new/providers/theme_providers.dart';
import 'package:habit_tracker_flutter_new/screens/app_shell_screen.dart';
import 'package:habit_tracker_flutter_new/screens/auth/auth_gate.dart';
import 'package:habit_tracker_flutter_new/repositories/hive/hive_habits_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/hive/hive_completions_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/hive/hive_settings_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/interfaces/i_completions_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/interfaces/i_habits_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/supabase/supabase_completions_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/supabase/supabase_habits_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/synced/synced_completions_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/synced/synced_habits_repository.dart';
import 'package:habit_tracker_flutter_new/services/interfaces/i_notification_service.dart';
import 'package:habit_tracker_flutter_new/services/local_notification_service.dart';
import 'package:habit_tracker_flutter_new/services/mock_data_loader.dart';
import 'package:habit_tracker_flutter_new/services/noop_notification_service.dart';
import 'package:habit_tracker_flutter_new/sync/cloud_sync_coordinator.dart';
import 'package:habit_tracker_flutter_new/sync/hive_sync_queue.dart';

const bool useMockData = false; // Change this to toggle demo/production mode
// ============================================================================

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Hive always backs the local cache (habits/completions offline) and
  // user preferences (theme mode, reminder settings)
  await Hive.initFlutter();

  final settingsRepository = HiveSettingsRepository();
  await settingsRepository.init();

  // With Supabase configured the app runs offline-first: habits and
  // completions live in the local Hive cache AND sync to Supabase
  // (per-user, enforced by RLS). Writes made offline are queued and
  // pushed when the connection returns. Without Supabase the app runs
  // local-only on Hive, no login.
  final IHabitsRepository habitsRepository;
  final ICompletionsRepository completionsRepository;

  if (ApiKeys.supabaseConfigured) {
    await Supabase.initialize(
      url: ApiKeys.supabaseUrl,
      publishableKey: ApiKeys.supabaseAnonKey,
    );

    final syncQueue = HiveSyncQueue();
    await syncQueue.init();
    final coordinator = CloudSyncCoordinator(
      queue: syncQueue,
      remoteHabits: SupabaseHabitsRepository(),
      remoteCompletions: SupabaseCompletionsRepository(),
    );

    habitsRepository = SyncedHabitsRepository(
      local: HiveHabitsRepository(),
      remote: SupabaseHabitsRepository(),
      coordinator: coordinator,
    );
    completionsRepository = SyncedCompletionsRepository(
      local: HiveCompletionsRepository(),
      remote: SupabaseCompletionsRepository(),
      coordinator: coordinator,
    );
  } else {
    habitsRepository = HiveHabitsRepository();
    completionsRepository = HiveCompletionsRepository();
  }

  await habitsRepository.init();
  await completionsRepository.init();

  // Load mock data if feature flag is enabled (local-only mode — never
  // seed demo rows into a real user's cloud data)
  if (useMockData && !ApiKeys.supabaseConfigured) {
    final mockDataLoader = MockDataLoader(
      habitsRepository: habitsRepository,
      completionsRepository: completionsRepository,
    );
    await mockDataLoader.loadIfNeeded(
      habitCount: 8,
      daysOfHistory: 60,
      forceClear: false,
    );
  }

  // Reminders use the platform notification plugin where available and
  // silently no-op elsewhere (e.g. web)
  INotificationService notificationService = LocalNotificationService();
  if (!await notificationService.init()) {
    notificationService = NoopNotificationService();
  }

  runApp(
    ProviderScope(
      overrides: [
        // Provide repository instances to the provider scope
        habitsRepositoryProvider.overrideWithValue(habitsRepository),
        completionsRepositoryProvider.overrideWithValue(completionsRepository),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show demo indicator in app title when using mock data
    final appTitle = useMockData ? 'TrackIt! (DEMO)' : 'TrackIt!';
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // With Supabase configured, gate the app behind login;
      // otherwise go straight to the shell (local-only mode)
      home: ApiKeys.supabaseConfigured
          ? const AuthGate()
          : const AppShellScreen(),
    );
  }
}
