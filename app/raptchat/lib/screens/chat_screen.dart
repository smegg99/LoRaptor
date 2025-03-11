// lib/screens/chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:raptchat/localization/localization.dart';
import 'package:raptchat/models/connection_element.dart';
import 'package:raptchat/models/message.dart';
import 'package:raptchat/managers/ble_device_manager.dart';
import 'package:raptchat/managers/messages_manager.dart';

class ChatScreen extends StatefulWidget {
  final ConnectionElement connection;
  const ChatScreen({super.key, required this.connection});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  AppLocalizations get localizations => AppLocalizations.of(context);

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      Provider.of<MessagesManager>(context, listen: false)
          .sendMessage(widget.connection.connectionID, text);
      _messageController.clear();
      // Scroll down after sending a message.
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    // Delay the scroll until the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Optionally, scroll to bottom when entering the screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleManager = Provider.of<BleDeviceManager>(context);
    final currentDevice = bleManager.connectedDevice;
    final currentNodeId = currentDevice?.nodeId;
    final bool isChatAllowed =
        currentDevice != null && currentNodeId == widget.connection.ownerNodeID;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.connection.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/edit',
                  arguments: widget.connection);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isChatAllowed)
            Container(
              width: double.infinity,
              color: Colors.redAccent,
              padding: const EdgeInsets.all(8.0),
              child: Text(
                localizations.translate('labels.messaging_disabled_not_paired'),
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: Consumer<MessagesManager>(
              builder: (context, messagesManager, _) {
                final List<Message> messages =
                    messagesManager.getMessages(widget.connection.connectionID);
                // After build, scroll to bottom.
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                if (messages.isEmpty) {
                  return Center(child: Text(localizations.translate('labels.no_messages')));
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMine = (currentDevice != null &&
                        msg.senderNodeID == currentDevice.nodeId);

                    if (isMine) {
                      final bubbleColor = msg.isPending
                          ? Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.5)
                          : Theme.of(context).colorScheme.primaryContainer;
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.7),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                msg.content,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat.Hm().format(
                                      DateTime.fromMillisecondsSinceEpoch(
                                          msg.timestamp),
                                    ),
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                  ),
                                  if (msg.isPending) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      localizations.translate('sending'),
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      final senderInfo = widget.connection.recipients
                          .firstWhereOrNull(
                              (r) => r.nodeId == msg.senderNodeID);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: (senderInfo != null &&
                                        senderInfo.avatarPath != null)
                                    ? FileImage(File(senderInfo.avatarPath!))
                                    : null,
                                child: (senderInfo == null ||
                                        senderInfo.avatarPath == null)
                                    ? Text(
                                        senderInfo?.customName.isNotEmpty ==
                                                true
                                            ? senderInfo!.customName[0]
                                                .toUpperCase()
                                            : msg.senderNodeID.toString(),
                                        style: const TextStyle(fontSize: 12),
                                      )
                                    : null,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    senderInfo?.customName ??
                                        msg.senderNodeID.toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      msg.content,
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                  ),
                                  Text(
                                    DateFormat.Hm().format(
                                      DateTime.fromMillisecondsSinceEpoch(
                                          msg.timestamp),
                                    ),
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: isChatAllowed,
                    decoration: InputDecoration(
                      hintText: isChatAllowed
                          ? localizations.translate('labels.message_hint')
                          : localizations.translate('labels.messaging_disabled'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: isChatAllowed ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
