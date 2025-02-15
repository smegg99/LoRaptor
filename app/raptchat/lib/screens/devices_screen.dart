import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:raptchat/localization/localization.dart';
import 'package:raptchat/models/connection_element.dart';
import 'package:raptchat/widgets/custom_navigation_bar.dart';
import 'package:raptchat/widgets/stream_list_item.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  int _currentIndex = 0;
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};

  AppLocalizations get localizations => AppLocalizations.of(context);

  void _handleEdit(ConnectionElement element) {
    Navigator.pushNamed(context, '/edit', arguments: element);
  }

  void _handleCreate() {
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
      for (var element in elementsToDelete) {
        await element.delete();
      }
      setState(() {
        _isSelectionMode = false;
        _selectedIndices.clear();
      });
    }
  }

  // Build the Connections page.
  Widget _buildConnectionsPage() {
    return ValueListenableBuilder<Box<ConnectionElement>>(
      valueListenable: Hive.box<ConnectionElement>('connection_elements').listenable(),
      builder: (context, box, _) {
        final elements = box.values.toList().cast<ConnectionElement>();
        elements.sort((a, b) => a.order.compareTo(b.order));

        if (elements.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image_not_supported,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(localizations
                    .translate('screens.home.labels.no_connections')),
              ],
            ),
          );
        }

        return ReorderableListView(
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) async {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final element = elements.removeAt(oldIndex);
              elements.insert(newIndex, element);
              for (int i = 0; i < elements.length; i++) {
                elements[i].order = i;
              }
            });
            // Persist updated order to Hive after reordering.
            Future.delayed(const Duration(milliseconds: 300), () async {
              for (final element in elements) {
                await element.save();
              }
            });
          },
          children: List.generate(
            elements.length,
            (index) {
              final element = elements[index];
              final isSelected = _selectedIndices.contains(index);
              return StreamListItem(
                key: ValueKey(element.key ?? element.name ?? index),
                element: element,
                isSelected: isSelected,
                isSelectionMode: _isSelectionMode,
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelectItem(index);
                  }
                },
                onEdit: () => _handleEdit(element),
                onConnect: () => _handleConnect(element),
                onLongPress: () => _toggleSelectionMode(index),
                onCheckboxChanged: (value) => _toggleSelectItem(index),
              );
            },
          ),
        );
      },
    );
  }

  // Stub for the Devices page.
  Widget _buildDevicesPage() {
    return Center(
      child: Text(localizations.translate('screens.devices.title')),
    );
  }

  // Stub for the Mesh page.
  Widget _buildMeshPage() {
    return Center(
      child: Text(localizations.translate('screens.mesh.title')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set the AppBar title based on the current tab and selection mode.
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
        title: Text(appBarTitle),
        actions: _currentIndex == 0 && _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final box = Hive.box<ConnectionElement>('connection_elements');
                    await _deleteSelectedItems(box);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedIndices.clear();
                    });
                  },
                ),
              ]
            : null,
      ),
      // Use an IndexedStack so that each page’s state is maintained.
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildConnectionsPage(),
          _buildDevicesPage(),
          _buildMeshPage(),
        ],
      ),
      floatingActionButton: _currentIndex == 0 && !_isSelectionMode
          ? FloatingActionButton(
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
