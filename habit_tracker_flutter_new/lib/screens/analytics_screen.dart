import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/utils/app_constants.dart';
import 'package:habit_tracker_flutter_new/widgets/analytics/time_range_selector.dart';
import 'package:habit_tracker_flutter_new/widgets/analytics/completion_rate_chart.dart';
import 'package:habit_tracker_flutter_new/widgets/analytics/category_performance_card.dart';
import 'package:habit_tracker_flutter_new/widgets/analytics/streak_analytics_card.dart';
import 'package:habit_tracker_flutter_new/widgets/analytics/best_days_analysis.dart';

/// Analytics & Insights Screen
/// 
/// Displays comprehensive analytics including:
/// - Time range selector
/// - Completion rate trends
/// - Category performance analysis
/// - Streak leaderboard
/// - Best days analysis
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Insights'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time Range Selector
            const TimeRangeSelector(),
            
            SizedBox(height: AppConstants.spacingLarge),
            
            // Completion Rate Chart
            const CompletionRateChart(),
            
            SizedBox(height: AppConstants.spacingLarge),
            
            // Category Performance
            const CategoryPerformanceCard(),
            
            SizedBox(height: AppConstants.spacingLarge),
            
            // Streak Analytics
            const StreakAnalyticsCard(),
            
            SizedBox(height: AppConstants.spacingLarge),
            
            // Best Days Analysis
            const BestDaysAnalysis(),
            
            SizedBox(height: AppConstants.spacingXLarge),
          ],
        ),
      ),
    );
  }
}
