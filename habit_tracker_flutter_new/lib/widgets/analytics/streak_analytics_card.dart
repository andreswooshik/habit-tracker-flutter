import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/providers/analytics_providers.dart';
import 'package:habit_tracker_flutter_new/utils/app_constants.dart';

/// Streak Analytics Card
/// Shows top performing habits by current streak
class StreakAnalyticsCard extends ConsumerWidget {
  const StreakAnalyticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakData = ref.watch(streakLeaderboardProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (streakData.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.paddingLarge),
          child: Center(
            child: Text(
              'No streak data available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange),
                SizedBox(width: AppConstants.spacingSmall),
                Text(
                  'Streak Leaderboard',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacingSmall),
            Text(
              'Top habits by current streak',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: AppConstants.spacingLarge),
            
            // Leaderboard entries
            ...streakData.asMap().entries.map((entry) {
              final index = entry.key;
              final streak = entry.value;
              
              return Padding(
                padding: EdgeInsets.only(bottom: AppConstants.spacingMedium),
                child: _StreakEntry(
                  rank: index + 1,
                  habitName: streak.habit.name,
                  currentStreak: streak.currentStreak,
                  longestStreak: streak.longestStreak,
                  categoryColor: streak.habit.category.color,
                ),
              );
            }),
            
            // Stats summary
            if (streakData.isNotEmpty) ...[
              Divider(height: AppConstants.spacingLarge * 2),
              _StreakSummary(streakData: streakData),
            ],
          ],
        ),
      ),
    );
  }
}

class _StreakEntry extends StatelessWidget {
  final int rank;
  final String habitName;
  final int currentStreak;
  final int longestStreak;
  final Color categoryColor;

  const _StreakEntry({
    required this.rank,
    required this.habitName,
    required this.currentStreak,
    required this.longestStreak,
    required this.categoryColor,
  });

  IconData _getMedalIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.military_tech;
      case 3:
        return Icons.workspace_premium;
      default:
        return Icons.grade;
    }
  }

  Color _getMedalColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPersonalBest = currentStreak == longestStreak && currentStreak > 0;
    
    return Container(
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: isPersonalBest
            ? Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Rank icon
          Icon(
            _getMedalIcon(rank),
            color: _getMedalColor(rank),
            size: 28,
          ),
          SizedBox(width: AppConstants.spacingMedium),
          
          // Category indicator
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: categoryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: AppConstants.spacingMedium),
          
          // Habit info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        habitName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPersonalBest) ...[
                      SizedBox(width: AppConstants.spacingSmall),
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: AppConstants.spacingSmall),
                Text(
                  'Best: $longestStreak days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          
          // Current streak
          Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: currentStreak > 0 ? Colors.orange : Colors.grey,
                    size: 20,
                  ),
                  SizedBox(width: AppConstants.spacingSmall),
                  Text(
                    '$currentStreak',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: currentStreak > 0 ? Colors.orange : Colors.grey,
                        ),
                  ),
                ],
              ),
              Text(
                'days',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakSummary extends StatelessWidget {
  final List<HabitStreak> streakData;

  const _StreakSummary({required this.streakData});

  @override
  Widget build(BuildContext context) {
    final totalActiveStreaks = streakData.where((s) => s.currentStreak > 0).length;
    final longestCurrentStreak = streakData.isEmpty ? 0 : streakData.first.currentStreak;
    final avgStreak = streakData.isEmpty
        ? 0.0
        : streakData.map((s) => s.currentStreak).reduce((a, b) => a + b) / streakData.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(
          icon: Icons.whatshot,
          label: 'Active',
          value: '$totalActiveStreaks',
          color: Colors.orange,
        ),
        _StatItem(
          icon: Icons.trending_up,
          label: 'Longest',
          value: '$longestCurrentStreak',
          color: Colors.green,
        ),
        _StatItem(
          icon: Icons.analytics,
          label: 'Average',
          value: avgStreak.toStringAsFixed(1),
          color: Colors.blue,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: AppConstants.spacingSmall),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
