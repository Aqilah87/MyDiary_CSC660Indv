import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../models/diary_entry.dart';
import '../services/draft_service.dart';

class EntryFormPageOffline extends StatefulWidget {
  final DiaryEntry? entry;

  EntryFormPageOffline({this.entry});

  @override
  _EntryFormPageOfflineState createState() => _EntryFormPageOfflineState();
}

class _EntryFormPageOfflineState extends State<EntryFormPageOffline> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  
  String _selectedEmoji = '😊';
  String? _imagePath;
  
  Timer? _autoSaveTimer;
  DateTime? _lastSaved;
  bool _hasUnsavedChanges = false;
  bool _isLoadingDraft = false;

  final List<String> _emojiList = [
    '😊', '😢', '😡', '😍', '😎', 
    '🤔', '😴', '🤗', '😱', '🥳'
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.entry != null) {
      _loadExistingEntry();
    } else {
      _checkAndLoadDraft();
    }
    
    _setupAutoSave();
    _titleController.addListener(_onTextChanged);
    _textController.addListener(_onTextChanged);
  }

  void _loadExistingEntry() {
    _titleController.text = widget.entry!.title;
    _textController.text = widget.entry!.text;
    _selectedEmoji = widget.entry!.emoji;
    _imagePath = widget.entry!.imagePath;
  }

  Future<void> _checkAndLoadDraft() async {
    setState(() => _isLoadingDraft = true);
    
    final hasDraft = await DraftService.hasDraft();
    
    if (hasDraft && mounted) {
      final age = await DraftService.getDraftAge();
      final ageStr = age != null ? DraftService.formatDraftAge(age) : 'unknown time';
      
      final restore = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.restore, color: Colors.blue),
              SizedBox(width: 8),
              Text('Draft Found'),
            ],
          ),
          content: Text(
            'You have an unsaved draft from $ageStr.\n\nDo you want to restore it?',
          ),
          actions: [
            TextButton(
              child: Text('Discard'),
              onPressed: () {
                DraftService.clearDraft();
                Navigator.pop(context, false);
              },
            ),
            ElevatedButton(
              child: Text('Restore'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      
      if (restore == true) {
        await _loadDraftData();
      }
    }
    
    setState(() => _isLoadingDraft = false);
  }

  Future<void> _loadDraftData() async {
    final draft = await DraftService.loadDraft();
    
    if (draft != null) {
      setState(() {
        _titleController.text = draft['title'] ?? '';
        _textController.text = draft['text'] ?? '';
        _selectedEmoji = draft['emoji'] ?? '😊';
        _imagePath = draft['imagePath'];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Draft restored!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _setupAutoSave() {
    _autoSaveTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_hasUnsavedChanges) {
        _saveDraft();
      }
    });
  }

  void _onTextChanged() {
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveDraft() async {
    final title = _titleController.text.trim();
    final text = _textController.text.trim();
    
    if (title.isEmpty && text.isEmpty) return;
    
    await DraftService.saveDraft(
      title: title,
      text: text,
      emoji: _selectedEmoji,
      imagePath: _imagePath,
    );
    
    setState(() {
      _lastSaved = DateTime.now();
      _hasUnsavedChanges = false;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _saveEntry() async {
    final title = _titleController.text.trim();
    final text = _textController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newEntry = DiaryEntry(
      title: title,
      text: text,
      emoji: _selectedEmoji,
      date: widget.entry?.date ?? DateTime.now(),
      imagePath: _imagePath,
    );

    await DraftService.clearDraft();

    Navigator.pop(context, newEntry);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Entry saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges || 
        _titleController.text.trim().isNotEmpty || 
        _textController.text.trim().isNotEmpty) {
      
      final leave = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Unsaved Changes'),
          content: Text(
            'You have unsaved changes. Your draft will be automatically saved.\n\nDo you want to leave?',
          ),
          actions: [
            TextButton(
              child: Text('Stay'),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              child: Text('Leave'),
              onPressed: () async {
                await _saveDraft();
                Navigator.pop(context, true);
              },
            ),
          ],
        ),
      );
      
      return leave ?? false;
    }
    
    return true;
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDraft) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.entry == null ? 'New Entry' : 'Edit Entry',
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          iconTheme: Theme.of(context).appBarTheme.iconTheme,
          actions: [
            if (_lastSaved != null)
              Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Saved',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
            if (_hasUnsavedChanges)
              Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Saving...',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.offline_bolt, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '✅ Offline Mode: Your data is saved locally and secure',
                        style: TextStyle(fontSize: 12, color: Colors.green[700]),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              Text(
                'How are you feeling?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _emojiList.map((emoji) {
                  final isSelected = emoji == _selectedEmoji;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedEmoji = emoji;
                        _hasUnsavedChanges = true;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Text(emoji, style: TextStyle(fontSize: 30)),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),

              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              SizedBox(height: 16),

              TextField(
                controller: _textController,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Write your thoughts...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              SizedBox(height: 16),

              if (_imagePath != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_imagePath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _imagePath = null;
                            _hasUnsavedChanges = true;
                          });
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              
              if (_imagePath == null)
                OutlinedButton.icon(
                  icon: Icon(Icons.image),
                  label: Text('Add Image'),
                  onPressed: _pickImage,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              
              SizedBox(height: 24),

              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text('Save Entry'),
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}