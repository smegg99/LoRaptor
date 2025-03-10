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
      connectionID: fields[0] as String,
      name: fields[1] as String,
      order: fields[2] as int,
      privateKey: fields[3] as String,
      avatarPath: fields[4] as String?,
      ownerNodeID: fields[5] as int,
      recipients: (fields[6] as List?)?.cast<ConnectionRecipient>(),
    );
  }

  @override
  void write(BinaryWriter writer, ConnectionElement obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.connectionID)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.order)
      ..writeByte(3)
      ..write(obj.privateKey)
      ..writeByte(4)
      ..write(obj.avatarPath)
      ..writeByte(5)
      ..write(obj.ownerNodeID)
      ..writeByte(6)
      ..write(obj.recipients);
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
