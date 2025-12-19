/// Service providers for business logic.
///
/// This library exports Riverpod providers for services,
/// following the Dependency Inversion Principle (DIP).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'streak_calculator.dart';
import 'data_generator.dart';
import 'interfaces/i_streak_calculator.dart';
import 'interfaces/i_data_generator.dart';

/// Provider for streak calculation service.
///
/// Returns a [BasicStreakCalculator] that implements [IStreakCalculator].
/// Used by streak-dependent providers to calculate current and longest streaks.
///
/// Example usage:
/// ```dart
/// final calculator = ref.read(streakCalculatorProvider);
/// final streak = calculator.calculateStreak(habit, completions);
/// ```
final streakCalculatorProvider = Provider<IStreakCalculator>((ref) {
  return const BasicStreakCalculator();
});

/// Provider for data generation service.
///
/// Returns a [RandomDataGenerator] that implements [IDataGenerator].
/// Used for:
/// - Demo mode
/// - Onboarding
/// - Testing with realistic data
///
/// Example usage:
/// ```dart
/// final generator = ref.read(dataGeneratorProvider);
/// final habits = generator.generateHabits(10);
/// final completions = generator.generateCompletions(habit: habit, ...);
/// ```
final dataGeneratorProvider = Provider<IDataGenerator>((ref) {
  return RandomDataGenerator();
});
