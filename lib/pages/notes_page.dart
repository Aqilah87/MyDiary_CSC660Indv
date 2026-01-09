import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import 'note_form_page.dart';

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    setState(() {
      _notes = NoteService.getNotesSortedByDate();
      _filteredNotes = _notes;
    });
  }

  void _searchNotes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredNotes = _notes;
      } else {
        _filteredNotes = NoteService.searchNotes(query);
      }
    });
  }

  void _addNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteFormPage()),
    );

    if (result == true) {
      _loadNotes();
    }
  }

  void _editNote(Note note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteFormPage(note: note),
      ),
    );

    if (result == true) {
      _loadNotes();
    }
  }

  void _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Note?'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: Text('Delete'),
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await NoteService.deleteNote(note.id);
      _loadNotes();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final noteDate = DateTime(date.year, date.month, date.day);

    if (noteDate == today) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (noteDate == yesterday) {
      return 'Yesterday, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getNoteColor(String? colorName) {
    switch (colorName) {
      case 'yellow':
        return Colors.yellow.shade100;
      case 'green':
        return Colors.green.shade100;
      case 'blue':
        return Colors.blue.shade100;
      case 'pink':
        return Colors.pink.shade100;
      case 'purple':
        return Colors.purple.shade100;
      default:
        return Colors.amber.shade50;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: TextStyle(color: Colors.white),
                onChanged: _searchNotes,
              )
            : Text('Notes'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredNotes = _notes;
                }
              });
            },
          ),
        ],
      ),
      body: _filteredNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add,
                    size: 100,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _isSearching && _searchController.text.isNotEmpty
                        ? 'No notes found'
                        : 'No notes yet',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (!_isSearching)
                    Text(
                      'Tap + to create your first note',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _filteredNotes.length,
              itemBuilder: (context, index) {
                final note = _filteredNotes[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  color: _getNoteColor(note.color),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _editNote(note),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  note.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteNote(note),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            note.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: 4),
                              Text(
                                _formatDate(note.lastModifiedDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        backgroundColor: Colors.deepPurple,
        child: Icon(Icons.add),
        tooltip: 'Add Note',
      ),
    );
  }
}