import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

/// Simple model for storing habit completion records in Hive
/// Each record represents a single completion of a habit on a specific date
class CompletionRecord extends Equatable {
  /// ID of the habit that was completed
  final String habitId;
  
  /// Date when the habit was completed (normalized to midnight)
  final DateTime completedAt;

  const CompletionRecord({
    required this.habitId,
    required this.completedAt,
  });

  @override
  List<Object?> get props => [habitId, completedAt];

  @override
  String toString() => 'CompletionRecord(habitId: $habitId, completedAt: $completedAt)';
}

/// Hive TypeAdapter for CompletionRecord
/// TypeId: 3
class CompletionRecordAdapter extends TypeAdapter<CompletionRecord> {
  @override
  final int typeId = 3;

  @override
  CompletionRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return CompletionRecord(
      habitId: fields[0] as String,
      completedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CompletionRecord obj) {
    writer
      ..writeByte(2) // number of fields
      ..writeByte(0)
      ..write(obj.habitId)
      ..writeByte(1)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletionRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
