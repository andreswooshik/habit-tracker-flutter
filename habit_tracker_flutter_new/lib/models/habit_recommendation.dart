import 'package:equatable/equatable.dart';

import 'habit_category.dart';
import 'habit_frequency.dart';

/// A suggested habit the user can add with one tap
///
/// Produced by an IRecommendationService; carries everything needed
/// to prefill a real [Habit] plus a short personalized reason.
class HabitRecommendation extends Equatable {
  /// Short habit name, e.g. "Read 10 pages"
  final String name;

  /// One-sentence description of the habit
  final String description;

  /// Suggested category
  final HabitCategory category;

  /// Suggested schedule
  final HabitFrequency frequency;

  /// Why this habit is being suggested to this user
  final String reason;

  const HabitRecommendation({
    required this.name,
    required this.description,
    required this.category,
    required this.frequency,
    required this.reason,
  });

  @override
  List<Object?> get props => [name, description, category, frequency, reason];
}
