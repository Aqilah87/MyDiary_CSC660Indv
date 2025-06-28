import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'entry_form_page.dart';
import '../models/diary_entry.dart';
import '../screens/calendar_page.dart';
import '../screens/settings_page.dart';
import '../theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

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
          _loadPinPreference();
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

        void _loadPinPreference() async {
          final prefs = await SharedPreferences.getInstance();
          setState(() {
            isPinEnabled = prefs.getBool('pin_enabled') ?? false;
          });
        }

        void _savePinPreference(bool value) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('pin_enabled', value);
        }

        void _handleThemeChanged(bool val) {
          setState(() => isDarkThemeEnabled = val);
          themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
        }

        void _handlePinChanged(bool val) {
          setState(() => isPinEnabled = val);
          _savePinPreference(val);
        }

        void _navigate(String label) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigated to: $label')),
          );
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
          return Scaffold(
      appBar: AppBar(
        title: const Text("Dear Diary"),
        backgroundColor: const Color.fromARGB(255, 115, 204, 241),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
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
      backgroundColor: const Color.fromARGB(255, 169, 229, 255),

      // Navigation Drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Color.fromARGB(255, 115, 204, 241),),
              child: Text(
                'My Diary',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            //home
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context); // close drawer
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomePage()),
                  );
                },
              ),

            // Create Diary
            ListTile(
              leading: Icon(Icons.create),
              title: Text('Create Diary'),
              onTap: () async {
                Navigator.pop(context); // close drawer
                final newEntry = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EntryFormPage()),
                  );
                  if (newEntry != null) {
                        _addNewEntry(newEntry);
                  }
              },
            ),

                  // Diary Calendar
                  ListTile(
                    leading: Icon(Icons.calendar_month),
                    title: Text('Diary Calendar'),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CalendarPage(entries: entries),
                        ),
                      );
                    },
                  ),
      
                  // Settings
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsPage(
                            isDarkMode: isDarkThemeEnabled,
                            isPinEnabled: isPinEnabled,
                            onThemeChanged: (val) {
                              setState(() {
                                isDarkThemeEnabled = val;
                                // apply your theme change logic
                              });
                            },
                            onPinChanged: (val) {
                              setState(() {
                                isPinEnabled = val;
                                // apply your pin lock logic
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
      
                  // About App 
                  ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('About App'),
                    onTap: () => _navigate('About App'),
                  ),
                ],
              ),
            ),
      
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    'assets/dd2.png',
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Welcome to My Diary 📖',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                          child: Text(
                            "Let's write diary today.",
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          physics: BouncingScrollPhysics(),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: Duration(milliseconds: 300 + index * 40),
                              builder: (context, value, child) =>
                                  Opacity(opacity: value, child: child),

                              child: Card(
                                color: Color(0xFFE0F2F1),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                  color: Color.fromARGB(255, 5, 128, 121), // Light green border
                                  ),
                                ),
                                elevation: 6,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Row with emoji and content
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.emoji,
                                            style: TextStyle(fontSize: 30),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Image (if available)
                                                if (entry.imagePath != null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(bottom: 8),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                      child: Image.file(
                                                        File(entry.imagePath!),
                                                        height: 120,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (context, error, stackTrace) =>
                                                                Icon(Icons.broken_image,
                                                                    size: 40),
                                                      ),
                                                    ),
                                                  ),
                                                Text(
                                                  entry.title,
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.black87,
                                                      ), 
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  DateFormat.yMMMd()
                                                      .add_jm()
                                                      .format(entry.date),
                                                  style: TextStyle(
                                                      color: Colors.grey[800],
                                                      fontSize: 12),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  entry.text,
                                                  style: TextStyle(fontSize: 14,
                                                  color: Colors.black87,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.edit,
                                                          color: Colors.orange),
                                                      onPressed: () async {
                                                        final updatedEntry =
                                                            await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                EntryFormPage(
                                                                    entry: entry),
                                                          ),
                                                        );
                                                        if (updatedEntry != null) {
                                                          _editEntry(index, updatedEntry);
                                                        }
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.delete,
                                                          color: Colors.red),
                                                      onPressed: () => _deleteEntry(index),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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
              backgroundColor: Colors.orangeAccent,
              child: Icon(Icons.add),
              onPressed: () async {
                final newEntry = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EntryFormPage()),
                );
                if (newEntry != null) {
                  _addNewEntry(newEntry);
                }
              },
            ),
          );
        }
      }

                                                                                            
class DiarySearchDelegate extends SearchDelegate<String> {
  final List<DiaryEntry> entries;

  DiarySearchDelegate(this.entries) : super();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = entries.where((entry) {
      return entry.title.toLowerCase().contains(query.toLowerCase()) ||
          entry.text.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final result = suggestions[index];
        return ListTile(
          leading: Text(result.emoji, style: const TextStyle(fontSize: 28)),
          title: Text(result.title),
          subtitle: Text(
            DateFormat.yMMMd().add_jm().format(result.date),
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () => close(context, result.title),
        );
      },
    );
  }
}