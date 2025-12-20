import 'package:hive/hive.dart';
import '../habit_frequency.dart';

/// Hive TypeAdapter for HabitFrequency enum
/// TypeId: 2
class HabitFrequencyAdapter extends TypeAdapter<HabitFrequency> {
  @override
  final int typeId = 2;

  @override
  HabitFrequency read(BinaryReader reader) {
    final index = reader.readByte();
    return HabitFrequency.values[index];
  }

  @override
  void write(BinaryWriter writer, HabitFrequency obj) {
    writer.writeByte(obj.index);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
