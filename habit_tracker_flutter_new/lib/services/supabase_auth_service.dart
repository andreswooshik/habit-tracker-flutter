import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import 'interfaces/i_auth_service.dart';

/// Supabase-backed implementation of [IAuthService]
///
/// Registration and login are handled by Supabase Auth (auth.users);
/// a matching row in public.profiles is auto-created by the database
/// trigger defined in supabase/schema.sql.
class SupabaseAuthService implements IAuthService {
  final GoTrueClient _auth;

  SupabaseAuthService({GoTrueClient? auth})
      : _auth = auth ?? Supabase.instance.client.auth;

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Stream<AppUser?> get authStateChanges =>
      _auth.onAuthStateChange.map((state) => _toAppUser(state.session?.user));

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        // Picked up by the handle_new_user trigger for profiles.display_name
        data: {
          if (displayName != null && displayName.trim().isNotEmpty)
            'display_name': displayName.trim(),
        },
      );

      final user = _toAppUser(response.user);
      if (user == null) {
        return const AuthResult.failure('Sign up failed. Please try again.');
      }
      // With email confirmation enabled, Supabase returns the user
      // without a session until the link is clicked
      if (response.session == null) {
        return const AuthResult.confirmationRequired();
      }
      return AuthResult.success(user);
    } on AuthException catch (e) {
      return AuthResult.failure(friendlyAuthMessage(e));
    } catch (_) {
      return const AuthResult.failure('Sign up failed. Please try again.');
    }
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = _toAppUser(response.user);
      if (user == null) {
        return const AuthResult.failure('Sign in failed. Please try again.');
      }
      return AuthResult.success(user);
    } on AuthException catch (e) {
      return AuthResult.failure(friendlyAuthMessage(e));
    } catch (_) {
      return const AuthResult.failure('Sign in failed. Please try again.');
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// Translates a Supabase [AuthException] into a message fit for the
  /// login/register screens — users should never see raw exception text
  /// like "ClientException: Failed to fetch, uri=…".
  ///
  /// Static and pure so it can be unit-tested without a client.
  static String friendlyAuthMessage(AuthException e) {
    // Network-level failures (offline, DNS, blocked request)
    if (e is AuthRetryableFetchException ||
        e.message.contains('Failed to fetch') ||
        e.message.contains('SocketException') ||
        e.message.contains('ClientException')) {
      return 'Can\'t reach the server. Check your internet connection '
          'and try again.';
    }

    switch (e.code) {
      case 'invalid_credentials':
        return 'Incorrect email or password.';
      case 'email_not_confirmed':
        return 'Please confirm your email first — check your inbox.';
      case 'user_already_exists':
      case 'email_exists':
        return 'An account with this email already exists. Try signing in.';
      case 'weak_password':
        return 'That password is too weak — use at least 6 characters.';
      case 'over_request_rate_limit':
        return 'Too many attempts. Wait a moment and try again.';
      case 'user_banned':
        return 'This account is currently disabled.';
    }

    // Other Supabase auth messages are generally human-readable
    return e.message;
  }

  AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['display_name']?.toString(),
    );
  }
}
