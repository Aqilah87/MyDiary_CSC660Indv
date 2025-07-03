import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/diary_entry.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
  File? _selectedImage;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _textController.text = widget.entry!.text;
      _selectedEmoji = widget.entry!.emoji;

      if (widget.entry!.imagePath != null) {
        _selectedImage = File(widget.entry!.imagePath!);
      }
    }
  }

  Future<String> saveImagePermanently(File image) async {
    final appDir = await getApplicationDocumentsDirectory();
    final filename = path.basename(image.path);
    final savedImage = await image.copy('${appDir.path}/$filename');
    return savedImage.path;
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

  void _submitEntry() {
    final newEntry = DiaryEntry(
      title: _titleController.text,
      text: _textController.text,
      emoji: _selectedEmoji,
      date: DateTime.now(),
      imagePath: _selectedImage?.path,
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.entry == null ? 'New Diary' : 'Edit Entry',
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.yellow[700] : theme.iconTheme.color,
            ),
            onPressed: () => setState(() => isFavorite = !isFavorite),
          ),
          TextButton(
            onPressed: _submitEntry,
            child: Text(
              widget.entry == null ? 'Save' : 'Update',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _titleController,
              style: theme.textTheme.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Enter title...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 4,
              style: theme.textTheme.bodyMedium,
              decoration: const InputDecoration(
                labelText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedEmoji,
              items: ['😊', '😢', '😡', '😍', '😴', '😞', '😤', '😨', '🤒', '😎', '😄', '🌧️', '☀️', '❤️', '💔', '🤔', '💐', '🎂']
                  .map((emoji) => DropdownMenuItem<String>(
                        value: emoji,
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedEmoji = value!),
              decoration: const InputDecoration(
                labelText: 'How do you feel?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Image.file(_selectedImage!, height: 150),
              ),
            Center(
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo),
                label: const Text('Add Photo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}