// lib/pages/connections_page.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:raptchat/localization/localization.dart';
import 'package:raptchat/models/connection_element.dart';
import 'package:raptchat/widgets/stream_list_item.dart';

class ConnectionsScreen extends StatefulWidget {
  final Function(ConnectionElement) onEdit;
  final Function(ConnectionElement) onConnect;
  final VoidCallback onCreate;
  final bool isSelectionMode;
  final Set<int> selectedIndices;
  final Function(int) onToggleSelectItem;
  final Function(int) onToggleSelectionMode;

  const ConnectionsScreen({
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
  State<ConnectionsScreen> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsScreen> {
  AppLocalizations get localizations => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<ConnectionElement>>(
      valueListenable:
          Hive.box<ConnectionElement>('connection_elements').listenable(),
      builder: (context, box, _) {
        final elements = box.values.toList().cast<ConnectionElement>();
        elements.sort((a, b) => a.order.compareTo(b.order));

        if (elements.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speaker_notes_off,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(localizations.translate('labels.no_connections')),
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
            // Delay saving to allow animation to complete
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
              final isSelected = widget.selectedIndices.contains(index);
              return StreamListItem(
                key: ValueKey(element.key ?? element.name ?? index),
                element: element,
                isSelected: isSelected,
                isSelectionMode: widget.isSelectionMode,
                onTap: () {
                  if (widget.isSelectionMode) {
                    widget.onToggleSelectItem(index);
                  }
                },
                onEdit: () => widget.onEdit(element),
                onConnect: () => widget.onConnect(element),
                onLongPress: () => widget.onToggleSelectionMode(index),
                onCheckboxChanged: (value) => widget.onToggleSelectItem(index),
              );
            },
          ),
        );
      },
    );
  }
}
