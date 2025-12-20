import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/services/category_style_service.dart';

class CategoryBreakdown extends ConsumerWidget {
  const CategoryBreakdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitState = ref.watch(habitsProvider);
    final completionsState = ref.watch(completionsProvider);
    final activeHabits = habitState.habits.where((h) => !h.isArchived).toList();

    // Calculate category data
    final categoryData = <HabitCategory, _CategoryData>{};

    for (final habit in activeHabits) {
      final completions = completionsState.completions[habit.id]?.length ?? 0;

      if (!categoryData.containsKey(habit.category)) {
        categoryData[habit.category] = _CategoryData(
          category: habit.category,
          habitCount: 0,
          completionCount: 0,
        );
      }

      categoryData[habit.category]!.habitCount++;
      categoryData[habit.category]!.completionCount += completions;
    }

    if (categoryData.isEmpty) {
      return _buildEmptyState(context);
    }

    final styleService = CategoryStyleService();
    final sections = categoryData.entries.map((entry) {
      final data = entry.value;
      return PieChartSectionData(
        value: data.completionCount.toDouble(),
        title: '${data.habitCount}',
        color: styleService.getColor(data.category),
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

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
              'Category Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 24),

            // Pie Chart
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Future: Handle tap to filter
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: categoryData.entries.map((entry) {
                return _buildLegendItem(
                  context,
                  entry.value.category,
                  entry.value.habitCount,
                  entry.value.completionCount,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    HabitCategory category,
    int habitCount,
    int completions,
  ) {
    final color = CategoryStyleService().getColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            category.displayName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($habitCount)',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'No habits to show',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create habits to see category breakdown',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _CategoryData {
  final HabitCategory category;
  int habitCount;
  int completionCount;

  _CategoryData({
    required this.category,
    required this.habitCount,
    required this.completionCount,
  });
}
