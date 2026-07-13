import 'package:flutter/material.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/services/category_style_service.dart';

class HabitDetailAppBar extends StatelessWidget {
  final Habit habit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Tag of the card hero this screen was opened from — must match the
  /// tapped HabitCard's tag exactly, or the flight animation is a no-op
  final String heroTag;

  const HabitDetailAppBar({
    super.key,
    required this.habit,
    required this.onEdit,
    required this.onDelete,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final styleService = CategoryStyleService();
    final categoryColor = styleService.getColor(habit.category);

    // Keep pointer feedback visible on the colored header without the
    // default dark focus circle + "Back" tooltip pill that stick to the
    // buttons on web/desktop after a click
    final onHeaderButtonStyle = IconButton.styleFrom(
      foregroundColor: Colors.white,
      hoverColor: Colors.white.withValues(alpha: 0.12),
      focusColor: Colors.white.withValues(alpha: 0.18),
      highlightColor: Colors.white.withValues(alpha: 0.12),
    );

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: categoryColor,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        style: onHeaderButtonStyle,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
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
                    tag: heroTag,
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
          icon: const Icon(Icons.edit),
          style: onHeaderButtonStyle,
          onPressed: onEdit,
          tooltip: 'Edit Habit',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          style: onHeaderButtonStyle,
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
