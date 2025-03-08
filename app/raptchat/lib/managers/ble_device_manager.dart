// lib/managers/ble_device_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:raptchat/models/ble_device.dart';
import 'package:hive/hive.dart';

class BleDeviceManager extends ChangeNotifier {
  BleDevice? _connectedDevice;
  final List<BleDevice> _availableDevices = [];
  bool _isScanning = false;
  bool _bluetoothEnabled = true;
  // Map to store FlutterBluePlus BluetoothDevice instances keyed by MAC address.
  final Map<String, BluetoothDevice> _deviceMap = {};

  // Field to track which device is currently connecting.
  String? _connectingDeviceMac;

  bool get isScanning => _isScanning;
  bool get bluetoothEnabled => _bluetoothEnabled;
  BleDevice? get connectedDevice => _connectedDevice;
  List<BleDevice> get availableDevices => _availableDevices;
  String? get connectingDeviceMac => _connectingDeviceMac;

  /// Adds a new device if its MAC address isn’t already in the list.
  /// If it exists, update its lastSeen timestamp.
  void addAvailableDevice(BleDevice device) {
    final index =
        _availableDevices.indexWhere((d) => d.macAddress == device.macAddress);
    if (index == -1) {
      _availableDevices.add(device);
    } else {
      _availableDevices[index].lastSeen = DateTime.now();
    }
    notifyListeners();
  }

  void clearAvailableDevices() {
    _availableDevices.clear();
    notifyListeners();
  }

  Future<void> connectToDevice(BleDevice device) async {
    if (_connectedDevice != null &&
        _connectedDevice!.macAddress != device.macAddress) {
      await disconnectDevice();
    }

    _connectingDeviceMac = device.macAddress;
    notifyListeners();

    try {
      final bluetoothDevice = _deviceMap[device.macAddress];
      if (bluetoothDevice == null) {
        throw Exception("Device not found in map");
      }
      await bluetoothDevice.connect(autoConnect: false);
      _connectedDevice = device;
      _availableDevices.removeWhere((d) => d.macAddress == device.macAddress);
      _availableDevices.insert(0, device);
    } catch (e) {
      print("Connection failed: $e");
    } finally {
      _connectingDeviceMac = null;
      notifyListeners();
    }
  }

  Future<void> disconnectDevice() async {
    if (_connectedDevice != null) {
      final bluetoothDevice = _deviceMap[_connectedDevice!.macAddress];
      try {
        await bluetoothDevice?.disconnect();
      } catch (e) {
        print("Error disconnecting: $e");
      }
    }
    _connectedDevice = null;
    notifyListeners();
  }

  Future<bool> _checkPermissions() async {
    final locationStatus = await Permission.location.request();
    final bluetoothScanStatus = await Permission.bluetoothScan.request();
    final bluetoothConnectStatus = await Permission.bluetoothConnect.request();

    return locationStatus.isGranted &&
        bluetoothScanStatus.isGranted &&
        bluetoothConnectStatus.isGranted;
  }

  void startScan({Duration timeout = const Duration(seconds: 3)}) async {
    if (_isScanning) return;

    if (!await _checkPermissions()) {
      print('BLE permissions not granted');
      return;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      try {
        await FlutterBluePlus.turnOn();
        final newState = await FlutterBluePlus.adapterState.first;
        if (newState != BluetoothAdapterState.on) {
          _bluetoothEnabled = false;
          notifyListeners();
          print('Bluetooth is disabled by user.');
          return;
        }
        _bluetoothEnabled = true;
      } catch (e) {
        _bluetoothEnabled = false;
        notifyListeners();
        print('Failed to enable Bluetooth: $e');
        return;
      }
    } else {
      _bluetoothEnabled = true;
    }

    _isScanning = true;
    notifyListeners();

    print('Starting BLE scan for ${timeout.inSeconds} seconds...');

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (var scanResult in results) {
        final device = scanResult.device;
        _deviceMap[device.remoteId.toString()] = device;

        final advertisementData = scanResult.advertisementData;
        String advName = advertisementData.advName;
        String deviceName = advName.isNotEmpty ? advName : device.platformName;
        bool isLoRaptorName = deviceName.startsWith("LoRaptor");

        if (isLoRaptorName) {
          // Extract node id from "LoRaptor (%d)" format.
          final regex = RegExp(r"LoRaptor\s*\((\d+)\)");
          final match = regex.firstMatch(deviceName);
          int parsedNodeId = match != null
              ? int.tryParse(match.group(1)!) ?? device.remoteId.hashCode
              : device.remoteId.hashCode;

          final bleDevice = BleDevice(
            originalName:
                deviceName.isNotEmpty ? deviceName : device.remoteId.toString(),
            nodeId: parsedNodeId,
            macAddress: device.remoteId.toString(),
            lastSeen: DateTime.now(),
          );

          // Check if a custom name was saved for this device.
          Hive.openBox<String>('saved_ble_devices').then((box) {
            if (box.containsKey(bleDevice.macAddress)) {
              bleDevice.displayName = box.get(bleDevice.macAddress)!;
            }
            addAvailableDevice(bleDevice);
            print(
                'Found device: ${bleDevice.displayName} (MAC: ${bleDevice.macAddress})');
          });
        }
      }
    }, onError: (error) {
      print('Scan error: $error');
    });

    FlutterBluePlus.startScan(
      timeout: timeout,
      oneByOne: true,
      continuousUpdates: true,
      androidScanMode: AndroidScanMode.lowLatency,
    );

    FlutterBluePlus.isScanning
        .where((scanning) => scanning == false)
        .first
        .then((_) {
      stopScan();
    });
  }

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  void stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    notifyListeners();
  }
}
