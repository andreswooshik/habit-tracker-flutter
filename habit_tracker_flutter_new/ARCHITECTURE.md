# Architecture & SOLID Principles

## Overview

This document details how the Habit Tracker implements SOLID principles using Riverpod for state management.

### ⚠️ Architecture Scope

**This is a pure in-memory application:**
- ✅ State management with Riverpod only
- ✅ Map, List, Set data structures in memory
- ❌ NO database layer (SQLite, Drift, Hive, etc.)
- ❌ NO persistence layer (SharedPreferences, files, etc.)
- ❌ NO repository pattern or data layer abstraction
- ❌ NO backend API or networking

**Why no database?**
This project focuses on demonstrating Riverpod state management and SOLID principles without the complexity of data persistence. The architecture is simplified to show clean provider patterns and state derivation.

---

## SOLID Principles Implementation

### 1. Single Responsibility Principle (SRP)

**Every class/provider has ONE reason to change.**

#### Examples:

**✅ Good - HabitsNotifier**
```dart
class HabitsNotifier extends StateNotifier<HabitState> {
  // ONLY manages habit CRUD operations
  void addHabit(Habit habit) { }
  void updateHabit(String id, Habit habit) { }
  void deleteHabit(String id) { }
  void archiveHabit(String id) { }
}
```

**✅ Good - CompletionsNotifier**
```dart
class CompletionsNotifier extends StateNotifier<Map<String, Set<DateTime>>> {
  // ONLY manages completion dates
  void toggleCompletion(String habitId, DateTime date) { }
  void markComplete(String habitId, DateTime date) { }
  void markIncomplete(String habitId, DateTime date) { }
}
```

**❌ Bad - God Object**
```dart
class HabitManager {
  // Violates SRP - too many responsibilities!
  void addHabit() { }
  void toggleCompletion() { }
  StreakData calculateStreak() { }
  List<Achievement> getAchievements() { }
  Map<DateTime, int> generateCalendar() { }
}
```

---

### 2. Open/Closed Principle (OCP)

**Open for extension, closed for modification.**

#### Streak Calculator Strategy Pattern

```dart
// Abstract interface - closed for modification
abstract class IStreakCalculator {
  StreakData calculateStreak(Habit habit, Set<DateTime> completions);
}

// Basic implementation
class BasicStreakCalculator implements IStreakCalculator {
  @override
  StreakData calculateStreak(Habit habit, Set<DateTime> completions) {
    // Basic streak logic
  }
}

// Extended with grace period - open for extension!
class GracePeriodStreakCalculator implements IStreakCalculator {
  final int graceDays;
  
  GracePeriodStreakCalculator({this.graceDays = 1});
  
  @override
  StreakData calculateStreak(Habit habit, Set<DateTime> completions) {
    // Enhanced logic with grace period
  }
}

// Provider can switch implementations without changing code
final streakCalculatorServiceProvider = Provider<IStreakCalculator>((ref) {
  return GracePeriodStreakCalculator(graceDays: 1);
  // Can easily swap to: BasicStreakCalculator()
});
```

#### Habit Frequency Extension

```dart
// New frequencies can be added without modifying existing code
enum HabitFrequency {
  everyDay,
  weekdays,
  weekends,
  custom;
  
  // Each frequency knows how to determine if it's scheduled
  bool isScheduledFor(DateTime date, List<int>? customDays) {
    switch (this) {
      case HabitFrequency.everyDay:
        return true;
      case HabitFrequency.weekdays:
        return date.weekday <= 5;
      case HabitFrequency.weekends:
        return date.weekday > 5;
      case HabitFrequency.custom:
        return customDays?.contains(date.weekday) ?? false;
    }
  }
}
```

---

### 3. Liskov Substitution Principle (LSP)

**Subtypes must be substitutable for their base types.**

#### Provider Testing Example

```dart
// Real provider
final habitsNotifierProvider = 
  StateNotifierProvider<HabitsNotifier, HabitState>((ref) {
    return HabitsNotifier();
  });

// Mock provider - can substitute real provider in tests
class MockHabitsNotifier extends StateNotifier<HabitState> 
  implements HabitsNotifier {
  
  MockHabitsNotifier() : super(HabitState.initial());
  
  @override
  void addHabit(Habit habit) {
    // Mock implementation
  }
  
  // All methods behave consistently with the interface
}

// Test setup
testWidgets('Can substitute mock provider', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        habitsNotifierProvider.overrideWith((ref) => MockHabitsNotifier()),
      ],
      child: MyApp(),
    ),
  );
  // UI works identically with mock!
});
```

---

### 4. Interface Segregation Principle (ISP)

**Clients shouldn't depend on interfaces they don't use.**

#### Segregated Providers

```dart
// ❌ Bad - Fat interface
final everythingProvider = Provider<HabitManager>((ref) {
  // Returns object with 20+ methods
  // Widgets must depend on entire object even if they only need one method
});

// ✅ Good - Segregated providers
final todaysHabitsProvider = Provider<List<Habit>>((ref) {
  // ONLY provides today's habits
});

final habitCompletionProvider = 
  Provider.family<bool, ({String habitId, DateTime date})>((ref, params) {
  // ONLY checks completion status
});

final streakProvider = Provider.family<StreakData, String>((ref, habitId) {
  // ONLY provides streak data
});

// Widgets depend only on what they need
class HabitCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only watches streak - doesn't depend on completions, insights, etc.
    final streak = ref.watch(streakProvider(habitId));
    return Text('Streak: ${streak.current}');
  }
}
```

#### Family Providers for Specific Queries

```dart
// Each family provider serves a specific, focused purpose

// Check if ONE habit is complete on ONE date
final habitCompletionProvider = 
  Provider.family<bool, ({String habitId, DateTime date})>((ref, params) {
    final completions = ref.watch(completionsProvider);
    return completions[params.habitId]?.contains(params.date) ?? false;
  });

// Get calendar data for ONE habit for ONE month
final calendarDataProvider = 
  Provider.family<Map<DateTime, int>, ({String habitId, int year, int month})>(
    (ref, params) {
      // Focused on just this query
    },
  );
```

---

### 5. Dependency Inversion Principle (DIP)

**Depend on abstractions, not concretions.**

#### Provider Dependencies

```dart
// High-level module (UI) depends on abstraction (provider)
class HabitListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Depends on provider interface, not concrete implementation
    final habits = ref.watch(todaysHabitsProvider);
    
    return ListView.builder(
      itemCount: habits.length,
      itemBuilder: (ctx, i) => HabitCard(habit: habits[i]),
    );
  }
}

// Provider (abstraction) coordinates between low-level modules
final todaysHabitsProvider = Provider<List<Habit>>((ref) {
  // Coordinates dependencies but UI doesn't know the details
  final habitState = ref.watch(habitsNotifierProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  
  return habitState.habits
    .where((h) => h.isScheduledFor(selectedDate))
    .toList();
});
```

#### Service Abstraction

```dart
// Abstract interface
abstract class IStreakCalculator {
  StreakData calculateStreak(Habit habit, Set<DateTime> completions);
}

// High-level provider depends on abstraction
final streakCalculatorProvider = 
  Provider.family<StreakData, String>((ref, habitId) {
    final habit = ref.watch(habitsNotifierProvider).getHabit(habitId);
    final completions = ref.watch(completionsProvider)[habitId] ?? {};
    
    // Depends on interface, not concrete class
    final calculator = ref.watch(streakCalculatorServiceProvider);
    
    return calculator.calculateStreak(habit, completions);
  });

// Can inject different implementations
final streakCalculatorServiceProvider = Provider<IStreakCalculator>((ref) {
  return GracePeriodStreakCalculator(); // Concrete implementation
});
```

---

## Riverpod Architecture Patterns

### 1. State Notifier for Complex State

```dart
@freezed
class HabitState with _$HabitState {
  const factory HabitState({
    required List<Habit> habits,
    required Map<String, Habit> habitsById,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _HabitState;
  
  factory HabitState.initial() => HabitState(
    habits: [],
    habitsById: {},
  );
}

class HabitsNotifier extends StateNotifier<HabitState> {
  HabitsNotifier() : super(HabitState.initial());
  
  void addHabit(Habit habit) {
    state = state.copyWith(
      habits: [...state.habits, habit],
      habitsById: {...state.habitsById, habit.id: habit},
    );
  }
}

final habitsNotifierProvider = 
  StateNotifierProvider<HabitsNotifier, HabitState>((ref) {
    return HabitsNotifier();
  });
```

### 2. AutoDispose for Performance

```dart
// Automatically disposed when no longer used
final calendarDataProvider = 
  Provider.family.autoDispose<Map<DateTime, int>, ({String habitId, int year, int month})>(
    (ref, params) {
      // Disposed when user navigates away from calendar
      final completions = ref.watch(completionsProvider)[params.habitId] ?? {};
      return _generateCalendarData(completions, params.year, params.month);
    },
  );

// Keep alive for frequently accessed data
final habitInsightsProvider = Provider<HabitInsights>((ref) {
  // NO autoDispose - insights used across multiple screens
  final habits = ref.watch(habitsNotifierProvider).habits;
  final completions = ref.watch(completionsProvider);
  return HabitInsights.compute(habits, completions);
});
```

### 3. Select for Minimal Rebuilds

```dart
class HabitCard extends ConsumerWidget {
  final String habitId;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuilds when THIS habit changes, not when any habit changes
    final habit = ref.watch(
      habitsNotifierProvider.select((state) => state.habitsById[habitId]),
    );
    
    return Card(child: Text(habit?.name ?? ''));
  }
}
```

### 4. Provider Combination

```dart
// Combines multiple providers efficiently
final todaysHabitsProvider = Provider<List<Habit>>((ref) {
  final habitState = ref.watch(habitsNotifierProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  
  return habitState.habits
    .where((h) => h.isScheduledFor(selectedDate))
    .toList();
});

// Depends on computed provider
final todaysCompletionRateProvider = Provider<double>((ref) {
  final todaysHabits = ref.watch(todaysHabitsProvider);
  final completions = ref.watch(completionsProvider);
  final today = ref.watch(selectedDateProvider);
  
  if (todaysHabits.isEmpty) return 0.0;
  
  final completed = todaysHabits
    .where((h) => completions[h.id]?.contains(today) ?? false)
    .length;
  
  return completed / todaysHabits.length;
});
```

---

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     UI Layer (Screens)                       │
│              ConsumerWidgets & ConsumerStatefulWidgets       │
│                 [Depends on Abstractions - DIP]              │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ ref.watch / ref.read
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Computed Providers (Read-Only)                  │
│        [Single Responsibility - Each computes one thing]     │
│  • todaysHabitsProvider                                      │
│  • habitCompletionProvider.family                            │
│  • habitInsightsProvider                                     │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ ref.watch
                            ↓
┌─────────────────────────────────────────────────────────────┐
│           Service Providers (Business Logic)                 │
│         [Open/Closed - Depend on Interfaces]                 │
│  • streakCalculatorProvider.family                           │
│  • calendarDataProvider.family                               │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ ref.watch
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              State Notifiers (Mutable State)                 │
│    [Single Responsibility - Each manages one state slice]    │
│  • habitsNotifierProvider (Habit CRUD)                       │
│  • completionsProvider (Completion tracking)                 │
│  • selectedDateProvider (Date selection)                     │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ state mutation
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                 Immutable State Objects                      │
│      [Value Objects & Entities - IN MEMORY ONLY]            │
│  • HabitState (with copyWith)                                │
│  • Map<String, Set<DateTime>> (completions)                  │
│  • DateTime (selected date)                                  │
│                                                              │
│  NO DATABASE - NO REPOSITORY - NO PERSISTENCE                │
│  Data resets when app restarts                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Testing Strategy

### Unit Testing Providers

```dart
void main() {
  group('HabitsNotifier', () {
    test('should add habit', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      final notifier = container.read(habitsNotifierProvider.notifier);
      final habit = Habit(id: '1', name: 'Test');
      
      notifier.addHabit(habit);
      
      final state = container.read(habitsNotifierProvider);
      expect(state.habits, contains(habit));
    });
  });
}
```

### Widget Testing with Providers

```dart
testWidgets('HabitCard displays streak', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        streakProvider('1').overrideWithValue(
          StreakData(current: 5, longest: 10),
        ),
      ],
      child: MaterialApp(home: HabitCard(habitId: '1')),
    ),
  );
  
  expect(find.text('5'), findsOneWidget);
});
```

---

## Performance Optimization

### 1. AutoDispose for Temporary State
- Calendar data providers (per month)
- Filtered lists
- Computed statistics for specific time ranges

### 2. Select for Granular Updates
- Watch specific habits by ID
- Watch specific fields from state
- Prevent unnecessary rebuilds

### 3. Family Providers for Parameterized Queries
- Per-habit streak calculations
- Per-date completion checks
- Per-month calendar data

### 4. Caching Strategies
- Provider values are cached automatically
- Family providers cache per parameter
- AutoDispose cleans up unused caches

---

## Summary

This architecture demonstrates:

✅ **SOLID Principles** throughout the codebase  
✅ **Riverpod Best Practices** for state management  
✅ **Clear Separation of Concerns** in layers  
✅ **Testability** through dependency injection  
✅ **Performance** through AutoDispose and select  
✅ **Maintainability** through single-purpose modules  

Every provider, service, and widget has a clear, single responsibility and depends on abstractions rather than concrete implementations.
