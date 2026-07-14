import 'dart:typed_data';

import '../../models/habit_photo.dart';

/// Repository for habit completion photos (Repository Pattern + DIP).
///
/// Implementations store the image bytes in object storage and the
/// metadata in a table. The UI and providers depend only on this
/// abstraction, so the feature can be swapped for a no-op when cloud
/// storage isn't configured.
abstract class IPhotosRepository {
  /// Whether photo capture is actually available (Supabase configured
  /// and signed in). The UI hides the camera prompt when false.
  bool get isEnabled;

  /// Uploads [bytes] for [habitId] and inserts a metadata row.
  /// Returns the saved photo. Throws on failure.
  Future<HabitPhoto> uploadPhoto({
    required String habitId,
    required Uint8List bytes,
    DateTime? takenAt,
  });

  /// Loads the current user's photos taken on/after [since], newest
  /// first, each with a fresh [HabitPhoto.signedUrl] for display.
  Future<List<HabitPhoto>> loadPhotosSince(DateTime since);

  /// Downloads the raw image bytes for a stored photo (used to feed the
  /// AI recap).
  Future<Uint8List> downloadBytes(String storagePath);

  /// Deletes a photo (both the object and its metadata row).
  Future<void> deletePhoto(HabitPhoto photo);
}
