import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../models/habit_frequency.dart';
import 'interfaces/i_data_generator.dart';

/// Random data generator for creating realistic habit samples and completions.
///
/// Generates habits with varied:
/// - Names from predefined templates
/// - Categories (health, productivity, mindfulness, etc.)
/// - Frequencies (daily, weekdays, custom patterns)
/// - Creation dates (recent to older)
///
/// Completion patterns mimic realistic user behavior with configurable rates.
class RandomDataGenerator implements IDataGenerator {
  final Random _random;
  final Uuid _uuid;

  /// Creates a [RandomDataGenerator] with optional seed for reproducibility.
  ///
  /// If [seed] is provided, generates deterministic sequences (useful for testing).
  RandomDataGenerator({int? seed})
      : _random = Random(seed),
        _uuid = const Uuid();

  // Predefined habit name templates by category
  static const Map<HabitCategory, List<String>> _habitTemplates = {
    HabitCategory.health: [
      'Morning Walk',
      'Drink Water',
      'Take Vitamins',
      'Healthy Breakfast',
      'Stretch',
      'Evening Jog',
      'Meal Prep',
      '8 Hours Sleep',
    ],
    HabitCategory.fitness: [
      'Gym Workout',
      'Yoga Session',
      'Run 5K',
      'Push-ups',
      'Planks',
      'Swimming',
      'Cycling',
      'Weight Training',
    ],
    HabitCategory.mindfulness: [
      'Morning Meditation',
      'Gratitude Journal',
      'Deep Breathing',
      'Mindful Walking',
      'Evening Reflection',
      'Affirmations',
      'Nature Time',
      'Digital Detox',
    ],
    HabitCategory.productivity: [
      'Daily Planning',
      'Focus Block',
      'Inbox Zero',
      'Review Tasks',
      'Learn New Skill',
      'Read Articles',
      'Clear Desk',
      'Time Blocking',
    ],
    HabitCategory.social: [
      'Call Family',
      'Text Friend',
      'Coffee Chat',
      'Network Event',
      'Help Someone',
      'Group Activity',
      'Volunteer Work',
      'Quality Time',
    ],
    HabitCategory.creativity: [
      'Creative Writing',
      'Sketch Daily',
      'Music Practice',
      'Photo Walk',
      'Art Project',
      'Brainstorm Ideas',
      'Learn Instrument',
      'Creative Reading',
    ],
    HabitCategory.learning: [
      'Read 30 Minutes',
      'Online Course',
      'Language Practice',
      'Watch Tutorial',
      'Take Notes',
      'Study Session',
      'Podcast Listen',
      'Skill Practice',
    ],
    HabitCategory.finance: [
      'Track Expenses',
      'Review Budget',
      'Save Money',
      'Investment Check',
      'Bill Payment',
      'Financial Reading',
      'No Impulse Buy',
      'Meal Budget',
    ],
    HabitCategory.other: [
      'Daily Habit',
      'Routine Task',
      'Good Deed',
      'Positive Action',
      'Life Goal',
      'Self Improvement',
      'Daily Practice',
      'Consistent Action',
    ],
  };

  @override
  List<Habit> generateHabits(int count) {
    if (count <= 0) {
      throw ArgumentError('Count must be greater than 0, got $count');
    }

    final habits = <Habit>[];
    final usedNames = <String>{};
    final categories = HabitCategory.values.toList();

    for (int i = 0; i < count; i++) {
      // Pick random category
      final category = categories[_random.nextInt(categories.length)];
      
      // Get unique name
      String name = _getUniqueName(category, usedNames);
      
      // Pick random frequency
      final frequency = _randomFrequency();
      final customDays = frequency == HabitFrequency.custom
          ? _randomCustomDays()
          : null;

      // Random creation date (0-90 days ago)
      final daysAgo = _random.nextInt(91);
      final createdAt = DateTime.now().subtract(Duration(days: daysAgo));

      // 20% chance of archived, 10% chance of grace period
      final isArchived = _random.nextDouble() < 0.2;
      final hasGracePeriod = _random.nextDouble() < 0.1;

      // Random target days (14, 21, 30, 60, 90, 365)
      final targetOptions = [14, 21, 30, 60, 90, 365];
      final targetDays = targetOptions[_random.nextInt(targetOptions.length)];

      habits.add(Habit.create(
        id: _uuid.v4(),
        name: name,
        frequency: frequency,
        customDays: customDays,
        category: category,
        targetDays: targetDays,
        hasGracePeriod: hasGracePeriod,
      ).copyWith(
        isArchived: isArchived,
        createdAt: createdAt,
      ));
    }

    return habits;
  }

  @override
  Set<DateTime> generateCompletions({
    required Habit habit,
    required DateTime startDate,
    required DateTime endDate,
    double completionRate = 0.7,
  }) {
    if (endDate.isBefore(startDate)) {
      throw ArgumentError(
        'endDate must be after startDate. '
        'Got startDate: $startDate, endDate: $endDate',
      );
    }

    if (completionRate < 0.0 || completionRate > 1.0) {
      throw ArgumentError(
        'completionRate must be between 0.0 and 1.0, got $completionRate',
      );
    }

    final completions = <DateTime>{};
    final normalizedStart = _normalizeDate(startDate);
    final normalizedEnd = _normalizeDate(endDate);

    // Iterate through each day in range
    DateTime current = normalizedStart;
    while (current.isBefore(normalizedEnd) || current.isAtSameMomentAs(normalizedEnd)) {
      // Check if habit is scheduled for this day
      if (habit.isScheduledFor(current)) {
        // Apply completion rate with slight randomness
        if (_random.nextDouble() < completionRate) {
          completions.add(current);
        }
      }
      
      current = current.add(const Duration(days: 1));
    }

    return completions;
  }

  @override
  GeneratedData generateCompleteDataset({
    int habitCount = 10,
    int daysOfHistory = 30,
  }) {
    if (habitCount <= 0) {
      throw ArgumentError('habitCount must be greater than 0, got $habitCount');
    }

    if (daysOfHistory < 0) {
      throw ArgumentError('daysOfHistory must be non-negative, got $daysOfHistory');
    }

    // Generate habits
    final habits = generateHabits(habitCount);

    // Generate completions for each habit
    final completionsMap = <String, Set<DateTime>>{};
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: daysOfHistory));

    for (final habit in habits) {
      // Use habit creation date if it's later than startDate
      final habitStartDate = habit.createdAt.isAfter(startDate)
          ? habit.createdAt
          : startDate;

      // Vary completion rate per habit (0.4 to 1.0)
      // This creates realistic variation: some users are very consistent, some struggle
      final baseRate = 0.4 + (_random.nextDouble() * 0.6);
      
      // Create a "decay" pattern - users tend to be more consistent at the start
      final completions = <DateTime>{};
      DateTime current = _normalizeDate(habitStartDate);
      final normalizedEnd = _normalizeDate(endDate);

      while (current.isBefore(normalizedEnd) || current.isAtSameMomentAs(normalizedEnd)) {
        if (habit.isScheduledFor(current)) {
          // Completion rate decays over time (simulate motivation decline)
          final daysSinceStart = current.difference(habitStartDate).inDays;
          final decayFactor = 1.0 - (daysSinceStart / (daysOfHistory * 2));
          final adjustedRate = (baseRate * decayFactor).clamp(0.3, 1.0);

          if (_random.nextDouble() < adjustedRate) {
            completions.add(current);
          }
        }
        
        current = current.add(const Duration(days: 1));
      }

      completionsMap[habit.id] = completions;
    }

    return GeneratedData(
      habits: habits,
      completions: completionsMap,
    );
  }

  /// Gets a unique habit name for the category.
  String _getUniqueName(HabitCategory category, Set<String> usedNames) {
    final templates = _habitTemplates[category] ?? _habitTemplates[HabitCategory.other]!;
    
    // Try to get an unused name
    for (int attempt = 0; attempt < 100; attempt++) {
      final name = templates[_random.nextInt(templates.length)];
      if (!usedNames.contains(name)) {
        usedNames.add(name);
        return name;
      }
    }

    // If all names used, add a number suffix
    final baseName = templates[_random.nextInt(templates.length)];
    int suffix = 2;
    while (usedNames.contains('$baseName $suffix')) {
      suffix++;
    }
    final uniqueName = '$baseName $suffix';
    usedNames.add(uniqueName);
    return uniqueName;
  }

  /// Returns a random frequency with realistic distribution.
  HabitFrequency _randomFrequency() {
    final value = _random.nextDouble();
    
    // Weighted distribution (more daily/weekday habits)
    if (value < 0.5) return HabitFrequency.everyDay;      // 50%
    if (value < 0.75) return HabitFrequency.weekdays;     // 25%
    if (value < 0.85) return HabitFrequency.custom;       // 10%
    return HabitFrequency.weekends;                        // 15%
  }

  /// Generates random custom days (1-7 for Monday-Sunday).
  List<int> _randomCustomDays() {
    final numDays = 1 + _random.nextInt(5); // 1-5 days
    final days = <int>{};
    
    while (days.length < numDays) {
      days.add(1 + _random.nextInt(7)); // 1-7 (Mon-Sun)
    }
    
    return days.toList()..sort();
  }

  /// Normalizes a date to midnight (removes time component).
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
