// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:raptchat/localization/localization.dart';
import 'package:raptchat/managers/ble_device_manager.dart';
import 'package:raptchat/models/connection_element.dart';
import 'package:raptchat/widgets/custom_navigation_bar.dart';
import 'package:raptchat/screens/home_screen.dart';
import 'package:raptchat/screens/devices_screen.dart';
import 'package:raptchat/screens/mesh_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};

  AppLocalizations get localizations => AppLocalizations.of(context);

  void _handleEdit(ConnectionElement element) {
    Navigator.pushNamed(context, '/edit', arguments: element);
  }

  void _handleCreate() {
    final bleManager = Provider.of<BleDeviceManager>(context, listen: false);
    if (bleManager.connectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)
                .translate('labels.no_device_paired'),
          ),
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/edit', arguments: null);
  }

  void _handleConnect(ConnectionElement element) {
    Navigator.pushNamed(context, '/connect', arguments: element);
  }

  void _toggleSelectionMode(int index) {
    setState(() {
      _isSelectionMode = true;
      _selectedIndices.add(index);
    });
  }

  void _toggleSelectItem(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  Future<void> _deleteSelectedItems(Box<ConnectionElement> box) async {
    final elementsToDelete =
        _selectedIndices.map((index) => box.getAt(index)!).toList();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            localizations.translate('screens.home.labels.delete_selected')),
        content: Text(localizations.translateWithParams(
            'screens.home.labels.delete_selected_confirmation',
            {'amount': _selectedIndices.length.toString()})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.translate('screens.home.labels.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations.translate('screens.home.labels.delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final element in elementsToDelete) {
        await element.delete();
      }
      setState(() {
        _isSelectionMode = false;
        _selectedIndices.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle;
    if (_currentIndex == 0) {
      appBarTitle = _isSelectionMode
          ? localizations.translateWithParams('screens.home.labels.selected',
              {'amount': _selectedIndices.length.toString()})
          : localizations.translate('screens.home.title');
    } else if (_currentIndex == 1) {
      appBarTitle = localizations.translate('screens.devices.title');
    } else {
      appBarTitle = localizations.translate('screens.mesh.title');
    }

    return Scaffold(
      appBar: AppBar(
        title: _currentIndex == 0 && !_isSelectionMode
            ? SvgPicture.asset(
                'assets/logo.svg',
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.inverseSurface,
                  BlendMode.srcIn,
                ),
                height: 40,
              )
            : Text(appBarTitle),
        actions: _currentIndex == 0
            ? _isSelectionMode
                ? [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final box =
                            Hive.box<ConnectionElement>('connection_elements');
                        await _deleteSelectedItems(box);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _isSelectionMode = false;
                            _selectedIndices.clear();
                          });
                        },
                      ),
                    ),
                  ]
                : [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                      ),
                    ),
                  ]
            : null,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onEdit: _handleEdit,
            onConnect: _handleConnect,
            onCreate: _handleCreate,
            isSelectionMode: _isSelectionMode,
            selectedIndices: _selectedIndices,
            onToggleSelectItem: _toggleSelectItem,
            onToggleSelectionMode: _toggleSelectionMode,
          ),
          DevicesScreen(isActive: _currentIndex == 1),
          const MeshScreen(),
        ],
      ),
      floatingActionButton: _currentIndex == 0 && !_isSelectionMode
          ? FloatingActionButton(
              enableFeedback: true,
              shape: const CircleBorder(),
              onPressed: _handleCreate,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            if (_currentIndex != 0) {
              _isSelectionMode = false;
              _selectedIndices.clear();
            }
          });
        },
      ),
    );
  }
}
