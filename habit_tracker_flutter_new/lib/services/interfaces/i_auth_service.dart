import '../../models/app_user.dart';

/// Outcome of a sign-in or sign-up attempt
///
/// Exactly one of the three states applies:
/// - [user] set: the user is signed in
/// - [needsEmailConfirmation]: account created, but Supabase requires
///   the user to click the confirmation link before signing in
/// - [errorMessage] set: the attempt failed
class AuthResult {
  final AppUser? user;
  final bool needsEmailConfirmation;
  final String? errorMessage;

  const AuthResult.success(AppUser this.user)
      : needsEmailConfirmation = false,
        errorMessage = null;

  const AuthResult.confirmationRequired()
      : user = null,
        needsEmailConfirmation = true,
        errorMessage = null;

  const AuthResult.failure(String this.errorMessage)
      : user = null,
        needsEmailConfirmation = false;

  bool get isSuccess => user != null;
}

/// Interface for authentication (Dependency Inversion)
///
/// The app depends on this abstraction; the Supabase-backed
/// implementation can be swapped for a fake in tests.
abstract class IAuthService {
  /// The currently signed-in user, or null
  AppUser? get currentUser;

  /// Emits the signed-in user whenever the auth state changes
  /// (sign in, sign out, token refresh, session restore)
  Stream<AppUser?> get authStateChanges;

  /// Creates a new account with email + password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  /// Signs in with email + password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  });

  /// Signs the current user out
  Future<void> signOut();
}
