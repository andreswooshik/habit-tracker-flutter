import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';

/// Builds a habit created far in the past (2020).
///
/// Provider tests exercise habits against fixed historic dates (2024);
/// since Habit.existedOn hides habits on days before their creation,
/// test habits must predate those dates — Habit.create would stamp
/// them with today's date and make them invisible to the providers.
Habit backdatedHabit({
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
  DateTime? createdAt,
}) {
  return Habit.create(
    id: id,
    name: name,
    description: description,
    icon: icon,
    frequency: frequency,
    customDays: customDays,
    category: category,
    targetDays: targetDays,
    hasGracePeriod: hasGracePeriod,
    notes: notes,
  ).copyWith(createdAt: createdAt ?? DateTime(2020, 1, 1));
}
