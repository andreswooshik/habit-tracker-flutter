import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/providers/analytics_providers.dart';
import 'package:habit_tracker_flutter_new/utils/app_constants.dart';

/// Best Days insight card — the historical aggregate.
///
/// Deliberately contains NO weekday timeline: a per-day bar list reads
/// as "this week's scorecard", so a Monday user sees "Tue 0%" and
/// feels they failed a day that hasn't happened. The current cycle
/// lives in ThisWeekCard; this card answers "what's my typical week?"
/// with a sentence and two stat tiles, plus a confidence banner while
/// the sample is still too small to judge.
class BestDaysAnalysis extends ConsumerWidget {
  const BestDaysAnalysis({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekdayData = ref.watch(weekdayPerformanceProvider);
    final timeRange = ref.watch(selectedTimeRangeProvider);
    final trackedDays = ref.watch(trackedDaysCountProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Only weekdays that had scheduled habits carry signal — a day
    // with nothing scheduled is "no data", not 0% performance
    final daysWithData =
        weekdayData.where((d) => d.totalScheduled > 0).toList();

    if (daysWithData.isEmpty) {
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

    final sortedByRate = List<DayPerformance>.from(daysWithData)
      ..sort((a, b) => b.completionRate.compareTo(a.completionRate));

    final bestDay = sortedByRate.first;
    final worstDay = sortedByRate.last;
    final avgRate =
        daysWithData.map((d) => d.completionRate).reduce((a, b) => a + b) /
            daysWithData.length;

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
                  'Best Days',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacingSmall),
            Text(
              // "typical" + the explicit window keep this from reading
              // as the current week's scorecard
              'Your typical week · averaged over the ${timeRange.description}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: AppConstants.spacingLarge),
            Text(
              _insightSentence(daysWithData, bestDay, worstDay),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: AppConstants.spacingLarge),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.trending_up,
                    label: 'Best day',
                    value: bestDay.dayName,
                    subtitle: _percent(bestDay.completionRate),
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: AppConstants.spacingSmall),
                Expanded(
                  child: daysWithData.length > 1
                      ? _MiniStat(
                          icon: Icons.flag_outlined,
                          label: 'Focus day',
                          value: worstDay.dayName,
                          subtitle: _percent(worstDay.completionRate),
                          color: colorScheme.primary,
                        )
                      : _MiniStat(
                          icon: Icons.analytics,
                          label: 'Average',
                          value: _percent(avgRate),
                          subtitle: 'across tracked days',
                          color: Colors.blue,
                        ),
                ),
              ],
            ),
            // Small samples produce loud, meaningless percentages —
            // say so instead of presenting them as verdicts
            if (trackedDays < 7) ...[
              SizedBox(height: AppConstants.spacingMedium),
              _ConfidenceBanner(trackedDays: trackedDays),
            ],
          ],
        ),
      ),
    );
  }

  String _percent(double rate) => '${(rate * 100).toStringAsFixed(0)}%';

  String _insightSentence(
    List<DayPerformance> daysWithData,
    DayPerformance bestDay,
    DayPerformance worstDay,
  ) {
    if (daysWithData.length == 1) {
      return '${bestDay.fullDayName}s are off to a '
          '${_percent(bestDay.completionRate)} start — more insights as '
          'you keep tracking.';
    }
    if (bestDay.completionRate == worstDay.completionRate) {
      return 'Steady ${_percent(bestDay.completionRate)} across your '
          'tracked days — consistency looks good.';
    }
    return 'You\'re strongest on ${bestDay.fullDayName}s '
        '(${_percent(bestDay.completionRate)}) and tend to slip on '
        '${worstDay.fullDayName}s (${_percent(worstDay.completionRate)}).';
  }
}

class _ConfidenceBanner extends StatelessWidget {
  final int trackedDays;

  const _ConfidenceBanner({required this.trackedDays});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_top,
            size: 20,
            color: colorScheme.onSecondaryContainer,
          ),
          SizedBox(width: AppConstants.spacingSmall),
          Expanded(
            child: Text(
              'You\'re just getting started — only $trackedDays '
              '${trackedDays == 1 ? 'day' : 'days'} tracked so far. These '
              'insights get sharper after a week or two.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
            ),
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
