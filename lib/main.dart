import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lock_screen.dart';
import 'pages/home_page.dart';
import 'pages/onboard_page.dart';
import 'models/diary_entry.dart';
import 'theme_controller.dart';

// 🌓 Global theme notifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(DiaryEntryAdapter());
  await Hive.openBox<DiaryEntry>('diary');

  // Load preferences
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('is_dark_mode') ?? false;
  final isPinEnabled = prefs.getBool('is_pin_enabled') ?? false;
  final seenOnboarding = prefs.getBool('seenOnboard') ?? false;

  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(MyApp(
    isPinEnabled: isPinEnabled,
    showOnboarding: !seenOnboarding,
  ));
}

class MyApp extends StatelessWidget {
  final bool isPinEnabled;
  final bool showOnboarding;

  const MyApp({
    Key? key,
    required this.isPinEnabled,
    required this.showOnboarding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Aqilah\'s Diary',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.purple,
        ),
        themeMode: mode,
        home: showOnboarding
            ? OnboardPage()
            : (isPinEnabled ? LockScreen() : HomePage()),
      ),
    );
  }
}