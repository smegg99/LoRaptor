import 'package:flutter/material.dart';
import 'package:raptchat/models/ble_device.dart';

class BleDeviceListItem extends StatelessWidget {
  final BleDevice device;
  final VoidCallback onTap;

  const BleDeviceListItem({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.bluetooth, color: Colors.white),
      ),
      title: Text(device.displayName),
      subtitle: Text('Node ID: ${device.nodeId}'),
      onTap: onTap,
    );
  }
}
