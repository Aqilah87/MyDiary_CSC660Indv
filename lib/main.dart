import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lock_screen.dart';
import 'pages/home_page.dart';
import 'pages/onboard_page.dart';
import 'models/diary_entry.dart';
import 'theme_controller.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(DiaryEntryAdapter());
  await Hive.openBox<DiaryEntry>('diary');

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('is_dark_mode') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Check if onboarding is completed
  Future<bool> _hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getBool('onboarding_done') ?? false;
    print('🔍 DEBUG - onboarding_done: $result');
    return result;
  }

  // Check if PIN is enabled
  Future<bool> _isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    
    // ✅ Check BOTH keys for compatibility
    final pinEnabled = prefs.getBool('pin_enabled') ?? false;
    final savedPin = prefs.getString('user_pin');
    
    print('🔍 DEBUG - PIN Status:');
    print('   pin_enabled: $pinEnabled');
    print('   user_pin exists: ${savedPin != null}');
    print('   user_pin value: ${savedPin ?? "NULL"}');
    
    // Return true only if both enabled AND PIN exists
    return pinEnabled && savedPin != null && savedPin.isNotEmpty;
  }

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

        // ✅ UPDATED: Smart routing based on onboarding + PIN status
        home: FutureBuilder<Map<String, bool>>(
          future: Future.wait([
            _hasCompletedOnboarding(),
            _isPinEnabled(),
          ]).then((results) {
            final data = {
              'onboardingDone': results[0],
              'pinEnabled': results[1],
            };
            
            print('🎯 ROUTING DECISION:');
            print('   onboardingDone: ${data['onboardingDone']}');
            print('   pinEnabled: ${data['pinEnabled']}');
            
            return data;
          }),
          builder: (context, snapshot) {
            // Show loading while checking
            if (!snapshot.hasData) {
              return Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading...'),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final onboardingDone = data['onboardingDone']!;
            final pinEnabled = data['pinEnabled']!;

            print('📍 Navigating to: ${!onboardingDone ? "OnboardPage" : pinEnabled ? "LockScreen" : "HomePage"}');

            // First time user → show onboarding
            if (!onboardingDone) {
              return OnboardPage();
            }

            // Onboarding done, check PIN setting
            if (pinEnabled) {
              print('✅ PIN is enabled - showing LockScreen');
              // PIN is enabled → show LockScreen first
              return LockScreen(childAfterUnlock: HomePage());
            } else {
              print('❌ PIN is disabled - going to HomePage');
              // PIN is disabled → go directly to HomePage
              return HomePage();
            }
          },
        ),
      ),
    );
  }
}