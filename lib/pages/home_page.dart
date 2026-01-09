import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'entry_form_page_offline.dart';
import '../models/diary_entry.dart';
import '../screens/calendar_page.dart';
import '../screens/settings_page.dart';
import '../theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'profile_page.dart';
import '../search/diary_search_delegate.dart';
import 'dart:io';
import '../screens/offline_status_widget.dart';
import 'notes_page.dart'; // ✅ NEW IMPORT

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isDarkThemeEnabled = false;
  bool isPinEnabled = false;

  List<DiaryEntry> entries = [];
  List<DiaryEntry> filteredEntries = [];

  late Box<DiaryEntry> diaryBox;

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
    _loadDiaryEntries();
  }

  void _addNewEntry(DiaryEntry entry) async {
    final box = Hive.box<DiaryEntry>('diary');
    await box.add(entry);
    setState(() {
      entries = box.values.toList();
      filteredEntries = entries;
    });
  }

  void _editEntry(int index, DiaryEntry updatedEntry) async {
    final key = diaryBox.keyAt(index);
    await diaryBox.put(key, updatedEntry);
    setState(() {
      entries = diaryBox.values.toList();
      filteredEntries = entries;
    });
  }

  void _deleteEntry(int index) async {
    final key = diaryBox.keyAt(index);
    await diaryBox.delete(key);
    setState(() {
      entries = diaryBox.values.toList();
      filteredEntries = entries;
    });
  }

  void _loadDiaryEntries() async {
    diaryBox = await Hive.openBox<DiaryEntry>('diary');
    setState(() {
      entries = diaryBox.values.toList();
      filteredEntries = entries;
    });
    print('Loaded ${entries.length} entries');
  }

  void _loadBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    
    print('🔍 HomePage - Loading Biometric preference: $biometricEnabled');
    
    setState(() {
      isPinEnabled = biometricEnabled;
    });
  }

  void _saveBiometricPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
  }

  void _handleThemeChanged(bool val) {
    setState(() => isDarkThemeEnabled = val);
    themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
  }

  void _handleBiometricChanged(bool val) {
    setState(() => isPinEnabled = val);
    _saveBiometricPreference(val);
  }

  void _searchDiary(String query) {
    final results = entries.where((entry) {
      final title = entry.title.toLowerCase();
      final text = entry.text.toLowerCase();
      final search = query.toLowerCase();
      return title.contains(search) || text.contains(search);
    }).toList();

    setState(() {
      filteredEntries = results;
    });
  }

  void _resetSearch() {
    setState(() {
      filteredEntries = entries;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().day;
    final quotes = [
      'You are stronger than you think.',
      'Believe in your journey.',
      'Small steps lead to big results.',
    ];
    final prompts = [
      '📝 What made you smile today?',
      '📝 What are you grateful for?',
      '📝 What\'s something you learned recently?',
    ];
    final dailyQuote = quotes[today % quotes.length];
    final dailyPrompt = prompts[today % prompts.length];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Dear Diary",
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
        iconTheme: Theme.of(context).appBarTheme.iconTheme ??
            IconThemeData(color: Theme.of(context).iconTheme.color),
        actions: [
          // ✅ NEW: Notes button
          IconButton(
            icon: Icon(Icons.note_alt, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotesPage()),
              );
            },
            tooltip: 'Notes',
          ),
          
          // Existing search button
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
            onPressed: () async {
              final result = await showSearch(
                context: context,
                delegate: DiarySearchDelegate(entries),
              );
              if (result == null || result.isEmpty) {
                _resetSearch();
              } else {
                _searchDiary(result);
              }
            },
          ),
        ],
      ),

      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
              ),
              child: Text(
                'My Diary',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: Theme.of(context).iconTheme.color),
              title: Text('Home', style: Theme.of(context).textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.create, color: Theme.of(context).iconTheme.color),
              title: Text('Create Diary', style: Theme.of(context).textTheme.bodyLarge),
              onTap: () async {
                Navigator.pop(context);
                final newEntry = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EntryFormPageOffline()),
                );
                if (newEntry != null) {
                  _addNewEntry(newEntry);
                }
              },
            ),
            
            // ✅ NEW: Notes menu item in drawer
            ListTile(
              leading: Icon(Icons.note_alt, color: Theme.of(context).iconTheme.color),
              title: Text('Notes', style: Theme.of(context).textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NotesPage()),
                );
              },
            ),
            
            ListTile(
              leading: Icon(Icons.calendar_month, color: Theme.of(context).iconTheme.color),
              title: Text('Diary Calendar', style: Theme.of(context).textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CalendarPage(entries: entries),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: Theme.of(context).iconTheme.color),
              title: Text('Profil', style: Theme.of(context).textTheme.bodyLarge),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Theme.of(context).iconTheme.color),
              title: Text('Settings', style: Theme.of(context).textTheme.bodyLarge),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsPage(
                      isDarkMode: isDarkThemeEnabled,
                      isPinEnabled: isPinEnabled,
                      onThemeChanged: (val) {
                        setState(() {
                          isDarkThemeEnabled = val;
                        });
                      },
                      onPinChanged: (val) {
                        setState(() {
                          isPinEnabled = val;
                        });
                      },
                    ),
                  ),
                );
                
                _loadBiometricPreference();
                print('🔄 Reloaded Biometric preference after Settings');
              },
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Card(
            color: Color.fromARGB(255, 224, 215, 246),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '"$dailyQuote"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 16,
                            color: Color(0xFF3C225C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.edit_note, color: Colors.teal),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dailyPrompt,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SimpleOfflineStatusWidget(),

          Expanded(
            child: filteredEntries.isEmpty
                ? Center(
                    child: Text(
                      "Let's write a diary today.",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    physics: BouncingScrollPhysics(),
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Color(0xFFE0F7F4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Color.fromARGB(255, 194, 200, 209)),
                          ),
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(entry.emoji, style: TextStyle(fontSize: 28)),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          if (entry.text.trim().isNotEmpty)
                                            Text(
                                              entry.text,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.orange),
                                      onPressed: () async {
                                        final updated = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EntryFormPageOffline(entry: entry),
                                          ),
                                        );
                                        if (updated != null) {
                                          _editEntry(index, updated);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: const Color.fromARGB(255, 164, 12, 1)),
                                      onPressed: () async {
                                        final confirm = await showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text('Delete Entry?'),
                                            content: Text('Are you sure you want to delete this diary?'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text('Cancel')),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                onPressed: () => Navigator.pop(context, true),
                                                child: Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          _deleteEntry(index);
                                        }
                                      },
                                    ),
                                  ],
                                ),

                                if (entry.imagePath != null && entry.imagePath!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(entry.imagePath!),
                                        height: 140,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Icon(Icons.broken_image, size: 48),
                                      ),
                                    ),
                                  ),

                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    DateFormat.yMMMd().add_jm().format(entry.date),
                                    style: TextStyle(fontSize: 12, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: Icon(Icons.add),
        onPressed: () async {
          final newEntry = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EntryFormPageOffline()),
          );
          if (newEntry != null) {
            _addNewEntry(newEntry);
          }
        },
      ),
    );
  }
}