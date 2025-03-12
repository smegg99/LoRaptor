import 'package:flutter/material.dart';
import 'package:raptchat/models/ble_device.dart';

class BleDeviceListItem extends StatelessWidget {
  final BleDevice device;
  final VoidCallback onTap;
  final bool isConnecting;
  final bool isConnected;
  final bool isSaved;
  final bool connectionError;

  const BleDeviceListItem({
    super.key,
    required this.device,
    required this.onTap,
    this.isConnecting = false,
    this.isConnected = false,
    this.isSaved = false,
    this.connectionError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color? tileColor;
    Widget? trailingIcon;

    if (connectionError) {
      tileColor = Theme.of(context).colorScheme.errorContainer;
      trailingIcon = Icon(Icons.error, color: Theme.of(context).colorScheme.error);
    } else if (isConnected) {
      tileColor = theme.colorScheme.primaryContainer;
      trailingIcon = Icon(Icons.check, color: theme.colorScheme.secondary);
    } else if (isConnecting) {
      trailingIcon = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.secondary,
        ),
      );
    }

    return ListTile(
      tileColor: tileColor,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary,
        child: isSaved
            ? Icon(Icons.star, color: theme.colorScheme.onPrimary)
            : Icon(Icons.bluetooth, color: theme.colorScheme.onPrimary),
      ),
      title: Text(device.displayName, style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
      subtitle: Text('MAC: ${device.macAddress}'),
      trailing: trailingIcon,
      onTap: onTap,
    );
  }
}
