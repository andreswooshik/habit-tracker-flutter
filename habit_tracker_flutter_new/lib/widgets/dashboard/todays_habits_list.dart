import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/widgets/habit_card.dart';

/// Widget that displays the list of habits scheduled for today
class TodaysHabitsList extends ConsumerWidget {
  const TodaysHabitsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysHabits = ref.watch(todaysHabitsProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final completedCount = ref.watch(completedTodayCountProvider);
    final totalCount = ref.watch(todaysHabitsCountProvider);

    if (todaysHabits.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No habits scheduled for today',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a habit to get started!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Separate completed and pending habits
    final pendingHabits = todaysHabits.where((habit) {
      final isCompleted = ref.watch(
        habitCompletionProvider((habitId: habit.id, date: selectedDate)),
      );
      return !isCompleted;
    }).toList();

    final completedHabits = todaysHabits.where((habit) {
      final isCompleted = ref.watch(
        habitCompletionProvider((habitId: habit.id, date: selectedDate)),
      );
      return isCompleted;
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
            Row(
              children: [
                Icon(
                  Icons.format_list_bulleted,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Habits',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedCount of $totalCount completed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Pending Habits Section
            if (pendingHabits.isNotEmpty) ...[
              Text(
                'To Complete (${pendingHabits.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
              ),
              const SizedBox(height: 12),
              ...pendingHabits.map((habit) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: HabitCard(
                      habit: habit,
                      selectedDate: selectedDate,
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            // Completed Habits Section
            if (completedHabits.isNotEmpty) ...[
              Text(
                'Completed (${completedHabits.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
              ),
              const SizedBox(height: 12),
              ...completedHabits.map((habit) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: HabitCard(
                      habit: habit,
                      selectedDate: selectedDate,
                    ),
                  )),
            ],

            // All completed message
            if (pendingHabits.isEmpty && completedHabits.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.celebration,
                      color: Colors.green.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '🎉 Perfect! All habits completed today!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.w600,
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
}
