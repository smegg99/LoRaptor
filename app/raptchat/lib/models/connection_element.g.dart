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
    );
  }

  @override
  void write(BinaryWriter writer, ConnectionElement obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.order)
      ..writeByte(2)
      ..write(obj.privateKey);
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

class ActionElementAdapter extends TypeAdapter<ActionElement> {
  @override
  final int typeId = 1;

  @override
  ActionElement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActionElement(
      name: fields[0] as String,
      order: fields[1] as int,
      endpoint: fields[2] as String,
      method: fields[3] as String,
      headers: (fields[4] as Map).cast<String, String>(),
      body: fields[5] as String?,
      copyBasicAuth: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ActionElement obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.order)
      ..writeByte(2)
      ..write(obj.endpoint)
      ..writeByte(3)
      ..write(obj.method)
      ..writeByte(4)
      ..write(obj.headers)
      ..writeByte(5)
      ..write(obj.body)
      ..writeByte(6)
      ..write(obj.copyBasicAuth);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionElementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
