import 'package:hive/hive.dart';
import '../models/note.dart';

class NoteService {
  static const String _boxName = 'notes';

  // Get notes box
  static Box<Note> _getBox() {
    return Hive.box<Note>(_boxName);
  }

  // Initialize notes box
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Note>(_boxName);
    }
  }

  // Add new note
  static Future<void> addNote(Note note) async {
    final box = _getBox();
    await box.put(note.id, note);
  }

  // Update existing note
  static Future<void> updateNote(Note note) async {
    note.lastModifiedDate = DateTime.now();
    final box = _getBox();
    await box.put(note.id, note);
  }

  // Delete note
  static Future<void> deleteNote(String id) async {
    final box = _getBox();
    await box.delete(id);
  }

  // Get all notes
  static List<Note> getAllNotes() {
    final box = _getBox();
    return box.values.toList();
  }

  // Get note by ID
  static Note? getNoteById(String id) {
    final box = _getBox();
    return box.get(id);
  }

  // Get notes sorted by last modified (newest first)
  static List<Note> getNotesSortedByDate() {
    final notes = getAllNotes();
    notes.sort((a, b) => b.lastModifiedDate.compareTo(a.lastModifiedDate));
    return notes;
  }

  // Search notes by title or content
  static List<Note> searchNotes(String query) {
    if (query.isEmpty) return getAllNotes();
    
    final notes = getAllNotes();
    return notes.where((note) {
      final titleLower = note.title.toLowerCase();
      final contentLower = note.content.toLowerCase();
      final queryLower = query.toLowerCase();
      return titleLower.contains(queryLower) || contentLower.contains(queryLower);
    }).toList();
  }

  // Get note count
  static int getNotesCount() {
    return _getBox().length;
  }

  // Clear all notes (be careful with this!)
  static Future<void> clearAllNotes() async {
    final box = _getBox();
    await box.clear();
  }
}