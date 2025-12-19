import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/services/services.dart';
import 'package:habit_tracker_flutter_new/screens/add_edit_habit_screen.dart';
import 'package:habit_tracker_flutter_new/screens/habit_detail_screen.dart';

class HabitCard extends ConsumerWidget {
  final Habit habit;
  final DateTime selectedDate;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.selectedDate,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = ref.watch(
      habitCompletionProvider((habitId: habit.id, date: selectedDate)),
    );

    return Dismissible(
      key: Key(habit.id),
      background: _buildSwipeBackground(
        context,
        alignment: Alignment.centerLeft,
        color: Colors.blue,
        icon: Icons.edit,
        label: 'Edit',
      ),
      secondaryBackground: _buildSwipeBackground(
        context,
        alignment: Alignment.centerRight,
        color: Colors.red,
        icon: Icons.delete,
        label: 'Delete',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right to edit
          _handleEdit(context, ref);
          return false; // Don't dismiss
        } else {
          // Swipe left to delete
          return await _showDeleteConfirmation(context);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _handleDelete(ref);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isCompleted
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap ?? () => _navigateToDetail(context),
          onLongPress: () => _handleEdit(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildCompletionCheckbox(context, ref, isCompleted),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHabitInfo(context, isCompleted),
                ),
                const SizedBox(width: 12),
                _StreakBadge(habitId: habit.id),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(
    BuildContext context, {
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCheckbox(
    BuildContext context,
    WidgetRef ref,
    bool isCompleted,
  ) {
    return GestureDetector(
      onTap: () => _toggleCompletion(ref, isCompleted),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isCompleted ? Colors.green : Colors.grey.shade400,
            width: 2.5,
          ),
          color: isCompleted ? Colors.green : Colors.transparent,
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: isCompleted
            ? const Icon(
                Icons.check,
                size: 20,
                color: Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _buildHabitInfo(BuildContext context, bool isCompleted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          habit.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? Colors.grey : null,
              ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildInfoChip(
              context,
              icon: _getCategoryIcon(habit.category),
              label: habit.category.displayName,
              color: _getCategoryColor(habit.category),
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              context,
              icon: Icons.repeat,
              label: habit.frequency.displayName,
              color: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  void _toggleCompletion(WidgetRef ref, bool isCompleted) {
    if (isCompleted) {
      ref.read(completionsProvider.notifier).markIncomplete(
            habit.id,
            selectedDate,
          );
    } else {
      ref.read(completionsProvider.notifier).markComplete(
            habit.id,
            selectedDate,
          );
    }
  }

  void _handleEdit(BuildContext context, WidgetRef ref) {
    if (onEdit != null) {
      onEdit!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddEditHabitScreen(habit: habit),
        ),
      );
    }
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HabitDetailScreen(habit: habit),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Habit'),
            content: Text('Are you sure you want to delete "${habit.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _handleDelete(WidgetRef ref) {
    if (onDelete != null) {
      onDelete!();
    } else {
      ref.read(habitsProvider.notifier).deleteHabit(habit.id);
    }
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

  Color _getCategoryColor(HabitCategory category) {
    switch (category.name) {
      case 'health':
        return Colors.red;
      case 'productivity':
        return Colors.orange;
      case 'mindfulness':
        return Colors.purple;
      case 'social':
        return Colors.pink;
      case 'creativity':
        return Colors.indigo;
      case 'learning':
        return Colors.blue;
      case 'fitness':
        return Colors.green;
      case 'finance':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

/// Streak badge showing current streak with Strava-style visual feedback
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStreakColor(streakData.current).withValues(alpha: 0.2),
            _getStreakColor(streakData.current).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStreakColor(streakData.current),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getStreakEmoji(streakData.current),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 4),
          Text(
            '${streakData.current}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
    if (streak >= 14) return Colors.deepOrange;
    if (streak >= 7) return Colors.orange;
    return Colors.blue;
  }

  String _getStreakEmoji(int streak) {
    if (streak >= 30) return '🏆';
    if (streak >= 14) return '⚡';
    if (streak >= 7) return '🔥';
    return '💪';
  }
}
