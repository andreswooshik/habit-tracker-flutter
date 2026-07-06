import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_recommendation.dart';
import 'package:habit_tracker_flutter_new/models/recommendations_state.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/utils/app_constants.dart';

/// Smart Habit Recommendations Card
/// Suggests new habits tailored to the user, with one-tap add
class SmartRecommendationsCard extends ConsumerWidget {
  const SmartRecommendationsCard({super.key});

  static const _uuid = Uuid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recommendationsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates, color: colorScheme.primary),
                SizedBox(width: AppConstants.spacingSmall),
                Expanded(
                  child: Text(
                    'Smart Recommendations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (state.hasRecommendations &&
                    !state.isLoading &&
                    state.errorMessage == null)
                  IconButton(
                    tooltip: 'Refresh suggestions',
                    icon: const Icon(Icons.refresh),
                    onPressed: () =>
                        ref.read(recommendationsProvider.notifier).generate(),
                  ),
              ],
            ),
            SizedBox(height: AppConstants.spacingSmall),
            Text(
              'Habit ideas picked for you',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: AppConstants.spacingLarge),
            _buildBody(context, ref, state),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    RecommendationsState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.isLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppConstants.spacingMedium),
          Text(
            'Finding ideas for you...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      );
    }

    if (state.errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                ),
          ),
          SizedBox(height: AppConstants.spacingMedium),
          FilledButton.icon(
            onPressed: () =>
                ref.read(recommendationsProvider.notifier).generate(),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      );
    }

    if (state.hasRecommendations) {
      return Column(
        children: [
          for (final recommendation in state.recommendations)
            Padding(
              padding: EdgeInsets.only(bottom: AppConstants.spacingMedium),
              child: _RecommendationTile(
                recommendation: recommendation,
                onAdd: () => _addHabit(context, ref, recommendation),
              ),
            ),
        ],
      );
    }

    // Empty after generating means every suggestion was added
    if (state.hasGenerated) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All suggestions added — nice!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: AppConstants.spacingMedium),
          FilledButton.icon(
            onPressed: () =>
                ref.read(recommendationsProvider.notifier).generate(),
            icon: const Icon(Icons.tips_and_updates),
            label: const Text('Suggest More'),
          ),
        ],
      );
    }

    return Center(
      child: FilledButton.icon(
        onPressed: () =>
            ref.read(recommendationsProvider.notifier).generate(),
        icon: const Icon(Icons.tips_and_updates),
        label: const Text('Suggest Habits'),
      ),
    );
  }

  Future<void> _addHabit(
    BuildContext context,
    WidgetRef ref,
    HabitRecommendation recommendation,
  ) async {
    final habit = Habit.create(
      id: _uuid.v4(),
      name: recommendation.name,
      description: recommendation.description.isNotEmpty
          ? recommendation.description
          : null,
      frequency: recommendation.frequency,
      category: recommendation.category,
    );

    final added = await ref.read(habitsProvider.notifier).addHabit(habit);
    if (!context.mounted) return;

    if (added) {
      ref.read(recommendationsProvider.notifier).dismiss(recommendation);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${recommendation.name}" added to your habits')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add habit. Please try again.')),
      );
    }
  }
}

class _RecommendationTile extends StatelessWidget {
  final HabitRecommendation recommendation;
  final VoidCallback onAdd;

  const _RecommendationTile({
    required this.recommendation,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Row(
        children: [
          // Category indicator
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: recommendation.category.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: AppConstants.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppConstants.spacingSmall / 2),
                Text(
                  '${recommendation.category.displayName} · '
                  '${recommendation.frequency.displayName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                if (recommendation.reason.isNotEmpty) ...[
                  SizedBox(height: AppConstants.spacingSmall / 2),
                  Text(
                    recommendation.reason,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: AppConstants.spacingMedium),
          FilledButton.tonal(
            onPressed: onAdd,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
