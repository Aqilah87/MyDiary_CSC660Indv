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

  void _addNewEntry(DiaryEntry entry) {
    setState(() {
      entries.add(entry);
    });
  }

  void _editEntry(int index, DiaryEntry updatedEntry) {
    setState(() {
      entries[index] = updatedEntry;
    });
  }

  void _deleteEntry(int index) {
    setState(() {
      entries.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Diary"),
        centerTitle: true,
      ),
      body: entries.isEmpty
          ? Center(child: Text("Let's write diary today."))
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(entry.text),
                    subtitle: Text(
                        entry.emoji + ' — ' + DateFormat.yMMMd().add_jm().format(entry.date)
                        ),
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
                                    EntryFormPage(entry: entry),
                              ),
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