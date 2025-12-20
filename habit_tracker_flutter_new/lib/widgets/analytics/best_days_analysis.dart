import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/providers/analytics_providers.dart';
import 'package:habit_tracker_flutter_new/utils/app_constants.dart';

/// Best Days Analysis Card
/// Shows which days of the week have highest/lowest completion rates
class BestDaysAnalysis extends ConsumerWidget {
  const BestDaysAnalysis({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekdayData = ref.watch(weekdayPerformanceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (weekdayData.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.paddingLarge),
          child: Center(
            child: Text(
              'No weekday data available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      );
    }

    final sortedByRate = List<DayPerformance>.from(weekdayData)
      ..sort((a, b) => b.completionRate.compareTo(a.completionRate));
    
    final bestDay = sortedByRate.first;
    final worstDay = sortedByRate.last;
    final avgRate = weekdayData.isEmpty
        ? 0.0
        : weekdayData.map((d) => d.completionRate).reduce((a, b) => a + b) / weekdayData.length;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: colorScheme.primary),
                SizedBox(width: AppConstants.spacingSmall),
                Text(
                  'Best Days Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacingSmall),
            Text(
              'Your performance by day of week',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: AppConstants.spacingLarge),
            
            // Bar chart
            ...weekdayData.map((day) {
              final isMaxHeight = day.completionRate == sortedByRate.first.completionRate;
              final barColor = isMaxHeight ? Colors.green : colorScheme.primary;
              
              return Padding(
                padding: EdgeInsets.only(bottom: AppConstants.spacingMedium),
                child: _DayBar(
                  dayName: day.dayName,
                  completionRate: day.completionRate,
                  color: barColor,
                  totalScheduled: day.totalScheduled,
                  totalCompleted: day.totalCompleted,
                ),
              );
            }),
            
            SizedBox(height: AppConstants.spacingLarge),
            
            // Insights
            _DayInsights(
              bestDay: bestDay,
              worstDay: worstDay,
              avgRate: avgRate,
            ),
          ],
        ),
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final String dayName;
  final double completionRate;
  final Color color;
  final int totalScheduled;
  final int totalCompleted;

  const _DayBar({
    required this.dayName,
    required this.completionRate,
    required this.color,
    required this.totalScheduled,
    required this.totalCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 60,
              child: Text(
                dayName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                child: Stack(
                  children: [
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: completionRate,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${(completionRate * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                  SizedBox(width: AppConstants.spacingSmall),
                  Text(
                    '($totalCompleted/$totalScheduled)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DayInsights extends StatelessWidget {
  final DayPerformance bestDay;
  final DayPerformance worstDay;
  final double avgRate;

  const _DayInsights({
    required this.bestDay,
    required this.worstDay,
    required this.avgRate,
  });

  String _getInsightText() {
    if (bestDay.completionRate > 0.8) {
      return '${bestDay.fullDayName}s are your powerhouse days! Keep up the momentum.';
    } else if (worstDay.completionRate < 0.5 && worstDay.totalScheduled > 0) {
      return '${worstDay.fullDayName}s need attention. Consider rescheduling demanding habits.';
    } else if (avgRate > 0.7) {
      return 'Consistent performance across the week! Well done.';
    } else {
      return 'Focus on improving ${worstDay.fullDayName}s to boost your overall completion rate.';
    }
  }

  IconData _getInsightIcon() {
    if (bestDay.completionRate > 0.8) {
      return Icons.celebration;
    } else if (worstDay.completionRate < 0.5) {
      return Icons.info_outline;
    } else {
      return Icons.tips_and_updates;
    }
  }

  Color _getInsightColor(BuildContext context) {
    if (bestDay.completionRate > 0.8) {
      return Colors.green;
    } else if (worstDay.completionRate < 0.5) {
      return Colors.orange;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final insightColor = _getInsightColor(context);
    
    return Container(
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: insightColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: insightColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getInsightIcon(), color: insightColor, size: 20),
              SizedBox(width: AppConstants.spacingSmall),
              Text(
                'Insight',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: insightColor,
                    ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingSmall),
          Text(
            _getInsightText(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: AppConstants.spacingMedium),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.trending_up,
                  label: 'Best Day',
                  value: bestDay.dayName,
                  subtitle: '${(bestDay.completionRate * 100).toStringAsFixed(0)}%',
                  color: Colors.green,
                ),
              ),
              SizedBox(width: AppConstants.spacingSmall),
              Expanded(
                child: _MiniStat(
                  icon: Icons.analytics,
                  label: 'Average',
                  value: '${(avgRate * 100).toStringAsFixed(0)}%',
                  subtitle: 'across week',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: AppConstants.spacingSmall),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingSmall),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
