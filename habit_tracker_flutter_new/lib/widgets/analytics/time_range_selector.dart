import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/providers/analytics_providers.dart';
import 'package:habit_tracker_flutter_new/utils/app_constants.dart';

/// Time Range Selector Widget
/// Allows users to select the time period for analytics
class TimeRangeSelector extends ConsumerWidget {
  const TimeRangeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRange = ref.watch(selectedTimeRangeProvider);
    
    return Card(
      elevation: AppConstants.elevationLow,
      child: Padding(
        padding: EdgeInsets.all(AppConstants.paddingSmall),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: TimeRange.values.map((range) {
            final isSelected = range == selectedRange;
            
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingSmall),
                child: _TimeRangeChip(
                  label: range.label,
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(selectedTimeRangeProvider.notifier).state = range;
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TimeRangeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeRangeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppConstants.paddingSmall,
          horizontal: AppConstants.paddingMedium,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}
