import 'package:hive/hive.dart';
import '../habit_category.dart';

/// Hive TypeAdapter for HabitCategory enum
/// TypeId: 1
class HabitCategoryAdapter extends TypeAdapter<HabitCategory> {
  @override
  final int typeId = 1;

  @override
  HabitCategory read(BinaryReader reader) {
    final index = reader.readByte();
    return HabitCategory.values[index];
  }

  @override
  void write(BinaryWriter writer, HabitCategory obj) {
    writer.writeByte(obj.index);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
