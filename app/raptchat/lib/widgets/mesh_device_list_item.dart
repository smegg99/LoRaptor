import 'package:flutter/material.dart';

class MeshDeviceListItem extends StatelessWidget {
  final int nodeID;

  const MeshDeviceListItem({
    super.key,
    required this.nodeID,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.hub, color: theme.colorScheme.onPrimary),
      ),
      title: Text(
        nodeID.toString(),
        style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
      ),
    );
  }
}
