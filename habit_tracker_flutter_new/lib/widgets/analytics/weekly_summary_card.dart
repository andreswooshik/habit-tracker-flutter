import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/weekly_summary_state.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/utils/app_constants.dart';

/// AI Weekly Summary Card
/// Generates a short narrative recap of the last 7 days on demand
class WeeklySummaryCard extends ConsumerWidget {
  const WeeklySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weeklySummaryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.primary),
                SizedBox(width: AppConstants.spacingSmall),
                Expanded(
                  child: Text(
                    'AI Weekly Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (state.hasSummary && !state.isGenerating && state.errorMessage == null)
                  IconButton(
                    tooltip: 'Regenerate',
                    icon: const Icon(Icons.refresh),
                    onPressed: () =>
                        ref.read(weeklySummaryProvider.notifier).generate(),
                  ),
              ],
            ),
            SizedBox(height: AppConstants.spacingSmall),
            Text(
              'Your last 7 days, recapped by your coach',
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
    WeeklySummaryState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.isGenerating) {
      return Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppConstants.spacingMedium),
          Text(
            'Writing your recap...',
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
                ref.read(weeklySummaryProvider.notifier).generate(),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      );
    }

    if (state.hasSummary) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        child: Text(
          state.summary!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
      );
    }

    return Center(
      child: FilledButton.icon(
        onPressed: () => ref.read(weeklySummaryProvider.notifier).generate(),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generate Summary'),
      ),
    );
  }
}
