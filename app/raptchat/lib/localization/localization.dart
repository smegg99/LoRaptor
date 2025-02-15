import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  late Map<String, dynamic> _localizedStrings;

  Future<void> load() async {
    final jsonString =
        await rootBundle.loadString('assets/langs/${locale.languageCode}.json');
    _localizedStrings = json.decode(jsonString);
  }

  String translate(String key) {
    final keys = key.split('.');
    dynamic value = _localizedStrings;
    for (final k in keys) {
      if (value[k] == null) return key;
      value = value[k];
    }
    return value is String ? value : key;
  }

  String translateWithParams(String key, Map<String, String> params) {
    String value = translate(key);

    params.forEach((placeholder, actualValue) {
      value = value.replaceAll('{$placeholder}', actualValue);
    });

    return value;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'pl'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
