import 'package:flutter/material.dart';

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
          'Aqilah Diary is a private space where users can write entries, choose emojis, attach photos, and manage their feelings. It includes personalized touches like mood emojis, calendar views, and more.',
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
            secondary: Icon(Icons.brightness_6),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() => _isDarkMode = value);
              widget.onThemeChanged(value); // Pass back to HomePage
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