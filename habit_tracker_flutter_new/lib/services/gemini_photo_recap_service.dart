import 'dart:convert';

import 'package:http/http.dart' as http;

import 'gemini_client.dart';
import 'interfaces/i_photo_recap_service.dart';

/// Multimodal implementation of [IPhotoRecapService] using Google
/// Gemini. Sends the week's photos inline (as base64 image parts)
/// alongside a text instruction and asks for a small JSON object back:
/// a narrative recap plus the id of the standout photo.
///
/// Transport (auth, retries, model fallback) is delegated to the shared
/// [GeminiClient]; this service only builds the prompt and parses the
/// reply — the same split used by the other Gemini services.
class GeminiPhotoRecapService implements IPhotoRecapService {
  final GeminiClient _gemini;

  /// Keeps the request light: only the most recent photos are sent.
  final int maxPhotos;

  GeminiPhotoRecapService({
    required String apiKey,
    String model = 'gemini-2.5-flash',
    this.maxPhotos = 8,
    http.Client? client,
  }) : _gemini = GeminiClient(apiKey: apiKey, model: model, client: client);

  @override
  Future<PhotoRecap> generateRecap(List<RecapPhoto> photos) async {
    final selected = photos.take(maxPhotos).toList();
    if (selected.isEmpty) {
      return const PhotoRecap(narrative: '');
    }

    // Build one multimodal user turn: an intro line, then for each photo
    // a text label (so the model can reference it by id) followed by the
    // image bytes, then the closing instruction.
    final parts = <Map<String, dynamic>>[
      {
        'text': 'Here are the photos I took this week while completing my '
            'habits. Each photo is labelled with its id and details.',
      },
    ];

    for (final photo in selected) {
      parts.add({
        'text': 'Photo id "${photo.photoId}" — habit "${photo.habitName}", '
            'taken ${_formatDate(photo.takenAt)}:',
      });
      parts.add({
        'inlineData': {
          'mimeType': 'image/jpeg',
          'data': base64Encode(photo.bytes),
        },
      });
    }

    parts.add({
      'text': 'Respond with a JSON object with exactly these keys: '
          '"narrative" (one warm, encouraging paragraph of 3-5 sentences, '
          'plain text, describing what I accomplished this week based on the '
          'photos and celebrating a highlight) and "highlightPhotoId" (the id '
          'of the single best/most representative photo). Use only the photo '
          'ids provided.',
    });

    final reply = await _gemini.generateText(
      systemInstruction: _systemInstruction,
      contents: [
        {'role': 'user', 'parts': parts},
      ],
      responseMimeType: 'application/json',
    );

    return _parseRecap(reply, selected);
  }

  static const _systemInstruction =
      'You are a friendly habit coach writing a short weekly photo recap '
      'inside a habit tracker app. You are given the user\'s own photos of '
      'them doing their habits. Be warm, specific, and encouraging, and only '
      'describe what is actually visible in the photos and the provided '
      'labels. Always reply with valid JSON only.';

  PhotoRecap _parseRecap(String reply, List<RecapPhoto> photos) {
    try {
      final json = jsonDecode(reply) as Map<String, dynamic>;
      final narrative = (json['narrative'] as String?)?.trim() ?? '';
      var highlightId = (json['highlightPhotoId'] as String?)?.trim();

      // Guard against the model inventing an id.
      final validIds = photos.map((p) => p.photoId).toSet();
      if (highlightId != null && !validIds.contains(highlightId)) {
        highlightId = null;
      }
      return PhotoRecap(
        narrative: narrative.isEmpty ? reply.trim() : narrative,
        highlightPhotoId: highlightId,
      );
    } catch (_) {
      // If the model didn't return clean JSON, fall back to raw text.
      return PhotoRecap(narrative: reply.trim());
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
