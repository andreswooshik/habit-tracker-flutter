/// Service interfaces for dependency inversion.
///
/// This library exports all service interfaces, allowing consumers
/// to depend on abstractions rather than concrete implementations.
///
/// Following SOLID principles:
/// - **DIP (Dependency Inversion)**: Depend on abstractions
/// - **ISP (Interface Segregation)**: Focused, single-purpose interfaces
library;

export 'i_streak_calculator.dart';
export 'i_data_generator.dart';
export 'i_chat_service.dart';
export 'i_auth_service.dart';
export 'i_weekly_summary_service.dart';
export 'i_recommendation_service.dart';
export 'i_notification_service.dart';
