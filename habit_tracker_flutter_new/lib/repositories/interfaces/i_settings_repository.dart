/// Repository interface for lightweight user preferences
/// (theme mode, notification settings, ...)
///
/// Following Repository Pattern and Dependency Inversion Principle:
/// consumers depend on this abstraction, not on Hive.
abstract class ISettingsRepository {
  /// Initialize the repository (open storage)
  Future<void> init();

  /// Read a string preference, or null when unset
  String? getString(String key);

  /// Write a string preference
  Future<void> setString(String key, String value);

  /// Read a boolean preference, or null when unset
  bool? getBool(String key);

  /// Write a boolean preference
  Future<void> setBool(String key, bool value);

  /// Read an integer preference, or null when unset
  int? getInt(String key);

  /// Write an integer preference
  Future<void> setInt(String key, int value);

  /// Close the storage
  Future<void> close();
}

/// In-memory implementation used as the default in tests and as a safe
/// fallback when persistent storage is unavailable.
class InMemorySettingsRepository implements ISettingsRepository {
  final Map<String, Object> _values = {};

  @override
  Future<void> init() async {}

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async {
    _values[key] = value;
  }

  @override
  int? getInt(String key) => _values[key] as int?;

  @override
  Future<void> setInt(String key, int value) async {
    _values[key] = value;
  }

  @override
  Future<void> close() async {
    _values.clear();
  }
}
