// lib/widgets/connection_list_item.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raptchat/models/connection_element.dart';

class ConnectionListItem extends StatefulWidget {
  final ConnectionElement element;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool?> onCheckboxChanged;

  const ConnectionListItem({
    super.key,
    required this.element,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onCheckboxChanged,
  });

  @override
  State<ConnectionListItem> createState() => _ConnectionListItemState();
}

class _ConnectionListItemState extends State<ConnectionListItem> {
  ThemeData get theme => Theme.of(context);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onLongPress();
      },
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: theme.colorScheme.onSurfaceVariant,
                backgroundImage: widget.element.avatarPath != null
                    ? FileImage(File(widget.element.avatarPath!))
                    : null,
                child: widget.element.avatarPath == null
                    ? Text(
                        widget.element.name.isNotEmpty
                            ? widget.element.name[0].toUpperCase()
                            : '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onInverseSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      )
                    : null,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.element.name,
                    style: theme.textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    // TODO: Replace with last message.
                    widget.element.privateKey.substring(
                        0,
                        widget.element.privateKey.length > 20
                            ? 20
                            : widget.element.privateKey.length),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: theme.colorScheme.onSurfaceVariant
                          .withAlpha((0.7 * 255).round()),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            // Selection checkbox.
            if (widget.isSelectionMode)
              Checkbox(
                value: widget.isSelected,
                onChanged: widget.onCheckboxChanged,
              ),
          ],
        ),
      ),
    );
  }
}
