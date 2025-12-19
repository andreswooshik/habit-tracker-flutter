/// Barrel file for all providers in the habit tracker application
/// 
/// This file exports all providers to simplify imports throughout the app.
/// Instead of importing multiple files, you can import this single file:
/// 
/// ```dart
/// import 'package:habit_tracker_flutter_new/providers/providers.dart';
/// ```
library;

// Core habit management
export 'habits_notifier.dart';

// Completion tracking
export 'completions_notifier.dart';

// Date selection and navigation
export 'selected_date_provider.dart';

// Computed providers (derived state)
export 'computed_providers.dart';

// Calendar visualization providers
export 'calendar_providers.dart';

// Analytics and insights providers
export 'insights_providers.dart';

// Achievements and consistency tracking
export 'achievements_providers.dart';
