// lib/models/connection_recipient.dart
import 'package:hive/hive.dart';

part 'connection_recipient.g.dart';

@HiveType(typeId: 2)
class ConnectionRecipient extends HiveObject {
  @HiveField(0)
  String customName;

  @HiveField(1)
  String? avatarPath;

  @HiveField(2)
  int nodeId;

  ConnectionRecipient({
    required this.customName,
    this.avatarPath,
    required this.nodeId,
  });
}