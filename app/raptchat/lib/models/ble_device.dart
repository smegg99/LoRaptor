// lib/models/ble_device.dart
import 'package:hive/hive.dart';

part 'ble_device.g.dart';

@HiveType(typeId: 1)
class BleDevice extends HiveObject {
  @HiveField(0)
  String displayName;

  @HiveField(1)
  int nodeId;

  BleDevice({required this.displayName, required this.nodeId});
}
