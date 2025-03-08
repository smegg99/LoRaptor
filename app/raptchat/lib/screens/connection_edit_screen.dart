import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:raptchat/localization/localization.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:raptchat/models/connection_element.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_cropper/image_cropper.dart';

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
  String? _avatarPath; // holds the file path of the selected avatar

  AppLocalizations get localizations => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.element?.name ?? '');
    _privateKeyController =
        TextEditingController(text: widget.element?.privateKey ?? '');
    _avatarPath = widget.element?.avatarPath;
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

    final box = Hive.box<ConnectionElement>('connection_elements');
    final existingNames = box.values.map((e) => e.name).toList();

    if (widget.element == null) {
      final resolvedName =
          _resolveNameConflict(_nameController.text, existingNames);

      final newElement = ConnectionElement(
        name: resolvedName,
        order: box.values.length,
        privateKey: _privateKeyController.text,
        avatarPath: _avatarPath,
        ownerNodeID: 0, // TODO: Change this to the reported node ID
        recipientNodeIDs: [],
      );

      await box.add(newElement);
    } else {
      final currentName = widget.element!.name;
      final newName = _nameController.text;

      if (newName != currentName) {
        final resolvedName = _resolveNameConflict(newName, existingNames);
        widget.element!.name = resolvedName;
      }

      widget.element!.privateKey = _privateKeyController.text;
      widget.element!.avatarPath = _avatarPath;

      await widget.element!.save();
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _generatePrivateKey() {
    final key = List<int>.generate(32, (i) => Random.secure().nextInt(256));
    setState(() {
      _privateKeyController.text = base64.encode(key);
    });
  }

  void _showQRCode() {
    final data = jsonEncode({
      'name': _nameController.text,
      'private_key': _privateKeyController.text,
      'avatar_path': _avatarPath,
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Connection QR Code"),
          content: SizedBox(
            width: 200,
            height: 200,
            child: Center(
              child: QrImageView(
                data: data,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        ),
      );
    }
  }

  void _scanQRCode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text("Scan QR Code")),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  final data = jsonDecode(barcode.rawValue!);
                  if (mounted) {
                    setState(() {
                      _nameController.text = data['name'] ?? '';
                      _privateKeyController.text = data['private_key'] ?? '';
                      _avatarPath = data['avatar_path'];
                    });
                    Navigator.pop(context);
                  }
                  break;
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _handleScanQRCode() async {
    bool hasPermission = await Permission.camera.isGranted;
    if (!hasPermission) {
      hasPermission = await _requestCameraPermission();
    }
    if (hasPermission) {
      _scanQRCode();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate(
                'screens.connection_edit.labels.camera_permission_required')),
          ),
        );
      }
    }
  }

  Future<void> _pickAvatarImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (!mounted) return;
      final Color primaryColor = Theme.of(context).primaryColor;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust Avatar',
            cropStyle: CropStyle.circle,
            toolbarColor: primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'Adjust Avatar',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('screens.connection_edit.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _handleScanQRCode,
          ),
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
                      setState(() => _isObscure = !_isObscure);
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
        ],
      ),
    );
  }
}
