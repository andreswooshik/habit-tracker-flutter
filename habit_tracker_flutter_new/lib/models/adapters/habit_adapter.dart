import 'package:hive/hive.dart';
import '../habit.dart';
import '../habit_category.dart';
import '../habit_frequency.dart';

/// Hive TypeAdapter for the Habit model
/// TypeId: 0
class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return Habit(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      icon: fields[3] as String?,
      frequency: fields[4] as HabitFrequency,
      customDays: (fields[5] as List?)?.cast<int>(),
      category: fields[6] as HabitCategory,
      targetDays: fields[7] as int,
      hasGracePeriod: fields[8] as bool,
      isArchived: fields[9] as bool,
      createdAt: fields[10] as DateTime,
      notes: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(12) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.frequency)
      ..writeByte(5)
      ..write(obj.customDays)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.targetDays)
      ..writeByte(8)
      ..write(obj.hasGracePeriod)
      ..writeByte(9)
      ..write(obj.isArchived)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
