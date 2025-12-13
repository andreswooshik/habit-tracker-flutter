# Quick Start Guide

## Dependencies to Add

### Update pubspec.yaml

```yaml
name: habit_tracker_flutter_new
description: "Habit Tracker with Riverpod and SOLID principles"
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.10.3

dependencies:
  flutter:
    sdk: flutter
  
  # State Management - The ONLY state management dependency
  flutter_riverpod: ^2.4.0
  
  # Utilities
  uuid: ^4.0.0              # Generate unique IDs for habits
  intl: ^0.18.0            # Date formatting only
  
  # UI
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  
  # Optional: For immutable models (recommended)
  freezed: ^2.4.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0
  build_runner: ^2.4.0

flutter:
  uses-material-design: true
```

### Install Dependencies

```bash
cd habit_tracker_flutter_new
flutter pub get
```

---

## Project Structure to Create

```
lib/
├── main.dart                          # ProviderScope wrapper
├── models/                            # Data classes
│   ├── habit.dart
│   ├── habit_frequency.dart
│   ├── habit_category.dart
│   ├── habit_state.dart
│   ├── streak_data.dart
│   ├── achievement.dart
│   └── habit_insights.dart
├── providers/                         # Riverpod providers
│   ├── habits_notifier.dart
│   ├── completions_notifier.dart
│   ├── selected_date_provider.dart
│   ├── computed_providers.dart
│   ├── streak_providers.dart
│   ├── calendar_providers.dart
│   └── insights_providers.dart
├── services/                          # Business logic
│   ├── interfaces/
│   │   ├── i_streak_calculator.dart
│   │   └── i_data_generator.dart
│   ├── streak_calculator.dart
│   └── mock_data_generator.dart
├── screens/                           # UI screens
│   ├── home_screen.dart
│   ├── habit_list_screen.dart
│   ├── habit_form_screen.dart
│   ├── calendar_screen.dart
│   └── insights_screen.dart
└── widgets/                           # Reusable components
    ├── habit_card.dart
    ├── streak_badge.dart
    ├── calendar_heatmap.dart
    ├── completion_button.dart
    ├── progress_indicator.dart
    └── achievement_badge.dart

test/
├── models/
├── providers/
├── services/
└── widgets/
```

---

## Initial Setup Code

### 1. main.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    // Wrap entire app with ProviderScope
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
```

### 2. Create First Provider (Example)

```dart
// lib/providers/selected_date_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple StateProvider for current selected date
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});
```

### 3. Use Provider in Widget

```dart
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/selected_date_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch provider for changes
    final selectedDate = ref.watch(selectedDateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
      ),
      body: Center(
        child: Text('Selected Date: ${selectedDate.toLocal()}'),
      ),
    );
  }
}
```

---

## Data Structures (In-Memory)

### State Containers

```dart
// HabitsNotifier holds:
Map<String, Habit> habitsById = {};
List<Habit> habits = [];

// CompletionsNotifier holds:
Map<String, Set<DateTime>> completions = {
  'habit-id-1': {DateTime(2025, 12, 10), DateTime(2025, 12, 11)},
  'habit-id-2': {DateTime(2025, 12, 11), DateTime(2025, 12, 12)},
};

// SelectedDateProvider holds:
DateTime selectedDate = DateTime.now();
```

### No Database Tables!

We DON'T have:
- ❌ SQL CREATE TABLE statements
- ❌ Database migrations
- ❌ Repository classes with async database calls
- ❌ DAOs or database entities

We DO have:
- ✅ Pure Dart classes (models)
- ✅ In-memory Maps and Lists
- ✅ Synchronous state updates
- ✅ Simple, clean code

---

## Running the App

```bash
# Navigate to project
cd habit_tracker_flutter_new

# Get dependencies
flutter pub get

# Run on device/emulator
flutter run

# Hot reload during development (keeps state)
# Press 'r' in terminal

# Hot restart (resets to mock data)
# Press 'R' in terminal

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage
```

---

## Development Workflow

### Day 1-2: Models
1. Create all model classes in `lib/models/`
2. Add validation logic
3. Write model tests

### Day 3-4: Core Providers
1. Create StateNotifiers for habits and completions
2. Add CRUD methods
3. Write provider unit tests

### Day 5-6: Services
1. Implement streak calculator
2. Create mock data generator
3. Test business logic thoroughly

### Day 7-8: Computed Providers
1. Add derived state providers
2. Use .family for parameterized queries
3. Test provider combinations

### Day 9-13: UI
1. Build screens one by one
2. Create reusable widgets
3. Wire up providers to UI
4. Test widgets

### Day 14-15: Integration & Polish
1. Load mock data at startup
2. Test full user flows
3. Optimize performance
4. Fix bugs

### Day 16-17: Final Testing & Demo
1. Achieve 70%+ coverage
2. Document code
3. Record demo video

---

## Testing Examples

### Provider Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('selectedDateProvider defaults to today', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    
    final selectedDate = container.read(selectedDateProvider);
    
    expect(selectedDate.day, equals(DateTime.now().day));
  });
}
```

### Widget Test

```dart
testWidgets('HomeScreen displays selected date', (tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: HomeScreen()),
    ),
  );
  
  expect(find.text('Selected Date:'), findsOneWidget);
});
```

---

## Common Commands

```bash
# Create new file
touch lib/models/habit.dart

# Run specific test
flutter test test/providers/habits_notifier_test.dart

# Clean build
flutter clean
flutter pub get

# Format code
dart format lib/

# Analyze code
flutter analyze

# Run with verbose logging
flutter run -v
```

---

## Troubleshooting

### "Provider not found"
- Make sure ProviderScope wraps your app in main.dart
- Check provider import paths

### "State doesn't update"
- Use ConsumerWidget or ConsumerStatefulWidget
- Make sure you're using ref.watch(), not ref.read() in build

### "Data resets on hot reload"
- Hot reload (r) preserves state
- Hot restart (R) resets to mock data - this is normal!

### "Tests fail - can't find provider"
- Wrap test widgets in ProviderScope
- Override providers if needed for mocking

---

## Remember

🎯 **Keep it simple - no database!**

- All state in Riverpod providers
- All data in memory (Maps, Lists, Sets)
- Clean, testable, SOLID code
- Focus on state management patterns

Ready to code? Start with Phase 1 in [ROADMAP.md](ROADMAP.md)! 🚀
