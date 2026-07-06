import 'package:equatable/equatable.dart';

import 'habit_recommendation.dart';

/// Immutable state container for smart habit recommendations
///
/// Mirrors the structure of [WeeklySummaryState]: the loaded
/// suggestions, a busy flag, and an optional error message.
class RecommendationsState extends Equatable {
  /// Current suggestions (shrinks as the user adds them)
  final List<HabitRecommendation> recommendations;

  /// Whether suggestions are currently being generated
  final bool isLoading;

  /// Whether a generation has completed at least once — distinguishes
  /// the initial empty state from "all suggestions added"
  final bool hasGenerated;

  /// Error message if the last generation failed
  final String? errorMessage;

  const RecommendationsState({
    this.recommendations = const [],
    this.isLoading = false,
    this.hasGenerated = false,
    this.errorMessage,
  });

  /// Factory constructor for the initial empty state
  factory RecommendationsState.initial() => const RecommendationsState();

  /// Whether there are suggestions to show
  bool get hasRecommendations => recommendations.isNotEmpty;

  /// Returns a copy with the given fields replaced
  ///
  /// Pass [clearError] to explicitly reset [errorMessage] to null.
  RecommendationsState copyWith({
    List<HabitRecommendation>? recommendations,
    bool? isLoading,
    bool? hasGenerated,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RecommendationsState(
      recommendations: recommendations ?? this.recommendations,
      isLoading: isLoading ?? this.isLoading,
      hasGenerated: hasGenerated ?? this.hasGenerated,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [recommendations, isLoading, hasGenerated, errorMessage];
}
