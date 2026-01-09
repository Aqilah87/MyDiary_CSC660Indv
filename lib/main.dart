import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lock_screen.dart';
import 'pages/home_page.dart';
import 'pages/onboard_page.dart';
import 'models/diary_entry.dart';
import 'models/note.dart';
import 'services/note_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(DiaryEntryAdapter());
  await Hive.openBox<DiaryEntry>('diary');
  Hive.registerAdapter(NoteAdapter());
  await NoteService.init();

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('is_dark_mode') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Aqilah\'s Diary',
        themeMode: mode,

        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Color(0xFFF4FDFF),
          primarySwatch: Colors.blue,
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF009DC4),
            foregroundColor: Colors.black,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          cardColor: Color(0xFFE0F7F4),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF32CD32),
              foregroundColor: Colors.white,
            ),
          ),
        ),

        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Color(0xFF121212),
          primarySwatch: Colors.blueGrey,
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          cardColor: Colors.grey[900],
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent[700],
              foregroundColor: Colors.black,
            ),
          ),
        ),

        home: InitialRouteChecker(),
      ),
    );
  }
}

class InitialRouteChecker extends StatefulWidget {
  @override
  _InitialRouteCheckerState createState() => _InitialRouteCheckerState();
}

class _InitialRouteCheckerState extends State<InitialRouteChecker> {
  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    await Future.delayed(Duration(milliseconds: 100));
    
    final prefs = await SharedPreferences.getInstance();
    
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    
    print('======================');
    print('🔍 STARTUP CHECK:');
    print('   onboarding_done: $onboardingDone');
    
    if (!onboardingDone) {
      print('📍 → Going to OnboardPage');
      print('======================');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OnboardPage()),
      );
      return;
    }
    
    final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    
    print('   biometric_enabled: $biometricEnabled');
    print('======================');
    
    if (biometricEnabled) {
      print('📍 → Going to LockScreen (Biometric)');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LockScreen(childAfterUnlock: HomePage()),
        ),
      );
    } else {
      print('📍 → Going to HomePage (No biometric)');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}