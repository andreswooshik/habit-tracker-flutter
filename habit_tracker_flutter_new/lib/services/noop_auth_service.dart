import '../models/app_user.dart';
import 'interfaces/i_auth_service.dart';

/// No-op [IAuthService] used when Supabase is not configured
///
/// Keeps widgets that watch auth state working in local-only mode:
/// there is never a signed-in user, and sign in/up always fail with
/// a clear message.
class NoopAuthService implements IAuthService {
  const NoopAuthService();

  @override
  AppUser? get currentUser => null;

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(null);

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    return const AuthResult.failure('Login is not configured in this build.');
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return const AuthResult.failure('Login is not configured in this build.');
  }

  @override
  Future<void> signOut() async {}
}
