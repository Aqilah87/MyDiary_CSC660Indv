import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DraftService {
  static const String DRAFT_KEY = 'diary_draft';
  static const String DRAFT_TIMESTAMP_KEY = 'diary_draft_timestamp';

  // Save draft automatically
  static Future<void> saveDraft({
    required String title,
    required String text,
    required String emoji,
    String? imagePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final draftData = {
      'title': title,
      'text': text,
      'emoji': emoji,
      'imagePath': imagePath,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(DRAFT_KEY, jsonEncode(draftData));
    await prefs.setString(DRAFT_TIMESTAMP_KEY, DateTime.now().toIso8601String());
    
    print('✅ Draft saved at ${DateTime.now()}');
  }

  // Load existing draft
  static Future<Map<String, dynamic>?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString(DRAFT_KEY);
    
    if (draftJson == null || draftJson.isEmpty) {
      return null;
    }
    
    try {
      final data = jsonDecode(draftJson) as Map<String, dynamic>;
      print('📝 Draft loaded from ${data['timestamp']}');
      return data;
    } catch (e) {
      print('❌ Error loading draft: $e');
      return null;
    }
  }

  // Check if draft exists
  static Future<bool> hasDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString(DRAFT_KEY);
    return draftJson != null && draftJson.isNotEmpty;
  }

  // Get draft age (berapa lama draft tu disimpan)
  static Future<Duration?> getDraftAge() async {
    final prefs = await SharedPreferences.getInstance();
    final timestampStr = prefs.getString(DRAFT_TIMESTAMP_KEY);
    
    if (timestampStr == null) return null;
    
    try {
      final timestamp = DateTime.parse(timestampStr);
      return DateTime.now().difference(timestamp);
    } catch (e) {
      return null;
    }
  }

  // Clear draft after successfully saving
  static Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(DRAFT_KEY);
    await prefs.remove(DRAFT_TIMESTAMP_KEY);
    print('🗑️ Draft cleared');
  }

  // Format draft age untuk display
  static String formatDraftAge(Duration age) {
    if (age.inMinutes < 1) {
      return 'Just now';
    } else if (age.inHours < 1) {
      return '${age.inMinutes} minute${age.inMinutes > 1 ? 's' : ''} ago';
    } else if (age.inDays < 1) {
      return '${age.inHours} hour${age.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${age.inDays} day${age.inDays > 1 ? 's' : ''} ago';
    }
  }
}