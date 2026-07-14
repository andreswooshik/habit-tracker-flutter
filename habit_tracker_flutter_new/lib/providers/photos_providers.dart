import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_keys.dart';
import '../models/habit_photo.dart';
import '../services/gemini_photo_recap_service.dart';
import '../services/interfaces/i_photo_recap_service.dart';
import 'habits_notifier.dart';
import 'repository_providers.dart';

/// Monday 00:00 (local) of the current ISO week — the boundary the
/// weekly photo gallery and recap use.
final currentWeekStartProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return today.subtract(Duration(days: today.weekday - 1));
});

/// This week's photos (newest first), each with a display signed URL.
/// Auto-refreshes when invalidated after a new capture.
final thisWeekPhotosProvider = FutureProvider<List<HabitPhoto>>((ref) async {
  final repository = ref.watch(photosRepositoryProvider);
  if (!repository.isEnabled) return const [];
  final weekStart = ref.watch(currentWeekStartProvider);
  return repository.loadPhotosSince(weekStart);
});

/// Shared [ImagePicker] (injectable so widget tests can fake it).
final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

/// The AI photo-recap service: Gemini when a key is configured, else a
/// no-op that produces nothing (the UI hides the recap button then).
final photoRecapServiceProvider = Provider<IPhotoRecapService?>((ref) {
  if (ApiKeys.gemini.isEmpty) return null;
  return GeminiPhotoRecapService(apiKey: ApiKeys.gemini);
});

/// Captures a photo with the camera and uploads it for [habitId].
///
/// Compression is done by the picker itself (imageQuality + maxWidth),
/// so no extra image library is needed. [state] is the in-flight flag.
class PhotoCaptureController extends StateNotifier<bool> {
  final Ref _ref;

  PhotoCaptureController(this._ref) : super(false);

  /// Returns the saved photo, or null if the user cancelled. Throws on
  /// upload failure so the caller can surface an error.
  Future<HabitPhoto?> captureForHabit(String habitId) async {
    final repository = _ref.read(photosRepositoryProvider);
    if (!repository.isEnabled) return null;

    final picker = _ref.read(imagePickerProvider);
    final file = await picker.pickImage(
      source: ImageSource.camera,
      // On-device downscale + recompress keeps uploads small and fast.
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (file == null) return null; // user cancelled

    state = true;
    try {
      final bytes = await file.readAsBytes();
      final saved =
          await repository.uploadPhoto(habitId: habitId, bytes: bytes);
      // Refresh the weekly gallery.
      _ref.invalidate(thisWeekPhotosProvider);
      return saved;
    } finally {
      state = false;
    }
  }
}

final photoCaptureProvider =
    StateNotifierProvider<PhotoCaptureController, bool>((ref) {
  return PhotoCaptureController(ref);
});

/// State for the AI weekly photo recap.
class PhotoRecapState {
  final bool isGenerating;
  final PhotoRecap? recap;
  final String? errorMessage;

  const PhotoRecapState({
    this.isGenerating = false,
    this.recap,
    this.errorMessage,
  });

  bool get hasRecap => recap != null && recap!.narrative.isNotEmpty;

  PhotoRecapState copyWith({
    bool? isGenerating,
    PhotoRecap? recap,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PhotoRecapState(
      isGenerating: isGenerating ?? this.isGenerating,
      recap: recap ?? this.recap,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Builds the weekly recap: downloads this week's photo bytes and asks
/// the AI service for a narrative + highlight. Single Responsibility —
/// only owns recap state; the AI work lives in [IPhotoRecapService].
class PhotoRecapNotifier extends StateNotifier<PhotoRecapState> {
  final Ref _ref;

  PhotoRecapNotifier(this._ref) : super(const PhotoRecapState());

  Future<void> generate() async {
    if (state.isGenerating) return;

    final service = _ref.read(photoRecapServiceProvider);
    final repository = _ref.read(photosRepositoryProvider);
    if (service == null || !repository.isEnabled) return;

    state = state.copyWith(isGenerating: true, clearError: true);
    try {
      final photos = await _ref.read(thisWeekPhotosProvider.future);
      if (photos.isEmpty) {
        state = state.copyWith(
          isGenerating: false,
          errorMessage: 'Take a few habit photos this week first!',
        );
        return;
      }

      final habitsById = _ref.read(habitsProvider).habitsById;
      final recapPhotos = <RecapPhoto>[];
      for (final photo in photos) {
        final bytes = await repository.downloadBytes(photo.storagePath);
        recapPhotos.add(RecapPhoto(
          photoId: photo.id,
          habitName: habitsById[photo.habitId]?.name ?? 'a habit',
          takenAt: photo.takenAt,
          bytes: bytes,
        ));
      }

      final recap = await service.generateRecap(recapPhotos);
      if (!mounted) return;
      state = state.copyWith(isGenerating: false, recap: recap);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isGenerating: false,
        errorMessage: 'Could not create your photo recap. Please try again.',
      );
    }
  }
}

final photoRecapProvider =
    StateNotifierProvider<PhotoRecapNotifier, PhotoRecapState>((ref) {
  return PhotoRecapNotifier(ref);
});
