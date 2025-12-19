import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';

class HeatmapCalendar extends ConsumerWidget {
  final Habit habit;
  final DateTime selectedDate;

  const HeatmapCalendar({
    super.key,
    required this.habit,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    final startDate = endDate.subtract(const Duration(days: 29));

    // Generate list of last 30 days
    final days = List.generate(
      30,
      (index) => startDate.add(Duration(days: index)),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
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
                  const Text(
                    'Last 30 Days',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  _buildLegend(),
                ],
              ),

              const SizedBox(height: 20),

              // Heatmap Grid
              _buildHeatmapGrid(ref, days),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmapGrid(WidgetRef ref, List<DateTime> days) {
    // Split into weeks (rows of 7 days)
    final weeks = <List<DateTime>>[];
    for (var i = 0; i < days.length; i += 7) {
      final end = (i + 7 < days.length) ? i + 7 : days.length;
      weeks.add(days.sublist(i, end));
    }

    return Column(
      children: weeks.map((week) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: week.map((day) {
              return _HeatmapDay(
                date: day,
                habitId: habit.id,
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem(Colors.grey.shade200, 'None'),
        const SizedBox(width: 8),
        _buildLegendItem(Colors.green.shade300, 'Done'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _HeatmapDay extends ConsumerWidget {
  final DateTime date;
  final String habitId;

  const _HeatmapDay({
    required this.date,
    required this.habitId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = ref.watch(
      habitCompletionProvider((habitId: habitId, date: date)),
    );

    final isToday = _isToday(date);
    final dayNumber = date.day;

    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _getColor(isCompleted),
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(
                    color: Colors.blue,
                    width: 2,
                  )
                : null,
          ),
          child: Center(
            child: Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isCompleted ? Colors.white : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getColor(bool isCompleted) {
    if (isCompleted) {
      return Colors.green.shade400;
    }
    return Colors.grey.shade200;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
