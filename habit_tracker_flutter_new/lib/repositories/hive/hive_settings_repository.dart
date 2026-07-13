import 'package:hive_flutter/hive_flutter.dart';

import '../interfaces/i_settings_repository.dart';

/// Hive implementation of ISettingsRepository
/// Stores preferences in an untyped key-value box
class HiveSettingsRepository implements ISettingsRepository {
  static const String _boxName = 'settings';
  Box<dynamic>? _box;

  Box<dynamic> get _settingsBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError('SettingsRepository not initialized. Call init() first.');
    }
    return _box!;
  }

  @override
  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  @override
  String? getString(String key) => _settingsBox.get(key) as String?;

  @override
  Future<void> setString(String key, String value) =>
      _settingsBox.put(key, value);

  @override
  bool? getBool(String key) => _settingsBox.get(key) as bool?;

  @override
  Future<void> setBool(String key, bool value) => _settingsBox.put(key, value);

  @override
  int? getInt(String key) => _settingsBox.get(key) as int?;

  @override
  Future<void> setInt(String key, int value) => _settingsBox.put(key, value);

  @override
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
