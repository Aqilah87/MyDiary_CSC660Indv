import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
              decoration: InputDecoration(labelText: 'Mood: '),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
      backgroundColor: const Color.fromARGB(255, 115, 204, 241),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 24),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _avatarFile != null
                    ? FileImage(_avatarFile!)
                    : AssetImage('assets/avatar.jpg') as ImageProvider,
              ),
            ),
            SizedBox(height: 12),
            Text(
              _userName,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (_mood.isNotEmpty)
            Text(
              "Today's mood: $_mood",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showEditDialog,
              icon: Icon(Icons.edit),
              label: Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 25, 201, 255),
              ),
            ),
          ],
        ),
      ),
    );
  }
}