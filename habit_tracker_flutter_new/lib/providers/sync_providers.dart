import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/cloud_sync_coordinator.dart';

/// The cloud sync coordinator, or null in local-only mode (no Supabase
/// configured) — the UI hides the sync indicator when null.
///
/// Overridden in main.dart when the app starts in cloud mode.
final cloudSyncCoordinatorProvider = Provider<CloudSyncCoordinator?>((ref) {
  return null;
});
