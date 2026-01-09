import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 2) // DiaryEntry is typeId: 1
class Note extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String content;

  @HiveField(3)
  late DateTime createdDate;

  @HiveField(4)
  late DateTime lastModifiedDate;

  @HiveField(5)
  String? color; // Optional: for colored notes

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdDate,
    required this.lastModifiedDate,
    this.color,
  });

  // Create a copy with updated fields
  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
    String? color,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      color: color ?? this.color,
    );
  }
}