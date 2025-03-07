// lib/managers/ble_device_manager.dart
import 'package:flutter/material.dart';
import 'package:raptchat/models/ble_device.dart';

class BleDeviceManager extends ChangeNotifier {
  BleDevice? _connectedDevice;
  final List<BleDevice> _availableDevices = [];

  BleDevice? get connectedDevice => _connectedDevice;
  List<BleDevice> get availableDevices => _availableDevices;

  void addAvailableDevice(BleDevice device) {
    if (!_availableDevices.any((d) => d.nodeId == device.nodeId)) {
      _availableDevices.add(device);
      notifyListeners();
    }
  }

  void clearAvailableDevices() {
    _availableDevices.clear();
    notifyListeners();
  }

  void connectDevice(BleDevice device) {
    _connectedDevice = device;
    notifyListeners();
  }

  void disconnectDevice() {
    _connectedDevice = null;
    notifyListeners();
  }
}
