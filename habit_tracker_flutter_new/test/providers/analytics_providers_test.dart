import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/providers/analytics_providers.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import '../mocks/provider_container.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = createTestProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Habit dailyHabit({required DateTime createdAt, String id = '1'}) {
    return Habit(
      id: id,
      name: 'Daily $id',
      frequency: HabitFrequency.everyDay,
      category: HabitCategory.health,
      createdAt: createdAt,
    );
  }

  group('Analytics ignores days before a habit existed (regression)', () {
    // Bug: a habit created today showed ~30 "scheduled" days in the
    // month view — one per range day — so Best Days Analysis displayed
    // misleading 0% rates over days the habit could never be done on.

    test('weekday performance only counts days since creation', () {
      container.read(habitsProvider.notifier).addHabit(
            dailyHabit(createdAt: today()),
          );

      final performance = container.read(weekdayPerformanceProvider);
      final totalScheduled =
          performance.fold(0, (sum, day) => sum + day.totalScheduled);

      // Created today -> exactly one scheduled day across the range
      expect(totalScheduled, equals(1));
    });

    test('weekday performance counts the full range for old habits', () {
      container.read(habitsProvider.notifier).addHabit(
            dailyHabit(createdAt: DateTime(2024, 1, 1)),
          );

      final performance = container.read(weekdayPerformanceProvider);
      final totalScheduled =
          performance.fold(0, (sum, day) => sum + day.totalScheduled);

      // Default range is the last 30 days, all after creation
      expect(totalScheduled, equals(30));
    });

    test('completing today gives a 100% rate on that weekday', () {
      container.read(habitsProvider.notifier).addHabit(
            dailyHabit(createdAt: today()),
          );
      container.read(completionsProvider.notifier).markComplete('1', today());

      final performance = container.read(weekdayPerformanceProvider);
      final todayPerformance = performance
          .firstWhere((day) => day.weekday == today().weekday);

      expect(todayPerformance.totalScheduled, equals(1));
      expect(todayPerformance.totalCompleted, equals(1));
      expect(todayPerformance.completionRate, equals(1.0));
    });

    test('category performance only counts days since creation', () {
      container.read(habitsProvider.notifier).addHabit(
            dailyHabit(createdAt: today()),
          );
      container.read(completionsProvider.notifier).markComplete('1', today());

      final performance = container.read(categoryPerformanceProvider);

      expect(performance, hasLength(1));
      expect(performance.first.totalScheduled, equals(1));
      expect(performance.first.completionRate, equals(1.0));
    });

    test('completion trend has no scheduled days before creation', () {
      container.read(habitsProvider.notifier).addHabit(
            dailyHabit(createdAt: today()),
          );

      final trend = container.read(completionTrendProvider);

      // Every point before today has nothing scheduled
      final pastPoints = trend.where((p) => p.date.isBefore(today()));
      for (final point in pastPoints) {
        expect(point.totalScheduled, equals(0));
      }
      expect(trend.last.totalScheduled, equals(1));
    });
  });
}
