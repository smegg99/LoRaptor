import 'package:flutter/material.dart';
import 'package:raptchat/localization/localization.dart';
import 'package:raptchat/common/common.dart';

class HeaderListItem extends StatefulWidget {
  final TextEditingController keyController;
  final TextEditingController valueController;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const HeaderListItem({
    super.key,
    required this.keyController,
    required this.valueController,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<HeaderListItem> createState() => _HeaderListItemState();
}

class _HeaderListItemState extends State<HeaderListItem> {
  AppLocalizations get localizations => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    widget.keyController.addListener(_handleKeyChanged);
    widget.valueController.addListener(_handleValueChanged);
  }

  @override
  void dispose() {
    widget.keyController.removeListener(_handleKeyChanged);
    widget.valueController.removeListener(_handleValueChanged);
    super.dispose();
  }

  void _handleKeyChanged() {
    widget.onChanged();
  }

  void _handleValueChanged() {
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.keyController,
              decoration: InputDecoration(
                labelText: localizations.translate(
                  'screens.action_edit.labels.header_key',
                ),
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (value) {
                    setState(() {
                      widget.keyController.text = value;
                      widget.onChanged();
                    });
                  },
                  itemBuilder: (context) {
                    return predefinedHeaderKeys.map((key) {
                      return PopupMenuItem<String>(
                        value: key,
                        child: Text(key),
                      );
                    }).toList();
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.valueController,
              decoration: InputDecoration(
                labelText: localizations.translate(
                  'screens.action_edit.labels.header_value',
                ),
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (value) {
                    setState(() {
                      widget.valueController.text = value;
                      widget.onChanged();
                    });
                  },
                  itemBuilder: (context) {
                    return predefinedHeaderValues.map((value) {
                      return PopupMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList();
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: Icon(Icons.close, color: theme.colorScheme.error),
              onPressed: widget.onDelete,
            ),
          ),
        ],
      ),
    );
  }
}
