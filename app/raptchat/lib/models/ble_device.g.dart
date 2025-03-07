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
      displayName: fields[0] as String,
      nodeId: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BleDevice obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.displayName)
      ..writeByte(1)
      ..write(obj.nodeId);
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
