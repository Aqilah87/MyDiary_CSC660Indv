import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/note_service.dart';

// NoteFormPage - Form to create new note or edit existing note
// Supports color coding and validates input before saving
class NoteFormPage extends StatefulWidget {
  final Note? note; // If null = create new, if not null = edit existing

  NoteFormPage({this.note});

  @override
  _NoteFormPageState createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedColor; // Stores user's color choice

  // Available color options for notes
  final List<Map<String, dynamic>> _colors = [
    {'name': 'yellow', 'color': Colors.yellow.shade100, 'label': '🟨 Yellow'},
    {'name': 'green', 'color': Colors.green.shade100, 'label': '🟩 Green'},
    {'name': 'blue', 'color': Colors.blue.shade100, 'label': '🟦 Blue'},
    {'name': 'pink', 'color': Colors.pink.shade100, 'label': '🟪 Pink'},
    {'name': 'purple', 'color': Colors.purple.shade100, 'label': '🟣 Purple'},
  ];

  @override
  void initState() {
    super.initState();
    // If editing existing note, load its data into form
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _selectedColor = widget.note!.color;
    }
  }

  // Save note to database (create new or update existing)
  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Validate title is not empty
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate content is not empty
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter some content'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.note == null) {
      // CREATE NEW NOTE
      // Generate unique ID using timestamp
      final newNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        createdDate: DateTime.now(),
        lastModifiedDate: DateTime.now(),
        color: _selectedColor,
      );
      await NoteService.addNote(newNote);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Note created!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // UPDATE EXISTING NOTE
      // Keep original created date, update modified date
      final updatedNote = widget.note!.copyWith(
        title: title,
        content: content,
        color: _selectedColor,
        lastModifiedDate: DateTime.now(),
      );
      await NoteService.updateNote(updatedNote);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Note updated!'),
          backgroundColor: Colors.green,
        ),
      );
    }

    // Return to previous page with success flag
    Navigator.pop(context, true);
  }

  // Prevent accidental data loss when back button pressed
  Future<bool> _onWillPop() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // If user has typed something, confirm before leaving
    if (title.isNotEmpty || content.isNotEmpty) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Discard Changes?'),
          content: Text('You have unsaved changes. Do you want to leave without saving?'),
          actions: [
            TextButton(
              child: Text('Stay'),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              child: Text('Discard'),
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      );
      return leave ?? false;
    }
    // If nothing typed, allow leaving without confirmation
    return true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Handle back button press
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
          backgroundColor: Colors.deepPurple,
          actions: [
            // Save button in app bar
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _saveNote,
              tooltip: 'Save',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title input field
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter note title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.title),
                ),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 16),

              // Color selection section
              Text(
                'Note Color',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              // Display color options as chips
              Wrap(
                spacing: 8,
                children: _colors.map((colorData) {
                  final isSelected = colorData['name'] == _selectedColor;
                  return ChoiceChip(
                    label: Text(colorData['label']),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedColor = selected ? colorData['name'] : null;
                      });
                    },
                    selectedColor: colorData['color'],
                    backgroundColor: Colors.grey.shade200,
                  );
                }).toList(),
              ),

              SizedBox(height: 16),

              // Content input field (multiline)
              TextField(
                controller: _contentController,
                maxLines: 15,
                decoration: InputDecoration(
                  labelText: 'Content',
                  hintText: 'Write your note here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
              ),

              SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.save),
                  label: Text(
                    widget.note == null ? 'Create Note' : 'Update Note',
                    style: TextStyle(fontSize: 16),
                  ),
                  onPressed: _saveNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 8),

              // Information text about local storage
              Center(
                child: Text(
                  '💾 Notes are saved locally on your device',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}