// lib/widgets/connection_list_item.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raptchat/models/connection_element.dart';
import 'package:raptchat/models/connection_recipient.dart';

class ConnectionListItem extends StatefulWidget {
  final ConnectionElement element;
  final bool isActive; // true if connection belongs to the current LoRaptor
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool?> onCheckboxChanged;
  final String? lastMessage; // Optional last message to display

  const ConnectionListItem({
    super.key,
    required this.element,
    required this.isActive,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onCheckboxChanged,
    this.lastMessage,
  });

  @override
  State<ConnectionListItem> createState() => _ConnectionListItemState();
}

class _ConnectionListItemState extends State<ConnectionListItem> {
  ThemeData get theme => Theme.of(context);

  /// Build a small avatar widget for a given recipient.
  Widget _buildRecipientAvatar(ConnectionRecipient recipient) {
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: CircleAvatar(
        radius: 12,
        backgroundColor:
            widget.isActive ? theme.colorScheme.primary : Colors.grey.shade400,
        backgroundImage: recipient.avatarPath != null
            ? FileImage(File(recipient.avatarPath!))
            : null,
        child: recipient.avatarPath == null
            ? Text(
                recipient.customName.isNotEmpty
                    ? recipient.customName[0].toUpperCase()
                    : '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 12,
                ),
              )
            : null,
      ),
    );
  }

  /// Builds the row of recipient avatars if any exist.
  Widget _buildRecipientsRow() {
    if (widget.element.recipients.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.element.recipients
            .map((r) => _buildRecipientAvatar(r))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define text styles; if not active, show in grey.
    final titleStyle = widget.isActive
        ? theme.textTheme.titleLarge
        : theme.textTheme.titleLarge?.copyWith(color: Colors.grey);
    final subtitleStyle = widget.isActive
        ? theme.textTheme.bodySmall
        : theme.textTheme.bodySmall?.copyWith(color: Colors.grey);
    final avatarBg =
        widget.isActive ? theme.colorScheme.onSurfaceVariant : Colors.grey[400];

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onLongPress();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // Main connection avatar.
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: avatarBg,
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
            // Expanded section for connection details.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Connection name.
                  Text(
                    widget.element.name,
                    style: titleStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  // Last message or private key snippet.
                  Text(
                    widget.lastMessage ??
                        widget.element.privateKey.substring(
                          0,
                          widget.element.privateKey.length > 20
                              ? 20
                              : widget.element.privateKey.length,
                        ),
                    style: subtitleStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 6),
                  // Row of recipient avatars.
                  _buildRecipientsRow(),
                ],
              ),
            ),
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
