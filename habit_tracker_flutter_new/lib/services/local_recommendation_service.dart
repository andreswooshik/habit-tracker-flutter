import '../models/habit_category.dart';
import '../models/habit_frequency.dart';
import '../models/habit_recommendation.dart';
import 'interfaces/i_recommendation_service.dart';

/// One suggestion template in the built-in catalog
class _CatalogEntry {
  final String name;
  final String description;
  final HabitCategory category;
  final HabitFrequency frequency;

  /// Lowercase keyword used to skip suggestions the user already has
  /// a similar habit for (matched against existing habit names)
  final String keyword;

  const _CatalogEntry(
    this.name,
    this.description,
    this.category,
    this.frequency,
    this.keyword,
  );
}

/// Local, catalog-based implementation of [IRecommendationService]
///
/// Picks from a curated list of starter habits, skipping ones similar
/// to habits the user already has and preferring categories the user
/// hasn't explored yet. Deterministic and fully offline — used when no
/// Gemini API key is configured, mirroring the chat and weekly summary
/// fallbacks.
class LocalRecommendationService implements IRecommendationService {
  const LocalRecommendationService();

  static const _catalog = [
    _CatalogEntry('Drink 8 glasses of water', 'Stay hydrated through the day',
        HabitCategory.health, HabitFrequency.everyDay, 'water'),
    _CatalogEntry('Take a 15-minute walk', 'A short daily walk to reset',
        HabitCategory.fitness, HabitFrequency.everyDay, 'walk'),
    _CatalogEntry('Read 10 pages', 'Small daily reading adds up fast',
        HabitCategory.learning, HabitFrequency.everyDay, 'read'),
    _CatalogEntry('Meditate for 5 minutes', 'A short daily mindfulness break',
        HabitCategory.mindfulness, HabitFrequency.everyDay, 'meditat'),
    _CatalogEntry('Plan tomorrow\'s top 3 tasks', 'End the workday with a plan',
        HabitCategory.productivity, HabitFrequency.weekdays, 'plan'),
    _CatalogEntry('Write 3 things you\'re grateful for',
        'A quick gratitude journal before bed', HabitCategory.mindfulness,
        HabitFrequency.everyDay, 'gratitude'),
    _CatalogEntry('Message a friend', 'Keep your connections warm',
        HabitCategory.social, HabitFrequency.weekends, 'friend'),
    _CatalogEntry('Track your spending', 'Note what you spent today',
        HabitCategory.finance, HabitFrequency.everyDay, 'spend'),
    _CatalogEntry('Sketch for 10 minutes', 'Loosen up with a daily doodle',
        HabitCategory.creativity, HabitFrequency.weekends, 'sketch'),
    _CatalogEntry('Lights out by 11pm', 'Protect your sleep schedule',
        HabitCategory.health, HabitFrequency.everyDay, 'sleep'),
    _CatalogEntry('Stretch for 10 minutes', 'Ease into the morning',
        HabitCategory.fitness, HabitFrequency.everyDay, 'stretch'),
    _CatalogEntry('Clear your inbox', 'A quick end-of-day email sweep',
        HabitCategory.productivity, HabitFrequency.weekdays, 'inbox'),
  ];

  @override
  Future<List<HabitRecommendation>> generateRecommendations(
    RecommendationContext context,
  ) async {
    final existingNames =
        context.activeHabitNames.map((n) => n.toLowerCase()).toList();

    final candidates = _catalog
        .where((entry) =>
            !existingNames.any((name) => name.contains(entry.keyword)))
        .toList();

    // Prefer categories the user hasn't explored yet; ties keep
    // catalog order (sort is stable)
    candidates.sort((a, b) => (context.habitCountByCategory[a.category] ?? 0)
        .compareTo(context.habitCountByCategory[b.category] ?? 0));

    return candidates
        .take(3)
        .map((entry) => HabitRecommendation(
              name: entry.name,
              description: entry.description,
              category: entry.category,
              frequency: entry.frequency,
              reason: _reasonFor(entry, context),
            ))
        .toList();
  }

  String _reasonFor(_CatalogEntry entry, RecommendationContext context) {
    if (!context.hasHabits) {
      return 'A simple habit to get your tracker started.';
    }
    final categoryCount = context.habitCountByCategory[entry.category] ?? 0;
    if (categoryCount == 0) {
      return 'You don\'t have any ${entry.category.displayName} habits yet '
          '— this is an easy way to start.';
    }
    if (context.recentCompletionRate < 0.5) {
      return 'A small, easy win to rebuild momentum this week.';
    }
    return 'Builds on your ${entry.category.displayName} routine.';
  }
}
