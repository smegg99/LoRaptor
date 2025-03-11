// lib/models/message.dart
import 'package:hive/hive.dart';
part 'message.g.dart';

@HiveType(typeId: 4)
class Message {
  @HiveField(0)
  final String content;

  @HiveField(1)
  final int senderNodeID;

  @HiveField(2)
  final int timestamp;

  @HiveField(3)
  bool isPending;

  Message({
    required this.content,
    required this.senderNodeID,
    required this.timestamp,
    this.isPending = true,
  });
}