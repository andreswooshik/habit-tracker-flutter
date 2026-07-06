import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/screens/app_shell_screen.dart';
import 'package:habit_tracker_flutter_new/screens/auth/login_screen.dart';

/// Routes between the login flow and the app based on auth state
///
/// Watches the auth state stream: signed in -> app shell,
/// signed out -> login screen, first event pending -> splash.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    // When a different account (or none) becomes active, drop all
    // per-user state so the next reads load that user's data fresh
    ref.listen(authStateChangesProvider, (previous, next) {
      if (previous?.valueOrNull?.id != next.valueOrNull?.id) {
        ref.invalidate(habitsProvider);
        ref.invalidate(completionsProvider);
        ref.invalidate(chatProvider);
        ref.invalidate(weeklySummaryProvider);
      }
    });

    return authState.when(
      data: (user) =>
          user != null ? const AppShellScreen() : const LoginScreen(),
      // Session restore is near-instant; show a lightweight splash
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Something went wrong: $error'),
          ),
        ),
      ),
    );
  }
}
