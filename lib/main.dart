import 'package:flutter/material.dart';
import 'lock_screen.dart';

// 🌓 Global theme notifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Aqilah\'s Diary',
          theme: ThemeData(primarySwatch: Colors.purple, brightness: Brightness.light),
          darkTheme: ThemeData(brightness: Brightness.dark),
          themeMode: mode,
          home: LockScreen(),
        );
      },
    );
  }
}