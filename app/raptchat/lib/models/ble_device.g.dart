// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ble_device.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BleDeviceAdapter extends TypeAdapter<BleDevice> {
  @override
  final int typeId = 1;

  @override
  BleDevice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BleDevice(
      originalName: fields[0] as String,
      displayName: fields[1] as String?,
      nodeId: fields[2] as int,
      macAddress: fields[3] as String,
      lastSeen: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BleDevice obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.originalName)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.nodeId)
      ..writeByte(3)
      ..write(obj.macAddress)
      ..writeByte(4)
      ..write(obj.lastSeen);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleDeviceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
