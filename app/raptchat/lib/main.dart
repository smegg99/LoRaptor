import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:raptchat/models/ble_device.dart';
import 'package:raptchat/models/connection_element.dart';
import 'package:raptchat/models/connection_recipient.dart';
import 'package:raptchat/models/message.dart';
import 'package:raptchat/models/settings_element.dart';
import 'package:raptchat/screens/chat_screen.dart';
import 'package:raptchat/theme/notifier.dart';
import 'package:raptchat/localization/localization.dart';
import 'package:raptchat/screens/main_screen.dart';
import 'package:raptchat/screens/connection_edit_screen.dart';
import 'package:raptchat/screens/settings_screen.dart';
import 'package:raptchat/screens/devices_screen.dart';
import 'package:raptchat/screens/mesh_screen.dart';
import 'package:raptchat/managers/ble_device_manager.dart';
import 'package:raptchat/managers/messages_manager.dart';

Future<Directory> _createAppDirectory(Directory appDir) async {
  try {
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
  } catch (e) {
    print('Error creating app directory: $e');
    throw Exception('Failed to initialize app directory.');
  }
  return appDir;
}

Future<Directory> _getAppDirectory() async {
  if (Platform.isLinux || Platform.isMacOS) {
    final homeDir = Directory(Platform.environment['HOME'] ?? '');
    final appDir = Directory('${homeDir.path}/.raptchat');
    return _createAppDirectory(appDir);
  } else if (Platform.isWindows) {
    final appData = Directory(Platform.environment['APPDATA'] ?? '');
    final appDir = Directory('${appData.path}\\raptchat');
    return _createAppDirectory(appDir);
  } else {
    return await getApplicationDocumentsDirectory();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final directory = await _getAppDirectory();

  await Hive.initFlutter(directory.path);
  Hive.registerAdapter(ConnectionElementAdapter());
  Hive.registerAdapter(SettingsElementAdapter());
  Hive.registerAdapter(BleDeviceAdapter());
  Hive.registerAdapter(ConnectionRecipientAdapter());
  Hive.registerAdapter(MessageAdapter());

  await Hive.openBox<ConnectionElement>('connection_elements');
  await Hive.openBox<BleDevice>('ble_devices');
  // Open the messages box without a generic type.
  await Hive.openBox('messages');

  final settingsBox = await Hive.openBox<SettingsElement>('settings');
  final settings = settingsBox.get(0);

  String themeMode = settings?.theme ?? 'System';
  String language = settings?.language ?? 'English';
  Locale initialLocale =
      language == 'English' ? const Locale('en') : const Locale('pl');

  runApp(
    DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final ColorScheme lightColorScheme = lightDynamic?.harmonized() ??
            ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 164, 0, 197),
              brightness: Brightness.light,
            );
        final ColorScheme darkColorScheme = darkDynamic?.harmonized() ??
            ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 164, 0, 197),
              brightness: Brightness.dark,
            );

        final lightThemeBase = ThemeData(
          colorScheme: lightColorScheme,
          useMaterial3: true,
        );
        final darkThemeBase = ThemeData(
          colorScheme: darkColorScheme,
          useMaterial3: true,
        );

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (context) => ThemeNotifier(
                lightThemeBase: lightThemeBase,
                darkThemeBase: darkThemeBase,
                initialMode: themeMode,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => BleDeviceManager(),
            ),
            ChangeNotifierProvider(
              create: (context) => MessagesManager(
                bleDeviceManager:
                    Provider.of<BleDeviceManager>(context, listen: false),
              ),
            ),
          ],
          child: MyApp(
            appDirectory: directory,
            initialLocale: initialLocale,
          ),
        );
      },
    ),
  );
}

class MyApp extends StatefulWidget {
  final Directory appDirectory;
  final Locale initialLocale;

  const MyApp({
    super.key,
    required this.appDirectory,
    required this.initialLocale,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      title: 'RaptChat',
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('pl'),
      ],
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.lightTheme,
      darkTheme: themeNotifier.darkTheme,
      themeMode: themeNotifier.currentThemeMode,
      routes: {
        '/': (context) => const MainScreen(),
        '/edit': (context) => ConnectionEditScreen(
              element: ModalRoute.of(context)!.settings.arguments
                  as ConnectionElement?,
              appDirectory: widget.appDirectory,
            ),
        '/settings': (context) => SettingsScreen(onLocaleChange: _setLocale),
        '/devices': (context) => const DevicesScreen(isActive: false),
        '/mesh': (context) => const MeshScreen(),
        '/chat': (context) => ChatScreen(
              connection: ModalRoute.of(context)!.settings.arguments
                  as ConnectionElement,
            ),
      },
    );
  }
}
