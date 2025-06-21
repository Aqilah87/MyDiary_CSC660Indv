import 'package:flutter/material.dart';
import '../models/diary_entry.dart';

class EntryFormPage extends StatefulWidget {
  final DiaryEntry? entry;

  EntryFormPage({this.entry});

  @override
  _EntryFormPageState createState() => _EntryFormPageState();
}

class _EntryFormPageState extends State<EntryFormPage> {
  final _textController = TextEditingController();
  final _titleController = TextEditingController();
  String _selectedEmoji = '😊';

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _textController.text = widget.entry!.text;
      _selectedEmoji = widget.entry!.emoji;
    }
  }

  void _submitEntry() {
    final newEntry = DiaryEntry(
      title: _titleController.text,
      text: _textController.text,
      emoji: _selectedEmoji,
      date: DateTime.now(),
    );
    Navigator.pop(context, newEntry);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'New Entry' : 'Edit Entry'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title',
            style: TextStyle(
              fontSize: 20,fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Enter title...',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedEmoji,
              items: ['😊', '😢', '😡', '😍', '😴', '😞', '😤', '😨', '🤒', '😎'].map((String emoji) {
                return DropdownMenuItem<String>(
                  value: emoji,
                  child: Text(emoji, style: TextStyle(fontSize: 24)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedEmoji = value!;
                });
              },
              decoration: InputDecoration(
                labelText: 'How do you feel?',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitEntry,
              child: Text(widget.entry == null ? 'Add Entry' : 'Update Entry'),
            ),
          ],
        ),
      ),
    );
  }
}