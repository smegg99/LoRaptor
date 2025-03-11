// lib/screens/devices_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raptchat/localization/localization.dart';
import 'package:raptchat/models/ble_device.dart';
import 'package:raptchat/widgets/ble_device_list_item.dart';
import 'package:raptchat/managers/ble_device_manager.dart';
import 'package:hive/hive.dart';

class DevicesScreen extends StatefulWidget {
  final bool isActive;
  const DevicesScreen({super.key, required this.isActive});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  Timer? _scanTimer;
  bool _isBottomSheetDisplayed = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _startPeriodicScan();
    }
  }

  @override
  void didUpdateWidget(covariant DevicesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _startPeriodicScan();
    } else if (oldWidget.isActive && !widget.isActive) {
      _cancelPeriodicScan();
    }
  }

  void _startPeriodicScan() {
    Provider.of<BleDeviceManager>(context, listen: false).startScan();
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      Provider.of<BleDeviceManager>(context, listen: false).startScan();
    });
  }

  void _cancelPeriodicScan() {
    _scanTimer?.cancel();
    _scanTimer = null;
  }

  @override
  void dispose() {
    _cancelPeriodicScan();
    Provider.of<BleDeviceManager>(context, listen: false).stopScan();
    super.dispose();
  }

  void _showConnectedDevice(BuildContext context, BleDevice device) {
    _isBottomSheetDisplayed = true;
    final TextEditingController _customNameController =
        TextEditingController(text: device.displayName);
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
                      Icon(
                        Icons.bluetooth_connected,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                        ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _customNameController,
                        builder: (context, value, child) {
                          return Text(
                          device.displayName,
                          style: Theme.of(context).textTheme.headlineLarge,
                          );
                        },
                        ),
                      Text('Node ID: ${device.nodeId}'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _customNameController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)
                              .translate('labels.custom_name'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final box = await Hive.openBox<String>(
                                'saved_ble_devices');
                              final newName = _customNameController.text.trim();
                              if (newName.isNotEmpty) {
                              await box.put(device.macAddress, newName);
                              setState(() {
                                device.displayName = newName;
                              });
                              }
                            },
                            child: Text(AppLocalizations.of(context)
                                .translate('labels.save_name')),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final box = await Hive.openBox<String>(
                                  'saved_ble_devices');
                              await box.delete(device.macAddress);
                              setState(() {
                                device.displayName = device.originalName;
                              });
                            },
                            child: Text(AppLocalizations.of(context)
                                .translate('labels.forget_name')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Provider.of<BleDeviceManager>(context, listen: false)
                              .disconnectDevice();
                          Navigator.pop(context);
                        },
                        child: Text(AppLocalizations.of(context)
                            .translate('labels.disconnect')),
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
        if (!manager.bluetoothEnabled) {
          if (manager.availableDevices.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              manager.clearAvailableDevices();
            });
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bluetooth_disabled,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)
                    .translate('labels.bluetooth_disabled')),
              ],
            ),
          );
        }
        return Column(
          children: [
            if (manager.isScanning)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)
                        .translate('labels.scanning')),
                  ],
                ),
              ),
            Expanded(
              child: manager.availableDevices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(AppLocalizations.of(context)
                              .translate('labels.no_devices')),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: manager.availableDevices.length,
                      itemBuilder: (context, index) {
                        final device = manager.availableDevices[index];
                        final isConnecting =
                            manager.connectingDeviceMac == device.macAddress;
                        // Mark as error if this device was last connected, currently not connected, and has an error flag.
                        final connectionError =
                            (manager.lastConnectedDeviceMac ==
                                    device.macAddress &&
                                manager.connectedDevice == null &&
                                manager.hasConnectionError(device.macAddress));
                        final isConnected =
                            manager.connectedDevice?.macAddress ==
                                device.macAddress;
                        final isSaved =
                            device.displayName != device.originalName;
                        return BleDeviceListItem(
                          device: device,
                          isConnecting: isConnecting,
                          isConnected: isConnected,
                          isSaved: isSaved,
                          connectionError: connectionError,
                          onTap: () {
                            Provider.of<BleDeviceManager>(context,
                                    listen: false)
                                .connectToDevice(device);
                            if (widget.isActive && !_isBottomSheetDisplayed) {
                              _showConnectedDevice(context, device);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
