/// Template for lib/config/api_keys.dart (which is gitignored).
///
/// Setup: copy this file to `api_keys.dart` in the same folder and
/// paste your Gemini API key into the `_gemini` constant.
class ApiKeys {
  ApiKeys._();

  /// Paste your Google Gemini API key between the quotes below.
  /// Get one at https://aistudio.google.com/apikey
  static const String _gemini = '';

  /// Optional override without touching code:
  /// `flutter run --dart-define=GEMINI_API_KEY=your_key`
  static const String _geminiFromEnv = String.fromEnvironment('GEMINI_API_KEY');

  /// The effective Gemini key: dart-define wins, then the pasted value.
  /// Empty means the app falls back to the offline rule-based coach.
  static String get gemini =>
      _geminiFromEnv.isNotEmpty ? _geminiFromEnv : _gemini;

  /// Paste your Supabase project URL below (Project Settings > API),
  /// e.g. 'https://abcdefghijkl.supabase.co'
  static const String _supabaseUrl = '';

  /// Paste your Supabase key below (Project Settings > API Keys) —
  /// either the new "publishable" key (sb_publishable_...) or the
  /// legacy "anon" key; both are safe for client apps
  static const String _supabaseAnonKey = '';

  static const String _supabaseUrlFromEnv =
      String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKeyFromEnv =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// The effective Supabase settings: dart-define wins, then pasted values.
  /// Empty means the app runs without login (local-only mode).
  static String get supabaseUrl =>
      _supabaseUrlFromEnv.isNotEmpty ? _supabaseUrlFromEnv : _supabaseUrl;
  static String get supabaseAnonKey => _supabaseAnonKeyFromEnv.isNotEmpty
      ? _supabaseAnonKeyFromEnv
      : _supabaseAnonKey;

  /// Whether Supabase auth is configured
  static bool get supabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
