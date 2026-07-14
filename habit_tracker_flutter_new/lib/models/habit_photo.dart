import 'package:equatable/equatable.dart';

/// A photo captured while completing a habit.
///
/// The image bytes live in the Supabase 'habit-photos' Storage bucket;
/// this model is the row metadata from public.habit_photos plus a
/// transient [signedUrl] filled in at load time so the UI can display
/// the private image without another round trip.
class HabitPhoto extends Equatable {
  final String id;
  final String habitId;

  /// Object key inside the 'habit-photos' bucket, e.g.
  /// `{userId}/{habitId}/{timestamp}.jpg`.
  final String storagePath;

  /// AI/user caption for the photo, if any.
  final String? caption;

  final DateTime takenAt;

  /// Short-lived signed URL for display. Not persisted — set when the
  /// repository loads photos from a private bucket.
  final String? signedUrl;

  const HabitPhoto({
    required this.id,
    required this.habitId,
    required this.storagePath,
    required this.takenAt,
    this.caption,
    this.signedUrl,
  });

  HabitPhoto copyWith({String? signedUrl, String? caption}) {
    return HabitPhoto(
      id: id,
      habitId: habitId,
      storagePath: storagePath,
      takenAt: takenAt,
      caption: caption ?? this.caption,
      signedUrl: signedUrl ?? this.signedUrl,
    );
  }

  /// Builds a model from a public.habit_photos row.
  factory HabitPhoto.fromRow(Map<String, dynamic> row) {
    return HabitPhoto(
      id: row['id'] as String,
      habitId: row['habit_id'] as String,
      storagePath: row['storage_path'] as String,
      caption: row['caption'] as String?,
      takenAt: DateTime.parse(row['taken_at'] as String).toLocal(),
    );
  }

  @override
  List<Object?> get props => [id, habitId, storagePath, caption, takenAt];
}
