import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io' show Platform;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'l10n/localizations_delegate.dart';
import 'l10n/locale_preferences.dart';
import 'preferences/theme_preferences.dart';
import 'theme/my_themes.dart';
import 'db/db_helper.dart';
import 'services/notification_service.dart';
import 'pages/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await DatabaseHelper.instance.database;
  await NotificationService.instance.init();
  NotificationService.instance.checkDuePayments('default_store');

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  static MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<MyAppState>();
  }

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  Locale _locale = const Locale('ar');
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final localeCode = await LocalePreferences.getLocale();
    final themeModeStr = await ThemePreferences.getThemeMode();
    setState(() {
      _locale = Locale(localeCode);
      _themeMode = _parseThemeMode(themeModeStr);
    });
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
    LocalePreferences.setLocale(locale.languageCode);
  }

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    String modeStr = 'system';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    if (mode == ThemeMode.light) modeStr = 'light';
    ThemePreferences.setThemeMode(modeStr);
  }

  ThemeData _buildTheme(bool dark) {
    final base = dark ? MyThemes.darkTheme : MyThemes.lightTheme;
    final font = _locale.languageCode == 'ar' ? 'Cairo' : 'Roboto';
    return base.copyWith(textTheme: base.textTheme.apply(fontFamily: font));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Template',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _buildTheme(false),
      darkTheme: _buildTheme(true),
      themeMode: _themeMode,
      home: const SplashScreen(),
    );
  }
}
