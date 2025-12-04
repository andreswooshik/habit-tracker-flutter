# 🏃‍♂️ Habit Tracker Flutter

> A Strava-inspired, offline-first habit tracking app built with Flutter and Riverpod, following SOLID principles. 

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [SOLID Principles](#-solid-principles)
- [Project Structure](#-project-structure)
- [Provider Architecture](#-provider-architecture)
- [Database Schema](#-database-schema)
- [Implementation Phases](#-implementation-phases)
- [Testing Strategy](#-testing-strategy)
- [Success Metrics](#-success-metrics)
- [Setup Instructions](#-setup-instructions)
- [Known Issues & Limitations](#-known-issues--limitations)
- [Future Enhancements](#-future-enhancements)

---

## 🎯 Overview

Build and track daily habits with a Strava-like mobile experience featuring activity feeds, streaks, personal records, visual calendars, achievements, and motivational insights.  All data is stored locally using Drift (SQLite) for complete offline functionality and privacy.

### Strava-Inspired Design

| Strava Feature | Habit Tracker Equivalent |
|----------------|-------------------------|
| Activity Feed | Daily habit completion feed |
| Kudos | Self-celebration animations |
| Segments & PRs | Personal Records (longest streaks) |
| Weekly Stats | Weekly/Monthly consistency reports |
| Training Calendar | Habit heatmap calendar |
| Achievements | Milestone badges (7, 30, 100-day) |
| Athlete Stats | Completion rates & consistency scores |

---

## ✨ Features

### FR-01: Habit Management
- ✅ Create custom habits (name, description, icon)
- ✅ Set frequency (Every Day, Weekdays, Custom days)
- ✅ Assign categories (Health, Productivity, Fitness, Mindfulness, Learning)
- ✅ Set habit target (days to complete)
- ✅ Archive or delete habits
- ✅ Reorder habits via drag and drop

### FR-02: Daily Tracking
- ✅ Mark habits as complete/incomplete for today
- ✅ Add notes to daily completions
- ✅ View today's habits list filtered by frequency
- ✅ Quick toggle completion status with haptic feedback
- ✅ Bulk complete multiple habits
- ✅ View and modify past completions

### FR-03: Streaks and Progress
- ✅ Current streak counter per habit with flame animation
- ✅ Longest streak record (Personal Record)
- ✅ Streak freeze (1-day grace period option)
- ✅ Monthly calendar heatmap view
- ✅ Overall completion percentage
- ✅ Weekly consistency view

### FR-04: Motivation and Insights
- ✅ Completion rate by habit (percentage)
- ✅ Best performing habits (highest streaks)
- ✅ Consistency score (7-day, 30-day)
- ✅ Weekly/monthly summary reports
- ✅ Achievement milestones (3-day, 7-day, 30-day streaks)
- ✅ PR celebrations when breaking records

### Additional Features
- ✅ Strava-style activity feed
- ✅ Dark/Light theme support
- ✅ Data export (JSON/CSV)
- ✅ Local notifications for reminders
- ✅ Mobile-optimized UI with smooth animations

---

## 📱 Screenshots

| Home | Calendar | Insights | Achievements |
|------|----------|----------|--------------|
| Today's habits with streaks | Monthly heatmap | Stats dashboard | Trophy case |

---

## 🛠 Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.x |
| State Management | Riverpod 2.x with Code Generation |
| Local Database | Drift (SQLite) |
| Local Storage | SharedPreferences |
| Code Generation | Freezed, JSON Serializable, Riverpod Generator |
| Notifications | flutter_local_notifications |
| Charts | fl_chart |
| Calendar | table_calendar |
| Testing | flutter_test, mocktail |
| Linting | very_good_analysis |

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2. 1.0
  path: ^1.8.0
  shared_preferences: ^2.2.0
  uuid: ^4.0.0
  intl: ^0. 18.0
  table_calendar: ^3.0.9
  fl_chart: ^0.65.0
  flutter_local_notifications: ^16.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.0
  freezed: ^2. 4.0
  json_serializable: ^6. 7.0
  drift_dev: ^2.14.0
  mocktail: ^1.0.0
  very_good_analysis: ^5.0.0
```

---

## 🏛 Architecture

The app follows **Clean Architecture** with three distinct layers:

```
┌─────────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                     │
│  ┌───────────┐  ┌───────────┐  ┌─────────────────────┐  │
│  │  Screens  │  │  Widgets  │  │  Providers (State)  │  │
│  └───────────┘  └───────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────┤
│                    DOMAIN LAYER                         │
│  ┌───────────┐  ┌───────────┐  ┌─────────────────────┐  │
│  │ Entities  │  │ Use Cases │  │ Repository Contracts│  │
│  └───────────┘  └───────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────┤
│                     DATA LAYER                          │
│  ┌───────────┐  ┌─────────────┐  ┌─────────────────┐    │
│  │  Models   │  │ Repositories │  │  Data Sources  │    │
│  └───────────┘  └─────────────┘  └─────────────────┘    │
├─────────────────────────────────────────────────────────┤
│                       CORE                              │
│  ┌──────────┐  ┌────────┐  ┌───────┐  ┌───────────┐     │
│  │ Database │  │ Theme  │  │ Utils │  │ Constants │     │
│  └──────────┘  └────────┘  └───────┘  └───────────┘     │
└─────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

| Layer | Responsibility |
|-------|----------------|
| **Presentation** | UI components, Riverpod providers, user interactions |
| **Domain** | Business logic, entities, use cases, repository contracts |
| **Data** | Data models, repository implementations, local data sources |
| **Core** | Database setup, theme, utilities, constants |

---

## 📐 SOLID Principles

### Single Responsibility Principle (SRP)

Each class has one specific responsibility:

| Class | Responsibility |
|-------|----------------|
| `HabitsNotifier` | Habit CRUD state management only |
| `CompletionsNotifier` | Completion state management only |
| `StreakCalculator` | Streak calculation logic only |
| `InsightsCalculator` | Analytics computation only |
| `AchievementService` | Achievement unlocking logic only |
| `CalendarService` | Calendar data generation only |
| `HabitRepository` | Habit data persistence only |
| `CompletionRepository` | Completion data persistence only |

### Open/Closed Principle (OCP)

Extensible via Strategy Pattern:

| Component | Extension Point |
|-----------|-----------------|
| `FrequencyStrategy` | Add new frequencies (Daily, Weekdays, Custom) without modifying existing code |
| `AchievementDefinition` | Add new achievement types without changing service |
| `HabitCategory` | Add new categories via enum |
| `ExportFormat` | Add new export formats via strategy |

### Liskov Substitution Principle (LSP)

All implementations can substitute their interfaces:

| Interface | Implementations |
|-----------|-----------------|
| `IHabitRepository` | `SqliteHabitRepository`, `InMemoryHabitRepository` |
| `ICompletionRepository` | `SqliteCompletionRepository`, `InMemoryCompletionRepository` |
| `IStreakCalculator` | `StreakCalculatorImpl`, `MockStreakCalculator` |
| `FrequencyStrategy` | `DailyFrequency`, `WeekdaysFrequency`, `CustomFrequency` |

### Interface Segregation Principle (ISP)

Focused interfaces for each concern:

| Interface | Purpose |
|-----------|---------|
| `IHabitRepository` | Habit CRUD operations |
| `ICompletionRepository` | Completion CRUD operations |
| `IStreakCalculator` | Streak computation |
| `IInsightsCalculator` | Analytics computation |
| `ICalendarService` | Calendar data generation |
| `IAchievementService` | Achievement management |

### Dependency Inversion Principle (DIP)

High-level modules depend on abstractions:

| Provider | Depends On |
|----------|------------|
| `habitsNotifierProvider` | `IHabitRepository` |
| `completionsProvider` | `ICompletionRepository` |
| `streakCalculatorProvider` | `IStreakCalculator` |
| `habitInsightsProvider` | `IInsightsCalculator` |
| `achievementsProvider` | `IAchievementService` |

---

## 📁 Project Structure

```
lib/
├── main.dart
├── app. dart
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── storage_keys.dart
│   │   └── achievement_definitions.dart
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── app_database. g.dart
│   │   ├── tables/
│   │   │   ├── habits_table.dart
│   │   │   ├── completions_table.dart
│   │   │   └── achievements_table.dart
│   │   └── daos/
│   │       ├── habits_dao.dart
│   │       ├── completions_dao.dart
│   │       └── achievements_dao.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── strava_colors.dart
│   │   └── app_typography.dart
│   ├── extensions/
│   │   ├── date_extensions.dart
│   │   └── context_extensions.dart
│   └── utils/
│       ├── date_utils.dart
│       └── id_generator.dart
│
├── features/
│   ├── habits/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── habit_model.dart
│   │   │   │   ├── habit_frequency.dart
│   │   │   │   └── habit_category.dart
│   │   │   ├── datasources/
│   │   │   │   └── habit_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── habit_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── habit. dart
│   │   │   ├── repositories/
│   │   │   │   └── i_habit_repository. dart
│   │   │   └── usecases/
│   │   │       ├── create_habit.dart
│   │   │       ├── update_habit.dart
│   │   │       ├── delete_habit.dart
│   │   │       └── archive_habit.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── habits_provider.dart
│   │       │   └── habits_provider. g.dart
│   │       ├── screens/
│   │       │   ├── habits_home_screen.dart
│   │       │   ├── habit_detail_screen. dart
│   │       │   └── create_habit_screen. dart
│   │       └── widgets/
│   │           ├── habit_card.dart
│   │           ├── habit_checkbox.dart
│   │           ├── frequency_selector.dart
│   │           └── category_chip.dart
│   │
│   ├── completions/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── completion_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── completion_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── completion_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── completion.dart
│   │   │   ├── repositories/
│   │   │   │   └── i_completion_repository.dart
│   │   │   └── usecases/
│   │   │       ├── toggle_completion.dart
│   │   │       ├── add_completion_note.dart
│   │   │       └── bulk_complete. dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── completions_provider.dart
│   │       │   ├── todays_habits_provider.dart
│   │       │   └── completion_check_provider.dart
│   │       └── widgets/
│   │           ├── completion_toggle. dart
│   │           ├── completion_animation.dart
│   │           └── bulk_complete_button. dart
│   │
│   ├── streaks/
│   │   ├── data/
│   │   │   └── models/
│   │   │       ├── streak_data_model.dart
│   │   │       └── personal_record_model.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── streak_data.dart
│   │   │   │   └── personal_record.dart
│   │   │   └── services/
│   │   │       ├── i_streak_calculator.dart
│   │   │       └── streak_calculator. dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── streak_provider.dart
│   │       │   └── personal_records_provider. dart
│   │       └── widgets/
│   │           ├── streak_flame_badge.dart
│   │           ├── streak_counter.dart
│   │           └── pr_celebration.dart
│   │
│   ├── calendar/
│   │   ├── data/
│   │   │   └── models/
│   │   │       └── calendar_day_model.dart
│   │   ├── domain/
│   │   │   └── services/
│   │   │       ├── i_calendar_service. dart
│   │   │       └── calendar_service.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── calendar_provider.dart
│   │       │   ├── selected_month_provider.dart
│   │       │   └── heatmap_data_provider.dart
│   │       ├── screens/
│   │       │   └── calendar_screen.dart
│   │       └── widgets/
│   │           ├── strava_heatmap.dart
│   │           ├── calendar_day_cell.dart
│   │           └── month_navigation. dart
│   │
│   ├── insights/
│   │   ├── data/
│   │   │   └── models/
│   │   │       ├── insights_model.dart
│   │   │       └── weekly_stats_model.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── habit_insights.dart
│   │   │   │   └── weekly_summary.dart
│   │   │   └── services/
│   │   │       ├── i_insights_calculator.dart
│   │   │       └── insights_calculator.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── insights_provider.dart
│   │       │   ├── weekly_stats_provider.dart
│   │       │   └── best_habits_provider. dart
│   │       ├── screens/
│   │       │   ├── insights_screen.dart
│   │       │   └── weekly_report_screen.dart
│   │       └── widgets/
│   │           ├── stats_card.dart
│   │           ├── consistency_ring.dart
│   │           └── weekly_bar_chart.dart
│   │
│   ├── achievements/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── achievement_model.dart
│   │   │   └── datasources/
│   │   │       └── achievement_local_datasource. dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── achievement.dart
│   │   │   └── services/
│   │   │       ├── i_achievement_service.dart
│   │   │       └── achievement_service.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── achievements_provider.dart
│   │       │   └── achievement_progress_provider.dart
│   │       ├── screens/
│   │       │   └── achievements_screen.dart
│   │       └── widgets/
│   │           ├── achievement_badge.dart
│   │           ├── achievement_modal.dart
│   │           └── trophy_case.dart
│   │
│   ├── feed/
│   │   ├── data/
│   │   │   └── models/
│   │   │       └── feed_item_model.dart
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── feed_item.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── activity_feed_provider. dart
│   │       ├── screens/
│   │       │   └── activity_feed_screen.dart
│   │       └── widgets/
│   │           ├── feed_item_card.dart
│   │           ├── feed_date_header.dart
│   │           └── kudos_button.dart
│   │
│   ├── settings/
│   │   ├── data/
│   │   │   └── models/
│   │   │       └── user_preferences_model.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── settings_provider.dart
│   │       │   └── theme_provider.dart
│   │       ├── screens/
│   │       │   └── settings_screen.dart
│   │       └── widgets/
│   │           ├── settings_tile.dart
│   │           └── export_button.dart
│   │
│   └── shared/
│       ├── providers/
│       │   ├── selected_date_provider.dart
│       │   └── database_provider.dart
│       └── widgets/
│           ├── strava_app_bar.dart
│           ├── strava_bottom_nav. dart
│           ├── loading_shimmer.dart
│           ├── empty_state.dart
│           └── error_widget.dart
│
├── mock/
│   ├── mock_habits.dart
│   └── mock_completions.dart
│
└── services/
    ├── notification_service.dart
    └── export_service.dart
```

---

## 🔄 Provider Architecture

### Provider Dependency Diagram

```
┌────────────────────────────────────────────────────────────────────────────┐
│                           STATE PROVIDERS                                   │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌────────────────────────┐       ┌────────────────────────────────────┐   │
│  │  selectedDateProvider  │       │      habitsNotifierProvider        │   │
│  │  StateProvider         │       │  StateNotifierProvider             │   │
│  │  <DateTime>            │       │  <HabitsNotifier, HabitState>      │   │
│  └───────────┬────────────┘       └─────────────────┬──────────────────┘   │
│              │                                       │                      │
│              │         ┌─────────────────────────────┤                      │
│              │         │                             │                      │
│              ▼         ▼                             ▼                      │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                      completionsProvider                            │    │
│  │       StateNotifierProvider<Map<String, Set<DateTime>>>            │    │
│  └─────────────────────────────────┬──────────────────────────────────┘    │
│                                     │                                       │
│      ┌──────────────┬───────────────┼───────────────┬──────────────┐       │
│      │              │               │               │              │        │
│      ▼              ▼               ▼               ▼              ▼        │
│ ┌──────────┐ ┌────────────┐ ┌─────────────┐ ┌───────────┐ ┌────────────┐   │
│ │ todays   │ │ habit      │ │ streak      │ │ calendar  │ │ habit      │   │
│ │ Habits   │ │ Completion │ │ Calculator  │ │ Data      │ │ Insights   │   │
│ │ Provider │ │ Provider   │ │ Provider    │ │ Provider  │ │ Provider   │   │
│ │          │ │ (. family)  │ │ (.family)   │ │ (.family) │ │            │   │
│ │ Provider │ │ Provider   │ │ Provider    │ │ Provider  │ │ Provider   │   │
│ │ <List    │ │ <bool,     │ │ <StreakData,│ │ <Map,     │ │ <Habit     │   │
│ │ <Habit>> │ │ (id,date)> │ │ String>     │ │ String>   │ │ Insights>  │   │
│ └──────────┘ └────────────┘ └──────┬──────┘ └───────────┘ └────────────┘   │
│                                     │                                       │
│                    ┌────────────────┴────────────────┐                     │
│                    │                                 │                      │
│                    ▼                                 ▼                      │
│         ┌───────────────────┐            ┌─────────────────────┐           │
│         │  achievements     │            │  weeklyConsistency  │           │
│         │  Provider         │            │  Provider           │           │
│         │  Provider         │            │  Provider           │           │
│         │  <List            │            │  <Map<String,       │           │
│         │  <Achievement>>   │            │  double>>           │           │
│         └───────────────────┘            └─────────────────────┘           │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

### Required Providers (TR-01)

| Provider | Type | Purpose |
|----------|------|---------|
| `habitsNotifierProvider` | StateNotifierProvider<HabitsNotifier, HabitState> | Habit CRUD operations |
| `completionsProvider` | StateNotifierProvider<Map<String, Set<DateTime>>> | Completion tracking (habitId → dates) |
| `selectedDateProvider` | StateProvider<DateTime> | Currently selected date |
| `todaysHabitsProvider` | Provider<List<Habit>> | Computed: today's scheduled habits |
| `habitCompletionProvider` | Provider. family<bool, (String, DateTime)> | Check if habit completed on date |
| `streakCalculatorProvider` | Provider.family<StreakData, String> | Calculate streak per habit |
| `calendarDataProvider` | Provider. family<Map<DateTime, int>, String> | Monthly calendar data |
| `habitInsightsProvider` | Provider<HabitInsights> | Computed analytics |
| `achievementsProvider` | Provider<List<Achievement>> | Computed achievements |
| `weeklyConsistencyProvider` | Provider<Map<String, double>> | Weekly consistency per habit |

### Provider Performance Considerations

| Optimization | Implementation |
|--------------|----------------|
| AutoDispose | Used on screen-specific providers to free memory |
| . family | Used for per-habit/per-date computations |
| select() | Used to watch specific state slices |
| Caching | Streak and calendar calculations cached |
| Debouncing | Bulk operations debounced for performance |

---

## 🗄 Database Schema

### Tables

#### habits
| Column | Type | Description |
|--------|------|-------------|
| id | TEXT (PK) | UUID |
| name | TEXT | Habit name |
| description | TEXT | Optional description |
| icon | TEXT | Icon identifier |
| color | TEXT | Hex color |
| frequency_type | TEXT | daily/weekdays/custom |
| frequency_days | TEXT | JSON array for custom |
| category | TEXT | Category enum |
| target_days | INTEGER | Goal days |
| has_grace_period | INTEGER | Boolean |
| is_archived | INTEGER | Boolean |
| sort_order | INTEGER | Display order |
| created_at | INTEGER | Timestamp |
| updated_at | INTEGER | Timestamp |

#### completions
| Column | Type | Description |
|--------|------|-------------|
| id | TEXT (PK) | UUID |
| habit_id | TEXT (FK) | Habit reference |
| completed_date | INTEGER | Date (midnight) |
| note | TEXT | Optional note |
| created_at | INTEGER | Timestamp |

#### achievements
| Column | Type | Description |
|--------|------|-------------|
| id | TEXT (PK) | Achievement ID |
| habit_id | TEXT (FK) | Habit reference |
| unlocked_at | INTEGER | Unlock timestamp |

### Indexes

```sql
CREATE INDEX idx_completions_habit ON completions(habit_id);
CREATE INDEX idx_completions_date ON completions(completed_date);
CREATE INDEX idx_completions_habit_date ON completions(habit_id, completed_date);
CREATE INDEX idx_achievements_habit ON achievements(habit_id);
```

---

## 📅 Implementation Phases

### Phase 1: Project Setup & Core Infrastructure

| Task | Description |
|------|-------------|
| 1.1 | Initialize Flutter project with folder structure |
| 1.2 | Configure pubspec.yaml with all dependencies |
| 1.3 | Set up Drift database with tables and DAOs |
| 1.4 | Create Strava-inspired theme system |
| 1.5 | Set up Riverpod with ProviderScope |
| 1.6 | Configure build_runner for code generation |
| 1.7 | Set up very_good_analysis linting |
| 1.8 | Create core utilities and date extensions |

**Deliverables:** Working project skeleton, database, theme

---

### Phase 2: Habit Management

| Task | Description |
|------|-------------|
| 2.1 | Create Habit entity and model with Freezed |
| 2.2 | Implement FrequencyStrategy pattern |
| 2.3 | Create HabitCategory enum |
| 2. 4 | Implement IHabitRepository interface |
| 2.5 | Implement SqliteHabitRepository |
| 2.6 | Create habit use cases |
| 2. 7 | Implement HabitsNotifier provider |
| 2.8 | Build Create Habit screen (mobile-optimized) |
| 2.9 | Build Habit List screen with cards |
| 2.10 | Build Habit Detail screen |

**Deliverables:** Full habit CRUD, mobile-friendly screens

---

### Phase 3: Completion Tracking

| Task | Description |
|------|-------------|
| 3. 1 | Create Completion entity and model |
| 3. 2 | Implement ICompletionRepository |
| 3. 3 | Implement SqliteCompletionRepository |
| 3.4 | Create completion use cases |
| 3.5 | Implement completionsProvider |
| 3.6 | Create todaysHabitsProvider (computed) |
| 3.7 | Create habitCompletionProvider (. family) |
| 3.8 | Build completion toggle with haptic feedback |
| 3.9 | Build Today view with checkboxes |
| 3.10 | Implement bulk complete feature |

**Deliverables:** Working completion tracking, Today view

---

### Phase 4: Streak Calculation (TR-02)

| Task | Description |
|------|-------------|
| 4. 1 | Create StreakData entity |
| 4. 2 | Create PersonalRecord entity |
| 4.3 | Implement IStreakCalculator interface |
| 4.4 | Implement streak algorithm with frequency awareness |
| 4.5 | Handle grace period (streak freeze) logic |
| 4.6 | Handle timezone consistency |
| 4.7 | Create streakCalculatorProvider (. family) |
| 4.8 | Build streak flame badge widget |
| 4.9 | Build PR celebration animation |
| 4.10 | Write comprehensive streak unit tests |

**Deliverables:** Accurate streak calculation, 100% test coverage

---

### Phase 5: Calendar & Heatmap (TR-03)

| Task | Description |
|------|-------------|
| 5.1 | Create CalendarDayData model |
| 5.2 | Implement ICalendarService interface |
| 5. 3 | Implement CalendarService with efficient queries |
| 5.4 | Generate monthly calendar matrix |
| 5.5 | Handle different habit frequencies |
| 5.6 | Create calendarDataProvider (.family) |
| 5.7 | Build Strava-style heatmap widget |
| 5. 8 | Build month navigation |
| 5. 9 | Build calendar screen (mobile-optimized) |
| 5.10 | Calculate completion percentage per month |

**Deliverables:** Monthly heatmap calendar, efficient rendering

---

### Phase 6: Activity Feed

| Task | Description |
|------|-------------|
| 6.1 | Create FeedItem entity |
| 6.2 | Create activityFeedProvider |
| 6. 3 | Build Strava-style activity card |
| 6.4 | Build date group headers |
| 6.5 | Build kudos self-celebration button |
| 6.6 | Build activity feed screen |
| 6.7 | Implement pull-to-refresh |
| 6. 8 | Implement filter by habit/category |

**Deliverables:** Chronological activity feed, Strava-style UI

---

### Phase 7: Insights & Analytics

| Task | Description |
|------|-------------|
| 7. 1 | Create HabitInsights entity |
| 7.2 | Create WeeklySummary entity |
| 7. 3 | Implement IInsightsCalculator |
| 7. 4 | Calculate completion rates |
| 7.5 | Calculate consistency scores (7/30 day) |
| 7.6 | Calculate best performing habits |
| 7.7 | Create habitInsightsProvider |
| 7. 8 | Create weeklyConsistencyProvider |
| 7.9 | Build stats cards (mobile-optimized) |
| 7.10 | Build consistency ring widget |
| 7.11 | Build weekly bar chart |
| 7.12 | Build insights dashboard screen |

**Deliverables:** Full analytics, insights dashboard

---

### Phase 8: Achievements System

| Task | Description |
|------|-------------|
| 8.1 | Create Achievement entity |
| 8.2 | Define achievement types (3, 7, 30-day streaks) |
| 8.3 | Implement IAchievementService |
| 8. 4 | Create achievementsProvider |
| 8.5 | Build achievement badge widget |
| 8.6 | Build achievement unlock modal |
| 8.7 | Build trophy case display |
| 8.8 | Build achievements screen |

**Deliverables:** Full achievement system, celebrations

---

### Phase 9: Settings & Polish

| Task | Description |
|------|-------------|
| 9.1 | Create UserPreferences model |
| 9.2 | Implement preferences data source |
| 9.3 | Create themeProvider with persistence |
| 9.4 | Build settings screen |
| 9. 5 | Implement dark/light theme toggle |
| 9.6 | Implement notification reminders |
| 9.7 | Implement data export (JSON/CSV) |
| 9.8 | Add haptic feedback throughout |
| 9.9 | Polish all animations |
| 9. 10 | Add empty states and error handling |

**Deliverables:** Settings, theme switching, export

---

### Phase 10: Mock Data & Testing (TR-04)

| Task | Description |
|------|-------------|
| 10.1 | Create 5-10 sample habits with different frequencies |
| 10.2 | Generate 60 days of historical completion data |
| 10.3 | Create various streak scenarios |
| 10. 4 | Write unit tests for StreakCalculator |
| 10. 5 | Write unit tests for InsightsCalculator |
| 10. 6 | Write unit tests for CalendarService |
| 10.7 | Write provider tests |
| 10.8 | Write widget tests for core widgets |
| 10.9 | Write integration tests for main flows |
| 10.10 | Generate test coverage report (≥70%) |

**Deliverables:** Mock data, comprehensive tests

---

### Phase 11: Documentation & Demo

| Task | Description |
|------|-------------|
| 11.1 | Write README with setup instructions |
| 11.2 | Create architecture diagram |
| 11.3 | Document provider dependencies |
| 11.4 | Document known issues |
| 11. 5 | Record 2-3 minute demo video |

**Deliverables:** Complete documentation, demo video

---

## 🧪 Testing Strategy

### Unit Tests

| Component | Coverage Target |
|-----------|-----------------|
| StreakCalculator | 100% |
| InsightsCalculator | 100% |
| AchievementService | 100% |
| CalendarService | 95% |
| FrequencyStrategy | 100% |
| Date utilities | 95% |
| Repositories | 90% |

### Provider Tests

| Provider | Test Cases |
|----------|------------|
| habitsNotifierProvider | CRUD, error states |
| completionsProvider | Toggle, bulk, filtering |
| streakCalculatorProvider | All streak scenarios |
| habitInsightsProvider | Correct computation |
| achievementsProvider | Unlock detection |

### Widget Tests

| Widget | Test Cases |
|--------|------------|
| HabitCard | Renders, tap handlers |
| StreakFlameBadge | Count, animation |
| CalendarHeatmap | Month render, intensity |
| AchievementBadge | Locked/unlocked states |

### Integration Tests

| Flow | Scenarios |
|------|-----------|
| Habit Creation | Create → appears → can complete |
| Completion | Toggle → streak updates → feed updates |
| Streak | Multiple days → correct calculation → PR |
| Achievement | Milestone → unlock → modal shows |

### Edge Cases

| Category | Test Case |
|----------|-----------|
| Timezone | Timezone changes |
| Dates | DST transitions |
| Dates | Leap years |
| Streaks | Habit created today |
| Streaks | Grace period edge cases |
| Streaks | Custom frequency gaps |
| Calendar | Month boundaries |
| Performance | 1000+ completions |

---

## ✅ Success Metrics

### Evaluation Rubric (100 points)

| Criteria | Points | Target |
|----------|--------|--------|
| Streak algorithm accuracy | 30 pts | 100% accurate |
| Calendar state generation | 20 pts | Efficient rendering |
| State computation efficiency | 20 pts | No unnecessary rebuilds |
| Insights accuracy | 15 pts | Correct calculations |
| Provider performance | 10 pts | AutoDispose, select() |
| Edge case handling | 5 pts | All cases covered |

### Functional Metrics

| Metric | Target |
|--------|--------|
| Streak calculation accuracy | 100% |
| Calendar data correctness | 100% |
| Insights computation accuracy | 100% |
| Achievement unlock accuracy | 100% |
| Completion toggle reliability | 100% |
| Grace period logic | 100% |
| Different frequencies handled | 100% |

### Performance Metrics

| Metric | Target |
|--------|--------|
| App startup time | < 2 seconds |
| Habit list load | < 100ms |
| Streak calculation | < 50ms |
| Calendar render | < 100ms |
| Toggle response | < 16ms (60fps) |
| No date calculation issues | ✓ |

### Quality Metrics

| Metric | Target |
|--------|--------|
| Test coverage | ≥ 70% |
| Critical path coverage | 100% |
| Linting errors | 0 |
| Documentation | All public APIs |

---

## 🚀 Setup Instructions

### Prerequisites

- Flutter SDK 3. x
- Dart SDK 3.x
- Android Studio / VS Code
- iOS Simulator / Android Emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/andreswooshik/habit-tracker-flutter.git
   cd habit-tracker-flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov. info -o coverage/html
open coverage/html/index.html
```

---

## ⚠️ Known Issues & Limitations

| Limitation | Reason | Workaround |
|------------|--------|------------|
| No cloud sync | Offline-first MVP | Manual export/import |
| Single timezone | Simplicity | Dates normalized to local |
| No habit sharing | MVP scope | Screenshot achievements |
| No web notifications | Platform limitation | Use mobile |

---

## 🔮 Future Enhancements

### Version 2.0
- Cloud sync with encryption
- Home screen widgets
- Apple Watch / Wear OS support
- Voice commands integration
- Social features and sharing

### Version 3.0
- Habit challenges
- Habit groups/routines
- AI-powered recommendations
- Leaderboards
- Public profiles

---

## 📄 License

MIT License - see LICENSE file for details. 

---

**Built with ❤️ using Flutter and Riverpod**
