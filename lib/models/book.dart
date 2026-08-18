import 'package:vocabulary_table_app/models/vocabulary_item.dart';

class BookMetadata {
  BookMetadata({
    required this.id,
    required this.title,
    required this.modifiedTime,
  });

  factory BookMetadata.fromJson(Map<String, dynamic> json) {
    return BookMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      modifiedTime: DateTime.parse(json['modifiedTime'] as String),
    );
  }

  final String id; // Represents the Google Drive File ID or a local UUID
  final String title;
  final DateTime modifiedTime;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'modifiedTime': modifiedTime.toIso8601String(),
    };
  }
}

class Book {
  Book({required this.metadata, required this.items});

  final BookMetadata metadata;
  final List<VocabularyItem> items;
}
