import 'dart:convert';

import 'package:http/http.dart' as http;

/// Low-level client for the Google Gemini generateContent REST API
///
/// Owns the HTTP transport concerns shared by every Gemini-backed
/// service: authentication, retries, model fallback on overload, and
/// response parsing. Services compose this client and only supply
/// their own system instruction and contents (Single Responsibility —
/// prompt building stays in the service, transport lives here).
/// The HTTP client is injectable so tests can run without network
/// access.
class GeminiClient {
  final String apiKey;
  final String model;
  final Duration retryDelay;
  final http.Client _client;

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Tried in order when the primary model is overloaded (503) or
  /// rate-limited (429) — the free tier hits this during peak hours
  static const _fallbackModels = [
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash',
  ];

  GeminiClient({
    required this.apiKey,
    this.model = 'gemini-2.5-flash',
    this.retryDelay = const Duration(milliseconds: 800),
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Sends a generateContent request and returns the reply text
  ///
  /// [contents] follows the Gemini API shape: a list of
  /// `{'role': ..., 'parts': [{'text': ...}]}` maps. Pass
  /// [responseMimeType] as 'application/json' to request structured
  /// JSON output. Throws on API errors or empty replies.
  Future<String> generateText({
    required String systemInstruction,
    required List<Map<String, dynamic>> contents,
    double temperature = 0.7,
    String? responseMimeType,
  }) async {
    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction},
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': temperature,
        if (responseMimeType != null) 'responseMimeType': responseMimeType,
      },
    });

    final models = [
      model,
      ..._fallbackModels.where((m) => m != model),
    ];

    Exception lastError = Exception('Gemini API unavailable');
    for (final currentModel in models) {
      // One retry per model before moving to the next one
      for (var attempt = 0; attempt < 2; attempt++) {
        final response = await _post(currentModel, body);

        if (response.statusCode == 200) {
          final reply = _extractText(response.body);
          if (reply == null || reply.trim().isEmpty) {
            throw Exception('Gemini returned an empty reply');
          }
          return reply.trim();
        }

        lastError = Exception(
          'Gemini API error ${response.statusCode}: '
          '${_errorMessage(response.body)}',
        );

        // Only overload/rate-limit errors are worth retrying;
        // anything else (bad key, malformed request) fails fast
        final isRetriable =
            response.statusCode == 429 || response.statusCode >= 500;
        if (!isRetriable) throw lastError;

        if (attempt == 0) await Future.delayed(retryDelay);
      }
    }
    throw lastError;
  }

  Future<http.Response> _post(String model, String body) {
    return _client
        .post(
          Uri.parse('$_baseUrl/$model:generateContent'),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));
  }

  /// Joins all text parts of the first candidate, or null if none
  String? _extractText(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return null;

    final content =
        (candidates.first as Map<String, dynamic>)['content']
            as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null) return null;

    return parts
        .map((part) => (part as Map<String, dynamic>)['text'] as String? ?? '')
        .join();
  }

  String _errorMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      return error?['message'] as String? ?? body;
    } catch (_) {
      return body;
    }
  }
}
