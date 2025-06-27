import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class SettingsPage extends StatefulWidget {
  final bool isDarkMode;
  final bool isPinEnabled;
  final Function(bool) onThemeChanged;
  final Function(bool) onPinChanged;

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
  late bool _isPinLock;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _isPinLock = widget.isPinEnabled;
  }

  void _toggleDarkMode(bool value) {
    setState(() => _isDarkMode = value);
    widget.onThemeChanged(value);
  }

  void _togglePinLock(bool value) {
    setState(() => _isPinLock = value);
    widget.onPinChanged(value);
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('About This App'),
        content: Text(
          '''Dear Diary is a personal and private digital diary that allows users to record their daily thoughts, feelings, and experiences.
          Users can write journal entries, select emojis that reflect their mood, attach meaningful photos, and personalize their diary in a creative way. 
          The app also includes features like a calendar view to track past entries, customizable fonts, and an easy-to-use interface for editing or deleting entries. 
          Whether you're feeling happy, sad, or anything in between, Dear Diary is your safe space to express yourself.'''
),

        actions: [
          TextButton(
            child: Text('OK', style: TextStyle(color: Theme.of(context).primaryColor)),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: const Color.fromARGB(255, 30, 160, 216),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('App Theme'),
            subtitle: Text(_isDarkMode ? 'Dark Mode' : 'Light Mode'),
            secondary: Icon(Icons.dark_mode),
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
          SwitchListTile(
            title: Text('PIN Lock'),
            subtitle: Text(_isPinLock ? 'Enabled' : 'Disabled'),
            secondary: Icon(Icons.lock),
            value: _isPinLock,
            onChanged: _togglePinLock,
          ),

          Divider(),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About App'),
            trailing: Icon(Icons.chevron_right),
            onTap: _showAboutDialog,
          ),
        ],
      ),
    );
  }
}