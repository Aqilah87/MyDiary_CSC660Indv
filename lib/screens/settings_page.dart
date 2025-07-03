import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'set_pin_page.dart';

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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('About This App'),
        content: Text(
          '''Dear Diary is a personal and private digital diary that allows users to record their daily thoughts, feelings, and experiences.
Users can write journal entries, select emojis that reflect their mood, attach meaningful photos, and personalize their diary in a creative way. 
The app also includes features like a calendar view to track past entries, customizable fonts, and an easy-to-use interface for editing or deleting entries. 
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

  Future<void> _handlePinToggle(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isPinLock = val);
    widget.onPinChanged(val);
    await prefs.setBool('is_pin_enabled', val);

    if (val) {
      final newPin = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SetPinPage()),
      );
      if (newPin != null && newPin.length >= 4) {
        await prefs.setString('user_pin_code', newPin);
      }
    } else {
      await prefs.remove('user_pin_code');
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

          SwitchListTile(
            title: Text('PIN Lock', style: textTheme.bodyMedium),
            subtitle: Text(_isPinLock ? 'Enabled' : 'Disabled', style: textTheme.bodySmall),
            secondary: Icon(Icons.lock, color: theme.iconTheme.color),
            value: _isPinLock,
            onChanged: _handlePinToggle,
          ),
          Divider(),

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