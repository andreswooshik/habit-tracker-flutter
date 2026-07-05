import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_flutter_new/models/app_user.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/screens/app_shell_screen.dart';
import 'package:habit_tracker_flutter_new/screens/auth/auth_gate.dart';
import 'package:habit_tracker_flutter_new/screens/auth/login_screen.dart';
import 'package:habit_tracker_flutter_new/screens/auth/register_screen.dart';
import 'package:habit_tracker_flutter_new/screens/settings_screen.dart';
import 'package:habit_tracker_flutter_new/services/interfaces/i_auth_service.dart';

import '../mocks/mock_completions_repository.dart';
import '../mocks/mock_habits_repository.dart';

/// Fake auth service with stubbable results for widget tests
class FakeAuthService implements IAuthService {
  AppUser? initialUser;
  AuthResult nextSignInResult;
  AuthResult nextSignUpResult;
  String? lastSignInEmail;
  String? lastSignUpEmail;
  String? lastSignUpDisplayName;
  bool signOutCalled = false;

  FakeAuthService({
    this.initialUser,
    this.nextSignInResult = const AuthResult.failure('not stubbed'),
    this.nextSignUpResult = const AuthResult.failure('not stubbed'),
  });

  @override
  AppUser? get currentUser => initialUser;

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(initialUser);

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    lastSignInEmail = email;
    return nextSignInResult;
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    lastSignUpEmail = email;
    lastSignUpDisplayName = displayName;
    return nextSignUpResult;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

const testUser = AppUser(
  id: 'user-1',
  email: 'alice@example.com',
  displayName: 'Alice',
);

Widget buildTestApp(FakeAuthService authService, {Widget? home}) {
  return ProviderScope(
    overrides: [
      habitsRepositoryProvider.overrideWithValue(MockHabitsRepository()),
      completionsRepositoryProvider.overrideWithValue(
        MockCompletionsRepository(),
      ),
      authServiceProvider.overrideWithValue(authService),
    ],
    child: MaterialApp(home: home ?? const AuthGate()),
  );
}

void main() {
  group('AuthGate', () {
    testWidgets('shows login screen when signed out', (tester) async {
      await tester.pumpWidget(buildTestApp(FakeAuthService()));
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(AppShellScreen), findsNothing);
    });

    testWidgets('shows app shell when signed in', (tester) async {
      await tester.pumpWidget(
        buildTestApp(FakeAuthService(initialUser: testUser)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(AppShellScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });

  group('LoginScreen', () {
    testWidgets('validates empty and malformed input', (tester) async {
      final auth = FakeAuthService();
      await tester.pumpWidget(buildTestApp(auth, home: const LoginScreen()));

      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'not-an-email');
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(find.text('Enter a valid email address'), findsOneWidget);

      // Nothing was sent to the service
      expect(auth.lastSignInEmail, isNull);
    });

    testWidgets('shows error snackbar on failed sign in', (tester) async {
      final auth = FakeAuthService(
        nextSignInResult: const AuthResult.failure('Invalid login credentials'),
      );
      await tester.pumpWidget(buildTestApp(auth, home: const LoginScreen()));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'alice@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'wrong-pass');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(auth.lastSignInEmail, 'alice@example.com');
      expect(find.text('Invalid login credentials'), findsOneWidget);
    });

    testWidgets('navigates to registration', (tester) async {
      await tester.pumpWidget(
        buildTestApp(FakeAuthService(), home: const LoginScreen()),
      );

      await tester.tap(find.text("Don't have an account? Register"));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
    });
  });

  group('RegisterScreen', () {
    testWidgets('rejects mismatched passwords', (tester) async {
      final auth = FakeAuthService();
      await tester
          .pumpWidget(buildTestApp(auth, home: const RegisterScreen()));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'bob@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'secret123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm password'), 'other123');
      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(auth.lastSignUpEmail, isNull);
    });

    testWidgets('passes display name and shows email-confirmation notice',
        (tester) async {
      final auth = FakeAuthService(
        nextSignUpResult: const AuthResult.confirmationRequired(),
      );
      // Push RegisterScreen on top of a base route so pop() has somewhere to go
      await tester.pumpWidget(buildTestApp(auth, home: const LoginScreen()));
      await tester.tap(find.text("Don't have an account? Register"));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Display name (optional)'),
          'Bob');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'bob@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'secret123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm password'), 'secret123');
      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(auth.lastSignUpEmail, 'bob@example.com');
      expect(auth.lastSignUpDisplayName, 'Bob');
      // Back on the login screen with the notice showing
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        find.textContaining('Check your email to confirm'),
        findsOneWidget,
      );
    });
  });

  group('SettingsScreen sign out', () {
    testWidgets('shows user info and signs out after confirmation',
        (tester) async {
      final auth = FakeAuthService(initialUser: testUser);
      await tester.pumpWidget(buildTestApp(
        auth,
        home: const Scaffold(body: SettingsScreen()),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('alice@example.com'), findsOneWidget);

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign Out'));
      await tester.pumpAndSettle();

      expect(auth.signOutCalled, isTrue);
    });
  });
}
