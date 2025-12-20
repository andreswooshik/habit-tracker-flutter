import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/screens/add_edit_habit_screen.dart';
import 'package:habit_tracker_flutter_new/widgets/habit_detail/habit_detail.dart';
import 'package:habit_tracker_flutter_new/widgets/animations/animations.dart';

class HabitDetailScreen extends ConsumerWidget {
  final Habit habit;

  const HabitDetailScreen({
    super.key,
    required this.habit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final habitInsights = ref.watch(habitInsightsForHabitProvider(habit.id));
    final streakData = ref.watch(habitStreakProvider(habit.id));
    final previousStreak = ref.watch(habitStreakProvider(habit.id)).current;

    return Hero(
      tag: 'habit_card_${habit.id}',
      child: StreakMilestoneCelebration(
        currentStreak: streakData.current,
        previousStreak: previousStreak - 1, // Simulate previous for celebration
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              // App Bar with gradient header
              HabitDetailAppBar(
                habit: habit,
                onEdit: () => _navigateToEdit(context),
                onDelete: () => _confirmDelete(context, ref),
              ),

              // Content sections
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Streak Display Section
                    StreakDisplayCard(
                      currentStreak: streakData.current,
                      bestStreak: streakData.longest,
                      isAtRisk: false, // TODO: Implement risk detection
                    ),

                    const SizedBox(height: 16),

                    // 30-Day Calendar Heatmap
                    HeatmapCalendar(
                      habit: habit,
                      selectedDate: selectedDate,
                    ),

                    const SizedBox(height: 16),

                    // Statistics Grid
                    StatisticsGrid(
                      habitId: habit.id,
                      insights: habitInsights,
                    ),

                    const SizedBox(height: 16),

                    // Recent Activity Timeline
                    RecentActivityTimeline(
                      habitId: habit.id,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditHabitScreen(habit: habit),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text(
          'Are you sure you want to delete "${habit.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ref.read(habitsProvider.notifier).deleteHabit(habit.id);
      Navigator.of(context).pop();
    }
  }
}
