import 'package:flutter/material.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';

class HabitDetailAppBar extends StatelessWidget {
  final Habit habit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HabitDetailAppBar({
    super.key,
    required this.habit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(habit.category);

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: categoryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          habit.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                categoryColor,
                categoryColor.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Icon(
                  _getCategoryIcon(habit.category),
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 12),
                Text(
                  _getFrequencyText(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: onEdit,
          tooltip: 'Edit Habit',
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.white),
          onPressed: onDelete,
          tooltip: 'Delete Habit',
        ),
      ],
    );
  }

  Color _getCategoryColor(HabitCategory category) {
    return switch (category) {
      HabitCategory.health => Colors.green,
      HabitCategory.fitness => Colors.orange,
      HabitCategory.productivity => Colors.blue,
      HabitCategory.learning => Colors.purple,
      HabitCategory.mindfulness => Colors.teal,
      HabitCategory.social => Colors.pink,
      HabitCategory.creativity => Colors.amber,
      HabitCategory.finance => Colors.indigo,
      HabitCategory.other => Colors.grey,
    };
  }

  IconData _getCategoryIcon(HabitCategory category) {
    return switch (category) {
      HabitCategory.health => Icons.favorite,
      HabitCategory.fitness => Icons.fitness_center,
      HabitCategory.productivity => Icons.work,
      HabitCategory.learning => Icons.school,
      HabitCategory.mindfulness => Icons.self_improvement,
      HabitCategory.social => Icons.people,
      HabitCategory.creativity => Icons.palette,
      HabitCategory.finance => Icons.attach_money,
      HabitCategory.other => Icons.category,
    };
  }

  String _getFrequencyText() {
    return habit.frequency.displayName;
  }
}
