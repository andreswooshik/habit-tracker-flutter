import 'package:flutter/material.dart';

/// Enum representing different habit categories
/// Each category has an associated color and icon for visual distinction
enum HabitCategory {
  health('Health', Colors.green, Icons.favorite),
  productivity('Productivity', Colors.blue, Icons.work),
  fitness('Fitness', Colors.orange, Icons.fitness_center),
  mindfulness('Mindfulness', Colors.purple, Icons.self_improvement),
  learning('Learning', Colors.teal, Icons.school),
  social('Social', Colors.pink, Icons.people),
  creativity('Creativity', Colors.amber, Icons.palette),
  finance('Finance', Colors.indigo, Icons.attach_money),
  other('Other', Colors.grey, Icons.category);

  final String displayName;
  final Color color;
  final IconData icon;

  const HabitCategory(this.displayName, this.color, this.icon);

  /// Returns a lighter shade of the category color for backgrounds
  Color get lightColor => color.withValues(alpha: 0.2);

  /// Returns a darker shade of the category color for emphasis
  Color get darkColor => Color.lerp(color, Colors.black, 0.3)!;

  /// Get category by name (case-insensitive)
  static HabitCategory? fromString(String name) {
    try {
      return HabitCategory.values.firstWhere(
        (category) => category.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Returns all category names as a list
  static List<String> get allNames {
    return HabitCategory.values.map((c) => c.displayName).toList();
  }

  /// Returns a description of what this category is for
  String get description {
    switch (this) {
      case HabitCategory.health:
        return 'Physical health, nutrition, sleep, and wellness';
      case HabitCategory.productivity:
        return 'Work tasks, time management, and efficiency';
      case HabitCategory.fitness:
        return 'Exercise, sports, and physical activities';
      case HabitCategory.mindfulness:
        return 'Meditation, reflection, and mental health';
      case HabitCategory.learning:
        return 'Education, reading, and skill development';
      case HabitCategory.social:
        return 'Relationships, communication, and networking';
      case HabitCategory.creativity:
        return 'Art, music, writing, and creative pursuits';
      case HabitCategory.finance:
        return 'Budgeting, saving, and financial planning';
      case HabitCategory.other:
        return 'Miscellaneous habits';
    }
  }
}
