// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_element.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConnectionElementAdapter extends TypeAdapter<ConnectionElement> {
  @override
  final int typeId = 0;

  @override
  ConnectionElement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConnectionElement(
      name: fields[0] as String,
      order: fields[1] as int,
      privateKey: fields[2] as String,
      avatarPath: fields[3] as String?,
      ownerNodeID: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ConnectionElement obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.order)
      ..writeByte(2)
      ..write(obj.privateKey)
      ..writeByte(3)
      ..write(obj.avatarPath)
      ..writeByte(4)
      ..write(obj.ownerNodeID);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionElementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
