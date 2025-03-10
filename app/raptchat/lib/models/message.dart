// lib/models/message.dart
class Message {
  final String content;
  final int senderNodeID;
  final int timestamp; // Epoch in milliseconds

  Message({
    required this.content,
    required this.senderNodeID,
    required this.timestamp,
  });
}
