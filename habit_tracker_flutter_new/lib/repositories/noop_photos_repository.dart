import 'dart:typed_data';

import 'interfaces/i_photos_repository.dart';
import '../models/habit_photo.dart';

/// Safe no-op used in local-only mode (Supabase not configured).
///
/// [isEnabled] is false so the UI never offers the camera prompt, and
/// the read methods return empty results instead of throwing.
class NoopPhotosRepository implements IPhotosRepository {
  const NoopPhotosRepository();

  @override
  bool get isEnabled => false;

  @override
  Future<HabitPhoto> uploadPhoto({
    required String habitId,
    required Uint8List bytes,
    DateTime? takenAt,
  }) {
    throw UnsupportedError('Photo capture requires cloud storage (sign in).');
  }

  @override
  Future<List<HabitPhoto>> loadPhotosSince(DateTime since) async => const [];

  @override
  Future<Uint8List> downloadBytes(String storagePath) {
    throw UnsupportedError('Photo capture requires cloud storage (sign in).');
  }

  @override
  Future<void> deletePhoto(HabitPhoto photo) async {}
}
