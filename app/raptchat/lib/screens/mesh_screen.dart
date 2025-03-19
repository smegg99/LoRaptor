import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raptchat/localization/localization.dart';
import 'package:raptchat/managers/messages_manager.dart';
import 'package:raptchat/widgets/mesh_device_list_item.dart';

class MeshScreen extends StatefulWidget {
  const MeshScreen({super.key});

  @override
  _MeshScreenState createState() => _MeshScreenState();
}

class _MeshScreenState extends State<MeshScreen> {
  Timer? _listNodesTimer;

  AppLocalizations get localizations => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    // Periodically send the "list nodes" command when on the mesh screen.
    _listNodesTimer = Timer.periodic(Duration(seconds: 7), (_) {
      final messagesManager =
          Provider.of<MessagesManager>(context, listen: false);
      messagesManager.addCommandToQueue(
        commandString: 'list nodes',
        expectedSuccess: 'type.list.nodes',
        onSuccess: () {
          print("List nodes command succeeded.");
        },
        onError: (err) {
          print("List nodes command error: $err");
        },
      );
    });
  }

  @override
  void dispose() {
    _listNodesTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagesManager>(
      builder: (context, messagesManager, child) {
        final nodes = messagesManager.meshNodes;
        if (nodes.isEmpty) {
          return Center(child: Text(localizations.translate('labels.no_nodes_found')));
        }
        return ListView.builder(
          itemCount: nodes.length,
          itemBuilder: (context, index) {
            return MeshDeviceListItem(nodeID: nodes[index]);
          },
        );
      },
    );
  }
}
