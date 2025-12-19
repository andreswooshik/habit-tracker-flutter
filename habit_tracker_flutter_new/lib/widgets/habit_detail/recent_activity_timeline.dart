import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:intl/intl.dart';

class RecentActivityTimeline extends ConsumerWidget {
  final String habitId;

  const RecentActivityTimeline({
    super.key,
    required this.habitId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completionsState = ref.watch(completionsProvider);
    final habitCompletions = completionsState.completions[habitId] ?? {};

    // Get last 10 completions, sorted by date (most recent first)
    final recentCompletions = habitCompletions.toList()
      ..sort((a, b) => b.compareTo(a));
    final displayCompletions = recentCompletions.take(10).toList();

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
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (displayCompletions.isNotEmpty)
                    Text(
                      '${displayCompletions.length} ${displayCompletions.length == 1 ? 'completion' : 'completions'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Timeline or Empty State
              if (displayCompletions.isEmpty)
                _buildEmptyState()
              else
                _buildTimeline(displayCompletions),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No completions yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start building your streak!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(List<DateTime> completions) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: completions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 0),
      itemBuilder: (context, index) {
        final date = completions[index];
        final isLast = index == completions.length - 1;

        return _TimelineItem(
          date: date,
          isLast: isLast,
        );
      },
    );
  }
}

/// Individual timeline item
///
/// Single Responsibility: Display single completion event
class _TimelineItem extends StatelessWidget {
  final DateTime date;
  final bool isLast;

  const _TimelineItem({
    required this.date,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM d, yyyy');
    final timeAgo = _getTimeAgo(date);
    final isToday = _isToday(date);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              // Dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isToday ? Colors.green : Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isToday ? Colors.green : Colors.blue)
                          .withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),

              // Connecting line
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateFormatter.format(date),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(compareDate).inDays;

    if (difference == 0) {
      return 'Completed today';
    } else if (difference == 1) {
      return 'Completed yesterday';
    } else if (difference < 7) {
      return 'Completed $difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return 'Completed $weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      return 'Completed $months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference / 365).floor();
      return 'Completed $years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
