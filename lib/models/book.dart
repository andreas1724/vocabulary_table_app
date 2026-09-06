import 'package:vocabulary_table_app/models/vocabulary_item.dart';

class BookMetadata {
  BookMetadata({
    required this.id,
    required this.title,
    required this.languageA,
    required this.languageB,
    required this.modifiedTime,
  });

  factory BookMetadata.fromJson(Map<String, dynamic> json) {
    return BookMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      languageA: json['languageA'] as String,
      languageB: json['languageB'] as String,
      modifiedTime: DateTime.parse(json['modifiedTime'] as String),
    );
  }

  BookMetadata copyWith({
    String? id,
    String? title,
    String? languageA,
    String? languageB,
    DateTime? modifiedTime,
  }) {
    return BookMetadata(
      id: id ?? this.id,
      title: title ?? this.title,
      languageA: languageA ?? this.languageA,
      languageB: languageB ?? this.languageB,
      modifiedTime: modifiedTime ?? this.modifiedTime,
    );
  }

  final String id; // Represents the Google Drive File ID or a local UUID
  final String title;
  final String languageA;
  final String languageB;
  final DateTime modifiedTime;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'languageA': languageA,
      'languageB': languageB,
      'modifiedTime': modifiedTime.toIso8601String(),
    };
  }
}

class Book {
  Book({required this.metadata, required this.items});

  final BookMetadata metadata;
  final List<VocabularyItem> items;
}
