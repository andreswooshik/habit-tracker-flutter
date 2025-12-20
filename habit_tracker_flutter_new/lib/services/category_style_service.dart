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
  static final CategoryStyleService _instance = CategoryStyleService._internal();
  
  factory CategoryStyleService() => _instance;
  
  CategoryStyleService._internal();

  /// Configuration map for category styles
  final Map<HabitCategory, _CategoryStyle> _styles = {
    HabitCategory.health: _CategoryStyle(
      icon: Icons.favorite,
      color: Colors.red,
    ),
    HabitCategory.productivity: _CategoryStyle(
      icon: Icons.work,
      color: Colors.orange,
    ),
    HabitCategory.mindfulness: _CategoryStyle(
      icon: Icons.self_improvement,
      color: Colors.purple,
    ),
    HabitCategory.social: _CategoryStyle(
      icon: Icons.people,
      color: Colors.pink,
    ),
    HabitCategory.creativity: _CategoryStyle(
      icon: Icons.palette,
      color: Colors.indigo,
    ),
    HabitCategory.learning: _CategoryStyle(
      icon: Icons.school,
      color: Colors.blue,
    ),
    HabitCategory.fitness: _CategoryStyle(
      icon: Icons.fitness_center,
      color: Colors.green,
    ),
    HabitCategory.finance: _CategoryStyle(
      icon: Icons.attach_money,
      color: Colors.teal,
    ),
    HabitCategory.other: _CategoryStyle(
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
  _CategoryStyle getStyle(HabitCategory category) {
    return _styles[category] ?? _CategoryStyle(icon: Icons.stars, color: Colors.grey);
  }
}

/// Internal class representing category visual style
class _CategoryStyle {
  final IconData icon;
  final Color color;

  _CategoryStyle({
    required this.icon,
    required this.color,
  });
}
