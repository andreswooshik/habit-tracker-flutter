import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/models/habit_state.dart';
import 'package:habit_tracker_flutter_new/providers/completions_notifier.dart';
import 'package:intl/intl.dart';

class WeeklyPerformanceChart extends ConsumerWidget {
  const WeeklyPerformanceChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitState = ref.watch(habitsProvider);
    final completionsState = ref.watch(completionsProvider);

    // Show loading indicator while data is being loaded
    if (completionsState.isLoading || habitState.isLoading) {
      return const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Use today as the end date for weekly performance
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate last 7 days data
    final weekData = _calculateWeekData(habitState, completionsState, today);
    final previousWeekData = _calculateWeekData(
      habitState,
      completionsState,
      today.subtract(const Duration(days: 7)),
    );

    final currentAvg = weekData.fold<double>(
          0,
          (sum, data) => sum + data.completionRate,
        ) /
        weekData.length;
    final previousAvg = previousWeekData.fold<double>(
          0,
          (sum, data) => sum + data.completionRate,
        ) /
        previousWeekData.length;
    final trend = currentAvg - previousAvg;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Performance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                _buildTrendIndicator(context, trend),
              ],
            ),

            const SizedBox(height: 20),

            // Bar Chart
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final data = weekData[group.x.toInt()];
                        return BarTooltipItem(
                          '${data.dayLabel}\n${rod.toY.toInt()}%',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    touchCallback:
                        null, // Disabled to prevent changing Today's Progress
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < weekData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                weekData[value.toInt()].dayLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: weekData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.completionRate,
                          color: _getBarColor(data.completionRate),
                          width: 24,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Legend
            Text(
              'Tap any bar to jump to that day',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context, double trend) {
    final isPositive = trend >= 0;
    // Calculate trend percentage and cap at ±100%
    final rawTrendPercentage = (trend * 100).abs();
    final trendPercentage = rawTrendPercentage.clamp(0, 100);
    final isCapped = rawTrendPercentage > 100;
    final displayPercentage = trendPercentage.toStringAsFixed(0);

    final widget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            '$displayPercentage%${isCapped ? '+' : ''}',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );

    // Add tooltip if value is capped
    if (isCapped) {
      return Tooltip(
        message:
            'Actual change: ${rawTrendPercentage.toStringAsFixed(0)}% (capped at 100% for display)',
        child: widget,
      );
    }
    return widget;
  }

  Color _getBarColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.blue;
    if (rate >= 40) return Colors.orange;
    return Colors.red;
  }

  List<_DayData> _calculateWeekData(
    HabitState habitState,
    CompletionsState completionsState,
    DateTime endDate,
  ) {
    final allHabits = habitState.habits.where((h) => !h.isArchived).toList();

    final weekData = <_DayData>[];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      ).subtract(Duration(days: i));

      final scheduledHabits =
          allHabits.where((h) => h.isScheduledFor(date)).toList();
      final completedCount = scheduledHabits.where((h) {
        return completionsState.isCompletedOn(h.id, date);
      }).length;

      final rate = scheduledHabits.isEmpty
          ? 0.0
          : (completedCount / scheduledHabits.length * 100);

      weekData.add(_DayData(
        date: date,
        dayLabel: DateFormat('EEE').format(date).substring(0, 1),
        completionRate: rate,
      ));
    }

    return weekData;
  }
}

class _DayData {
  final DateTime date;
  final String dayLabel;
  final double completionRate;

  _DayData({
    required this.date,
    required this.dayLabel,
    required this.completionRate,
  });
}
