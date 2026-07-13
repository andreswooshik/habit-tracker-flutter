import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/widgets/habit_card.dart';
import 'package:habit_tracker_flutter_new/widgets/onboarding/empty_onboarding_card.dart';
import 'package:habit_tracker_flutter_new/screens/add_edit_habit_screen.dart';
import 'package:intl/intl.dart';

/// Main screen displaying the list of habits for the selected date
///
/// Features:
/// - Displays today's habits with completion status
/// - Shows progress statistics
/// - Allows completion toggle
/// - Filters and sorts habits
class HabitListScreen extends ConsumerWidget {
  final bool showAppBar;

  const HabitListScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Anchored to the browsed date, not today — this screen navigates
    // between days without affecting the dashboard
    final todaysHabits = ref.watch(selectedDateHabitsProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final todaysProgress = ref.watch(selectedDateProgressProvider);
    final completedCount = ref.watch(selectedDateCompletedCountProvider);
    final totalCount = ref.watch(selectedDateHabitsCountProvider);
    final hasAnyActiveHabits =
        ref.watch(habitsProvider).activeHabits.isNotEmpty;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Habit Tracker'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _navigateToAddHabit(context),
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          // Date selector and progress card
          _DateProgressCard(
            selectedDate: selectedDate,
            progress: todaysProgress,
            completedCount: completedCount,
            totalCount: totalCount,
            onDateChanged: (date) {
              ref.read(selectedDateProvider.notifier).state = date;
            },
          ),

          // Habits list
          Expanded(
            child: todaysHabits.isEmpty
                ? _EmptyState(
                    selectedDate: selectedDate,
                    hasAnyActiveHabits: hasAnyActiveHabits,
                    onCreateCustom: () => _navigateToAddHabit(context),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: todaysHabits.length,
                    itemBuilder: (context, index) {
                      final habit = todaysHabits[index];
                      return HabitCard(
                        habit: habit,
                        selectedDate: selectedDate,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddHabit(context),
        tooltip: 'Create a new habit',
        icon: const Icon(Icons.add),
        label: const Text('New Habit'),
      ),
    );
  }

  void _navigateToAddHabit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddEditHabitScreen(),
      ),
    );
  }
}

/// Date selector and progress card widget
class _DateProgressCard extends StatelessWidget {
  final DateTime selectedDate;
  final double progress;
  final int completedCount;
  final int totalCount;
  final ValueChanged<DateTime> onDateChanged;

  const _DateProgressCard({
    required this.selectedDate,
    required this.progress,
    required this.completedCount,
    required this.totalCount,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(selectedDate);
    final dateText =
        isToday ? 'Today' : DateFormat('EEEE, MMM d').format(selectedDate);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    onDateChanged(
                        selectedDate.subtract(const Duration(days: 1)));
                  },
                ),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      onDateChanged(date);
                    }
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      dateText,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    onDateChanged(selectedDate.add(const Duration(days: 1)));
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(progress),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Progress text
            Text(
              '$completedCount of $totalCount habits completed',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),

            // Percentage
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getProgressColor(progress),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

/// Empty state when no habits scheduled for the day
class _EmptyState extends StatelessWidget {
  final DateTime selectedDate;
  final bool hasAnyActiveHabits;
  final VoidCallback onCreateCustom;

  const _EmptyState({
    required this.selectedDate,
    required this.hasAnyActiveHabits,
    required this.onCreateCustom,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(selectedDate);

    if (!hasAnyActiveHabits) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EmptyOnboardingCard(onCreateCustom: onCreateCustom),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isToday ? Icons.celebration : Icons.event_busy,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              isToday
                  ? 'No habits scheduled for today'
                  : 'No habits scheduled for this day',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isToday
                  ? 'Tap the + button to create your first habit'
                  : 'Check another date or create a new habit',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
