import 'dart:developer' as developer;

import 'package:habit_tracker_flutter_new/repositories/interfaces/i_completions_repository.dart';
import 'package:habit_tracker_flutter_new/repositories/interfaces/i_habits_repository.dart';
import 'package:habit_tracker_flutter_new/services/data_generator.dart';
import 'package:habit_tracker_flutter_new/services/interfaces/i_data_generator.dart';

/// Service responsible for loading mock data into repositories
///
/// Follows SOLID principles:
/// - Single Responsibility: Only handles mock data loading
/// - Open/Closed: Can be extended with different generators
/// - Dependency Inversion: Depends on repository interfaces
class MockDataLoader {
  final IHabitsRepository _habitsRepository;
  final ICompletionsRepository _completionsRepository;
  final IDataGenerator _dataGenerator;

  MockDataLoader({
    required IHabitsRepository habitsRepository,
    required ICompletionsRepository completionsRepository,
    IDataGenerator? dataGenerator,
  })  : _habitsRepository = habitsRepository,
        _completionsRepository = completionsRepository,
        _dataGenerator = dataGenerator ?? RandomDataGenerator(seed: 42);

  /// Loads mock data if the database is empty
  ///
  /// Returns true if data was loaded, false if skipped
  Future<bool> loadIfNeeded({
    int habitCount = 8,
    int daysOfHistory = 60,
    bool forceClear = false,
  }) async {
    try {
      // Force clear if requested (for development/testing)
      if (forceClear) {
        await _habitsRepository.clearAll();
        await _completionsRepository.clearAll();
        _log('Cleared old mock data to regenerate with improvements.');
      }

      // Check if database already has data
      final existingHabits = await _habitsRepository.loadHabits();

      if (existingHabits.isNotEmpty) {
        _log(
          'Hive already has ${existingHabits.length} habits; skipping mock data load.',
        );
        return false;
      }

      // Database is empty - generate and load mock data
      _log('Generating mock data...');

      // Generate complete dataset
      final mockData = _dataGenerator.generateCompleteDataset(
        habitCount: habitCount,
        daysOfHistory: daysOfHistory,
      );

      _log('Loading ${mockData.habits.length} mock habits into storage...');

      // Load habits
      for (final habit in mockData.habits) {
        await _habitsRepository.saveHabit(habit);
      }

      // Load completions
      int totalCompletions = 0;
      for (final entry in mockData.completions.entries) {
        final habitId = entry.key;
        final completionDates = entry.value;

        for (final date in completionDates) {
          await _completionsRepository.addCompletion(habitId, date);
          totalCompletions++;
        }
      }

      // Log success with detailed info
      _logSuccess(mockData, totalCompletions);

      return true;
    } catch (e) {
      _logError(e);
      return false;
    }
  }

  void _log(String message) {
    developer.log(message, name: 'MockDataLoader');
  }

  void _logSuccess(GeneratedData mockData, int totalCompletions) {
    _log('Mock data loaded successfully.');
    _log('${mockData.habits.length} habits');
    _log('$totalCompletions total completions');

    // Debug: Show today's completions
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    int todaysCompletions = 0;

    for (final entry in mockData.completions.entries) {
      if (entry.value.contains(todayNormalized)) {
        todaysCompletions++;
        final habitName =
            mockData.habits.firstWhere((h) => h.id == entry.key).name;
        _log('Today completion: $habitName');
      }
    }

    _log('$todaysCompletions completions for today');
    _log('Data persists in storage until you clear it');
    _log('To switch to production mode with an empty start:');
    _log('1. Set useMockData = false in main.dart');
    _log('2. Run: flutter clean && flutter run');
  }

  void _logError(Object error) {
    _log('Error loading mock data: $error');
    _log('App will continue with an empty database.');
  }
}
