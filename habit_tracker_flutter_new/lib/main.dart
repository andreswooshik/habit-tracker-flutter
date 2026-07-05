import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:habit_tracker_flutter_new/config/api_keys.dart';
import 'package:habit_tracker_flutter_new/config/app_theme.dart';
import 'package:habit_tracker_flutter_new/providers/repository_providers.dart';
import 'package:habit_tracker_flutter_new/screens/app_shell_screen.dart';
import 'package:habit_tracker_flutter_new/screens/auth/auth_gate.dart';
import 'package:habit_tracker_flutter_new/repositories/hive/hive_habits_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/hive/hive_completions_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/interfaces/i_completions_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/interfaces/i_habits_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/supabase/supabase_completions_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/supabase/supabase_habits_repository.dart';
import 'package:habit_tracker_flutter_new/services/mock_data_loader.dart';

const bool useMockData = false; // Change this to toggle demo/production mode
// ============================================================================

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // With Supabase configured the app runs in cloud mode: login is
  // required and habits/completions live in Supabase tables (per-user,
  // enforced by RLS). Otherwise it runs local-only on Hive, no login.
  final IHabitsRepository habitsRepository;
  final ICompletionsRepository completionsRepository;

  if (ApiKeys.supabaseConfigured) {
    await Supabase.initialize(
      url: ApiKeys.supabaseUrl,
      publishableKey: ApiKeys.supabaseAnonKey,
    );
    habitsRepository = SupabaseHabitsRepository();
    completionsRepository = SupabaseCompletionsRepository();
  } else {
    await Hive.initFlutter();
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

  runApp(
    ProviderScope(
      overrides: [
        // Provide repository instances to the provider scope
        habitsRepositoryProvider.overrideWithValue(habitsRepository),
        completionsRepositoryProvider.overrideWithValue(completionsRepository),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Show demo indicator in app title when using mock data
    final appTitle = useMockData ? 'TrackIt! (DEMO)' : 'TrackIt!';

    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // With Supabase configured, gate the app behind login;
      // otherwise go straight to the shell (local-only mode)
      home: ApiKeys.supabaseConfigured
          ? const AuthGate()
          : const AppShellScreen(),
    );
  }
}
