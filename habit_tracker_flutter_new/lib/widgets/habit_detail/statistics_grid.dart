import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/habit_insights.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/widgets/habit_detail/stats_card.dart';

class StatisticsGrid extends ConsumerWidget {
  final String habitId;
  final HabitInsights insights;

  const StatisticsGrid({
    super.key,
    required this.habitId,
    required this.insights,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Calculate habit-specific stats
    final completionsState = ref.watch(completionsProvider);
    final habitCompletions = completionsState.completions[habitId] ?? {};
    final totalCompletions = habitCompletions.length;

    // Calculate completion rate for this habit (last 30 days)
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentCompletions = habitCompletions.where((date) {
      return date.isAfter(thirtyDaysAgo);
    }).length;
    final completionRate = (recentCompletions / 30 * 100).clamp(0, 100);

    // Use insights for weekly consistency
    final weeklyConsistency = (insights.weeklyConsistency * 100).clamp(0, 100);

    // Calculate perfect days for this specific habit
    final perfectDays = _calculatePerfectDays(habitCompletions);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              StatsCard(
                icon: Icons.percent,
                title: 'Completion Rate',
                value: '${completionRate.toStringAsFixed(0)}%',
                color: Colors.blue,
                subtitle: 'Last 30 days',
              ),
              StatsCard(
                icon: Icons.trending_up,
                title: 'Weekly Consistency',
                value: '${weeklyConsistency.toStringAsFixed(0)}%',
                color: Colors.green,
                subtitle: 'Last 7 days',
              ),
              StatsCard(
                icon: Icons.stars,
                title: 'Perfect Days',
                value: '$perfectDays',
                color: Colors.purple,
                subtitle: 'All time',
              ),
              StatsCard(
                icon: Icons.check_circle,
                title: 'Total Completions',
                value: '$totalCompletions',
                color: Colors.orange,
                subtitle: 'All time',
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculatePerfectDays(Set<DateTime> completions) {
    // Perfect days = consecutive completions
    if (completions.isEmpty) return 0;

    final sortedDates = completions.toList()..sort();
    int perfectDays = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (diff == 1) {
        perfectDays++;
      }
    }

    return perfectDays;
  }
}
