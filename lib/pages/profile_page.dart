// ✨ Imports
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../models/diary_entry.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'My Diary';
  String _mood = '';
  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'My Diary';
      _mood = prefs.getString('userMood') ?? '';
      final avatarPath = prefs.getString('avatarPath');
      if (avatarPath != null) _avatarFile = File(avatarPath);
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('userName', _userName);
    prefs.setString('userMood', _mood);
    if (_avatarFile != null) prefs.setString('avatarPath', _avatarFile!.path);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
      _saveProfile();
    }
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: _userName);
    final moodController = TextEditingController(text: _mood);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: moodController,
              decoration: InputDecoration(labelText: 'Mood'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _userName = nameController.text.trim().isEmpty
                    ? 'Name'
                    : nameController.text.trim();
                _mood = moodController.text.trim();
              });
              _saveProfile();
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  int _calculateLongestStreak(List<DiaryEntry> entries) {
    if (entries.isEmpty) return 0;
    entries.sort((a, b) => a.date.compareTo(b.date));
    int longest = 1;
    int current = 1;

    for (int i = 1; i < entries.length; i++) {
      final prev = entries[i - 1].date;
      final curr = entries[i].date;
      if (curr.difference(prev).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }

    return longest;
  }

  @override
  Widget build(BuildContext context) {
    final diaryBox = Hive.box<DiaryEntry>('diary');
    final entries = diaryBox.values.toList();
    final totalEntries = entries.length;

    final totalWords = entries.fold<int>(
      0,
      (sum, e) => sum + e.text.trim().split(RegExp(r'\s+')).length,
    );

    final longestStreak = _calculateLongestStreak(entries);

    final moodFrequency = <String, int>{};
    for (var entry in entries) {
      moodFrequency[entry.emoji] = (moodFrequency[entry.emoji] ?? 0) + 1;
    }

    final topMood = moodFrequency.isNotEmpty
        ? moodFrequency.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : '😶';

    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        backgroundColor: Color(0xFF009DC4),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _avatarFile != null
                          ? FileImage(_avatarFile!)
                          : AssetImage('assets/avatar.jpg') as ImageProvider,
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedEmojiBubbles(emojis: [topMood]),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                _userName,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (_mood.isNotEmpty)
                Text("Today's mood: $_mood", style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showEditDialog,
                icon: Icon(Icons.edit),
                label: Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:  Color.fromARGB(255, 173, 226, 238),
                ),
              ),
              SizedBox(height: 20),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  children: [
                    _buildStat("Diaries", "$totalEntries entries"),
                    _buildStat("Words", "$totalWords words"),
                    _buildStat("Streak", "$longestStreak days"),
                    _buildStat("Top Mood", topMood),
                  ],
                ),
              ),
              SizedBox(height: 40), // ✨ Bottom spacing added here
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

// ✨ Emoji bubble animation
class AnimatedEmojiBubbles extends StatelessWidget {
  final List<String> emojis;
  AnimatedEmojiBubbles({required this.emojis});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: List.generate(emojis.length, (index) {
        final emoji = emojis[index];
        final left = Random().nextDouble() * screenWidth;

        return Positioned(
          left: left,
          bottom: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: -80),
            duration: Duration(seconds: 4),
            curve: Curves.easeOut,
            builder: (_, value, __) => Opacity(
              opacity: 1 - (value.abs() / 80),
              child: Transform.translate(
                offset: Offset(0, value),
                child: Text(emoji, style: TextStyle(fontSize: 22)),
              ),
            ),
          ),
        );
      }),
    );
  }
}