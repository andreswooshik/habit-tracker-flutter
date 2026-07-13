import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/utils/app_constants.dart';

/// The current calendar week (Mon–Sun) as seven day pips.
///
/// This card answers "how is my week going?" — the current cycle —
/// so future days are legitimately *pending*, today is *in progress*,
/// and only past days carry a verdict. The historical aggregate
/// ("what's my typical week?") lives in BestDaysAnalysis instead;
/// splitting the two is what keeps a Monday user from reading
/// "Tue 0%" as failure.
class ThisWeekCard extends ConsumerWidget {
  const ThisWeekCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final days = [
      for (var i = 0; i < 7; i++) monday.add(Duration(days: i)),
    ];

    final todayScheduled =
        ref.watch(scheduledHabitsForDateProvider(today)).length;
    final todayCompleted = ref.watch(completedCountForDateProvider(today));

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today,
                    color: Theme.of(context).colorScheme.primary),
                SizedBox(width: AppConstants.spacingSmall),
                Text(
                  'This Week',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final day in days)
                  _DayPip(date: day, today: today),
              ],
            ),
            SizedBox(height: AppConstants.spacingMedium),
            Text(
              todayScheduled == 0
                  ? 'Nothing scheduled today'
                  : '$todayCompleted of $todayScheduled done so far today',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One day of the current week.
///
/// States (see BestDaysAnalysis docs for why these are distinct):
/// - future  → faint outline, no verdict yet
/// - today   → accent outline with live "done/total"
/// - past, all done      → filled with a check
/// - past, partly done   → soft fill with "done/total"
/// - past, none done     → hollow ring with "0" (neutral, not red)
/// - past, none scheduled→ faint dash, "no habits" is not a failure
class _DayPip extends ConsumerWidget {
  final DateTime date;
  final DateTime today;

  const _DayPip({required this.date, required this.today});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final scheduled = ref.watch(scheduledHabitsForDateProvider(date)).length;
    final completed = ref.watch(completedCountForDateProvider(date));

    final isToday = date == today;
    final isFuture = date.isAfter(today);

    final dayLetter = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1];

    late final Widget pip;
    late final String semanticLabel;

    if (isFuture) {
      pip = _circle(
        border: scheme.outlineVariant.withValues(alpha: 0.6),
        child: null,
      );
      semanticLabel = '${_weekdayName(date)}: upcoming';
    } else if (isToday) {
      pip = _circle(
        border: scheme.primary,
        borderWidth: 2.5,
        child: Text(
          scheduled == 0 ? '–' : '$completed/$scheduled',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
        ),
      );
      semanticLabel =
          'Today: $completed of $scheduled habits done so far';
    } else if (scheduled == 0) {
      pip = _circle(
        border: scheme.outlineVariant.withValues(alpha: 0.6),
        child: Text(
          '–',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
      semanticLabel = '${_weekdayName(date)}: no habits scheduled';
    } else if (completed == scheduled) {
      pip = _circle(
        fill: scheme.primary,
        child: Icon(Icons.check, size: 18, color: scheme.onPrimary),
      );
      semanticLabel = '${_weekdayName(date)}: all $scheduled habits done';
    } else if (completed > 0) {
      pip = _circle(
        fill: scheme.primary.withValues(alpha: 0.35),
        child: Text(
          '$completed/$scheduled',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
        ),
      );
      semanticLabel =
          '${_weekdayName(date)}: $completed of $scheduled habits done';
    } else {
      pip = _circle(
        border: scheme.outline,
        child: Text(
          '0',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      );
      semanticLabel = '${_weekdayName(date)}: none of $scheduled habits done';
    }

    return Semantics(
      label: semanticLabel,
      child: Column(
        children: [
          Text(
            dayLetter,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: isToday ? scheme.primary : scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 6),
          pip,
        ],
      ),
    );
  }

  Widget _circle({
    Color? fill,
    Color? border,
    double borderWidth = 1.5,
    required Widget? child,
  }) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: border != null
            ? Border.all(color: border, width: borderWidth)
            : null,
      ),
      child: child,
    );
  }

  String _weekdayName(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }
}
