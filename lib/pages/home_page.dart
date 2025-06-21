import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'entry_form_page.dart';
import '../models/diary_entry.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<DiaryEntry> entries = [];
  List<DiaryEntry> filteredEntries = [];

  @override
  void initState() {
    super.initState();
    filteredEntries = entries;
  }

  void _addNewEntry(DiaryEntry entry) {
    setState(() {
      entries.add(entry);
      filteredEntries = entries; // Reset filtered entries
    });
  }

  void _editEntry(int index, DiaryEntry updatedEntry) {
    setState(() {
      entries[index] = updatedEntry;
      filteredEntries = entries; // Reset filtered entries
    });
  }

  void _deleteEntry(int index) {
    setState(() {
      entries.removeAt(index);
      filteredEntries = entries; // Reset filtered entries
    });
  }

  void _navigate(String label) {
    Navigator.pop(context); // close drawer
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
        title: Text("My Diary"),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
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

      // Navigation Drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'My Diary',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () => _navigate('Home'),
            ),
            ListTile(
              leading: Icon(Icons.create),
              title: Text('Create Diary'),
              onTap: () => _navigate('Create Diary'),
            ),
            ListTile(
              leading: Icon(Icons.calendar_month),
              title: Text('Diary Calendar'),
              onTap: () => _navigate('Diary Calendar'),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () => _navigate('Settings'),
            ),
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
            child: 
            Image.asset('assets/diary2.png',
              height: 150,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Welcome to My Diary',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          
          Expanded(
             child: entries.isEmpty
          ? Center(child: Text("Let's write diary today."))
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    leading: Text(
                      entry.emoji,
                      style: TextStyle(fontSize: 30),
                    ),

                    title: Text(
                      entry.text,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    subtitle: Text(
                                DateFormat.yMMMd()
                                    .add_jm()
                                    .format(entry.date),
                                style: TextStyle(
                                    color: Colors.grey[600], 
                                    fontSize: 12,
                                ),
                              ),
                              
                          isThreeLine: false,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.orange),
                                onPressed: () async {
                                  final updatedEntry = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            EntryFormPage(entry: entry)),
                                  );
                                  if (updatedEntry != null) {
                                    _editEntry(index, updatedEntry);
                                  }
                                },
                              ),

                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteEntry(index),
                        ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
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

  DiarySearchDelegate(this.entries);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => query = '',
        icon: Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, ''),
      icon: Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return SizedBox.shrink();
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
          leading: Text(result.emoji, style: TextStyle(fontSize: 28)),
          title: Text(result.title),
          subtitle: Text(
            DateFormat.yMMMd().add_jm().format(result.date),
            style: TextStyle(fontSize: 12),
          ),
          onTap: () => close(context, result.title),
        );
      },
    );
  }
}