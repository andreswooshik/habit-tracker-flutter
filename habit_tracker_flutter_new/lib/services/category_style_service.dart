import 'package:flutter/material.dart';
import '../models/habit_category.dart';

/// Service for providing consistent category styling across the app
///
/// Follows SOLID principles:
/// - Single Responsibility: Only handles category visual styling
/// - Open/Closed: Extensible via configuration, closed for modification
/// - Liskov Substitution: Can be replaced with alternative implementations
/// - Interface Segregation: Provides focused styling interface
/// - Dependency Inversion: UI depends on this abstraction, not concrete values
class CategoryStyleService {
  static final CategoryStyleService _instance =
      CategoryStyleService._internal();

  factory CategoryStyleService() => _instance;

  CategoryStyleService._internal();

  /// Configuration map for category styles
  final Map<HabitCategory, CategoryStyle> _styles = {
    HabitCategory.health: CategoryStyle(
      icon: Icons.favorite,
      color: Colors.red,
    ),
    HabitCategory.productivity: CategoryStyle(
      icon: Icons.work,
      color: Colors.orange,
    ),
    HabitCategory.mindfulness: CategoryStyle(
      icon: Icons.self_improvement,
      color: Colors.purple,
    ),
    HabitCategory.social: CategoryStyle(
      icon: Icons.people,
      color: Colors.pink,
    ),
    HabitCategory.creativity: CategoryStyle(
      icon: Icons.palette,
      color: Colors.indigo,
    ),
    HabitCategory.learning: CategoryStyle(
      icon: Icons.school,
      color: Colors.blue,
    ),
    HabitCategory.fitness: CategoryStyle(
      icon: Icons.fitness_center,
      color: Colors.green,
    ),
    HabitCategory.finance: CategoryStyle(
      icon: Icons.attach_money,
      color: Colors.teal,
    ),
    HabitCategory.other: CategoryStyle(
      icon: Icons.stars,
      color: Colors.grey,
    ),
  };

  /// Gets the icon for a category
  IconData getIcon(HabitCategory category) {
    return _styles[category]?.icon ?? Icons.stars;
  }

  /// Gets the color for a category
  Color getColor(HabitCategory category) {
    return _styles[category]?.color ?? Colors.grey;
  }

  /// Gets both icon and color for a category
  CategoryStyle getStyle(HabitCategory category) {
    return _styles[category] ??
        CategoryStyle(icon: Icons.stars, color: Colors.grey);
  }
}

/// Represents category visual style
class CategoryStyle {
  final IconData icon;
  final Color color;

  CategoryStyle({
    required this.icon,
    required this.color,
  });
}
