import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/widgets/habit_detail/stats_card.dart';

class QuickStatsGrid extends ConsumerWidget {
  const QuickStatsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(habitInsightsProvider);
    final habitState = ref.watch(habitsProvider);

    final totalHabits = habitState.habits.length;
    final activeHabits = insights.totalActiveHabits;
    final totalCompletions = insights.totalCompletions;
    final perfectDays = insights.perfectDaysCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Quick Stats',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            StatsCard(
              icon: Icons.list_alt,
              title: 'Total Habits',
              value: '$totalHabits',
              color: Colors.blue,
              subtitle: 'Created',
            ),
            StatsCard(
              icon: Icons.check_circle_outline,
              title: 'Active Habits',
              value: '$activeHabits',
              color: Colors.green,
              subtitle: 'In progress',
            ),
            StatsCard(
              icon: Icons.done_all,
              title: 'Completions',
              value: '$totalCompletions',
              color: Colors.orange,
              subtitle: 'All time',
            ),
            StatsCard(
              icon: Icons.stars,
              title: 'Perfect Days',
              value: '$perfectDays',
              color: Colors.purple,
              subtitle: 'This period',
            ),
          ],
        ),
      ],
    );
  }
}
