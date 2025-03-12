import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:raptchat/localization/localization.dart';
import 'package:raptchat/models/connection_element.dart';
import 'package:raptchat/widgets/connection_list_item.dart';
import 'package:raptchat/managers/ble_device_manager.dart';
import 'package:raptchat/managers/messages_manager.dart';

class HomeScreen extends StatefulWidget {
  final Function(ConnectionElement) onEdit;
  final Function(ConnectionElement) onConnect;
  final VoidCallback onCreate;
  final bool isSelectionMode;
  final Set<int> selectedIndices;
  final Function(int) onToggleSelectItem;
  final Function(int) onToggleSelectionMode;

  const HomeScreen({
    super.key,
    required this.onEdit,
    required this.onConnect,
    required this.onCreate,
    required this.isSelectionMode,
    required this.selectedIndices,
    required this.onToggleSelectItem,
    required this.onToggleSelectionMode,
  });

  @override
  State<HomeScreen> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<HomeScreen> {
  AppLocalizations get localizations => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    final bleManager = Provider.of<BleDeviceManager>(context);
    final currentNodeID = bleManager.connectedDevice?.nodeId;
    return ValueListenableBuilder<Box<ConnectionElement>>(
      valueListenable:
          Hive.box<ConnectionElement>('connection_elements').listenable(),
      builder: (context, box, _) {
        final elements = box.values.toList().cast<ConnectionElement>();
        // Sort connections with matching owner node appear on top.
        elements.sort((a, b) {
          bool aActive =
              currentNodeID != null && a.ownerNodeID == currentNodeID;
          bool bActive =
              currentNodeID != null && b.ownerNodeID == currentNodeID;
          if (aActive && !bActive) {
            return -1;
          } else if (!aActive && bActive) {
            return 1;
          } else {
            return a.order.compareTo(b.order);
          }
        });

        if (elements.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speaker_notes_off, size: 64, color: Theme.of(context).colorScheme.onSurface),
                const SizedBox(height: 16),
                Text(localizations.translate('labels.no_connections')),
              ],
            ),
          );
        }

        return ReorderableListView(
          padding: const EdgeInsets.only(
            top: 8.0,
            bottom: kToolbarHeight,
          ),
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
            Future.delayed(const Duration(milliseconds: 300), () async {
              for (final element in elements) {
                await element.save();
              }
            });
          },
          children: List.generate(elements.length, (index) {
            final element = elements[index];
            final isSelected = widget.selectedIndices.contains(index);
            final isActive =
                currentNodeID != null && element.ownerNodeID == currentNodeID;
            // Wrap the connection list item inside a Consumer with a key.
            return Consumer<MessagesManager>(
              key: ValueKey(element.connectionID),
              builder: (context, messagesManager, _) {
                final lastMsg =
                    messagesManager.getLastMessage(element.connectionID);
                return ConnectionListItem(
                  element: element,
                  isActive: isActive,
                  isSelected: isSelected,
                  isSelectionMode: widget.isSelectionMode,
                  onTap: () {
                    Navigator.pushNamed(context, '/chat', arguments: element);
                  },
                  onLongPress: () => widget.onToggleSelectionMode(index),
                  onCheckboxChanged: (value) =>
                      widget.onToggleSelectItem(index),
                  lastMessage: lastMsg,
                );
              },
            );
          }),
        );
      },
    );
  }
}
