import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/habit.dart';
import 'package:habit_tracker_flutter_new/models/habit_category.dart';
import 'package:habit_tracker_flutter_new/models/habit_frequency.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:uuid/uuid.dart';

class EmptyOnboardingCard extends ConsumerWidget {
  final VoidCallback onCreateCustom;

  const EmptyOnboardingCard({
    super.key,
    required this.onCreateCustom,
  });

  static const _templates = [
    _HabitTemplate(
      name: 'Drink Water',
      category: HabitCategory.health,
      frequency: HabitFrequency.everyDay,
      icon: Icons.water_drop,
    ),
    _HabitTemplate(
      name: 'Study Session',
      category: HabitCategory.learning,
      frequency: HabitFrequency.weekdays,
      icon: Icons.school,
    ),
    _HabitTemplate(
      name: 'Daily Walk',
      category: HabitCategory.fitness,
      frequency: HabitFrequency.everyDay,
      icon: Icons.directions_walk,
    ),
    _HabitTemplate(
      name: 'Track Expenses',
      category: HabitCategory.finance,
      frequency: HabitFrequency.everyDay,
      icon: Icons.savings,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.rocket_launch_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create your first habit',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start from scratch or pick a quick template.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreateCustom,
              icon: const Icon(Icons.add),
              label: const Text('Create Custom Habit'),
            ),
            const SizedBox(height: 20),
            Text(
              'Quick templates',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final template in _templates)
                  _TemplateChip(
                    template: template,
                    onTap: () => _createFromTemplate(context, ref, template),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createFromTemplate(
    BuildContext context,
    WidgetRef ref,
    _HabitTemplate template,
  ) async {
    final habit = Habit.create(
      id: const Uuid().v4(),
      name: template.name,
      category: template.category,
      frequency: template.frequency,
      targetDays: 30,
    );

    final success = await ref.read(habitsProvider.notifier).addHabit(habit);
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${template.name} added'
              : ref.read(habitsProvider).errorMessage ?? 'Unable to add habit',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final _HabitTemplate template;
  final VoidCallback onTap;

  const _TemplateChip({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = template.category.color;

    return ActionChip(
      avatar: Icon(template.icon, size: 18, color: color),
      label: Text(template.name),
      tooltip:
          '${template.category.displayName} - ${template.frequency.displayName}',
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      backgroundColor: color.withValues(alpha: 0.08),
      onPressed: onTap,
    );
  }
}

class _HabitTemplate {
  final String name;
  final HabitCategory category;
  final HabitFrequency frequency;
  final IconData icon;

  const _HabitTemplate({
    required this.name,
    required this.category,
    required this.frequency,
    required this.icon,
  });
}
