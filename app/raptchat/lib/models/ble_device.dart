// lib/models/ble_device.dart
import 'package:hive/hive.dart';

part 'ble_device.g.dart';

@HiveType(typeId: 1)
class BleDevice extends HiveObject {
  // The original name as detected from the device advertisement.
  @HiveField(0)
  String originalName;

  // The current display name (which may be a user-customized name).
  @HiveField(1)
  String displayName;

  @HiveField(2)
  // Node ID reported by the device. It's basically LoRaptor's MAC address.
  int nodeId;

  @HiveField(3)
  String macAddress;

  @HiveField(4)
  DateTime lastSeen;

  BleDevice({
    required this.originalName,
    String? displayName,
    required this.nodeId,
    required this.macAddress,
    DateTime? lastSeen,
  })  : displayName = displayName ?? originalName,
        lastSeen = lastSeen ?? DateTime.now();
}
