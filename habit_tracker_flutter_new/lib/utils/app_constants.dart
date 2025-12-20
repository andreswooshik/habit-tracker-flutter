import 'package:flutter/material.dart';

/// Application-wide constants
/// Follows Open/Closed Principle - centralized configuration
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;

  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Spacing
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 20.0;
  static const double spacingXLarge = 24.0;

  // Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  // Card Elevation
  static const double cardElevationLow = 2.0;
  static const double cardElevationMedium = 4.0;
  static const double cardElevationHigh = 8.0;

  // Progress Indicator
  static const double progressStrokeWidth = 12.0;
  static const double progressIndicatorSize = 120.0;

  // Animation Durations
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);

  // Safety Limits
  static const int maxStreakCalculationDays = 1000;
  static const int maxRecentActivities = 7;

  // Opacity Values (using double for withValues)
  static const double opacityLight = 0.1;
  static const double opacityMedium = 0.2;
  static const double opacityHeavy = 0.3;
}

/// Theme-related extensions
extension ColorExtensions on Color {
  /// Replace deprecated withOpacity with withValues
  Color withAlpha(double opacity) {
    return withValues(alpha: opacity);
  }
}
