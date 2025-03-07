// lib/screens/devices_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raptchat/localization/localization.dart';
import 'package:raptchat/models/ble_device.dart';
import 'package:raptchat/widgets/ble_device_list_item.dart';
import 'package:raptchat/managers/ble_device_manager.dart';

class DevicesScreen extends StatefulWidget {
  final bool isActive;
  const DevicesScreen({super.key, required this.isActive});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  bool _isBottomSheetDisplayed = false;

  void _showConnectedDevice(BuildContext context, BleDevice device) {
    _isBottomSheetDisplayed = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return FractionallySizedBox(
          widthFactor: 1.0,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            minChildSize: 0.3,
            maxChildSize: 0.75,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TODO: Replace this with your LoRaptor PCB vector if available.
                      Icon(
                        Icons.bluetooth_connected,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        device.displayName,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      Text('Node ID: ${device.nodeId}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Provider.of<BleDeviceManager>(context, listen: false)
                              .disconnectDevice();
                          Navigator.pop(context);
                        },
                        child: Text(
                          AppLocalizations.of(context)
                                  .translate('devices.disconnect'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      _isBottomSheetDisplayed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BleDeviceManager>(
      builder: (context, manager, child) {
        return ListView.builder(
          itemCount: manager.availableDevices.length,
          itemBuilder: (context, index) {
            final device = manager.availableDevices[index];
            return BleDeviceListItem(
              device: device,
              onTap: () {
                Provider.of<BleDeviceManager>(context, listen: false)
                    .connectDevice(device);
                if (widget.isActive && !_isBottomSheetDisplayed) {
                  _showConnectedDevice(context, device);
                }
              },
            );
          },
        );
      },
    );
  }
}
