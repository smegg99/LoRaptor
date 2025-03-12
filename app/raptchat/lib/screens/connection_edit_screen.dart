// lib/screens/connection_edit_screen.dart
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:raptchat/localization/localization.dart';
import 'package:raptchat/models/connection_element.dart';
import 'package:raptchat/models/connection_recipient.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:raptchat/managers/ble_device_manager.dart';

class ConnectionEditScreen extends StatefulWidget {
  final ConnectionElement? element;
  final Directory appDirectory;

  const ConnectionEditScreen({
    super.key,
    this.element,
    required this.appDirectory,
  });

  @override
  State<ConnectionEditScreen> createState() => _ConnectionEditScreenState();
}

class _ConnectionEditScreenState extends State<ConnectionEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _privateKeyController;
  bool _isObscure = true;
  String? _avatarPath;
  List<ConnectionRecipient> _recipients = [];

  AppLocalizations get localizations => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    // For new connections, the display name is entered by the user.
    // For existing connections, display name is editable; connectionID and key are read-only.
    _nameController = TextEditingController(text: widget.element?.name ?? '');
    _privateKeyController =
        TextEditingController(text: widget.element?.privateKey ?? '');
    _avatarPath = widget.element?.avatarPath;
    if (widget.element != null) {
      _recipients = List.from(widget.element!.recipients);
    } else {
      // When creating a new connection, automatically add a default recipient
      // representing the current device using its custom name.
      final bleManager = Provider.of<BleDeviceManager>(context, listen: false);
      final currentDevice = bleManager.connectedDevice;
      if (currentDevice != null) {
        _recipients.add(ConnectionRecipient(
          customName: currentDevice.displayName,
          nodeId: currentDevice.nodeId,
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _privateKeyController.dispose();
    super.dispose();
  }

  String _resolveNameConflict(String baseName, List<String> existingNames) {
    String newName = baseName;
    int count = 1;
    while (existingNames.contains(newName)) {
      newName = '$baseName ($count)';
      count++;
    }
    return newName;
  }

  String _resolveRecipientNameConflict(String baseName) {
    String newName = baseName;
    int count = 1;
    while (_recipients
        .any((r) => r.customName.toLowerCase() == newName.toLowerCase())) {
      newName = '$baseName ($count)';
      count++;
    }
    return newName;
  }

  Future<void> _editRecipientName(int index) async {
    final currentName = _recipients[index].customName;
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: currentName);
        return AlertDialog(
          title: Text("Edit Recipient Name"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: "Custom Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.pop(context, text);
                }
              },
              child: Text("Save"),
            )
          ],
        );
      },
    );
    if (newName != null && newName.isNotEmpty) {
      final resolvedName = _resolveRecipientNameConflict(newName);
      setState(() {
        _recipients[index].customName = resolvedName;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty || _privateKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate(
              'screens.connection_edit.labels.please_fill_needed_fields')),
        ),
      );
      return;
    }

    // Validate recipients, at least one must exist and not all be the current device.
    final currentNodeID = Provider.of<BleDeviceManager>(context, listen: false)
            .connectedDevice
            ?.nodeId ??
        0;
    if (_recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please add at least one recipient.")));
      return;
    }
    if (_recipients.every((r) => r.nodeId == currentNodeID)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot add only your own device as recipient.")));
      return;
    }

    final box = Hive.box<ConnectionElement>('connection_elements');
    final existingNames = box.values.map((e) => e.name).toList();
    final bleManager = Provider.of<BleDeviceManager>(context, listen: false);

    if (widget.element == null) {
      final resolvedName =
          _resolveNameConflict(_nameController.text, existingNames);
      final newConnectionID = base64
          .encode(List<int>.generate(16, (_) => Random.secure().nextInt(256)));

      final newElement = ConnectionElement(
        connectionID: newConnectionID,
        name: resolvedName,
        order: box.values.length,
        privateKey: _privateKeyController.text,
        avatarPath: _avatarPath,
        ownerNodeID: currentNodeID,
        recipients: _recipients,
      );

      await box.add(newElement);

      final command =
          'create connection -id "$newConnectionID" -k "${_privateKeyController.text}" -r [${_recipients.map((r) => r.nodeId).join(", ")}]';
      bleManager.sendNUSCommand(command);
    } else {
      widget.element!.name = _nameController.text;
      widget.element!.avatarPath = _avatarPath;

      // Compare original recipients with updated list.
      final originalRecipients = widget.element!.recipients;
      final addedRecipients = _recipients
          .where(
              (nr) => !originalRecipients.any((or) => or.nodeId == nr.nodeId))
          .toList();
      final removedRecipients = originalRecipients
          .where((or) => !_recipients.any((nr) => nr.nodeId == or.nodeId))
          .toList();

      widget.element!.recipients = _recipients;
      await widget.element!.save();

      // Allow recipient modifications only if the current device is the owner.
      final allowModification = widget.element!.ownerNodeID == currentNodeID;
      if (allowModification) {
        // For each added recipient (except the default current device), send a create command.
        for (final r in addedRecipients) {
          if (r.nodeId == currentNodeID) continue;
          final cmd =
              'create connectionRecipient -id "${widget.element!.connectionID}" -r "${r.nodeId}"';
          bleManager.sendNUSCommand(cmd);
        }
        // For each removed recipient (except the default current device), send a delete command.
        for (final r in removedRecipients) {
          if (r.nodeId == currentNodeID) continue;
          final cmd =
              'delete connectionRecipient -id "${widget.element!.connectionID}" -r ${r.nodeId}';
          bleManager.sendNUSCommand(cmd);
        }
      }
    }

    Navigator.of(context).pop();
  }

  void _generatePrivateKey() {
    final key = List<int>.generate(32, (i) => Random.secure().nextInt(256));
    setState(() {
      _privateKeyController.text = base64.encode(key);
    });
  }

  Future<void> _pickAvatarImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: localizations.translate('labels.adjust_avatar'),
            cropStyle: CropStyle.circle,
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor:
                Theme.of(context).colorScheme.onPrimaryContainer,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: localizations.translate('labels.adjust_avatar'),
            cropStyle: CropStyle.circle,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            rotateButtonsHidden: true,
          ),
        ],
      );
      if (croppedFile != null) {
        setState(() {
          _avatarPath = croppedFile.path;
        });
      }
    }
  }

  Future<void> _pickRecipientAvatar(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: localizations.translate('labels.adjust_avatar'),
            cropStyle: CropStyle.circle,
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor:
                Theme.of(context).colorScheme.onPrimaryContainer,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: localizations.translate('labels.adjust_avatar'),
            cropStyle: CropStyle.circle,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            rotateButtonsHidden: true,
          ),
        ],
      );
      if (croppedFile != null) {
        setState(() {
          _recipients[index].avatarPath = croppedFile.path;
        });
      }
    }
  }

  Future<void> _addRecipient() async {
    final currentNodeID = Provider.of<BleDeviceManager>(context, listen: false)
            .connectedDevice
            ?.nodeId ??
        0;

    final allowModification = widget.element == null ||
        (widget.element != null &&
            widget.element!.ownerNodeID == currentNodeID);
    if (!allowModification) return;

    final newRecipient = await showDialog<ConnectionRecipient>(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController();
        final TextEditingController nodeIdController = TextEditingController();
        return AlertDialog(
          title: Text(localizations.translate('labels.add_recipient')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                    labelText: localizations.translate('labels.custom_name')),
              ),
              TextField(
                controller: nodeIdController,
                decoration: InputDecoration(
                    labelText: localizations.translate('labels.node_id')),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.translate('labels.cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final customName = nameController.text.trim();
                final nodeId = int.tryParse(nodeIdController.text.trim()) ?? 0;
                if (customName.isEmpty || nodeId == 0) {
                  return;
                }
                if (nodeId == currentNodeID) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations
                          .translate('labels.can_not_add_own_device')),
                    ),
                  );
                  return;
                }
                // Prevent duplicate recipients by node ID.
                if (_recipients.any((r) => r.nodeId == nodeId)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations
                          .translate('labels.recipient_already_added')),
                    ),
                  );
                  return;
                }
                final resolvedName = _resolveRecipientNameConflict(customName);
                Navigator.pop(
                  context,
                  ConnectionRecipient(
                    customName: resolvedName,
                    nodeId: nodeId,
                  ),
                );
              },
              child: Text(localizations.translate('labels.add')),
            ),
          ],
        );
      },
    );
    if (newRecipient != null) {
      setState(() {
        _recipients.add(newRecipient);
      });
    }
  }

  void _removeRecipient(int index) {
    // final removed = _recipients.removeAt(index);
    // final currentNodeID = Provider.of<BleDeviceManager>(context, listen: false)
    //         .connectedDevice
    //         ?.nodeId ??
    //     0;
    // final allowModification = widget.element == null ||
    //     (widget.element != null &&
    //         widget.element!.ownerNodeID == currentNodeID);
    // if (widget.element != null && allowModification) {
    //   final cmd =
    //       'delete connectionRecipient -id "${widget.element!.connectionID}" -r ${removed.nodeId}';
    //   Provider.of<BleDeviceManager>(context, listen: false).sendNUSCommand(cmd);
    // }

    // setState(() {});
    setState(() {
      _recipients.removeAt(index);
    });
  }

  Widget _buildRecipientsSection() {
    final currentNodeID = Provider.of<BleDeviceManager>(context, listen: false)
            .connectedDevice
            ?.nodeId ??
        0;

    final bool allowModification = widget.element == null ||
        (widget.element != null &&
            widget.element!.ownerNodeID == currentNodeID);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.translate('labels.recipients'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...List.generate(_recipients.length, (index) {
          final r = _recipients[index];
          return ListTile(
            leading: GestureDetector(
              onTap: () => _pickRecipientAvatar(index),
              child: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                backgroundImage: r.avatarPath != null
                    ? FileImage(File(r.avatarPath!))
                    : null,
                child: r.avatarPath == null
                    ? Text(
                        r.customName.isNotEmpty
                            ? r.customName[0].toUpperCase()
                            : '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                      )
                    : null,
              ),
            ),
            title: Text(r.customName,
                overflow: TextOverflow.ellipsis, maxLines: 1),
            subtitle: Text(
                "${localizations.translate('labels.node_id')}: ${r.nodeId}",
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
            trailing: allowModification
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (r.nodeId != currentNodeID)
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _removeRecipient(index),
                        ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _editRecipientName(index),
                      ),
                    ],
                  )
                : null,
          );
        }),
        if (allowModification)
          TextButton.icon(
            onPressed: _addRecipient,
            icon: Icon(Icons.add),
            label: Text(localizations.translate('labels.add_recipient')),
          ),
      ],
    );
  }

  void _handleScanQRCode() {
    _scanQRCode();
  }

  void _scanQRCode() {
    // Create a controller for MobileScanner.
    final MobileScannerController scannerController = MobileScannerController();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(localizations.translate('labels.scan_qr_code')),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  scannerController.dispose();
                  Navigator.pop(context);
                },
              )
            ],
          ),
          body: MobileScanner(
            controller: scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  try {
                    final decoded = jsonDecode(barcode.rawValue!);
                    if (decoded is! Map<String, dynamic>) {
                      throw Exception(
                          "QR code does not contain a valid JSON object.");
                    }

                    // Case 1: Full connection data.
                    if (decoded.containsKey('connection_name') &&
                        decoded.containsKey('recipients')) {
                      debugPrint("Scanned full connection QR code: $decoded");
                      setState(() {
                        // Update private key if empty.
                        if (_privateKeyController.text.isEmpty &&
                            decoded.containsKey('private_key')) {
                          _privateKeyController.text =
                              decoded['private_key'] ?? '';
                        }
                        // Update connection name if empty.
                        if (_nameController.text.isEmpty) {
                          _nameController.text =
                              decoded['connection_name'] ?? '';
                        }
                        // Merge recipients.
                        if (decoded['recipients'] is List) {
                          List<dynamic> recData = decoded['recipients'];
                          List<ConnectionRecipient> scannedRecipients = recData
                              .map((e) {
                                if (e is Map<String, dynamic>) {
                                  return ConnectionRecipient(
                                    customName: e['custom_name'] ?? '',
                                    nodeId: e['node_id'] ?? 0,
                                  );
                                }
                                return null;
                              })
                              .whereType<ConnectionRecipient>()
                              .toList();
                          for (var recipient in scannedRecipients) {
                            if (!_recipients
                                .any((r) => r.nodeId == recipient.nodeId)) {
                              _recipients.add(recipient);
                            }
                          }
                        }
                      });
                      debugPrint(
                          "Updated fields: name=${_nameController.text}, privateKey=${_privateKeyController.text}, recipients=$_recipients");
                      // Dispose controller and exit scanner screen.
                      scannerController.dispose();
                      Navigator.pop(context);
                      return;
                    }
                    // Case 2: Recipient-only data.
                    else if (decoded.containsKey('node_id') &&
                        decoded.containsKey('custom_name')) {
                      debugPrint("Scanned recipient-only QR code: $decoded");
                      final int scannedNodeId = decoded['node_id'];
                      final String scannedCustomName =
                          decoded['custom_name'] ?? '';
                      setState(() {
                        if (!_recipients
                            .any((r) => r.nodeId == scannedNodeId)) {
                          _recipients.add(ConnectionRecipient(
                            customName: scannedCustomName,
                            nodeId: scannedNodeId,
                          ));
                        }
                      });
                      debugPrint("Updated recipients: $_recipients");
                      scannerController.dispose();
                      Navigator.pop(context);
                      return;
                    }
                    throw Exception(
                        "QR code does not contain valid connection or recipient data.");
                  } catch (e) {
                    debugPrint("QR Scan Exception: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("QR Scan Error: ${e.toString()}")),
                    );
                    scannerController.dispose();
                    Navigator.pop(context);
                    return;
                  }
                }
              }
            },
          ),
        ),
      ),
    );
  }

  void _showQRCode() {
    final data = jsonEncode({
      'private_key': _privateKeyController.text,
      'connection_id': widget.element?.connectionID ?? '',
      'connection_name': _nameController.text,
      'recipients': _recipients
          .map((r) => {'node_id': r.nodeId, 'custom_name': r.customName})
          .toList(),
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('labels.connection_qr_code')),
        content: SizedBox(
          width: 200,
          height: 200,
          child: Center(
            child: QrImageView(
              backgroundColor: Theme.of(context).colorScheme.primary,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              data: data,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('labels.close')),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickAvatarImage,
        child: DottedBorder(
          borderType: BorderType.Circle,
          dashPattern: [6, 3],
          color: Theme.of(context).colorScheme.primary,
          strokeWidth: 2,
          child: CircleAvatar(
            radius: 64,
            backgroundColor: Colors.transparent,
            backgroundImage:
                _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
            child: _avatarPath == null
                ? const Icon(
                    Icons.add,
                    size: 40,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.element != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('screens.connection_edit.title')),
        actions: [
          // In creation mode, allow scanning a QR code to import connection info.
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _handleScanQRCode,
            ),
          // In edit mode, allow showing the QR code for sharing.
          if (isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.qr_code),
                onPressed: _showQRCode,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAvatarPicker(),
          const SizedBox(height: 16),
          if (isEditing) ...[
            TextField(
              controller:
                  TextEditingController(text: widget.element!.connectionID),
              decoration: InputDecoration(
                labelText: localizations.translate('labels.connection_id'),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller:
                  TextEditingController(text: widget.element!.privateKey),
              decoration: InputDecoration(
                labelText: localizations.translate('labels.encryption_key'),
                suffixIcon: IconButton(
                  icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                ),
              ),
              readOnly: true,
              obscureText: _isObscure,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: localizations.translate('labels.connection_name'),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: localizations.translate('labels.connection_name'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _privateKeyController,
              decoration: InputDecoration(
                labelText: localizations.translate('labels.private_key'),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                          _isObscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.casino),
                      onPressed: _generatePrivateKey,
                    ),
                  ],
                ),
              ),
              obscureText: _isObscure,
            ),
            const SizedBox(height: 16),
          ],
          _buildRecipientsSection(),
        ],
      ),
    );
  }
}
