// lib/models/diary_entry.dart
// UPDATED with Draft/Published status

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'diary_entry.g.dart'; // for generated code

@HiveType(typeId: 0)
class DiaryEntry extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String text;

  @HiveField(2)
  String emoji;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? imagePath;

  @HiveField(5) // ✅ NEW: Is this a draft?
  bool isDraft;

  @HiveField(6) // ✅ NEW: Was this published online?
  bool isPublished;

  @HiveField(7) // ✅ NEW: When was it published?
  DateTime? publishedDate;

  DiaryEntry({
    required this.title,
    required this.text,
    required this.emoji,
    required this.date,
    this.imagePath,
    this.isDraft = false, // ✅ Default: not a draft
    this.isPublished = false, // ✅ Default: not published
    this.publishedDate,
  });

  // ✅ Helper: Check if entry needs publishing
  bool get needsPublishing => isDraft && !isPublished;

  // ✅ Helper: Get status badge text
  String get statusBadge {
    if (isPublished) return '✅ Published';
    if (isDraft) return '📝 Draft';
    return '💾 Saved';
  }

  // ✅ Helper: Get status color name
  String get statusColor {
    if (isPublished) return 'green';
    if (isDraft) return 'orange';
    return 'blue';
  }

  // ✅ Helper: Get background color (for cards)
  int get cardColorValue {
    if (isPublished) return 0xFFE0F7F4; // Light green
    if (isDraft) return 0xFFFFF4E6; // Light orange
    return 0xFFE0F7F4; // Default green
  }

  // ✅ Helper: Get border color value
  int get borderColorValue {
    if (isPublished) return 0xFF4CAF50; // Green
    if (isDraft) return 0xFFFF9800; // Orange
    return 0xFF9E9E9E; // Grey
  }
}