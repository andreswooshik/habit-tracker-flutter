import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';

import '../mocks/provider_container.dart';

/// Regression tests: a habit must only be visible from the day it was
/// created (Habit.existedOn). Creating a habit today used to make it
/// appear — as scheduled and missed — on every earlier day browsed in
/// the habit list and counted in the calendar heatmap.
void main() {
  DateTime day(DateTime date) => DateTime(date.year, date.month, date.day);

  test('habit created today is not scheduled on earlier days', () {
    final container = createTestProviderContainer();
    addTearDown(container.dispose);

    final habit = Habit.create(id: 'new', name: 'Mobile Legends');
    container.read(habitsProvider.notifier).addHabit(habit);

    final today = day(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    expect(
      container.read(scheduledHabitsForDateProvider(today)),
      hasLength(1),
    );
    expect(
      container.read(scheduledHabitsForDateProvider(yesterday)),
      isEmpty,
    );
    expect(container.read(habitsScheduledCountProvider(yesterday)), 0);
  });

  test('habit is visible on its creation day itself', () {
    final container = createTestProviderContainer();
    addTearDown(container.dispose);

    final habit = Habit.create(id: 'new', name: 'Mobile Legends');
    container.read(habitsProvider.notifier).addHabit(habit);

    expect(habit.existedOn(DateTime.now()), isTrue);
    expect(
      habit.existedOn(DateTime.now().subtract(const Duration(days: 1))),
      isFalse,
    );
  });
}
