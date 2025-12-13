import 'package:equatable/equatable.dart';
import 'habit_frequency.dart';
import 'habit_category.dart';

/// Immutable habit entity representing a single habit
/// 
/// Uses Equatable for value equality and provides copyWith for immutability
class Habit extends Equatable {
  /// Unique identifier for the habit
  final String id;

  /// Name of the habit (required)
  final String name;

  /// Optional description providing more details
  final String? description;

  /// Optional emoji or icon identifier
  final String? icon;

  /// How often the habit should be performed
  final HabitFrequency frequency;

  /// Custom days for custom frequency (1=Monday, 7=Sunday)
  final List<int>? customDays;

  /// Category classification
  final HabitCategory category;

  /// Target number of days to complete this habit
  final int targetDays;

  /// Whether this habit has a 1-day grace period for streaks
  final bool hasGracePeriod;

  /// Whether this habit is archived (soft delete)
  final bool isArchived;

  /// When this habit was created
  final DateTime createdAt;

  /// Optional notes or additional context
  final String? notes;

  const Habit({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.frequency,
    this.customDays,
    required this.category,
    this.targetDays = 30,
    this.hasGracePeriod = false,
    this.isArchived = false,
    required this.createdAt,
    this.notes,
  });

  /// Factory constructor for creating a new habit with defaults
  factory Habit.create({
    required String id,
    required String name,
    String? description,
    String? icon,
    HabitFrequency frequency = HabitFrequency.everyDay,
    List<int>? customDays,
    HabitCategory category = HabitCategory.other,
    int targetDays = 30,
    bool hasGracePeriod = false,
    String? notes,
  }) {
    return Habit(
      id: id,
      name: name,
      description: description,
      icon: icon,
      frequency: frequency,
      customDays: customDays,
      category: category,
      targetDays: targetDays,
      hasGracePeriod: hasGracePeriod,
      isArchived: false,
      createdAt: DateTime.now(),
      notes: notes,
    );
  }

  /// Checks if this habit is scheduled for the given date
  bool isScheduledFor(DateTime date) {
    if (isArchived) return false;
    return frequency.isScheduledFor(date, customDays);
  }

  /// Validates that the habit data is correct
  bool get isValid {
    // Name must not be empty
    if (name.trim().isEmpty) return false;

    // Target days must be positive
    if (targetDays <= 0) return false;

    // If custom frequency, must have custom days
    if (frequency == HabitFrequency.custom) {
      if (customDays == null || customDays!.isEmpty) return false;
      // All days must be valid (1-7)
      if (customDays!.any((day) => day < 1 || day > 7)) return false;
    }

    return true;
  }

  /// Returns the expected number of completions per week
  int get expectedPerWeek {
    if (frequency == HabitFrequency.custom && customDays != null) {
      return customDays!.length;
    }
    return frequency.expectedPerWeek;
  }

  /// Creates a copy of this habit with updated fields
  Habit copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    HabitFrequency? frequency,
    List<int>? customDays,
    HabitCategory? category,
    int? targetDays,
    bool? hasGracePeriod,
    bool? isArchived,
    DateTime? createdAt,
    String? notes,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      category: category ?? this.category,
      targetDays: targetDays ?? this.targetDays,
      hasGracePeriod: hasGracePeriod ?? this.hasGracePeriod,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        icon,
        frequency,
        customDays,
        category,
        targetDays,
        hasGracePeriod,
        isArchived,
        createdAt,
        notes,
      ];

  @override
  String toString() {
    return 'Habit(id: $id, name: $name, frequency: ${frequency.displayName}, '
        'category: ${category.displayName}, isArchived: $isArchived)';
  }
}
