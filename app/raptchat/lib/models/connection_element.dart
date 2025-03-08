// lib/models/stream_element.dart
// dart run build_runner build
import 'package:hive/hive.dart';

part 'connection_element.g.dart';

@HiveType(typeId: 0)
class ConnectionElement extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int order;

  @HiveField(2)
  String privateKey;

  @HiveField(3)
  String? avatarPath;

  @HiveField(4)
  int ownerNodeID;

  @HiveField(5)
  List<int> recipientNodeIDs = [];

  ConnectionElement({
    required this.name,
    required this.order,
    required this.privateKey,
    required this.recipientNodeIDs,
    this.avatarPath,
    this.ownerNodeID = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'order': order,
      'private_key': privateKey,
      'avatar_path': avatarPath,
      'owner_node_id': ownerNodeID,
      'recipient_node_ids': recipientNodeIDs,
    };
  }

  factory ConnectionElement.fromJson(Map<String, dynamic> json) {
    return ConnectionElement(
      name: json['name'] ?? '',
      order: json['order'] ?? 0,
      privateKey: json['private_key'] ?? '',
      avatarPath: json['avatar_path'] ?? '',
      recipientNodeIDs: json['recipient_node_ids'] ?? [],
      ownerNodeID: json['owner_node_id'] ?? 0,
    );
  }
}
