// lib/models/settings_element.dart
import 'package:hive/hive.dart';

part 'settings_element.g.dart';

@HiveType(typeId: 3)
class SettingsElement extends HiveObject {
  @HiveField(0)
  String theme;

  @HiveField(1)
  String language;

  SettingsElement({
    required this.theme,
    required this.language,
  });
}
