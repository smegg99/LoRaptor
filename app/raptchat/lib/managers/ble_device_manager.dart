// lib/managers/ble_device_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:raptchat/models/ble_device.dart';
import 'package:hive/hive.dart';
import 'package:raptchat/cli/raptor_cli.dart';
import 'package:raptchat/models/connection_element.dart';

class BleDeviceManager extends ChangeNotifier {
  BleDevice? _connectedDevice;
  final List<BleDevice> _availableDevices = [];
  bool _isScanning = false;
  bool _bluetoothEnabled = true;
  // Map storing BluetoothDevice instances keyed by MAC address.
  final Map<String, BluetoothDevice> _deviceMap = {};

  // Field to track which device is currently connecting.
  String? _connectingDeviceMac;

  // Field to track the last connected device's MAC address.
  String? _lastConnectedDeviceMac;
  String? get lastConnectedDeviceMac => _lastConnectedDeviceMac;

  // Map to track connection errors by MAC address.
  final Map<String, bool> _connectionErrors = {};
  bool hasConnectionError(String mac) => _connectionErrors[mac] ?? false;

  // Flag to indicate if disconnect was manual.
  bool _manualDisconnect = false;

  // Flag to ensure startup commands run only once per connection.
  bool _startupExecuted = false;

  // Heartbeat fields, not used for now.
  Timer? _heartbeatTimer;
  // final Duration _heartbeatInterval = Duration(seconds: 10);
  // final Duration _heartbeatTimeout = Duration(seconds: 7);

  Dispatcher? _cliDispatcher;
  BluetoothCharacteristic? _nusRxChar;

  final StreamController<String> _nusDataController =
      StreamController<String>.broadcast();
  Stream<String> get nusDataStream => _nusDataController.stream;

  bool get isScanning => _isScanning;
  bool get bluetoothEnabled => _bluetoothEnabled;
  BleDevice? get connectedDevice => _connectedDevice;
  List<BleDevice> get availableDevices => _availableDevices;
  String? get connectingDeviceMac => _connectingDeviceMac;

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
    _manualDisconnect = false;
    _startupExecuted = false; // Reset startup flag for new connection.
    _connectingDeviceMac = device.macAddress;
    notifyListeners();

    try {
      final bluetoothDevice = _deviceMap[device.macAddress];
      if (bluetoothDevice == null) throw Exception("Device not found in map");
      await bluetoothDevice.connect(autoConnect: false);
      _connectedDevice = device;
      _lastConnectedDeviceMac = device.macAddress;
      _connectionErrors[device.macAddress] = false;
      _availableDevices.removeWhere((d) => d.macAddress == device.macAddress);
      _availableDevices.insert(0, device);
      await _establishNUSCommunication(device, bluetoothDevice);
      if (!_startupExecuted) {
        await executeDeviceSetupCommands({});
        _startupExecuted = true;
      }
      // _startHeartbeat();
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
      if (bluetoothDevice != null) {
        try {
          _manualDisconnect = true;
          final currentState = await bluetoothDevice.connectionState.first;
          if (currentState == BluetoothConnectionState.connected) {
            await bluetoothDevice.disconnect();
          } else {
            print("Device already disconnected (state: $currentState)");
          }
        } catch (e) {
          print("Error disconnecting: $e");
        }
      }
    }
    _stopHeartbeat();
    _connectedDevice = null;
    notifyListeners();
    Future.delayed(Duration(milliseconds: 100), () {
      _manualDisconnect = false;
    });
  }

  Future<bool> _checkPermissions() async {
    final locationStatus = await Permission.location.request();
    final bluetoothScanStatus = await Permission.bluetoothScan.request();
    final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
    return locationStatus.isGranted &&
        bluetoothScanStatus.isGranted &&
        bluetoothConnectStatus.isGranted;
  }

  // TODO: Change the timeout to a more reasonable value.
  void startScan({Duration timeout = const Duration(seconds: 1)}) async {
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

  Future<void> _establishNUSCommunication(
      BleDevice device, BluetoothDevice bluetoothDevice) async {
    print("Establishing NUS communication...");
    List<BluetoothService> services = await bluetoothDevice.discoverServices();
    BluetoothService? nusService;
    for (BluetoothService service in services) {
      if (service.uuid.toString().toLowerCase() ==
          "6e400001-b5a3-f393-e0a9-e50e24dcca9e") {
        nusService = service;
        break;
      }
    }
    if (nusService == null) {
      print("NUS service not found");
      return;
    }
    BluetoothCharacteristic? txChar;
    BluetoothCharacteristic? rxChar;
    for (BluetoothCharacteristic char in nusService.characteristics) {
      String uuid = char.uuid.toString().toLowerCase();
      if (uuid == "6e400003-b5a3-f393-e0a9-e50e24dcca9e") {
        txChar = char;
      } else if (uuid == "6e400002-b5a3-f393-e0a9-e50e24dcca9e") {
        rxChar = char;
      }
    }

    if (txChar == null || rxChar == null) {
      print("NUS characteristics not found");
      return;
    }
    _nusRxChar = rxChar;

    // Always write with response.
    await txChar.setNotifyValue(true);
    txChar.lastValueStream.listen((data) {
      String received = String.fromCharCodes(data);
      print("Raw NUS data received: '$received'");
      print("Code units: $data");
      String cleaned = received.trim();
      print("Cleaned data: '$cleaned'");
      if (cleaned.isEmpty) return;
      _cliDispatcher?.dispatch(cleaned);
      _nusDataController.add(cleaned);
    });

    // Listen for connection state changes.
    bluetoothDevice.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        if (!_manualDisconnect &&
            _connectedDevice?.macAddress == device.macAddress) {
          print("Device ${device.displayName} disconnected unexpectedly.");
          _connectionErrors[device.macAddress] = true;
          _connectedDevice = null;
          _attemptReconnect(bluetoothDevice, device);
        } else {
          print("Device ${device.displayName} disconnected manually.");
          _connectionErrors[device.macAddress] = false;
        }
        notifyListeners();
      }
    });

    _cliDispatcher = Dispatcher();
    _cliDispatcher!.registerOutput(_NUSCLIOutput(rxChar));
    _cliDispatcher!.registerCommand(Command(
      name: "ready",
      description: "Device is ready",
      callback: (cmd) async {
        print("NUS: Device is ready. Sending 'get nodeID' command...");
        await sendNUSCommand("get nodeID");
      },
    ));

    // Register an error command that ignores "error.conn.exists" so as not to trigger multiple startups.
    _cliDispatcher!.registerCommand(Command(
      name: "error",
      description: "Error command from device",
      callback: (cmd) {
        if (cmd.arguments.any((arg) => arg.name == "m")) {
          final argM = cmd.arguments.firstWhere((arg) => arg.name == "m");
          String errorMsg = argM.values.first.toString();
          if (errorMsg.contains("error.conn.exists")) {
            print("Ignoring error.conn.exists: connection already exists.");
            _startupExecuted = true;
          } else {
            print("NUS error: $errorMsg");
          }
        }
      },
    ));

    final returnCommand = Command(
      name: "return",
      description: "Return command from device",
      callback: (cmd) {
        final argV = cmd.arguments.firstWhere((arg) => arg.name == "v");
        final valueStr = argV.values.first.toString().replaceAll('"', '');
        final nodeId = int.tryParse(valueStr);
        if (nodeId != null) {
          print("NUS: Received node ID: $nodeId");
        } else {
          print("NUS: Received message: $valueStr");
        }
      },
    );

    returnCommand.addArgSpec(ArgSpec("v", ValueType.stringType,
        required: true, helpText: "Value from device"));

    _cliDispatcher!.registerCommand(returnCommand);
    _cliDispatcher?.registerErrorCallback((error) {
      print("Error: $error");
    });
  }

  Future<void> _attemptReconnect(
      BluetoothDevice bluetoothDevice, BleDevice device) async {
    print("Attempting to reconnect to ${device.displayName}...");
    await Future.delayed(Duration(seconds: 3));
    try {
      await bluetoothDevice.connect(autoConnect: false);
      _connectedDevice = device;
      _lastConnectedDeviceMac = device.macAddress;
      _connectionErrors[device.macAddress] = false;
      _startupExecuted =
          false; // Reset startup flag so that startup commands run on reconnection.
      await _establishNUSCommunication(device, bluetoothDevice);
      if (!_startupExecuted) {
        await executeDeviceSetupCommands({});
        _startupExecuted = true;
      }
      // _startHeartbeat();
      notifyListeners();
      print("Reconnection successful for ${device.displayName}");
    } catch (e) {
      print("Reconnection failed for ${device.displayName}: $e");
      _connectionErrors[device.macAddress] = true;
      notifyListeners();
    }
  }

  /// Starts a heartbeat timer to periodically ping the device.
  // void _startHeartbeat() {
  //   _heartbeatTimer?.cancel();
  //   _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
  //     if (_connectedDevice != null) {
  //       try {
  //         await sendNUSCommand("ping");
  //         final response = await nusDataStream
  //             .firstWhere((data) => data.trim() == 'return -v "pong"')
  //             .timeout(_heartbeatTimeout);
  //         print("Heartbeat received: $response");
  //       } catch (e) {
  //         print("Heartbeat timeout or error: $e");
  //         if (_connectedDevice != null) {
  //           _connectionErrors[_connectedDevice!.macAddress] = true;
  //           if (!_manualDisconnect) {
  //             final device = _connectedDevice!;
  //             final bluetoothDevice = _deviceMap[device.macAddress];
  //             if (bluetoothDevice != null) {
  //               await _attemptReconnect(bluetoothDevice, device);
  //             }
  //           }
  //         }
  //       }
  //     }
  //   });
  // }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> sendNUSCommand(String command) async {
    if (_nusRxChar == null) {
      print("Cannot send command: NUS RX characteristic not available");
      return;
    }
    List<int> bytes = command.codeUnits;
    try {
      await _nusRxChar!.write(bytes, withoutResponse: false);
      print("Sent over NUS (with response): $command");
    } catch (e) {
      print("Error sending command: $e");
    }
  }

  // Executes startup commands only once per connection:
  // 1. Sets the RTC using the current epoch (in seconds).
  // 2. For each saved connection (owned by the current device), sends a create connection command.
  // TODO: 3. Make so it periodically updates saved location. 
  Future<void> executeDeviceSetupCommands(Map<String, dynamic> settings) async {
    if (_nusRxChar == null) {
      print(
          "NUS communication not established, cannot execute device setup commands.");
      return;
    }
    if (_startupExecuted) {
      print("Startup commands have already been executed for this connection.");
      return;
    }
    print("Executing device setup commands...");
    int epochSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await sendNUSCommand('set rtc -t $epochSeconds');
    await Future.delayed(Duration(milliseconds: 200));
    final currentNodeID = _connectedDevice?.nodeId;
    if (currentNodeID != null) {
      final box = await Hive.openBox<ConnectionElement>('connection_elements');
      final connections =
          box.values.where((c) => c.ownerNodeID == currentNodeID);
      for (var connection in connections) {
        String recipientsList = connection.recipients.map((r) => r.nodeId.toString()).join(", ");
        final cmd =
            'create connection -id "${connection.connectionID}" -k "${connection.privateKey}" -r [$recipientsList]';
        await sendNUSCommand(cmd);
        await Future.delayed(Duration(milliseconds: 200));
      }
    }
    _startupExecuted = true;
    print("Device setup commands executed.");
  }

  Future<String> readNextNUSData() async {
    return await nusDataStream.first;
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _nusDataController.close();
    super.dispose();
  }
}

class _NUSCLIOutput implements CLIOutput {
  final BluetoothCharacteristic rxChar;
  _NUSCLIOutput(this.rxChar);
  @override
  void print(String s) {
    rxChar.write(s.codeUnits, withoutResponse: true);
  }

  @override
  void println(String s) {
    print("$s\n");
  }

  @override
  void printlnEmpty() {
    print("\n");
  }
}
