import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/screens/ai_chat_screen.dart';
import 'package:habit_tracker_flutter_new/screens/analytics_screen.dart';
import 'package:habit_tracker_flutter_new/screens/habit_list_screen.dart';
import 'package:habit_tracker_flutter_new/screens/home_dashboard_screen.dart';
import 'package:habit_tracker_flutter_new/screens/settings_screen.dart';

class AppShellScreen extends ConsumerStatefulWidget {
  const AppShellScreen({super.key});

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Schedule smart reminders once the first frame (and providers) are up
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reminderSchedulerProvider).reschedule();
    });
  }

  static const _destinations = [
    _AppDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _AppDestination(
      label: 'Habits',
      icon: Icons.checklist_outlined,
      selectedIcon: Icons.checklist,
    ),
    _AppDestination(
      label: 'Analytics',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
    ),
    _AppDestination(
      label: 'AI Coach',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
    ),
    _AppDestination(
      label: 'Settings',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  final _pages = const [
    HomeDashboardScreen(showAppBar: false),
    HabitListScreen(showAppBar: false),
    AnalyticsScreen(showAppBar: false),
    AiChatScreen(showAppBar: false),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Keep scheduled reminders in step with the data: completing a habit
    // drops its reminder, adding one schedules it
    ref.listen(completionsProvider, (previous, next) {
      ref.read(reminderSchedulerProvider).reschedule();
    });
    ref.listen(habitsProvider, (previous, next) {
      ref.read(reminderSchedulerProvider).reschedule();
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 800;

        return Scaffold(
          appBar: AppBar(
            title: Text(_destinations[_selectedIndex].label),
            centerTitle: false,
          ),
          body: Row(
            children: [
              if (useRail)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectDestination,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final destination in _destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
              if (useRail) const VerticalDivider(width: 1),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectDestination,
                  destinations: [
                    for (final destination in _destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: destination.label,
                      ),
                  ],
                ),
        );
      },
    );
  }

  void _selectDestination(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class _AppDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
