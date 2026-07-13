import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/interfaces/i_settings_repository.dart';
import 'repository_providers.dart';

/// StateNotifier for the app-wide theme mode (system / light / dark)
///
/// Persists the choice through ISettingsRepository so it survives restarts.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String settingsKey = 'theme_mode';

  final ISettingsRepository _settings;

  ThemeModeNotifier(this._settings) : super(_initialMode(_settings));

  static ThemeMode _initialMode(ISettingsRepository settings) {
    final stored = settings.getString(settingsKey);
    return ThemeMode.values.asNameMap()[stored] ?? ThemeMode.system;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _settings.setString(settingsKey, mode.name);
  }
}

/// Global provider for the current theme mode
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(settingsRepositoryProvider));
});
