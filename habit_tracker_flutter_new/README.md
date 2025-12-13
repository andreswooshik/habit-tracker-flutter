# 🎯 Habit Tracker - Riverpod Implementation

> Build and track daily habits with streaks, visual calendar, and motivational insights using in-memory state management with Riverpod.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Provider Architecture](#-provider-architecture)
- [Project Structure](#-project-structure)
- [Streak Algorithm](#-streak-algorithm)
- [Setup Instructions](#-setup-instructions)
- [Testing](#-testing)
- [Known Issues](#-known-issues)
- [Success Metrics](#-success-metrics)

---

## 🎯 Overview

A comprehensive habit tracking application built with Flutter and Riverpod, demonstrating advanced state management patterns including:

- **StateNotifier** for complex state management
- **Provider computation** for derived state
- **Calendar state management** with date-based calculations
- **In-memory state persistence** patterns
- **Performance optimization** with AutoDispose
- **State history tracking** for streaks and insights

### ⚠️ Important: In-Memory State Only

**This app does NOT use:**
- ❌ SQLite or any database
- ❌ SharedPreferences or local storage
- ❌ Backend API or cloud services
- ❌ File system persistence

**It uses ONLY:**
- ✅ Riverpod StateNotifiers with Map/List data structures
- ✅ Pure in-memory state management
- ✅ Data resets when app restarts (by design for evaluation)

> This is intentional for demonstrating Riverpod state management patterns and SOLID principles without database complexity.

### Key Evaluation Criteria

✅ Correct provider type selection  
✅ Proper state lifecycle management  
✅ In-memory state persistence patterns  
✅ Performance optimization (AutoDispose usage)  
✅ State derivation and computation  
✅ Code maintainability and organization  
✅ Testing capability (70%+ coverage)  

---

## ✨ Key Features

### FR-01: Habit Management
- Create custom habits (name, description, icon)
- Set frequency (Every Day, Weekdays, Custom days)
- Assign categories (Health, Productivity, Fitness, Mindfulness, Learning)
- Set habit target (days to complete)
- Archive or delete habits

### FR-02: Daily Tracking
- Mark habits as complete/incomplete for today
- Add notes to daily completions
- View today's habits list
- Quick toggle completion status
- Bulk complete multiple habits

### FR-03: Streaks and Progress
- Current streak counter per habit
- Longest streak record
- Streak freeze (1-day grace period option)
- Monthly calendar heatmap view
- Overall completion percentage
- Weekly consistency view

### FR-04: Motivation and Insights
- Completion rate by habit (percentage)
- Best performing habits (highest streaks)
- Consistency score (7-day, 30-day)
- Weekly/monthly summary reports
- Achievement milestones (3-day, 7-day, 30-day streaks)

---

## 🛠 Tech Stack

- **Flutter SDK**: ^3.10.3
- **Dart**: ^3.10.3
- **State Management**: flutter_riverpod 2.x (ONLY dependency for state)
- **Date Handling**: intl package (formatting only)
- **Utilities**: uuid (ID generation)
- **Data Storage**: Pure in-memory (Map<String, dynamic>, List, Set)
- **Testing**: flutter_test, riverpod test utilities

### What We're NOT Using

- ❌ **NO** sqflite, drift, hive, isar, or any database
- ❌ **NO** shared_preferences or any local storage
- ❌ **NO** http, dio, or any networking
- ❌ **NO** firebase or cloud services
- ❌ **NO** file_picker or file system access

> **Why?** This project focuses purely on Riverpod state management and SOLID principles without database complexity.

---

## 🏗 Architecture

### SOLID Principles Implementation

This project strictly adheres to SOLID principles throughout the codebase:

#### **S - Single Responsibility Principle**
- Each provider manages ONE aspect of state
- Each service class has ONE clear purpose
- Models contain only data and validation logic
- UI components handle only presentation

#### **O - Open/Closed Principle**
- Providers are open for extension via Riverpod modifiers
- Services use abstract interfaces for flexibility
- Strategy pattern for different streak calculation strategies
- New habit frequencies can be added without modifying existing code

#### **L - Liskov Substitution Principle**
- All providers implement consistent interfaces
- Mock providers can substitute real providers in tests
- Abstract classes define contracts for services

#### **I - Interface Segregation Principle**
- Separate providers for different concerns (habits, completions, insights)
- Family modifiers for specific queries
- No provider exposes unnecessary methods

#### **D - Dependency Inversion Principle**
- UI depends on provider abstractions, not concrete implementations
- Services depend on interfaces, not concrete classes
- High-level modules (UI) don't depend on low-level modules (data)
- Both depend on abstractions (provider contracts)

### Provider Architecture

The app uses a layered Riverpod provider architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│  (ConsumerWidgets observing providers)                      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   Computed Providers                         │
│  • todaysHabitsProvider                                      │
│  • habitCompletionProvider.family                            │
│  • habitInsightsProvider                                     │
│  • achievementsProvider                                      │
│  • weeklyConsistencyProvider                                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Calculation/Service Providers                   │
│  • streakCalculatorProvider.family                           │
│  • calendarDataProvider.family                               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   State Notifiers                            │
│  • habitsNotifierProvider                                    │
│  • completionsProvider                                       │
│  • selectedDateProvider                                      │
└─────────────────────────────────────────────────────────────┘
```

### Required Providers (Following SOLID)

#### State Notifiers (Single Responsibility)
```dart
// Core habit state management - ONLY manages habits CRUD
final habitsNotifierProvider = 
  StateNotifierProvider<HabitsNotifier, HabitState>((ref) {
    return HabitsNotifier();
  });

// Track completions - ONLY manages completion dates
final completionsProvider = 
  StateNotifierProvider<CompletionsNotifier, Map<String, Set<DateTime>>>((ref) {
    return CompletionsNotifier();
  });

// Current selected date - ONLY manages date selection
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});
```

#### Computed Providers (Dependency Inversion & Interface Segregation)
```dart
// Habits visible today - depends on abstractions, not concrete state
final todaysHabitsProvider = Provider<List<Habit>>((ref) {
  final habitState = ref.watch(habitsNotifierProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  return habitState.habits.where((h) => h.isScheduledFor(selectedDate)).toList();
});

// Check completion status - family provider for specific queries
final habitCompletionProvider = 
  Provider.family<bool, ({String habitId, DateTime date})>((ref, params) {
    final completions = ref.watch(completionsProvider);
    return completions[params.habitId]?.contains(params.date) ?? false;
  });

// Calculate streak data - delegates to service (Open/Closed)
final streakCalculatorProvider = 
  Provider.family<StreakData, String>((ref, habitId) {
    final habit = ref.watch(habitsNotifierProvider).getHabit(habitId);
    final completions = ref.watch(completionsProvider)[habitId] ?? {};
    final calculator = ref.watch(streakCalculatorServiceProvider);
    return calculator.calculateStreak(habit, completions);
  });

// Generate calendar data - efficient date range queries
final calendarDataProvider = 
  Provider.family.autoDispose<Map<DateTime, int>, ({String habitId, int year, int month})>(
    (ref, params) {
      final completions = ref.watch(completionsProvider)[params.habitId] ?? {};
      return _generateCalendarData(completions, params.year, params.month);
    },
  );

// Aggregate insights - computes from multiple sources
final habitInsightsProvider = Provider<HabitInsights>((ref) {
  final habits = ref.watch(habitsNotifierProvider).habits;
  final completions = ref.watch(completionsProvider);
  return HabitInsights.compute(habits, completions);
});

// Achievement detection - derived from streaks
final achievementsProvider = Provider<List<Achievement>>((ref) {
  final habits = ref.watch(habitsNotifierProvider).habits;
  return habits
    .map((h) => ref.watch(streakCalculatorProvider(h.id)))
    .expand((streak) => Achievement.fromStreak(streak))
    .toList();
});

// Weekly consistency - Interface Segregation (separate concern)
final weeklyConsistencyProvider = Provider.autoDispose<Map<String, double>>((ref) {
  final habits = ref.watch(habitsNotifierProvider).habits;
  final completions = ref.watch(completionsProvider);
  return _calculateWeeklyConsistency(habits, completions);
});
```

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry with ProviderScope
├── models/                            # [S] Single Responsibility - Pure data models
│   ├── habit.dart                     # Habit entity with validation
│   ├── habit_frequency.dart           # Frequency enum (EveryDay, Weekdays, Custom)
│   ├── habit_category.dart            # Category enum with colors
│   ├── habit_state.dart               # Immutable state container
│   ├── streak_data.dart               # Streak value object
│   ├── achievement.dart               # Achievement entity
│   └── habit_insights.dart            # Insights value object
├── providers/                         # [D] Depend on abstractions
│   ├── habits_notifier.dart           # [S] ONLY habit CRUD
│   ├── completions_notifier.dart      # [S] ONLY completion tracking
│   ├── selected_date_provider.dart    # [S] ONLY date selection
│   ├── computed_providers.dart        # [I] Segregated derived state
│   ├── streak_providers.dart          # [I] Streak-specific queries
│   ├── calendar_providers.dart        # [I] Calendar-specific data
│   └── insights_providers.dart        # [I] Analytics & achievements
├── services/                          # [O][D] Open for extension, depend on interfaces
│   ├── interfaces/
│   │   ├── i_streak_calculator.dart   # Abstract streak calculator
│   │   └── i_data_generator.dart      # Abstract data generator
│   ├── streak_calculator.dart         # Concrete implementation
│   ├── streak_with_grace.dart         # [O] Extended with grace period
│   └── mock_data_generator.dart       # Test data generation
├── screens/                           # [S] Single responsibility per screen
│   ├── home_screen.dart               # Dashboard with today's habits
│   ├── habit_list_screen.dart         # All habits CRUD
│   ├── habit_form_screen.dart         # Add/Edit form
│   ├── calendar_screen.dart           # Heatmap visualization
│   └── insights_screen.dart           # Statistics dashboard
└── widgets/                           # [S] Reusable, single-purpose widgets
    ├── habit_card.dart                # Display habit item
    ├── streak_badge.dart              # Display streak count
    ├── calendar_heatmap.dart          # Monthly heatmap grid
    ├── completion_button.dart         # Toggle completion
    ├── progress_indicator.dart        # Visual progress bar
    └── achievement_badge.dart         # Display achievements

test/
├── models/                            # Model tests
├── providers/                         # Provider tests
├── services/                          # Service tests
└── widgets/                           # Widget tests
```

---

## 🔢 Streak Algorithm

### Current Streak Calculation

```dart
1. Sort completion dates descending (most recent first)
2. Start from today and work backwards
3. For each expected day based on habit frequency:
   a. If date is completed → increment streak
   b. If date is missed:
      - If within grace period (1 day) → continue
      - Otherwise → break and return streak
4. Return current streak count
```

### Longest Streak Calculation

```dart
1. Sort completion dates ascending
2. Initialize maxStreak = 0, currentStreak = 0
3. For each date in history:
   a. If date continues streak → increment currentStreak
   b. If date breaks streak → reset currentStreak
   c. Update maxStreak if currentStreak > maxStreak
4. Return maxStreak
```

### Grace Period Logic

- **1-day grace period** (optional per habit)
- If a habit is missed one day, streak continues
- Second consecutive miss breaks the streak
- Only applies to current streak, not longest streak

### Frequency Handling

- **Every Day**: Expect completion every calendar day
- **Weekdays**: Expect Mon-Fri only
- **Custom Days**: Expect only selected days (e.g., Mon/Wed/Fri)

---

## 🚀 Setup Instructions

### Prerequisites

- Flutter SDK 3.10.3 or higher
- Dart 3.10.3 or higher
- IDE (VS Code, Android Studio, or IntelliJ)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd habit-tracker-flutter/habit_tracker_flutter_new
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

4. **Run tests**
   ```bash
   flutter test
   ```

5. **Run tests with coverage**
   ```bash
   flutter test --coverage
   ```

### Mock Data (In-Memory)

The app includes pre-generated mock data loaded at startup:
- 5-10 sample habits with different frequencies
- 60 days of historical completion data
- Various streak scenarios (active, broken, recovered)
- Different categories and targets

> **Note**: All data is loaded into memory from a mock data generator service. When you restart the app, it resets to the initial mock data. This is intentional - no persistence layer means clean evaluation of state management patterns.

---

## 🧪 Testing

### Test Coverage Target

- **Minimum**: 70% code coverage
- **Target**: 85%+ code coverage

### Test Structure

```
test/
├── models/
│   └── streak_data_test.dart          # Model logic tests
├── providers/
│   ├── habits_notifier_test.dart      # CRUD operations
│   ├── completions_notifier_test.dart # Completion tracking
│   └── computed_providers_test.dart   # Derived state
├── services/
│   └── streak_calculator_test.dart    # Streak algorithm
└── widgets/
    ├── habit_card_test.dart           # Widget rendering
    └── calendar_heatmap_test.dart     # Calendar display
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/streak_calculator_test.dart

# Run tests with coverage
flutter test --coverage

# View coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## ⚠️ Known Issues & Limitations

See [KNOWN_ISSUES.md](KNOWN_ISSUES.md) for detailed information about:

- **In-memory state** - All data resets on app restart (by design)
- **No persistence** - No database, SharedPreferences, or file storage
- Timezone handling considerations
- Performance considerations with large datasets
- Missing features (push notifications, cloud sync, persistence, etc.)

> **Important**: The lack of persistence is intentional. This project demonstrates Riverpod state management patterns, not database integration.

---

## 📊 Success Metrics

### Evaluation Rubric (100 points)

| Category | Points | Criteria |
|----------|--------|----------|
| **Streak Algorithm Accuracy** | 30 | Current/longest streaks calculate correctly, grace period works, frequency handling accurate |
| **Calendar State Generation** | 20 | Efficient date range queries, correct heatmap data, handles all frequencies |
| **State Computation Efficiency** | 20 | Proper AutoDispose usage, minimal rebuilds, efficient selectors |
| **Insights Accuracy** | 15 | Correct completion rates, consistency scores, achievement detection |
| **Provider Performance** | 10 | No unnecessary computations, proper caching, responsive UI |
| **Edge Case Handling** | 5 | Timezone consistency, leap years, boundary conditions |

### Performance Benchmarks

- ✅ Completion toggle: < 16ms (single frame)
- ✅ Calendar generation: < 100ms
- ✅ Insights computation: < 200ms
- ✅ Streak calculation: < 50ms per habit

---

## 🎓 Learning Outcomes

This project demonstrates:

### Riverpod Mastery
1. **Provider Selection**: StateNotifierProvider vs Provider vs StateProvider
2. **Provider Families**: Dynamic providers based on parameters
3. **AutoDispose**: Automatic cleanup for unused providers
4. **Provider Dependencies**: Watching and combining multiple providers
5. **State Derivation**: Computing derived state efficiently
6. **Performance Optimization**: Using select() to minimize rebuilds

### SOLID Principles
1. **Single Responsibility**: Each class/provider has one clear purpose
2. **Open/Closed**: Extensible architecture via interfaces
3. **Liskov Substitution**: Mock providers in tests
4. **Interface Segregation**: Focused provider contracts
5. **Dependency Inversion**: Depend on abstractions

### Advanced Patterns
1. **Date Calculations**: Complex date-based logic with frequencies
2. **State History**: Tracking and querying historical data
3. **Immutable State**: Using copyWith patterns
4. **Value Objects**: Encapsulating domain logic
5. **Testing Patterns**: Unit testing providers with ProviderContainer

---

## 📝 Documentation

- **Architecture & SOLID Principles**: See [ARCHITECTURE.md](ARCHITECTURE.md)
- **Provider Dependencies**: Detailed in ARCHITECTURE.md
- **Streak Algorithm**: Detailed in README (see Streak Algorithm section)
- **Known Issues**: See [KNOWN_ISSUES.md](KNOWN_ISSUES.md) (to be created)

### Additional Resources

- **Riverpod Documentation**: https://riverpod.dev
- **SOLID Principles**: https://en.wikipedia.org/wiki/SOLID
- **Flutter Testing**: https://docs.flutter.dev/testing

---

## 👤 Author

**Your Name**
- GitHub: [@yourusername](https://github.com/yourusername)

---

## 📄 License

This project is part of an academic assignment and is not licensed for public use.
