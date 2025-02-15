import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:raptchat/models/connection_element.dart';
import 'package:raptchat/models/settings_element.dart';
import 'package:raptchat/theme/notifier.dart';
import 'package:raptchat/localization/localization.dart';
import 'package:raptchat/screens/main_screen.dart';
import 'package:raptchat/screens/connection_edit_screen.dart';
import 'package:raptchat/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final directory = await _getAppDirectory();

  await Hive.initFlutter(directory.path);
  Hive.registerAdapter(ConnectionElementAdapter());
  Hive.registerAdapter(ActionElementAdapter());
  Hive.registerAdapter(SettingsElementAdapter());
  await Hive.openBox<ConnectionElement>('connection_elements');
  final settingsBox = await Hive.openBox<SettingsElement>('settings');
  final settings = settingsBox.get(0);

  String themeMode = settings?.theme ?? 'System';
  String language = settings?.language ?? 'English';
  Locale initialLocale =
      language == 'English' ? const Locale('en') : const Locale('pl');

  runApp(
    DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final fallbackSeed = Colors.blue;

        final lightTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: lightDynamic ??
              ColorScheme.fromSeed(
                  seedColor: fallbackSeed, brightness: Brightness.light),
        );
        final darkTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: darkDynamic ??
              ColorScheme.fromSeed(
                  seedColor: fallbackSeed, brightness: Brightness.dark),
        );

        final brightness =
            SchedulerBinding.instance.platformDispatcher.platformBrightness;
        final initialTheme = themeMode == 'Light'
            ? lightTheme
            : themeMode == 'Dark'
                ? darkTheme
                : brightness == Brightness.dark
                    ? darkTheme
                    : lightTheme;

        return ChangeNotifierProvider(
          create: (context) => ThemeNotifier(initialTheme, themeMode),
          child: MyApp(
            appDirectory: directory,
            initialLocale: initialLocale,
            lightTheme: lightTheme,
            darkTheme: darkTheme,
          ),
        );
      },
    ),
  );
}

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

class MyApp extends StatefulWidget {
  final Directory appDirectory;
  final Locale initialLocale;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  const MyApp({
    super.key,
    required this.appDirectory,
    required this.initialLocale,
    required this.lightTheme,
    required this.darkTheme,
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
      theme: themeNotifier.currentTheme,
      darkTheme: widget.darkTheme,
      themeMode: themeNotifier.currentThemeMode,
      routes: {
        '/': (context) => const MainScreen(),
        '/edit': (context) => ConnectionEditScreen(
              element:
                  ModalRoute.of(context)!.settings.arguments as ConnectionElement?,
              appDirectory: widget.appDirectory,
            ),
        '/settings': (context) => SettingsScreen(onLocaleChange: _setLocale),
      },
    );
  }
}
