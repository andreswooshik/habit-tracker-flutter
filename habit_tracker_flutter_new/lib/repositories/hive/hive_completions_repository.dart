import 'package:hive_flutter/hive_flutter.dart';
import '../interfaces/i_completions_repository.dart';
import '../../models/adapters/completion_record.dart';

/// Hive implementation of ICompletionsRepository
/// Stores completion records in a Hive box with habitId as composite key
class HiveCompletionsRepository implements ICompletionsRepository {
  static const String _boxName = 'completions';
  Box<CompletionRecord>? _box;

  /// Get the Hive box, ensuring it's initialized
  Box<CompletionRecord> get _completionsBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError('CompletionsRepository not initialized. Call init() first.');
    }
    return _box!;
  }

  @override
  Future<void> init() async {
    // Register adapter if not already registered
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(CompletionRecordAdapter());
    }

    // Open the box
    _box = await Hive.openBox<CompletionRecord>(_boxName);
  }

  @override
  Future<Map<String, Set<DateTime>>> loadCompletions() async {
    final Map<String, Set<DateTime>> completionsMap = {};

    for (final record in _completionsBox.values) {
      completionsMap.putIfAbsent(record.habitId, () => {}).add(_normalizeDate(record.completedAt));
    }

    return completionsMap;
  }

  @override
  Future<void> addCompletion(String habitId, DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    final key = _generateKey(habitId, normalizedDate);
    
    final record = CompletionRecord(
      habitId: habitId,
      completedAt: normalizedDate,
    );
    
    await _completionsBox.put(key, record);
  }

  @override
  Future<void> removeCompletion(String habitId, DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    final key = _generateKey(habitId, normalizedDate);
    await _completionsBox.delete(key);
  }

  @override
  Future<Set<DateTime>> getCompletionsForHabit(String habitId) async {
    final completions = _completionsBox.values
        .where((record) => record.habitId == habitId)
        .map((record) => _normalizeDate(record.completedAt))
        .toSet();
    
    return completions;
  }

  @override
  Future<void> deleteCompletionsForHabit(String habitId) async {
    final keysToDelete = <dynamic>[];
    
    for (final entry in _completionsBox.toMap().entries) {
      if (entry.value.habitId == habitId) {
        keysToDelete.add(entry.key);
      }
    }
    
    await _completionsBox.deleteAll(keysToDelete);
  }

  @override
  Future<void> clearAll() async {
    await _completionsBox.clear();
  }

  @override
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }

  /// Normalize date to midnight local time for consistent storage
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Generate a composite key from habitId and date
  String _generateKey(String habitId, DateTime date) {
    return '${habitId}_${date.millisecondsSinceEpoch}';
  }
}
