# Phase 8: Analytics & Insights Screen - Implementation Plan

**Branch:** `feature/phase8-analytics-insights`  
**Status:** 🚧 In Progress  
**Priority:** 🟡 Medium  
**Estimated Effort:** 500 lines + 150 lines tests

## 📋 Overview

Create a comprehensive Analytics & Insights screen that provides users with deep insights into their habit performance, trends, and patterns. This screen will leverage existing providers (`habitInsightsProvider`, `calendarDataProvider`) to deliver meaningful analytics.

## 🎯 Goals

1. **Data Visualization:** Present complex analytics in easy-to-understand charts
2. **Actionable Insights:** Provide recommendations based on patterns
3. **Performance Analysis:** Show trends and comparisons over time
4. **User Engagement:** Motivate users with success metrics and achievements

## 🏗️ Architecture

### File Structure
```
lib/
├── screens/
│   └── analytics_screen.dart              (Main analytics screen)
├── widgets/
│   └── analytics/
│       ├── time_range_selector.dart       (Week/Month/Year tabs)
│       ├── completion_rate_chart.dart     (Line chart with trends)
│       ├── category_performance_card.dart (Category analysis)
│       ├── streak_analytics_card.dart     (Streak leaderboard)
│       ├── correlation_matrix.dart        (Habit correlations)
│       └── best_days_analysis.dart        (Weekday performance)
├── providers/
│   └── analytics_providers.dart           (Time range, aggregations)
└── utils/
    └── analytics_helpers.dart             (Data aggregation utilities)

test/
├── screens/
│   └── analytics_screen_test.dart
├── widgets/
│   └── analytics/
│       └── [widget tests]
└── providers/
    └── analytics_providers_test.dart
```

## 📊 Components Breakdown

### 1. Time Range Selector
**Widget:** `TimeRangeSelector`  
**Responsibility:** Allow users to select data timeframe

**Features:**
- Tab bar: Week / Month / Year / All Time
- Custom date range picker (modal bottom sheet)
- Preset quick selectors (Last 7 days, Last 30 days, This month)
- Smooth tab indicator animation

**Provider:**
```dart
final selectedTimeRangeProvider = StateProvider<TimeRange>((ref) => TimeRange.month);

enum TimeRange { week, month, year, allTime, custom }

class CustomDateRange {
  final DateTime start;
  final DateTime end;
}
```

**SOLID Compliance:**
- Single Responsibility: Only handles time range selection
- Open/Closed: Can add new time ranges without modifying existing code

---

### 2. Completion Rate Chart
**Widget:** `CompletionRateChart`  
**Responsibility:** Visualize completion trends over time

**Features:**
- Line chart showing daily/weekly completion rate
- Comparison line for previous period (dotted)
- Average benchmark line (horizontal dashed)
- Touch interaction to see exact values
- Highlight best/worst periods with colored zones
- Trend indicator (↑/↓ X% vs previous period)

**Data Source:**
- Uses `habitInsightsProvider` for current period
- Calculates previous period for comparison
- Aggregates data based on selected time range

**Chart Library:** `fl_chart`
```dart
final completionTrendProvider = Provider.family<List<FlSpot>, TimeRange>((ref, range) {
  // Aggregate completion data for the time range
  // Return list of data points for chart
});
```

**SOLID Compliance:**
- Dependency Inversion: Depends on provider abstraction
- Single Responsibility: Only displays completion trends

---

### 3. Category Performance Analysis
**Widget:** `CategoryPerformanceCard`  
**Responsibility:** Show which categories perform best/worst

**Features:**
- Best performing category (🏆 badge)
- Needs improvement category (⚠️ indicator)
- Horizontal bar chart comparing all categories
- Tap category to see detailed breakdown
- Completion rate percentage per category

**Data Structure:**
```dart
class CategoryPerformance {
  final HabitCategory category;
  final int totalHabits;
  final int completions;
  final double completionRate;
  final int streak;
}

final categoryPerformanceProvider = Provider.family<List<CategoryPerformance>, TimeRange>(
  (ref, range) {
    // Aggregate by category
  }
);
```

**Design:**
- Material 3 Card with elevation
- Color-coded bars matching category colors
- Sorted by completion rate (descending)

---

### 4. Streak Analytics
**Widget:** `StreakAnalyticsCard`  
**Responsibility:** Display streak leaderboard and statistics

**Features:**
- Top 5 current active streaks (leaderboard)
- Longest streak ever badge (all habits)
- Streak distribution histogram (how many habits at each streak level)
- Milestone timeline (7-day, 30-day, 100-day achievements)
- Flame icons with color intensity based on streak length

**Data Source:**
```dart
final streakLeaderboardProvider = Provider<List<HabitStreak>>((ref) {
  final allStreaks = ref.watch(allStreaksProvider);
  // Sort by current streak, return top 5
});

class HabitStreak {
  final String habitId;
  final String habitName;
  final int currentStreak;
  final int longestStreak;
  final HabitCategory category;
}
```

**Visual Elements:**
- Podium-style layout for top 3
- Animated flame icons (💪→🔥→⚡→🏆)
- Progress bars for each streak

---

### 5. Habit Correlation Matrix
**Widget:** `CorrelationMatrix`  
**Responsibility:** Show which habits are completed together

**Features:**
- Heatmap-style grid showing correlation strength
- Color intensity: Low (light) → High (dark)
- Tap cell to see correlation details
- Success pattern discovery
- Habit dependency suggestions ("When you complete X, you're Y% more likely to complete Z")

**Algorithm:**
```dart
class HabitCorrelation {
  final String habitId1;
  final String habitId2;
  final double correlationScore; // 0.0 to 1.0
  final int coCompletions; // Days both completed
}

double calculateCorrelation(Set<DateTime> completions1, Set<DateTime> completions2) {
  final intersection = completions1.intersection(completions2).length;
  final union = completions1.union(completions2).length;
  return union > 0 ? intersection / union : 0.0;
}

final habitCorrelationsProvider = Provider<List<HabitCorrelation>>((ref) {
  // Calculate correlations for all habit pairs
});
```

**Design:**
- Grid layout with habit names on axes
- Tap for detailed modal
- Only show for users with 3+ habits

---

### 6. Best Days Analysis
**Widget:** `BestDaysAnalysis`  
**Responsibility:** Identify which days perform best

**Features:**
- Bar chart showing completion rate by weekday (Mon-Sun)
- Best day indicator (crown icon 👑)
- Worst day indicator (needs improvement 💡)
- Monthly pattern detection (e.g., "You perform better in the first half of the month")
- Recommendations based on patterns
- Time-of-completion analysis (if data available)

**Data Source:**
```dart
class DayPerformance {
  final int weekday; // 1=Mon, 7=Sun
  final double completionRate;
  final int totalScheduled;
  final int totalCompleted;
}

final weekdayPerformanceProvider = Provider.family<List<DayPerformance>, TimeRange>(
  (ref, range) {
    // Aggregate completions by weekday
  }
);
```

**Insights Generation:**
```dart
String generateRecommendation(List<DayPerformance> performance) {
  final best = performance.reduce((a, b) => a.completionRate > b.completionRate ? a : b);
  final worst = performance.reduce((a, b) => a.completionRate < b.completionRate ? a : b);
  
  return "You're most consistent on ${getDayName(best.weekday)}. "
         "Consider scheduling important habits on that day!";
}
```

---

## 🎨 UI/UX Design

### Screen Layout
```
┌─────────────────────────────────┐
│ ← Analytics                  ⋮  │ (App Bar with menu)
├─────────────────────────────────┤
│ [Week][Month][Year][All Time]   │ (Time Range Tabs)
├─────────────────────────────────┤
│                                 │
│  📈 Completion Rate Trend       │
│  [Line Chart]                   │
│  ↑ 12% vs last month            │
│                                 │
├─────────────────────────────────┤
│  🏆 Category Performance        │
│  Health  ████████░ 85%          │
│  Fitness ██████░░░ 67%          │
│  ...                            │
├─────────────────────────────────┤
│  🔥 Active Streaks              │
│  1. Morning Run - 45 days       │
│  2. Meditation - 32 days        │
│  ...                            │
├─────────────────────────────────┤
│  🔗 Habit Correlations          │
│  [Heatmap Grid]                 │
│                                 │
├─────────────────────────────────┤
│  📅 Best Days Analysis          │
│  Monday    ████████░ 82%        │
│  Tuesday   ██████░░░ 65%        │
│  ...                            │
│  💡 Tip: [Recommendation]       │
└─────────────────────────────────┘
```

### Color Scheme
- Success/High: Colors.green (>70% completion)
- Warning/Medium: Colors.orange (40-70% completion)
- Alert/Low: Colors.red (<40% completion)
- Neutral: Colors.grey (no data)

### Animations
- Chart entry animations (stagger from left to right)
- Tab transition (smooth slide)
- Card reveal (fade in + slide up)
- Pull-to-refresh for data reload

---

## 🔧 Technical Implementation

### Providers Architecture

```dart
// analytics_providers.dart

// 1. Time Range Selection
final selectedTimeRangeProvider = StateProvider<TimeRange>((ref) => TimeRange.month);

final customDateRangeProvider = StateProvider<CustomDateRange?>((ref) => null);

final effectiveDateRangeProvider = Provider<DateRange>((ref) {
  final timeRange = ref.watch(selectedTimeRangeProvider);
  final customRange = ref.watch(customDateRangeProvider);
  
  if (timeRange == TimeRange.custom && customRange != null) {
    return DateRange(start: customRange.start, end: customRange.end);
  }
  
  // Calculate date range based on TimeRange enum
  return calculateDateRange(timeRange);
});

// 2. Aggregated Analytics
final aggregatedAnalyticsProvider = Provider.family<AggregatedAnalytics, DateRange>(
  (ref, dateRange) {
    final habits = ref.watch(habitsProvider).habits;
    final completions = ref.watch(completionsProvider).completions;
    
    return AggregateAnalytics.calculate(habits, completions, dateRange);
  }
);

class AggregatedAnalytics {
  final double overallCompletionRate;
  final List<DayPerformance> weekdayPerformance;
  final List<CategoryPerformance> categoryPerformance;
  final List<HabitStreak> streakLeaderboard;
  final List<HabitCorrelation> correlations;
  final Map<DateTime, double> dailyCompletionRates;
}
```

### Data Aggregation Utilities

```dart
// utils/analytics_helpers.dart

class AnalyticsHelpers {
  static List<FlSpot> generateCompletionTrendData({
    required Map<String, Set<DateTime>> completions,
    required List<Habit> habits,
    required DateRange range,
  }) {
    // Aggregate daily completion rates
    final spots = <FlSpot>[];
    for (var day in range.days) {
      final rate = calculateCompletionRateForDay(day, completions, habits);
      spots.add(FlSpot(day.millisecondsSinceEpoch.toDouble(), rate));
    }
    return spots;
  }
  
  static double calculateCompletionRateForDay(
    DateTime day,
    Map<String, Set<DateTime>> completions,
    List<Habit> habits,
  ) {
    final scheduledCount = habits.where((h) => h.isScheduledFor(day)).length;
    if (scheduledCount == 0) return 0.0;
    
    final completedCount = habits.where((h) {
      final habitCompletions = completions[h.id] ?? {};
      return h.isScheduledFor(day) && habitCompletions.contains(normalizeDate(day));
    }).length;
    
    return completedCount / scheduledCount;
  }
  
  static Map<int, DayPerformance> calculateWeekdayPerformance(
    Map<String, Set<DateTime>> completions,
    List<Habit> habits,
    DateRange range,
  ) {
    // Group by weekday and calculate averages
  }
  
  static List<HabitCorrelation> calculateCorrelations(
    Map<String, Set<DateTime>> completions,
    List<Habit> habits,
  ) {
    // Calculate pairwise correlations
  }
}
```

### Export Functionality

```dart
class AnalyticsExporter {
  static Future<String> exportToCSV(AggregatedAnalytics analytics) async {
    // Generate CSV string
    final csv = StringBuffer();
    csv.writeln('Date,Completion Rate,Category,Streak');
    // ... populate data
    return csv.toString();
  }
  
  static Future<Map<String, dynamic>> exportToJSON(AggregatedAnalytics analytics) async {
    return {
      'overall_completion_rate': analytics.overallCompletionRate,
      'weekday_performance': analytics.weekdayPerformance.map((d) => d.toJson()).toList(),
      // ... more data
    };
  }
  
  static Future<void> shareExport(String data, String format) async {
    // Use share_plus package to share file
  }
}
```

---

## 🧪 Testing Strategy

### Unit Tests
```dart
// test/providers/analytics_providers_test.dart

void main() {
  group('Analytics Providers', () {
    test('effectiveDateRangeProvider returns correct range for month', () {
      final container = ProviderContainer();
      container.read(selectedTimeRangeProvider.notifier).state = TimeRange.month;
      
      final range = container.read(effectiveDateRangeProvider);
      
      expect(range.days.length, equals(30));
    });
    
    test('aggregatedAnalyticsProvider calculates correct completion rate', () {
      // Setup test data
      // Assert calculations
    });
  });
}
```

### Widget Tests
```dart
// test/widgets/analytics/completion_rate_chart_test.dart

void main() {
  testWidgets('CompletionRateChart displays correctly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: CompletionRateChart(),
        ),
      ),
    );
    
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Completion Rate'), findsOneWidget);
  });
}
```

---

## 📦 Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  fl_chart: ^0.69.2  # Already included
  intl: ^0.18.1      # Already included
  share_plus: ^7.2.1 # For export functionality
```

---

## 🎯 Success Criteria

- [ ] All 6 widget components implemented
- [ ] Time range selector functional
- [ ] Charts display real data from providers
- [ ] Export to CSV/JSON works
- [ ] All unit tests passing
- [ ] All widget tests passing
- [ ] Performance optimized (no lag with large datasets)
- [ ] Follows SOLID principles
- [ ] Uses existing AppConstants and AppTheme
- [ ] Responsive design works on all screen sizes
- [ ] Zero linter issues

---

## 📝 Implementation Checklist

### Sprint 1: Foundation (Days 1-2)
- [ ] Create analytics_providers.dart with time range providers
- [ ] Create analytics_helpers.dart with data aggregation utilities
- [ ] Create analytics_screen.dart scaffold
- [ ] Implement TimeRangeSelector widget
- [ ] Write tests for providers and utilities

### Sprint 2: Core Charts (Days 3-4)
- [ ] Implement CompletionRateChart with fl_chart
- [ ] Implement CategoryPerformanceCard
- [ ] Add comparison with previous period
- [ ] Write widget tests

### Sprint 3: Advanced Analytics (Days 5-6)
- [ ] Implement StreakAnalyticsCard
- [ ] Implement CorrelationMatrix
- [ ] Implement BestDaysAnalysis
- [ ] Add insights generation logic

### Sprint 4: Polish & Export (Days 7)
- [ ] Add animations and transitions
- [ ] Implement export functionality
- [ ] Add loading states and error handling
- [ ] Final testing and bug fixes
- [ ] Update documentation

---

## 🚀 Next Steps

1. Start with Sprint 1: Create provider foundation
2. Ensure fl_chart is properly set up
3. Create reusable chart components
4. Follow existing patterns from Phase 6
5. Maintain 85%+ test coverage

---

**Created:** December 20, 2025  
**Branch:** feature/phase8-analytics-insights  
**Estimated Completion:** 7 days
