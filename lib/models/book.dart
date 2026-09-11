import 'package:vocabulary_table_app/models/vocabulary_item.dart';

class BookMetadata {
  const BookMetadata({
    required this.id,
    required this.title,
    required this.languageA,
    required this.languageB,
    required this.commentHeader,
    required this.updatedAt,
  });

  factory BookMetadata.fromJson(Map<String, dynamic> json) {
    return BookMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      languageA: json['languageA'] as String,
      languageB: json['languageB'] as String,
      commentHeader: json['commentHeader'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id; // Represents the Google Drive File ID or a local UUID
  final String title;
  final String languageA;
  final String languageB;
  final String commentHeader;
  final DateTime updatedAt;

  BookMetadata copyWith({
    String? id,
    String? title,
    String? languageA,
    String? languageB,
    String? commentHeader,
    DateTime? updatedAt,
  }) {
    return BookMetadata(
      id: id ?? this.id,
      title: title ?? this.title,
      languageA: languageA ?? this.languageA,
      languageB: languageB ?? this.languageB,
      commentHeader: commentHeader ?? this.commentHeader,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'languageA': languageA,
      'languageB': languageB,
      'commentHeader': commentHeader,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Book {
  const Book({required this.metadata, required this.items});

  final BookMetadata metadata;
  final List<VocabularyItem> items;
}
