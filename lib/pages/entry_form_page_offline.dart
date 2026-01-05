import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../models/diary_entry.dart';
import '../services/draft_service.dart';
import '../helpers/network_helper.dart';
import '../helpers/voice_helper.dart'; // ✅ NEW IMPORT

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
  bool _isOnline = true;
  
  // ✅ NEW: Voice input variables
  bool _isListening = false;
  String _voiceText = '';
  final VoiceHelper _voiceHelper = VoiceHelper();

  final List<String> _emojiList = [
    '😊', '😢', '😡', '😍', '😎', 
    '🤔', '😴', '🤗', '😱', '🥳'
  ];

  @override
  void initState() {
    super.initState();
    
    _checkOnlineStatus();
    _initializeVoice(); // ✅ NEW: Initialize voice
    
    if (widget.entry != null) {
      _loadExistingEntry();
    } else {
      _checkAndLoadDraft();
    }
    
    _setupAutoSave();
    _titleController.addListener(_onTextChanged);
    _textController.addListener(_onTextChanged);
  }

  Future<void> _checkOnlineStatus() async {
    final online = await NetworkHelper().isOnline();
    setState(() {
      _isOnline = online;
    });
  }

  // ✅ NEW: Initialize voice helper
  Future<void> _initializeVoice() async {
    await _voiceHelper.initialize();
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

  // ✅ NEW: Start voice input
  Future<void> _startVoiceInput() async {
    // Check if online first
    final isOnline = await NetworkHelper().isOnline();
    
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('🎤 Voice input requires internet connection'),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Check permission
    final hasPermission = await _voiceHelper.checkPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.mic_off, color: Colors.white),
              SizedBox(width: 8),
              Text('Microphone permission is required'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isListening = true;
      _voiceText = 'Listening...';
    });

    final started = await _voiceHelper.startListening(
      onResult: (text) {
        setState(() {
          _voiceText = text;
          // Append voice text to content
          if (_textController.text.isNotEmpty) {
            _textController.text += ' ' + text;
          } else {
            _textController.text = text;
          }
          _isListening = false;
          _hasUnsavedChanges = true;
        });
      },
      onPartialResult: (text) {
        setState(() {
          _voiceText = text;
        });
      },
      locale: 'en_US', // Change to 'ms_MY' for Malay
    );

    if (!started) {
      setState(() {
        _isListening = false;
        _voiceText = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start voice input'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ NEW: Stop voice input
  Future<void> _stopVoiceInput() async {
    await _voiceHelper.stopListening();
    setState(() {
      _isListening = false;
      _voiceText = '';
    });
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

    final isOnline = await NetworkHelper().isOnline();

    final newEntry = DiaryEntry(
      title: title,
      text: text,
      emoji: _selectedEmoji,
      date: widget.entry?.date ?? DateTime.now(),
      imagePath: _imagePath,
      isDraft: !isOnline,
      isPublished: isOnline,
      publishedDate: isOnline ? DateTime.now() : null,
    );

    await DraftService.clearDraft();

    Navigator.pop(context, newEntry);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isOnline ? Icons.cloud_done : Icons.edit_note,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Text(isOnline 
                ? '✅ Entry published!' 
                : '📝 Saved as draft (offline)'),
          ],
        ),
        backgroundColor: isOnline ? Colors.green : Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _publishDraft() async {
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

    final publishedEntry = DiaryEntry(
      title: title,
      text: text,
      emoji: _selectedEmoji,
      date: widget.entry?.date ?? DateTime.now(),
      imagePath: _imagePath,
      isDraft: false,
      isPublished: true,
      publishedDate: DateTime.now(),
    );

    await DraftService.clearDraft();

    Navigator.pop(context, publishedEntry);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.publish, color: Colors.white),
            SizedBox(width: 12),
            Text('✅ Draft published!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // ✅ Stop listening if active
    if (_isListening) {
      await _stopVoiceInput();
    }
    
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
    _voiceHelper.dispose(); // ✅ NEW: Dispose voice helper
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
              // Status banner
              FutureBuilder<bool>(
                future: NetworkHelper().isOnline(),
                builder: (context, snapshot) {
                  final isOnline = snapshot.data ?? true;
                  return Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isOnline 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOnline 
                            ? Colors.green.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOnline ? Icons.cloud_done : Icons.cloud_off,
                          color: isOnline ? Colors.green : Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isOnline 
                                ? '🟢 Online: Entry will be published'
                                : '🟠 Offline: Entry will be saved as draft',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOnline ? Colors.green[700] : Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 20),

              // Emoji selector
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

              // Title field
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              SizedBox(height: 16),

              // ✅ UPDATED: Content field with voice button
              Stack(
                children: [
                  TextField(
                    controller: _textController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: 'Write your thoughts...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      // Add padding for voice button
                      contentPadding: EdgeInsets.fromLTRB(12, 12, 60, 12),
                    ),
                  ),
                  
                  // ✅ NEW: Floating voice button
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isListening ? _stopVoiceInput : _startVoiceInput,
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isListening 
                                ? Colors.red.shade400 
                                : (_isOnline 
                                    ? Theme.of(context).primaryColor 
                                    : Colors.grey.shade400),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ✅ NEW: Voice status indicator
              if (_isListening || _voiceText.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(top: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_isListening)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      if (_isListening) SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _voiceText,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).primaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 16),

              // Image section
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

              // Publish draft button (for drafts when online)
              if (widget.entry != null && widget.entry!.isDraft)
                FutureBuilder<bool>(
                  future: NetworkHelper().isOnline(),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return Column(
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.publish),
                            label: Text('Publish Draft (You\'re Online!)'),
                            onPressed: _publishDraft,
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),
                        ],
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),

              // Regular save button
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