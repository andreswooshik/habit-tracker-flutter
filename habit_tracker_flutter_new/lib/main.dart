import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/config/app_theme.dart';
import 'package:habit_tracker_flutter_new/screens/home_dashboard_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrackIt!',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeDashboardScreen(),
    );
  }
}
