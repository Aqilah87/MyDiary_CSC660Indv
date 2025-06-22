import 'package:flutter/material.dart';
import 'lock_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🌓 Global theme notifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Optional: Load saved theme mode from preferences (if you want persistence)
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    _loadThemePreference();
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
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
          home: LockScreen(),
        );
      },
    );
  }
}