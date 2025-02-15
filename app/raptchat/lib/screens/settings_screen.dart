import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:raptchat/models/settings_element.dart';
import 'package:provider/provider.dart';
import 'package:raptchat/theme/notifier.dart';
import 'package:raptchat/localization/localization.dart';

class SettingsScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;

  const SettingsScreen({super.key, required this.onLocaleChange});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _theme;
  late String _language;

  late Box<SettingsElement> _settingsBox;
  AppLocalizations get localizations => AppLocalizations.of(context);

  SettingsElement? _settings;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    _settingsBox = await Hive.openBox<SettingsElement>('settings');
    _settings = _settingsBox.get(0);

    if (_settings == null) {
      _settings = SettingsElement(
        theme: 'Light',
        language: 'English',
      );
      await _settingsBox.put(0, _settings!);
    }

    setState(() {
      _theme = _settings!.theme;
      _language = _settings!.language;
    });
  }

  Future<void> _saveChanges(String theme, String language) async {
    if (_settings == null) return;

    _settings!
      ..theme = theme
      ..language = language;

    await _settings!.save();
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('screens.settings.title')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          // Text(
          //   localizations.translate('screens.settings.options.groups.common'),
          //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          // ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(localizations
                          .translate('screens.settings.labels.language')),
                      DropdownMenu<String>(
                        initialSelection: _language,
                        label: Text(''),
                        dropdownMenuEntries: ['English', 'Polish'].map((lang) {
                          final key = lang == 'English' ? 'en' : 'pl';
                          return DropdownMenuEntry(
                            value: lang,
                            label: localizations.translate(
                                'screens.settings.options.languages.$key'),
                          );
                        }).toList(),
                        onSelected: (value) {
                          setState(() {
                            _language = value!;
                            _saveChanges(_theme, _language);

                            Locale locale = _language == 'English'
                                ? const Locale('en')
                                : const Locale('pl');
                            widget.onLocaleChange(locale);
                          });
                        },
                      )
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(localizations
                          .translate('screens.settings.labels.theme')),
                      DropdownMenu<String>(
                        initialSelection: _theme,
                        label: Text(''),
                        dropdownMenuEntries:
                            ['Light', 'Dark', 'System'].map((theme) {
                          final key = theme.toLowerCase();
                          return DropdownMenuEntry(
                            value: theme,
                            label: localizations.translate(
                                'screens.settings.options.themes.$key'),
                          );
                        }).toList(),
                        onSelected: (value) {
                          if (value != null) {
                            setState(() {
                              _theme = value;
                              _saveChanges(_theme, _language);

                              themeNotifier.switchThemeMode(value);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
