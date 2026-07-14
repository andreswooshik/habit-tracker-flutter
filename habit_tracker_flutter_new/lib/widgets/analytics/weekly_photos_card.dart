import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_flutter_new/models/habit_photo.dart';
import 'package:habit_tracker_flutter_new/providers/providers.dart';
import 'package:habit_tracker_flutter_new/utils/app_constants.dart';

/// Weekly Photo Journal
///
/// Shows the photos captured while completing habits this week in a grid
/// and, when a Gemini key is configured, an AI-written recap that also
/// highlights the standout photo. Hidden entirely in local-only mode
/// (no cloud storage).
class WeeklyPhotosCard extends ConsumerWidget {
  const WeeklyPhotosCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nothing to show without cloud storage.
    if (!ref.watch(photosRepositoryProvider).isEnabled) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final photosAsync = ref.watch(thisWeekPhotosProvider);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library, color: colorScheme.primary),
                SizedBox(width: AppConstants.spacingSmall),
                Expanded(
                  child: Text(
                    'Weekly Photo Journal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacingSmall),
            Text(
              'Photos you captured while completing habits this week',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: AppConstants.spacingLarge),
            photosAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => Text(
                'Could not load your photos.',
                style: TextStyle(color: colorScheme.error),
              ),
              data: (photos) => _buildContent(context, ref, photos),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<HabitPhoto> photos,
  ) {
    if (photos.isEmpty) {
      return _buildEmptyState(context);
    }

    final recapState = ref.watch(photoRecapProvider);
    final highlightId = recapState.recap?.highlightPhotoId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: photos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) => _PhotoTile(
            photo: photos[index],
            isHighlight: photos[index].id == highlightId,
          ),
        ),
        SizedBox(height: AppConstants.spacingLarge),
        _buildRecapSection(context, ref, recapState),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        children: [
          Icon(Icons.add_a_photo,
              size: 40, color: colorScheme.onSurfaceVariant),
          SizedBox(height: AppConstants.spacingMedium),
          Text(
            'No photos yet this week',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: AppConstants.spacingSmall),
          Text(
            'Complete a habit and tap "Take Photo" to start your journal.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapSection(
    BuildContext context,
    WidgetRef ref,
    PhotoRecapState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // No AI configured — grid only.
    if (ref.watch(photoRecapServiceProvider) == null) {
      return const SizedBox.shrink();
    }

    if (state.isGenerating) {
      return Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppConstants.spacingMedium),
          Text(
            'Looking through your week...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      );
    }

    if (state.errorMessage != null && !state.hasRecap) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.errorMessage!,
            style: TextStyle(color: colorScheme.error),
          ),
          SizedBox(height: AppConstants.spacingMedium),
          _generateButton(ref, label: 'Try Again'),
        ],
      );
    }

    if (state.hasRecap) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: colorScheme.primary),
              SizedBox(width: AppConstants.spacingSmall),
              Text(
                'Your AI recap',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Regenerate',
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () =>
                    ref.read(photoRecapProvider.notifier).generate(),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            child: Text(
              state.recap!.narrative,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.4),
            ),
          ),
        ],
      );
    }

    return Center(child: _generateButton(ref, label: 'Generate AI Recap'));
  }

  Widget _generateButton(WidgetRef ref, {required String label}) {
    return FilledButton.icon(
      onPressed: () => ref.read(photoRecapProvider.notifier).generate(),
      icon: const Icon(Icons.auto_awesome),
      label: Text(label),
    );
  }
}

/// A single photo in the grid; taps open a full-screen preview.
class _PhotoTile extends StatelessWidget {
  final HabitPhoto photo;
  final bool isHighlight;

  const _PhotoTile({required this.photo, required this.isHighlight});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = photo.signedUrl;

    return GestureDetector(
      onTap: url == null ? null : () => _openPreview(context, url),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: isHighlight
              ? Border.all(color: colorScheme.primary, width: 3)
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusMedium),
              child: url == null
                  ? Container(color: colorScheme.surfaceContainerHighest)
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image),
                      ),
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                              ? child
                              : Container(
                                  color: colorScheme.surfaceContainerHighest,
                                ),
                    ),
            ),
            if (isHighlight)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.star,
                      size: 14, color: colorScheme.onPrimary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openPreview(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(dialogContext).pop(),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
