import 'package:hive/hive.dart';

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

//class DiaryEntry {
  //final String title;
  //final String text;
  //final String emoji;
  //final DateTime date;

  DiaryEntry({
    required this.title,
    required this.text,
    required this.emoji,
    required this.date,
  });
}

