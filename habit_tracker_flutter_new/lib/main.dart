import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habit_tracker_flutter_new/config/app_theme.dart';
import 'package:habit_tracker_flutter_new/screens/home_dashboard_screen.dart';
import 'package:habit_tracker_flutter_new/repositories/hive/hive_habits_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/hive/hive_completions_repository.dart';
import 'package:habit_tracker_flutter_new/services/mock_data_loader.dart';

// ============================================================================
// 🎛️ FEATURE FLAG - DEMO MODE CONTROL
// ============================================================================
/// Feature flag to control whether the app loads mock data on first run.
///
/// **DEMO MODE (true):**
/// - Loads 8 sample habits with 60 days of realistic completion history
/// - Features streak patterns, weekend effects, and motivation decay
/// - Includes habit descriptions and varied categories
/// - Perfect for demos, evaluations, and testing
/// - Data persists in Hive until manually cleared
/// - App title shows "TrackIt! (DEMO)"
///
/// **PRODUCTION MODE (false):**
/// - Starts with empty database
/// - Normal production behavior
/// - App title shows "TrackIt!"
///
/// **To switch modes:**
/// 1. Change this flag to `true` or `false`
/// 2. Run: `flutter clean && flutter run`
/// 3. This clears Hive and restarts fresh
const bool useMockData = true; // 👈 Change this to toggle demo/production mode
// ============================================================================

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize repositories
  final habitsRepository = HiveHabitsRepository();
  final completionsRepository = HiveCompletionsRepository();

  await habitsRepository.init();
  await completionsRepository.init();

  // Load mock data if feature flag is enabled
  if (useMockData) {
    final mockDataLoader = MockDataLoader(
      habitsRepository: habitsRepository,
      completionsRepository: completionsRepository,
    );
    await mockDataLoader.loadIfNeeded(
      habitCount: 8,
      daysOfHistory: 60,
      forceClear: true, // TEMPORARY: Remove after first run
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
      home: const HomeDashboardScreen(),
    );
  }
}

// Repository providers
final habitsRepositoryProvider = Provider<HiveHabitsRepository>((ref) {
  throw UnimplementedError('Repository must be overridden in ProviderScope');
});

final completionsRepositoryProvider =
    Provider<HiveCompletionsRepository>((ref) {
  throw UnimplementedError('Repository must be overridden in ProviderScope');
});
