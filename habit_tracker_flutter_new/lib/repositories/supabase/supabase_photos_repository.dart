import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../interfaces/i_photos_repository.dart';
import '../../models/habit_photo.dart';

/// Supabase implementation of [IPhotosRepository].
///
/// Image bytes go to the private 'habit-photos' Storage bucket under
/// `{userId}/{habitId}/{timestamp}.jpg`; metadata goes to the
/// public.habit_photos table (see supabase/schema.sql). Row Level
/// Security and the storage object policies scope everything to the
/// signed-in user. Display uses short-lived signed URLs.
class SupabasePhotosRepository implements IPhotosRepository {
  static const String _bucket = 'habit-photos';
  static const String _table = 'habit_photos';

  /// Signed URLs live long enough to browse a screen, not forever.
  static const int _signedUrlTtlSeconds = 60 * 60; // 1 hour

  final SupabaseClient _client;

  SupabasePhotosRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  bool get isEnabled => _client.auth.currentUser != null;

  @override
  Future<HabitPhoto> uploadPhoto({
    required String habitId,
    required Uint8List bytes,
    DateTime? takenAt,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Must be signed in to upload a photo');
    }

    final when = takenAt ?? DateTime.now();
    final path =
        '$userId/$habitId/${when.millisecondsSinceEpoch}.jpg';

    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    // user_id and week_start are filled by table defaults.
    final row = await _client
        .from(_table)
        .insert({
          'habit_id': habitId,
          'storage_path': path,
          'taken_at': when.toUtc().toIso8601String(),
        })
        .select()
        .single();

    final saved = HabitPhoto.fromRow(row);
    final url = await _signedUrl(path);
    return saved.copyWith(signedUrl: url);
  }

  @override
  Future<List<HabitPhoto>> loadPhotosSince(DateTime since) async {
    final rows = await _client
        .from(_table)
        .select()
        .gte('taken_at', since.toUtc().toIso8601String())
        .order('taken_at', ascending: false);

    final photos = rows.map(HabitPhoto.fromRow).toList();
    if (photos.isEmpty) return photos;

    // One batched call for all signed URLs instead of N round trips.
    // ignore: deprecated_member_use
    final signed = await _client.storage.from(_bucket).createSignedUrls(
          photos.map((p) => p.storagePath).toList(),
          _signedUrlTtlSeconds,
        );
    final urlByPath = {
      for (final item in signed) item.path: item.signedUrl,
    };

    return [
      for (final photo in photos)
        photo.copyWith(signedUrl: urlByPath[photo.storagePath]),
    ];
  }

  @override
  Future<Uint8List> downloadBytes(String storagePath) {
    return _client.storage.from(_bucket).download(storagePath);
  }

  @override
  Future<void> deletePhoto(HabitPhoto photo) async {
    await _client.storage.from(_bucket).remove([photo.storagePath]);
    await _client.from(_table).delete().eq('id', photo.id);
  }

  Future<String> _signedUrl(String path) {
    return _client.storage.from(_bucket).createSignedUrl(
          path,
          _signedUrlTtlSeconds,
        );
  }
}
