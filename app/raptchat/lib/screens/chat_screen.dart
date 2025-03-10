// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:raptchat/models/connection_element.dart';
import 'package:raptchat/models/message.dart';
import 'package:raptchat/managers/ble_device_manager.dart';

class ChatScreen extends StatelessWidget {
  final ConnectionElement connection;

  const ChatScreen({super.key, required this.connection});

  @override
  Widget build(BuildContext context) {
    final currentNodeId =
        Provider.of<BleDeviceManager>(context).connectedDevice?.nodeId;
    // MOCK, for now
    final List<Message> messages = [
      Message(
        content:
            "Hello there! I wanted to reach out and see how you're doing today.",
        senderNodeID: connection.ownerNodeID, 
        timestamp: DateTime.now().millisecondsSinceEpoch - 60000,
      ),
      Message(
        content: "Hi! This is my reply.",
        senderNodeID: currentNodeId ?? 0,
        timestamp: DateTime.now().millisecondsSinceEpoch - 30000,
      ),
      Message(
        content: "Another message from owner.",
        senderNodeID: connection.ownerNodeID,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(connection.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/edit', arguments: connection);
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          final isMine = (msg.senderNodeID == currentNodeId);
          return Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 4),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7),
              decoration: BoxDecoration(
                color: isMine
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment:
                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: isMine
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.Hm().format(
                        DateTime.fromMillisecondsSinceEpoch(msg.timestamp)),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
