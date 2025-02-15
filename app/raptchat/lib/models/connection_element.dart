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

  ConnectionElement({
    required this.name,
    required this.order,
    required this.privateKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'order': order,
      'private_key': privateKey,
    };
  }

  factory ConnectionElement.fromJson(Map<String, dynamic> json) {
    return ConnectionElement(
      name: json['name'] ?? '',
      order: json['order'] ?? 0,
      privateKey: json['private_key'] ?? '',
    );
  }
}

@HiveType(typeId: 1)
class ActionElement {
  @HiveField(0)
  String name;

  @HiveField(1)
  int order;

  @HiveField(2)
  String endpoint;

  @HiveField(3)
  String method;

  @HiveField(4)
  Map<String, String> headers;

  @HiveField(5)
  String? body;

  @HiveField(6)
  bool copyBasicAuth;

  ActionElement({
    required this.name,
    required this.order,
    required this.endpoint,
    required this.method,
    this.headers = const {},
    this.body,
    this.copyBasicAuth = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'order': order,
      'endpoint': endpoint,
      'method': method,
      'headers': headers,
      'body': body,
      'copyBasicAuth': copyBasicAuth,
    };
  }

  factory ActionElement.fromJson(Map<String, dynamic> json) {
    return ActionElement(
      name: json['name'],
      order: json['order'],
      endpoint: json['endpoint'],
      method: json['method'],
      headers: Map<String, String>.from(json['headers']),
      body: json['body'],
      copyBasicAuth: json['copyBasicAuth'] ?? false,
    );
  }
}
