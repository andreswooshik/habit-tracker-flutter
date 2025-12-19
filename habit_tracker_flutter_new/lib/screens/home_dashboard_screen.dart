import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/screens/habit_list_screen.dart';
import 'package:habit_tracker_flutter_new/widgets/dashboard/dashboard.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrackIt!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _navigateToHabitList(context),
            tooltip: 'View Habits',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh providers
          ref.invalidate(todaysHabitsProvider);
          ref.invalidate(habitInsightsProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's Summary Card
              const TodaysSummaryCard(),

              const SizedBox(height: 20),

              // Weekly Performance Chart
              const WeeklyPerformanceChart(),

              const SizedBox(height: 20),

              // Achievements Showcase
              const AchievementsShowcase(),

              const SizedBox(height: 20),

              // Consistency Tracker
              const ConsistencyTracker(),

              const SizedBox(height: 20),

              // Quick Stats Grid
              const QuickStatsGrid(),

              const SizedBox(height: 20),

              // Category Breakdown
              const CategoryBreakdown(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToHabitList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HabitListScreen(),
      ),
    );
  }
}
