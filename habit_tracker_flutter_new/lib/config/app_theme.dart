import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

/// Application theme configuration
/// Follows Open/Closed Principle - centralized theme management
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  /// Primary color seed for the app
  static const Color primaryColorSeed = Colors.deepPurple;

  /// Light theme configuration
  static ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColorSeed,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    
    // Card theme
    cardTheme: CardThemeData(
      elevation: AppConstants.cardElevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
    ),

    // AppBar theme
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingMedium,
      ),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLarge,
          vertical: AppConstants.paddingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLarge,
          vertical: AppConstants.paddingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
      ),
    ),

    // Icon theme
    iconTheme: const IconThemeData(
      size: AppConstants.iconSizeMedium,
    ),

    // Floating Action Button theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: AppConstants.cardElevationMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
    ),
  );

  /// Dark theme configuration (for future implementation)
  static ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColorSeed,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    
    // Card theme
    cardTheme: CardThemeData(
      elevation: AppConstants.cardElevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
    ),
  );

  /// Get category color - extracted for reusability
  static Color getCategoryColor(dynamic category) {
    // Implementation moved here for centralized theme management
    // This would use the HabitCategory enum
    return primaryColorSeed;
  }
}
