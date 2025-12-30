// lib/screens/settings_page.dart
// BIOMETRIC TOGGLE (no PIN)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class SettingsPage extends StatefulWidget {
  final bool isDarkMode;
  final bool isPinEnabled; // Now means "biometric enabled"
  final Function(bool) onThemeChanged;
  final Function(bool) onPinChanged; // Now means "biometric changed"

  SettingsPage({
    required this.isDarkMode,
    required this.isPinEnabled,
    required this.onThemeChanged,
    required this.onPinChanged,
  });

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _isDarkMode;
  late bool _isBiometricEnabled;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _isBiometricEnabled = widget.isPinEnabled;
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    
    print('🔍 Settings - Loading biometric status: $biometricEnabled');
    
    setState(() {
      _isBiometricEnabled = biometricEnabled;
    });
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('About This App'),
        content: Text(
          '''Dear Diary is a personal and private digital diary that allows users to record their daily thoughts, feelings, and experiences.

Features:
• Biometric security (fingerprint/face recognition)
• Offline-first with auto-save
• Photo attachments
• Emoji mood tracking
• Calendar view
• Search functionality

Whether you're feeling happy, sad, or anything in between, Dear Diary is your safe space to express yourself.''',
        ),
        actions: [
          TextButton(
            child: Text('OK', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Future<void> _handleBiometricToggle(bool val) async {
    final prefs = await SharedPreferences.getInstance();

    if (val) {
      // Enable biometric
      print('✅ Enabling biometric lock');
      
      await prefs.setBool('biometric_enabled', true);
      
      // Verify save
      final saved = prefs.getBool('biometric_enabled');
      print('🔍 Verification - biometric_enabled after save: $saved');
      
      setState(() => _isBiometricEnabled = true);
      widget.onPinChanged(true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.fingerprint, color: Colors.white),
              SizedBox(width: 12),
              Text('🔐 Biometric lock enabled!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      // Disable biometric - ask for confirmation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Disable Biometric Lock?'),
          content: Text('Are you sure you want to disable biometric protection?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: Text('Disable', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      
      if (confirm == true) {
        print('❌ Disabling biometric lock');
        
        await prefs.setBool('biometric_enabled', false);
        
        // Verify save
        final saved = prefs.getBool('biometric_enabled');
        print('🔍 Verification - biometric_enabled after disable: $saved');
        
        setState(() => _isBiometricEnabled = false);
        widget.onPinChanged(false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric lock disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // User cancelled, keep toggle on
        setState(() => _isBiometricEnabled = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        children: [
          // Theme Toggle
          SwitchListTile(
            title: Text('App Theme', style: textTheme.bodyMedium),
            subtitle: Text(
              _isDarkMode ? 'Dark Mode' : 'Light Mode',
              style: textTheme.bodySmall,
            ),
            secondary: Icon(Icons.dark_mode, color: theme.iconTheme.color),
            value: _isDarkMode,
            onChanged: (val) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_dark_mode', val);

              setState(() => _isDarkMode = val);
              themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
              widget.onThemeChanged(val);
            },
          ),
          Divider(),

          // Biometric Lock Toggle
          SwitchListTile(
            title: Text('Biometric Lock', style: textTheme.bodyMedium),
            subtitle: Text(
              _isBiometricEnabled ? 'Enabled' : 'Disabled',
              style: textTheme.bodySmall,
            ),
            secondary: Icon(Icons.fingerprint, color: theme.iconTheme.color),
            value: _isBiometricEnabled,
            onChanged: _handleBiometricToggle,
          ),
          
          // Info about biometric
          if (_isBiometricEnabled)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your diary is protected with fingerprint or face recognition',
                        style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          Divider(),

          // About App
          ListTile(
            leading: Icon(Icons.info_outline, color: theme.iconTheme.color),
            title: Text('About App', style: textTheme.bodyMedium),
            trailing: Icon(Icons.chevron_right, color: theme.iconTheme.color),
            onTap: _showAboutDialog,
          ),
        ],
      ),
    );
  }
}