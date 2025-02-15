// lib/widgets/stream_list_item.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raptchat/models/connection_element.dart';

class StreamListItem extends StatefulWidget {
  final ConnectionElement element;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onConnect;
  final VoidCallback onLongPress;
  final ValueChanged<bool?> onCheckboxChanged;

  const StreamListItem({
    super.key,
    required this.element,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onEdit,
    required this.onConnect,
    required this.onLongPress,
    required this.onCheckboxChanged,
  });

  @override
  State<StreamListItem> createState() => _StreamListItemState();
}

class _StreamListItemState extends State<StreamListItem> {
  ThemeData get theme => Theme.of(context);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onDoubleTap: widget.onConnect,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.element.name,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            if (widget.isSelectionMode)
              Row(
                children: [
                  Checkbox(
                      value: widget.isSelected,
                      onChanged: widget.onCheckboxChanged),
                ],
              )
            else
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                    onPressed: widget.onEdit,
                  ),
                  IconButton(
                    icon: Icon(Icons.link, color: theme.colorScheme.secondary),
                    onPressed: widget.onConnect,
                  ),
                  ReorderableDragStartListener(
                    index: widget.element.order,
                    child: GestureDetector(
                      onTapDown: (_) => HapticFeedback.lightImpact(),
                      child: Icon(Icons.drag_indicator,
                          color: theme.colorScheme.tertiary),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
