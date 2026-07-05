import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_keys.dart';
import '../models/app_user.dart';
import '../services/interfaces/i_auth_service.dart';
import '../services/noop_auth_service.dart';
import '../services/supabase_auth_service.dart';

/// Provider for the auth service implementation
///
/// Supabase-backed when configured, a safe no-op in local-only mode.
/// Overridden with a fake in widget tests (Dependency Inversion).
final authServiceProvider = Provider<IAuthService>((ref) {
  if (ApiKeys.supabaseConfigured) {
    return SupabaseAuthService();
  }
  return const NoopAuthService();
});

/// Emits the signed-in user (or null) whenever auth state changes
final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// The currently signed-in user, or null while signed out / loading
final currentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.valueOrNull ??
      ref.watch(authServiceProvider).currentUser;
});
