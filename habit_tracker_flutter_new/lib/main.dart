import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habit_tracker_flutter_new/config/app_theme.dart';
import 'package:habit_tracker_flutter_new/screens/home_dashboard_screen.dart';
import 'package:habit_tracker_flutter_new/repositories/hive/hive_habits_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/hive/hive_completions_repository.dart';
import 'package:habit_tracker_flutter_new/services/data_generator.dart';

// ============================================================================
// 🎛️ FEATURE FLAG - DEMO MODE CONTROL
// ============================================================================
/// Feature flag to control whether the app loads mock data on first run.
///
/// **DEMO MODE (true):**
/// - Loads 8 sample habits with 60 days of completion history
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

  // 🎲 Load mock data if feature flag is enabled and database is empty
  if (useMockData) {
    await _loadMockDataIfNeeded(habitsRepository, completionsRepository);
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

/// Loads mock data into Hive repositories if the database is empty.
///
/// This function is **idempotent** - it safely skips loading if data already
/// exists in Hive, making it safe to call on every app startup.
///
/// **What it does:**
/// 1. Checks if Hive database already has habits
/// 2. If empty: Generates 8 habits with 60 days of completion history
/// 3. Loads all data into the actual Hive repositories
/// 4. Prints progress messages to console
///
/// **Mock Data Characteristics:**
/// - 8 diverse habits across different categories
/// - 60 days of realistic completion patterns
/// - Fixed random seed (42) for reproducible data
/// - Realistic completion rates (varies per habit)
/// - Some habits more consistent than others
///
/// **Use Cases:**
/// - Demo presentations
/// - Feature evaluations
/// - Manual testing
/// - Screenshot generation
/// - Training materials
///
/// Parameters:
/// - [habitsRepository]: The Hive habits repository to populate
/// - [completionsRepository]: The Hive completions repository to populate
Future<void> _loadMockDataIfNeeded(
  HiveHabitsRepository habitsRepository,
  HiveCompletionsRepository completionsRepository,
) async {
  try {
    // Check if database already has data
    final existingHabits = await habitsRepository.loadHabits();

    if (existingHabits.isNotEmpty) {
      // Data already exists - skip loading to maintain idempotency
      // ignore: avoid_print
      print(
          '\n✅ Hive already has ${existingHabits.length} habits - skipping mock data load\n');
      return;
    }

    // Database is empty - generate and load mock data
    // ignore: avoid_print
    print('\n🎲 useMockData = true: Generating mock data...');

    // Create data generator with fixed seed for reproducibility
    final generator = RandomDataGenerator(seed: 42);

    // Generate complete dataset: 8 habits with 60 days of history
    final mockData = generator.generateCompleteDataset(
      habitCount: 8,
      daysOfHistory: 60,
    );

    // ignore: avoid_print
    print('📝 Loading ${mockData.habits.length} mock habits into Hive...');

    // Load habits into Hive repository
    for (final habit in mockData.habits) {
      await habitsRepository.saveHabit(habit);
    }

    // Load completions into Hive repository
    int totalCompletions = 0;
    for (final entry in mockData.completions.entries) {
      final habitId = entry.key;
      final completionDates = entry.value;

      for (final date in completionDates) {
        await completionsRepository.addCompletion(habitId, date);
        totalCompletions++;
      }
    }

    // Success! Print summary
    // ignore: avoid_print
    print('🎉 Mock data loaded successfully!');
    // ignore: avoid_print
    print('   ✅ ${mockData.habits.length} habits');
    // ignore: avoid_print
    print('   ✅ $totalCompletions total completions');
    // ignore: avoid_print
    print('   ✅ Data persists in Hive until you clear it');
    // ignore: avoid_print
    print('\n💡 To switch to production mode (empty start):');
    // ignore: avoid_print
    print('   1. Set useMockData = false in main.dart');
    // ignore: avoid_print
    print('   2. Run: flutter clean && flutter run\n');
  } catch (e) {
    // Log error but don't crash the app
    // ignore: avoid_print
    print('❌ Error loading mock data: $e');
    // ignore: avoid_print
    print('   App will continue with empty database.\n');
  }
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
