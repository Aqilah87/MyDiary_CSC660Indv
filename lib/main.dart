import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lock_screen.dart';
import 'pages/home_page.dart';
import 'pages/onboard_page.dart';
import 'models/diary_entry.dart';
import 'models/note.dart';
import 'services/note_service.dart';
import 'theme_controller.dart'; // ✅ Make sure this import exists

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Hive
  await Hive.initFlutter();
  
  // ✅ Register adapters
  Hive.registerAdapter(DiaryEntryAdapter());
  Hive.registerAdapter(NoteAdapter());
  
  // ✅ Open boxes
  await Hive.openBox<DiaryEntry>('diary');
  await NoteService.init();

  // ✅ Load theme preference
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

        // ✅ Light Theme
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
            iconTheme: IconThemeData(color: Colors.black),
          ),
          cardColor: Color(0xFFE0F7F4),
          iconTheme: IconThemeData(color: Colors.black87),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Colors.black87),
            bodyMedium: TextStyle(color: Colors.black87),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF32CD32),
              foregroundColor: Colors.white,
            ),
          ),
        ),

        // ✅ Dark Theme
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
            iconTheme: IconThemeData(color: Colors.white),
          ),
          cardColor: Colors.grey[900],
          iconTheme: IconThemeData(color: Colors.white70),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Colors.white70),
            bodyMedium: TextStyle(color: Colors.white70),
          ),
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

// ✅ Initial Route Checker with Biometric Support
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
    // ✅ Small delay to ensure everything is loaded
    await Future.delayed(Duration(milliseconds: 100));
    
    final prefs = await SharedPreferences.getInstance();
    
    // ✅ Check if onboarding is done
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
    
    // ✅ Check if biometric is enabled
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
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}