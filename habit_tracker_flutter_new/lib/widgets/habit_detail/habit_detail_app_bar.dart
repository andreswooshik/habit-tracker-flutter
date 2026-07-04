import 'package:flutter/material.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/services/category_style_service.dart';

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
    final styleService = CategoryStyleService();
    final categoryColor = styleService.getColor(habit.category);

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: categoryColor,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding:
            const EdgeInsetsDirectional.only(start: 56, bottom: 16, end: 96),
        title: Text(
          habit.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
            child: Padding(
              // Keep the icon and frequency label above the title strip
              // that FlexibleSpaceBar draws along the bottom edge
              padding: const EdgeInsets.only(top: 16, bottom: 64),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Paired with the habit card's Hero so the card flies
                  // into this icon on navigation
                  Hero(
                    tag: 'habit_card_${habit.id}',
                    child: Icon(
                      styleService.getIcon(habit.category),
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
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

  String _getFrequencyText() {
    return habit.frequency.displayName;
  }
}
