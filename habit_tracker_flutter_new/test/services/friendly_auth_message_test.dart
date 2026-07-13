import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/services/supabase_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseAuthService.friendlyAuthMessage', () {
    test('network failures never leak raw exception text', () {
      const raw = AuthException(
        'ClientException: Failed to fetch, '
        'uri=https://example.supabase.co/auth/v1/token',
      );

      final message = SupabaseAuthService.friendlyAuthMessage(raw);

      expect(message, isNot(contains('ClientException')));
      expect(message, isNot(contains('uri=')));
      expect(message, contains('internet connection'));
    });

    test('AuthRetryableFetchException maps to connection message', () {
      final message = SupabaseAuthService.friendlyAuthMessage(
        AuthRetryableFetchException(message: 'socket closed'),
      );

      expect(message, contains('internet connection'));
    });

    test('invalid credentials get a human message', () {
      final message = SupabaseAuthService.friendlyAuthMessage(
        const AuthException('invalid login credentials',
            code: 'invalid_credentials'),
      );

      expect(message, 'Incorrect email or password.');
    });

    test('existing account suggests signing in', () {
      final message = SupabaseAuthService.friendlyAuthMessage(
        const AuthException('already registered',
            code: 'user_already_exists'),
      );

      expect(message, contains('already exists'));
    });

    test('unknown codes fall back to the original message', () {
      final message = SupabaseAuthService.friendlyAuthMessage(
        const AuthException('Signups not allowed for this instance',
            code: 'signup_disabled'),
      );

      expect(message, 'Signups not allowed for this instance');
    });
  });
}
