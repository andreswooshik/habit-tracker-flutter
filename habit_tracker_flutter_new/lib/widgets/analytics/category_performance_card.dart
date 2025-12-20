import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/providers/analytics_providers.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/utils/app_constants.dart';

/// Category Performance Card
/// Shows which categories perform best/worst with bar chart
class CategoryPerformanceCard extends ConsumerWidget {
  const CategoryPerformanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryData = ref.watch(categoryPerformanceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (categoryData.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.paddingLarge),
          child: Center(
            child: Text(
              'No category data available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      );
    }

    final bestCategory = categoryData.first;
    final worstCategory = categoryData.last;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: colorScheme.primary),
                SizedBox(width: AppConstants.spacingSmall),
                Text(
                  'Category Performance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacingMedium),
            
            // Best and worst category summary
            Row(
              children: [
                Expanded(
                  child: _CategorySummary(
                    icon: Icons.emoji_events,
                    iconColor: Colors.amber,
                    label: 'Best',
                    categoryName: bestCategory.categoryName,
                    rate: bestCategory.completionRate,
                  ),
                ),
                SizedBox(width: AppConstants.spacingSmall),
                Expanded(
                  child: _CategorySummary(
                    icon: Icons.trending_up,
                    iconColor: Colors.orange,
                    label: 'Needs Focus',
                    categoryName: worstCategory.categoryName,
                    rate: worstCategory.completionRate,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: AppConstants.spacingLarge),
            
            // Bar chart
            ...categoryData.map((category) {
              final categoryEnum = HabitCategory.values.firstWhere(
                (c) => c.displayName == category.categoryName,
                orElse: () => HabitCategory.other,
              );
              
              return Padding(
                padding: EdgeInsets.only(bottom: AppConstants.spacingMedium),
                child: _CategoryBar(
                  categoryName: category.categoryName,
                  completionRate: category.completionRate,
                  color: categoryEnum.color,
                  totalHabits: category.totalHabits,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CategorySummary extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String categoryName;
  final double rate;

  const _CategorySummary({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.categoryName,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              SizedBox(width: AppConstants.spacingSmall),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingSmall),
          Text(
            categoryName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${(rate * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String categoryName;
  final double completionRate;
  final Color color;
  final int totalHabits;

  const _CategoryBar({
    required this.categoryName,
    required this.completionRate,
    required this.color,
    required this.totalHabits,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AppConstants.spacingSmall),
                Text(
                  categoryName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(width: AppConstants.spacingSmall),
                Text(
                  '($totalHabits)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            Text(
              '${(completionRate * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
        SizedBox(height: AppConstants.spacingSmall),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          child: LinearProgressIndicator(
            value: completionRate,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
