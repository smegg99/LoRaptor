// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_recipient.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConnectionRecipientAdapter extends TypeAdapter<ConnectionRecipient> {
  @override
  final int typeId = 2;

  @override
  ConnectionRecipient read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConnectionRecipient(
      customName: fields[0] as String,
      avatarPath: fields[1] as String?,
      nodeId: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ConnectionRecipient obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.customName)
      ..writeByte(1)
      ..write(obj.avatarPath)
      ..writeByte(2)
      ..write(obj.nodeId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionRecipientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
