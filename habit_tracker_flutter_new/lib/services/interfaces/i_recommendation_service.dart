import '../../models/habit_category.dart';
import '../../models/habit_recommendation.dart';

/// Snapshot of the user's habit landscape handed to a recommendation
/// service
///
/// Plain value object assembled by the caller so services stay
/// decoupled from providers and repositories (DIP), mirroring
/// [ChatCoachContext] and [WeeklySummaryContext].
class RecommendationContext {
  /// Names of all active (non-archived) habits
  final List<String> activeHabitNames;

  /// How many active habits the user has per category
  final Map<HabitCategory, int> habitCountByCategory;

  /// Overall completion rate over the last 7 days (0.0 - 1.0);
  /// 0.0 when nothing was scheduled
  final double recentCompletionRate;

  const RecommendationContext({
    required this.activeHabitNames,
    required this.habitCountByCategory,
    required this.recentCompletionRate,
  });

  /// Whether the user has any habits at all
  bool get hasHabits => activeHabitNames.isNotEmpty;
}

/// Interface for a service that suggests new habits for the user
///
/// Abstraction allows swapping the local catalog-based generator for
/// an LLM-backed implementation without touching UI or state code.
abstract class IRecommendationService {
  /// Suggests up to 3 new habits tailored to [context]
  Future<List<HabitRecommendation>> generateRecommendations(
    RecommendationContext context,
  );
}
