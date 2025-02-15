// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_element.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsElementAdapter extends TypeAdapter<SettingsElement> {
  @override
  final int typeId = 2;

  @override
  SettingsElement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsElement(
      theme: fields[0] as String,
      language: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsElement obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.theme)
      ..writeByte(1)
      ..write(obj.language);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsElementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
