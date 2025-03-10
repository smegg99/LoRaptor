// lib/models/connection_element.dart
import 'package:hive/hive.dart';
import 'connection_recipient.dart';

part 'connection_element.g.dart';

@HiveType(typeId: 0)
class ConnectionElement extends HiveObject {
  @HiveField(0)
  String connectionID; // Unchangeable connection ID

  @HiveField(1)
  String name; // Display name, can be changed by user

  @HiveField(2)
  int order;

  @HiveField(3)
  String privateKey;

  @HiveField(4)
  String? avatarPath;

  @HiveField(5)
  // Owner node ID of the device that owns this connection.
  int ownerNodeID;

  @HiveField(6)
  // Detailed recipient list.
  List<ConnectionRecipient> recipients;

  ConnectionElement({
    required this.connectionID,
    required this.name,
    required this.order,
    required this.privateKey,
    this.avatarPath,
    this.ownerNodeID = 0,
    List<ConnectionRecipient>? recipients,
  }) : recipients = recipients ?? [];

  Map<String, dynamic> toJson() {
    return {
      'connection_id': connectionID,
      'name': name,
      'order': order,
      'private_key': privateKey,
      'avatar_path': avatarPath,
      'owner_node_id': ownerNodeID,
      'recipients': recipients
          .map((r) => {
                'custom_name': r.customName,
                'avatar_path': r.avatarPath,
                'node_id': r.nodeId,
              })
          .toList(),
    };
  }

  factory ConnectionElement.fromJson(Map<String, dynamic> json) {
    return ConnectionElement(
      connectionID: json['connection_id'] ?? '',
      name: json['name'] ?? '',
      order: json['order'] ?? 0,
      privateKey: json['private_key'] ?? '',
      avatarPath: json['avatar_path'] ?? '',
      ownerNodeID: json['owner_node_id'] ?? 0,
      recipients: json['recipients'] != null
          ? (json['recipients'] as List).map((e) {
              return ConnectionRecipient(
                customName: e['custom_name'] ?? '',
                avatarPath: e['avatar_path'],
                nodeId: e['node_id'] ?? 0,
              );
            }).toList()
          : [],
    );
  }
}
