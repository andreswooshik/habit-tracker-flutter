import '../../models/habit.dart';

/// Interface for generating sample habit data for testing and demonstration.
///
/// Defines the contract for data generation services, enabling:
/// - Realistic test data creation
/// - Demo mode population
/// - Onboarding examples
/// - Multiple implementation strategies (randomized, template-based, etc.)
///
/// This interface follows the Interface Segregation Principle (ISP) by providing
/// focused data generation capabilities without unnecessary dependencies.
///
/// Example implementations might include:
/// - `RandomDataGenerator`: Generates random realistic data
/// - `TemplateDataGenerator`: Uses predefined templates
/// - `SeededDataGenerator`: Reproducible data for testing
abstract class IDataGenerator {
  /// Generates a list of sample habits with realistic data.
  ///
  /// Creates habits spanning different:
  /// - Categories (health, productivity, mindfulness, etc.)
  /// - Frequencies (daily, specific days, custom intervals)
  /// - Creation dates (recent to older)
  /// - Active/archived states
  ///
  /// Useful for:
  /// - Initial app setup and onboarding
  /// - Demo mode for app store screenshots
  /// - Testing UI with realistic data volumes
  /// - User tutorials and walkthroughs
  ///
  /// Examples:
  /// ```dart
  /// // Generate 5 habits for demo
  /// final demoHabits = generator.generateHabits(5);
  /// for (final habit in demoHabits) {
  ///   habitsNotifier.addHabit(habit);
  /// }
  ///
  /// // Generate many habits for stress testing
  /// final stressTest = generator.generateHabits(100);
  /// ```
  ///
  /// Parameters:
  /// - [count]: Number of habits to generate (must be > 0)
  ///
  /// Returns: List of [Habit] objects with valid, unique IDs
  ///
  /// Characteristics of generated habits:
  /// - ✅ Unique UUIDs for each habit
  /// - ✅ Valid names (realistic habit descriptions)
  /// - ✅ Distributed across all categories
  /// - ✅ Mix of frequencies (not just daily)
  /// - ✅ Some archived, mostly active
  /// - ✅ Varied creation dates
  ///
  /// Throws:
  /// - [ArgumentError] if count <= 0
  List<Habit> generateHabits(int count);

  /// Generates sample completion data for a given habit over a date range.
  ///
  /// Creates realistic completion patterns based on:
  /// - Habit frequency requirements
  /// - Optional completion rate (how often the user completes it)
  /// - Date range constraints
  /// - Natural variation (humans aren't perfectly consistent)
  ///
  /// Useful for:
  /// - Generating historical data for new demo habits
  /// - Testing streak calculations
  /// - Populating insights and statistics
  /// - Time-series visualizations
  ///
  /// Examples:
  /// ```dart
  /// // Generate 30 days of completions (80% completion rate)
  /// final habit = Habit.create(/*...*/);
  /// final completions = generator.generateCompletions(
  ///   habit: habit,
  ///   startDate: DateTime.now().subtract(Duration(days: 30)),
  ///   endDate: DateTime.now(),
  ///   completionRate: 0.8,  // 80% of expected completions
  /// );
  ///
  /// // Perfect completion for achievement testing
  /// final perfectCompletions = generator.generateCompletions(
  ///   habit: dailyHabit,
  ///   startDate: DateTime(2024, 1, 1),
  ///   endDate: DateTime(2024, 1, 31),
  ///   completionRate: 1.0,  // Every single day
  /// );
  /// ```
  ///
  /// Parameters:
  /// - [habit]: The habit to generate completions for (frequency matters)
  /// - [startDate]: Beginning of date range (inclusive)
  /// - [endDate]: End of date range (inclusive)
  /// - [completionRate]: Probability of completion (0.0 to 1.0), defaults to 0.7
  ///
  /// Returns: Set of [DateTime] objects (normalized to midnight)
  ///
  /// Behavior:
  /// - Respects habit frequency (only generates on valid days)
  /// - Applies completion rate probabilistically
  /// - All dates normalized (time stripped)
  /// - No dates outside [startDate, endDate] range
  ///
  /// Examples of completion rates:
  /// - `1.0`: Perfect consistency (every expected day)
  /// - `0.7`: Good (70% of expected completions)
  /// - `0.5`: Average (half the expected completions)
  /// - `0.3`: Struggling (30% completion rate)
  ///
  /// Throws:
  /// - [ArgumentError] if endDate < startDate
  /// - [ArgumentError] if completionRate not in [0.0, 1.0]
  Set<DateTime> generateCompletions({
    required Habit habit,
    required DateTime startDate,
    required DateTime endDate,
    double completionRate = 0.7,
  });

  /// Generates a complete demo dataset: habits + their completion histories.
  ///
  /// Creates a cohesive set of habits with realistic completion patterns,
  /// perfect for:
  /// - App onboarding (show users what filled state looks like)
  /// - Demo mode in app stores
  /// - Integration testing with full data
  /// - User tutorials
  ///
  /// Examples:
  /// ```dart
  /// // Generate complete demo data
  /// final data = generator.generateCompleteDataset(
  ///   habitCount: 8,
  ///   daysOfHistory: 60,
  /// );
  ///
  /// // Load into providers
  /// habitsNotifier.loadHabits(data.habits);
  /// completionsNotifier.loadCompletions(data.completions);
  /// ```
  ///
  /// Parameters:
  /// - [habitCount]: Number of habits to generate (default: 10)
  /// - [daysOfHistory]: How many days back to generate completions (default: 30)
  ///
  /// Returns: [GeneratedData] containing:
  /// - `habits`: List of generated habits
  /// - `completions`: Map of habitId -> Set<DateTime> completions
  ///
  /// Generated data characteristics:
  /// - ✅ Varied completion rates per habit (some consistent, some struggling)
  /// - ✅ Mix of active streaks and broken streaks
  /// - ✅ Some habits with gaps, some perfect
  /// - ✅ Realistic patterns (better at start, taper off)
  ///
  /// Throws:
  /// - [ArgumentError] if habitCount <= 0 or daysOfHistory < 0
  GeneratedData generateCompleteDataset({
    int habitCount = 10,
    int daysOfHistory = 30,
  });
}

/// Container for generated demo data.
///
/// Returned by [IDataGenerator.generateCompleteDataset] to provide
/// a complete set of habits with their completion histories.
class GeneratedData {
  /// The list of generated habits.
  final List<Habit> habits;

  /// Map of habit IDs to their completion date sets.
  ///
  /// Structure: `Map<String habitId, Set<DateTime> completionDates>`
  final Map<String, Set<DateTime>> completions;

  /// Creates a [GeneratedData] instance.
  ///
  /// Parameters:
  /// - [habits]: List of habit objects
  /// - [completions]: Map of habit IDs to completion dates
  const GeneratedData({
    required this.habits,
    required this.completions,
  });

  /// Creates an empty dataset with no habits or completions.
  const GeneratedData.empty()
      : habits = const [],
        completions = const {};
}

// Note: This interface depends on:
// - Habit model (from lib/models/habit.dart)
// - DateTime (from dart:core)
//
// Implementations will be created in lib/services/ directory
