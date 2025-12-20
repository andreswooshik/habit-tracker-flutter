import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
/// Follows Single Responsibility Principle - only handles responsive calculations
class Responsive {
  /// Breakpoint for mobile devices
  static const double mobileBreakpoint = 600;
  
  /// Breakpoint for tablet devices
  static const double tabletBreakpoint = 900;
  
  /// Breakpoint for desktop devices
  static const double desktopBreakpoint = 1200;

  /// Check if current device is mobile
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Check if current device is tablet
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;

  /// Check if current device is desktop
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  /// Get responsive value based on screen size
  static T valueWhen<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Get screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Get screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Calculate responsive padding
  static double padding(BuildContext context) {
    return valueWhen(
      context: context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
  }

  /// Calculate responsive font size multiplier
  static double fontScale(BuildContext context) {
    return valueWhen(
      context: context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
    );
  }
}
