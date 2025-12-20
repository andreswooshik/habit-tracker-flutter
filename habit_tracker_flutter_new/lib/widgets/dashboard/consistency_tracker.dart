import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';

class ConsistencyTracker extends ConsumerWidget {
  const ConsistencyTracker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(habitInsightsProvider);
    final weeklyConsistency = (insights.weeklyConsistency * 100).toInt();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Consistency Tracker',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 20),

            // Weekly Consistency
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Consistency',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$weeklyConsistency%',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getConsistencyColor(weeklyConsistency),
                              ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Last 7 days',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.black45,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Icon(
                  _getConsistencyIcon(weeklyConsistency),
                  size: 48,
                  color: _getConsistencyColor(weeklyConsistency),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Mini Heatmap (last 30 days)
            _buildMiniHeatmap(ref),

            const SizedBox(height: 20),

            // Streak Comparison
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStreakStat(
                    context,
                    'Current Streak',
                    '${insights.longestCurrentStreak}',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade300,
                  ),
                  _buildStreakStat(
                    context,
                    'Best Streak',
                    '${insights.longestCurrentStreak}', // Using same for now
                    Icons.emoji_events,
                    Colors.amber,
                  ),
                ],
              ),
            ),

            // Tip
            if (weeklyConsistency < 70) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Completing habits daily builds stronger consistency!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniHeatmap(WidgetRef ref) {
    final habitState = ref.read(habitsProvider);
    final completionsState = ref.read(completionsProvider);
    final allHabits = habitState.habits.where((h) => !h.isArchived).toList();

    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    final days = List.generate(
      30,
      (index) => endDate.subtract(Duration(days: 29 - index)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last 30 Days',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: days.map((day) {
            final scheduledHabits =
                allHabits.where((h) => h.isScheduledFor(day)).toList();
            final completedCount = scheduledHabits.where((h) {
              return completionsState.isCompletedOn(h.id, day);
            }).length;

            final rate = scheduledHabits.isEmpty
                ? 0.0
                : completedCount / scheduledHabits.length;

            return Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: _getHeatmapColor(rate),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStreakStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Color _getConsistencyColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  IconData _getConsistencyIcon(int percentage) {
    if (percentage >= 80) return Icons.check_circle;
    if (percentage >= 60) return Icons.trending_up;
    if (percentage >= 40) return Icons.show_chart;
    return Icons.warning_amber_rounded;
  }

  Color _getHeatmapColor(double rate) {
    if (rate >= 0.8) return Colors.green.shade400;
    if (rate >= 0.6) return Colors.green.shade300;
    if (rate >= 0.4) return Colors.green.shade200;
    if (rate > 0) return Colors.green.shade100;
    return Colors.grey.shade200;
  }
}
