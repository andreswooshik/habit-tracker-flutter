import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/services/services.dart';
import 'package:intl/intl.dart';

/// Main screen displaying the list of habits for the selected date
/// 
/// Features:
/// - Displays today's habits with completion status
/// - Shows progress statistics
/// - Allows completion toggle
/// - Filters and sorts habits
class HabitListScreen extends ConsumerWidget {
  const HabitListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysHabits = ref.watch(todaysHabitsProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final todaysProgress = ref.watch(todaysProgressProvider);
    final completedCount = ref.watch(completedTodayCountProvider);
    final totalCount = ref.watch(todaysHabitsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to AddEditHabitScreen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector and progress card
          _DateProgressCard(
            selectedDate: selectedDate,
            progress: todaysProgress,
            completedCount: completedCount,
            totalCount: totalCount,
            onDateChanged: (date) {
              ref.read(selectedDateProvider.notifier).state = date;
            },
          ),
          
          // Habits list
          Expanded(
            child: todaysHabits.isEmpty
                ? _EmptyState(selectedDate: selectedDate)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: todaysHabits.length,
                    itemBuilder: (context, index) {
                      final habit = todaysHabits[index];
                      return _HabitCard(
                        habit: habit,
                        selectedDate: selectedDate,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to AddEditHabitScreen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Date selector and progress card widget
class _DateProgressCard extends StatelessWidget {
  final DateTime selectedDate;
  final double progress;
  final int completedCount;
  final int totalCount;
  final ValueChanged<DateTime> onDateChanged;

  const _DateProgressCard({
    required this.selectedDate,
    required this.progress,
    required this.completedCount,
    required this.totalCount,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(selectedDate);
    final dateText = isToday 
        ? 'Today' 
        : DateFormat('EEEE, MMM d').format(selectedDate);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    onDateChanged(selectedDate.subtract(const Duration(days: 1)));
                  },
                ),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      onDateChanged(date);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      dateText,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    onDateChanged(selectedDate.add(const Duration(days: 1)));
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(progress),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Progress text
            Text(
              '$completedCount of $totalCount habits completed',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            // Percentage
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getProgressColor(progress),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

/// Individual habit card widget
class _HabitCard extends ConsumerWidget {
  final Habit habit;
  final DateTime selectedDate;

  const _HabitCard({
    required this.habit,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = ref.watch(
      habitCompletionProvider((habitId: habit.id, date: selectedDate)),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to HabitDetailScreen
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Completion checkbox
              GestureDetector(
                onTap: () {
                  if (isCompleted) {
                    ref.read(completionsProvider.notifier)
                        .markIncomplete(habit.id, selectedDate);
                  } else {
                    ref.read(completionsProvider.notifier)
                        .markComplete(habit.id, selectedDate);
                  }
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted 
                          ? Colors.green 
                          : Colors.grey,
                      width: 2,
                    ),
                    color: isCompleted 
                        ? Colors.green 
                        : Colors.transparent,
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 18,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Habit info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                        color: isCompleted 
                            ? Colors.grey 
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getCategoryIcon(habit.category),
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          habit.category.displayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.repeat,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          habit.frequency.displayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Streak indicator
              _StreakBadge(habitId: habit.id),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(HabitCategory category) {
    switch (category.name) {
      case 'health':
        return Icons.favorite;
      case 'productivity':
        return Icons.work;
      case 'mindfulness':
        return Icons.self_improvement;
      case 'social':
        return Icons.people;
      case 'creativity':
        return Icons.palette;
      case 'learning':
        return Icons.school;
      case 'fitness':
        return Icons.fitness_center;
      case 'finance':
        return Icons.attach_money;
      default:
        return Icons.stars;
    }
  }
}

/// Streak badge showing current streak
class _StreakBadge extends ConsumerWidget {
  final String habitId;

  const _StreakBadge({required this.habitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakData = ref.watch(streakDataProvider(habitId));

    if (streakData.current == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStreakColor(streakData.current).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStreakColor(streakData.current),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🔥',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            '${streakData.current}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getStreakColor(streakData.current),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStreakColor(int streak) {
    if (streak >= 30) return Colors.purple;
    if (streak >= 7) return Colors.orange;
    return Colors.blue;
  }
}

/// Empty state when no habits scheduled for the day
class _EmptyState extends StatelessWidget {
  final DateTime selectedDate;

  const _EmptyState({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(selectedDate);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isToday ? Icons.celebration : Icons.event_busy,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              isToday 
                  ? 'No habits scheduled for today'
                  : 'No habits scheduled for this day',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isToday
                  ? 'Tap the + button to create your first habit'
                  : 'Check another date or create a new habit',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }
}
