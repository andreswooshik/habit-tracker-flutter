import 'package:equatable/equatable.dart';

/// Immutable state container for the AI weekly summary
///
/// Mirrors the structure of [ChatState]: the generated text, a busy
/// flag, and an optional error message.
class WeeklySummaryState extends Equatable {
  /// The generated summary, or null if none has been generated yet
  final String? summary;

  /// When [summary] was generated, or null if none yet
  final DateTime? generatedAt;

  /// Whether a summary is currently being generated
  final bool isGenerating;

  /// Error message if the last generation failed
  final String? errorMessage;

  const WeeklySummaryState({
    this.summary,
    this.generatedAt,
    this.isGenerating = false,
    this.errorMessage,
  });

  /// Factory constructor for the initial empty state
  factory WeeklySummaryState.initial() => const WeeklySummaryState();

  /// Whether a summary has been generated
  bool get hasSummary => summary != null;

  /// Returns a copy with the given fields replaced
  ///
  /// Pass [clearError] to explicitly reset [errorMessage] to null.
  WeeklySummaryState copyWith({
    String? summary,
    DateTime? generatedAt,
    bool? isGenerating,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WeeklySummaryState(
      summary: summary ?? this.summary,
      generatedAt: generatedAt ?? this.generatedAt,
      isGenerating: isGenerating ?? this.isGenerating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [summary, generatedAt, isGenerating, errorMessage];
}
