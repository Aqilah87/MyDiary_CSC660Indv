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

  DiaryEntry({
    required this.title,
    required this.text,
    required this.emoji,
    required this.date,
    this.imagePath,
  });
}

