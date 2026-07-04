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
}
