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
      'Drink 8 Glasses Water',
      'Take Vitamins',
      'Healthy Breakfast',
      'Stretch 10 Minutes',
      'Evening Jog',
      'Meal Prep Sunday',
      '8 Hours Sleep',
      'Floss Teeth',
      'Posture Check',
      'Eye Rest Break',
      'Healthy Snack',
    ],
    HabitCategory.fitness: [
      'Gym Workout',
      'Yoga Session',
      'Run 5K',
      '50 Push-ups',
      '2 Min Plank',
      'Swimming',
      'Cycling 30 Min',
      'Weight Training',
      'HIIT Workout',
      'Core Exercises',
      'Leg Day',
      'Cardio Session',
    ],
    HabitCategory.mindfulness: [
      'Morning Meditation',
      'Gratitude Journal',
      'Deep Breathing',
      'Mindful Walking',
      'Evening Reflection',
      'Daily Affirmations',
      'Nature Time',
      'Digital Detox Hour',
      'Body Scan',
      'Mindful Eating',
      'Stress Relief',
      'Present Moment',
    ],
    HabitCategory.productivity: [
      'Daily Planning',
      '2 Hour Focus Block',
      'Inbox Zero',
      'Review Tasks',
      'Learn New Skill',
      'Read Articles',
      'Clear Desk',
      'Time Blocking',
      'Weekly Review',
      'Priority Setting',
      'Deep Work Session',
      'No Distractions',
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
      'Reach Out',
      'Active Listening',
      'Compliment Someone',
      'Social Connection',
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
      'Doodle Break',
      'Poetry Writing',
      'Design Practice',
      'Craft Time',
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
      'Duolingo Lesson',
      'Book Chapter',
      'Educational Video',
      'Practice Coding',
    ],
    HabitCategory.finance: [
      'Track Expenses',
      'Review Budget',
      'Save \$10',
      'Investment Check',
      'Bill Payment',
      'Financial Reading',
      'No Impulse Buy',
      'Meal Budget',
      'Check Accounts',
      'Update Spreadsheet',
      'Savings Goal',
      'Price Compare',
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
      'Morning Routine',
      'Evening Routine',
      'Weekly Check-in',
      'Personal Growth',
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

      // Random creation date (0-30 days ago) - recent habits for demo
      final daysAgo = _random.nextInt(31);
      final createdAt = DateTime.now().subtract(Duration(days: daysAgo));

      // 10% chance of archived (less archived for demo), 15% chance of grace period
      final isArchived = _random.nextDouble() < 0.1;
      final hasGracePeriod = _random.nextDouble() < 0.15;

      // Random target days (14, 21, 30, 60, 90, 365)
      final targetOptions = [14, 21, 30, 60, 90, 365];
      final targetDays = targetOptions[_random.nextInt(targetOptions.length)];

      // Generate a description for the habit
      final description = _generateDescription(name, category);

      habits.add(Habit.create(
        id: _uuid.v4(),
        name: name,
        description: description,
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
    // Normalize to today at midnight to ensure we include today's data
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    final startDate = endDate.subtract(Duration(days: daysOfHistory));

    for (final habit in habits) {
      // Use habit creation date if it's later than startDate
      final habitStartDate = habit.createdAt.isAfter(startDate)
          ? habit.createdAt
          : startDate;

      // Vary completion rate per habit (0.75 to 0.95) - very high for demo
      // This creates realistic variation: some users are very consistent, some struggle
      final baseRate = 0.75 + (_random.nextDouble() * 0.20);
      
      // Create realistic patterns with streaks and breaks
      final completions = <DateTime>{};
      DateTime current = _normalizeDate(habitStartDate);
      final normalizedEnd = _normalizeDate(endDate);
      
      // Simulate streak patterns
      int consecutiveDays = 0;
      int missedDays = 0;
      final streakBonus = _random.nextDouble() * 0.15; // 0-15% bonus when on streak

      while (current.isBefore(normalizedEnd) || current.isAtSameMomentAs(normalizedEnd)) {
        if (habit.isScheduledFor(current)) {
          // Completion rate with streak momentum
          final daysSinceStart = current.difference(habitStartDate).inDays;
          final daysUntilEnd = normalizedEnd.difference(current).inDays;
          
          // Boost recent days (last 7 days) to ensure weekly chart has data
          final recencyBoost = daysUntilEnd <= 7 ? 1.4 : 1.0;
          
          // Slight decay over time but not too aggressive
          final decayFactor = 1.0 - (daysSinceStart / (daysOfHistory * 3));
          
          // Streak bonus - being consistent makes you more likely to continue
          final streakFactor = consecutiveDays > 0 ? (1.0 + streakBonus) : 1.0;
          
          // Weekend effect - slightly lower completion on weekends for some habits
          final isWeekend = current.weekday == DateTime.saturday || current.weekday == DateTime.sunday;
          final weekendFactor = (isWeekend && habit.frequency != HabitFrequency.weekends) ? 0.85 : 1.0;
          
          final adjustedRate = (baseRate * decayFactor * streakFactor * weekendFactor * recencyBoost).clamp(0.7, 1.0);

          if (_random.nextDouble() < adjustedRate) {
            completions.add(current);
            consecutiveDays++;
            missedDays = 0;
          } else {
            missedDays++;
            // Reset streak after 2 missed days
            if (missedDays >= 2) {
              consecutiveDays = 0;
            }
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
    // For demo purposes, all habits are Every Day so all 8 show daily
    // This makes the demo cleaner and avoids confusion
    return HabitFrequency.everyDay;
    
    // Original weighted distribution (uncomment for realistic variation):
    // final value = _random.nextDouble();
    // if (value < 0.5) return HabitFrequency.everyDay;      // 50%
    // if (value < 0.75) return HabitFrequency.weekdays;     // 25%
    // if (value < 0.85) return HabitFrequency.custom;       // 10%
    // return HabitFrequency.weekends;                        // 15%
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

  /// Generates a realistic description for a habit
  String? _generateDescription(String name, HabitCategory category) {
    // 70% chance of having a description
    if (_random.nextDouble() > 0.7) return null;

    final descriptions = {
      'Morning Walk': 'Start the day with a refreshing 20-minute walk',
      'Drink 8 Glasses Water': 'Stay hydrated throughout the day',
      'Take Vitamins': 'Daily multivitamin with breakfast',
      'Gym Workout': 'Full body workout at the gym',
      'Yoga Session': '30 minutes of yoga and stretching',
      'Morning Meditation': '10 minutes of mindfulness meditation',
      'Gratitude Journal': 'Write 3 things I\'m grateful for',
      'Daily Planning': 'Plan tomorrow\'s tasks and priorities',
      'Read 30 Minutes': 'Read before bed to unwind',
      'Track Expenses': 'Log all spending in budget app',
      'Creative Writing': 'Write at least 500 words',
      'Call Family': 'Check in with parents or siblings',
      'Run 5K': 'Morning run around the neighborhood',
      '50 Push-ups': 'Build upper body strength',
      'Deep Breathing': '5 minutes of breathing exercises',
      'Language Practice': 'Practice Spanish on Duolingo',
      'No Impulse Buy': 'Think twice before purchasing',
    };

    return descriptions[name] ?? 'Building this habit for personal growth';
  }
}
