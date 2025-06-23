import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/diary_entry.dart';
import 'dart:io';

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
  String _selectedFont = 'Roboto';
  File? _selectedImage;
  bool isFavorite = false;

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableFonts = ['Roboto', 'Lobster', 'Dancing Script', 'Pacifico'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'New Diary' : 'Edit Entry'),
        backgroundColor: const Color.fromARGB(255, 30, 160, 216),

        actions: [
          // IconButton for favorite toggle
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.yellow[700] : Colors.white,
              ),
            onPressed: () {
              setState(() {
                isFavorite = !isFavorite;
              });
            },
          ),

          // TextButton for saving the entry
          TextButton(
            onPressed: _submitEntry,
            child: Text(
              widget.entry == null ? 'Save' : 'Update',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],

                ),

      body: SingleChildScrollView(
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
              items: ['😊', '😢', '😡', '😍', '😴', '😞', '😤', '😨', '🤒', '😎','😄','🌧️', '☀️', '❤️', '💔', '🤔', '💐', '🎂'].map((String emoji) {
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
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Image.file(_selectedImage!, height: 150),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.photo),
                  label: Text('Add Photo'),
                ),
                SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedFont,
                  items: availableFonts.map((font) {
                    return DropdownMenuItem(
                      value: font,
                      child: Text(font),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFont = value!;
                    });
                  },
                ),
          ],
        ),
          ],
      ),
      ),
    );
  }
}