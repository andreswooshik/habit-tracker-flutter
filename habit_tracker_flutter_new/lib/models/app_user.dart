import 'package:equatable/equatable.dart';

/// Immutable value object for the signed-in user
///
/// Keeps the rest of the app decoupled from Supabase's own User type
/// (Dependency Inversion — UI and state only ever see this).
class AppUser extends Equatable {
  /// Unique user id (Supabase auth.users id)
  final String id;

  /// The user's email address
  final String email;

  /// Optional display name chosen at registration
  final String? displayName;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
  });

  /// Name to show in the UI, falling back to the email's local part
  String get shownName {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email.split('@').first;
  }

  @override
  List<Object?> get props => [id, email, displayName];
}
