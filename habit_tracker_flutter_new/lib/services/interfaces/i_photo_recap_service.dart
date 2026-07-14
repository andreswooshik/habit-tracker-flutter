import 'dart:typed_data';

/// One photo handed to the AI recap: its image bytes plus the habit it
/// documents and when it was taken.
class RecapPhoto {
  final String photoId;
  final String habitName;
  final DateTime takenAt;
  final Uint8List bytes;

  const RecapPhoto({
    required this.photoId,
    required this.habitName,
    required this.takenAt,
    required this.bytes,
  });
}

/// Result of an AI weekly photo recap.
class PhotoRecap {
  /// A short, encouraging narrative of the week built from the photos.
  final String narrative;

  /// The [RecapPhoto.photoId] the AI picked as the week's highlight, or
  /// null if it didn't choose one.
  final String? highlightPhotoId;

  const PhotoRecap({required this.narrative, this.highlightPhotoId});
}

/// Generates a weekly recap from the photos a user captured while
/// completing habits (Dependency Inversion — callers depend on this,
/// not on any specific AI vendor).
abstract class IPhotoRecapService {
  Future<PhotoRecap> generateRecap(List<RecapPhoto> photos);
}
