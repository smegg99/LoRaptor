import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:raptchat/managers/ble_device_manager.dart';
import 'package:raptchat/models/connection_element.dart';
import 'package:raptchat/models/message.dart';

class QueuedCommand {
  final String commandString;
  final String expectedSuccess; // e.g. "msg.send.success" or "type.flush.mess"
  final VoidCallback? onSuccess;
  final Function(String)? onError;

  QueuedCommand({
    required this.commandString,
    required this.expectedSuccess,
    this.onSuccess,
    this.onError,
  });
}

class MessagesManager extends ChangeNotifier {
  final BleDeviceManager bleDeviceManager;

  final List<QueuedCommand> _commandQueue = [];
  bool _isProcessingQueue = false;

  // In-memory map from connection ID to list of messages.
  final Map<String, List<Message>> _messages = {};

  Timer? _flushTimer;
  late Box _messagesBox;

  MessagesManager({required this.bleDeviceManager}) {
    _messagesBox = Hive.box('messages');
    _loadMessagesFromBox();

    bleDeviceManager.registerNewMessageCallback(handleIncomingMessage);
    // Set our flush callback.
    bleDeviceManager.onFlushReceived = _handleFlush;
    bleDeviceManager.onGenericReturn = _onGenericReturn;

    _startFlushTimer();
  }

  // ----------------------
  //    COMMAND QUEUE
  // ----------------------
  void addCommandToQueue({
    required String commandString,
    required String expectedSuccess,
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) {
    _commandQueue.add(QueuedCommand(
      commandString: commandString,
      expectedSuccess: expectedSuccess,
      onSuccess: onSuccess,
      onError: onError,
    ));
    _processQueue();
  }

  void _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    while (_commandQueue.isNotEmpty) {
      final cmd = _commandQueue.first;
      // Send the command over BLE.
      await bleDeviceManager.sendNUSCommand(cmd.commandString);

      final completer = Completer<void>();
      final timer = Timer(Duration(seconds: 1), () {
        if (!completer.isCompleted) {
          completer.completeError(
              'Timeout waiting for success: ${cmd.commandString}');
        }
      });

      void onCmdSuccess() {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }

      void onCmdError(String err) {
        if (!completer.isCompleted) {
          completer.completeError(err);
        }
      }

      // Store the expected success token and callbacks.
      _pendingSuccess = cmd.expectedSuccess;
      _pendingSuccessCallback = onCmdSuccess;
      _pendingErrorCallback = onCmdError;

      try {
        await completer.future;
        timer.cancel();
        cmd.onSuccess?.call();
        _commandQueue.removeAt(0);
      } catch (e) {
        timer.cancel();
        cmd.onError?.call(e.toString());
        _commandQueue.removeAt(0);
      }
    }

    _isProcessingQueue = false;
  }

  String? _pendingSuccess;
  VoidCallback? _pendingSuccessCallback;
  Function(String)? _pendingErrorCallback;

  void _onGenericReturn(String value) {
    print("Generic return from device: $value");
    // If we're waiting for a specific token, check that first.
    if (_pendingSuccess != null && value == _pendingSuccess) {
      _pendingSuccessCallback?.call();
      _pendingSuccess = null;
      _pendingSuccessCallback = null;
      _pendingErrorCallback = null;
    } else if (value == "msg.send.success") {
      // Even if we have no pending command (or it timed out), mark all pending messages
      // sent by the current device as confirmed.
      final currentNodeId = bleDeviceManager.connectedDevice?.nodeId ?? 0;
      _messages.forEach((connectionID, msgList) async {
        final index = msgList.lastIndexWhere(
            (m) => m.isPending && m.senderNodeID == currentNodeId);
        if (index != -1) {
          msgList[index].isPending = false;
          await _messagesBox.put(connectionID, msgList);
          notifyListeners();
        }
      });
    }
  }

  void _loadMessagesFromBox() {
    for (var key in _messagesBox.keys) {
      final stored = _messagesBox.get(key);
      if (stored != null && stored is List) {
        try {
          final msgs = stored.map<Message>((e) => e as Message).toList();
          _messages[key] = msgs;
        } catch (e) {
          print("Error converting stored messages for key $key: $e");
        }
      }
    }
  }

  List<Message> getMessages(String connectionID) =>
      _messages[connectionID] ?? [];

  String? getLastMessage(String connectionID) {
    final msgs = _messages[connectionID];
    return (msgs != null && msgs.isNotEmpty) ? msgs.last.content : null;
  }

  Future<void> sendMessage(String connectionID, String content) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final currentNodeId = bleDeviceManager.connectedDevice?.nodeId ?? 0;
    final msg = Message(
      content: content,
      senderNodeID: currentNodeId,
      timestamp: now,
      isPending: true,
    );
    _messages.putIfAbsent(connectionID, () => []);
    _messages[connectionID]!.add(msg);
    await _messagesBox.put(connectionID, _messages[connectionID]!);
    notifyListeners();

    final cmdString = 'send -id "$connectionID" -m "$content"';
    addCommandToQueue(
      commandString: cmdString,
      expectedSuccess: 'msg.send.success',
      onSuccess: () async {
        print("Message sent success for: $cmdString");
        final messages = _messages[connectionID];
        if (messages != null && messages.isNotEmpty) {
          final index = messages.lastIndexWhere(
            (m) => m.isPending && m.senderNodeID == currentNodeId,
          );
          if (index != -1) {
            messages[index].isPending = false;
            await _messagesBox.put(connectionID, messages);
            notifyListeners();
          }
        }
      },
      onError: (err) {
        print("Failed to send message: $err");
      },
    );
  }

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(Duration(seconds: 7), (_) async {
      final connections = _getConnectionsForCurrentDevice();
      for (var connectionID in connections) {
        final cmd = 'flush -id "$connectionID"';
        addCommandToQueue(
          commandString: cmd,
          expectedSuccess: 'type.flush.mess', // Device returns this for flush.
        );
      }
    });
  }

  List<String> _getConnectionsForCurrentDevice() {
    final box = Hive.box<ConnectionElement>('connection_elements');
    final ids = <String>[];
    for (var element in box.values) {
      if (element.connectionID.isNotEmpty) {
        ids.add(element.connectionID);
      }
    }
    return ids;
  }

  void _handleFlush(List<List<dynamic>> flushData) async {
    try {
      for (var item in flushData) {
        if (item.isEmpty || item.length < 3) {
          print("Skipping invalid flush item: $item");
          continue;
        }
        try {
          int senderNodeID = int.tryParse(item[0].toString()) ?? 0;
          int epochSeconds = int.tryParse(item[1].toString()) ?? 0;
          String msgContent = item[2].toString();
          final timestamp = epochSeconds * 1000;
          final flushMsg = Message(
            content: msgContent,
            senderNodeID: senderNodeID,
            timestamp: timestamp,
            isPending: false,
          );
          final connBox = Hive.box<ConnectionElement>('connection_elements');
          for (var connection in connBox.values) {
            if (connection.recipients.any((r) => r.nodeId == senderNodeID)) {
              _messages.putIfAbsent(connection.connectionID, () => []);
              _messages[connection.connectionID]!.add(flushMsg);
              await _messagesBox.put(
                  connection.connectionID, _messages[connection.connectionID]!);
              notifyListeners();
            }
          }
        } catch (e) {
          print("Error processing flush item $item: $e");
          continue;
        }
      }
    } catch (e, st) {
      print("Error in flush handler: $e, stack: $st");
    }
  }

  void handleIncomingMessage(
      int senderNodeID, int epochSeconds, String message) async {
    final timestamp = epochSeconds * 1000;
    final msg = Message(
      content: message,
      senderNodeID: senderNodeID,
      timestamp: timestamp,
      isPending: false,
    );

    final box = Hive.box<ConnectionElement>('connection_elements');
    bool messageAdded = false;
    for (var connection in box.values) {
      if (connection.recipients.any((r) => r.nodeId == senderNodeID)) {
        _messages.putIfAbsent(connection.connectionID, () => []);
        _messages[connection.connectionID]!.add(msg);
        await _messagesBox.put(
            connection.connectionID, _messages[connection.connectionID]!);
        messageAdded = true;
        notifyListeners();
        // Removed the 'break;' so that the message is added to all matching connections.
      }
    }
    if (!messageAdded) {
      print("No connection found for sender node ID: $senderNodeID");
    }
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    super.dispose();
  }
}
