import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raptchat/localization/localization.dart';
import 'package:raptchat/models/connection_element.dart';

class ActionListItem extends StatefulWidget {
  final ActionElement action;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onLongPress;
  final ValueChanged<bool?> onCheckboxChanged;

  const ActionListItem({
    super.key,
    required this.action,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onEdit,
    required this.onLongPress,
    required this.onCheckboxChanged,
  });

  @override
  State<ActionListItem> createState() => _ActionListItemState();
}

class _ActionListItemState extends State<ActionListItem> {
  AppLocalizations get localizations => AppLocalizations.of(context);

  ThemeData get theme => Theme.of(context);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.action.name.isEmpty
                        ? localizations.translate(
                            'screens.action_edit.labels.unnamed_action')
                        : widget.action.name,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    widget.action.endpoint,
                    style: theme.textTheme.labelSmall,
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
                  ReorderableDragStartListener(
                    index: widget.action.order,
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
