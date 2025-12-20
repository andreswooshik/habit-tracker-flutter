import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';

class TodaysSummaryCard extends ConsumerWidget {
  const TodaysSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysProgress = ref.watch(todaysProgressProvider);
    final completedCount = ref.watch(completedTodayCountProvider);
    final totalCount = ref.watch(todaysHabitsCountProvider);
    final todaysHabits = ref.watch(todaysHabitsProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    final greeting = _getGreeting();
    final progressPercentage = (todaysProgress * 100).toInt();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              greeting,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),

            const SizedBox(height: 8),

            Text(
              'Let\'s make today count!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
            ),

            const SizedBox(height: 24),

            // Progress Section
            Row(
              children: [
                // Circular Progress
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: todaysProgress,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getProgressColor(todaysProgress),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$progressPercentage%',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getProgressColor(todaysProgress),
                                ),
                          ),
                          Text(
                            'Complete',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.black54,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Completed count
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$completedCount completed',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Remaining count
                      Row(
                        children: [
                          Icon(
                            Icons.radio_button_unchecked,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${totalCount - completedCount} remaining',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Complete All Button
                      if (totalCount > 0 && completedCount < totalCount)
                        FilledButton.icon(
                          onPressed: () => _completeAllHabits(
                              ref, todaysHabits, selectedDate),
                          icon: const Icon(Icons.done_all, size: 20),
                          label: const Text('Complete All'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Motivational message
            if (totalCount > 0) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getMotivationalColor(todaysProgress).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getMotivationalIcon(todaysProgress),
                      color: _getMotivationalColor(todaysProgress),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getMotivationalMessage(
                            todaysProgress, completedCount, totalCount),
                        style: TextStyle(
                          fontSize: 13,
                          color: _getMotivationalColor(todaysProgress),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning! ☀️';
    } else if (hour < 18) {
      return 'Good Afternoon! 🌤️';
    } else {
      return 'Good Evening! 🌙';
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.blue;
    if (progress >= 0.4) return Colors.orange;
    return Colors.red;
  }

  IconData _getMotivationalIcon(double progress) {
    if (progress >= 1.0) return Icons.celebration;
    if (progress >= 0.7) return Icons.trending_up;
    if (progress >= 0.4) return Icons.lightbulb_outline;
    return Icons.flag;
  }

  Color _getMotivationalColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.blue;
    if (progress >= 0.4) return Colors.orange;
    return Colors.red;
  }

  String _getMotivationalMessage(double progress, int completed, int total) {
    if (progress >= 1.0) {
      return '🎉 Perfect! All $total habits completed today!';
    } else if (progress >= 0.7) {
      return '💪 Great progress! Only ${total - completed} more to go!';
    } else if (progress >= 0.4) {
      return '⚡ Keep going! You\'re making good progress!';
    } else if (completed > 0) {
      return '🌱 Good start! Let\'s build momentum!';
    } else {
      return '🚀 Ready to start? Complete your first habit!';
    }
  }

  void _completeAllHabits(WidgetRef ref, List<dynamic> habits, DateTime date) {
    final completionsNotifier = ref.read(completionsProvider.notifier);
    for (final habit in habits) {
      completionsNotifier.markComplete(habit.id, date);
    }
  }
}
