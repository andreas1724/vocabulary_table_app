import 'package:uuid/uuid.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

const _uuid = Uuid();

class BookMetadata {
  const BookMetadata({
    required this.id,
    required this.title,
    required this.languageA,
    required this.languageB,
    required this.commentHeader,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.cleanedAt,
  });

  factory BookMetadata.create({
    String? id,
    required String title,
    required String languageA,
    required String languageB,
    required String commentHeader,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? cleanedAt,
  }) {
    final now = DateTime.now().toUtc();
    return BookMetadata(
      id: id ?? _uuid.v4(),
      title: title,
      languageA: languageA,
      languageB: languageB,
      commentHeader: commentHeader,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      deletedAt: deletedAt,
      cleanedAt: cleanedAt ?? now,
    );
  }

  factory BookMetadata.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toUtc();
    return BookMetadata(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      languageA: json['languageA'] as String? ?? '',
      languageB: json['languageB'] as String? ?? '',
      commentHeader: json['commentHeader'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
      deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
      cleanedAt: DateTime.tryParse(json['cleanedAt'] as String? ?? '') ?? now,
    );
  }

  final String id; // Represents the Google Drive File ID or a local UUID
  final String title;
  final String languageA;
  final String languageB;
  final String commentHeader;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime cleanedAt;

  BookMetadata copyWith({
    String? id,
    String? title,
    String? languageA,
    String? languageB,
    String? commentHeader,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? cleanedAt,
  }) {
    return BookMetadata(
      id: id ?? this.id,
      title: title ?? this.title,
      languageA: languageA ?? this.languageA,
      languageB: languageB ?? this.languageB,
      commentHeader: commentHeader ?? this.commentHeader,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      cleanedAt: cleanedAt ?? this.cleanedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'languageA': languageA,
      'languageB': languageB,
      'commentHeader': commentHeader,
      // Defensively ensure UTC conversion to guarantee the 'Z' suffix
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'deletedAt': deletedAt?.toUtc().toIso8601String(),
      'cleanedAt': cleanedAt.toUtc().toIso8601String(),
    };
  }
}

class Book {
  const Book({required this.metadata, required this.items});

  final BookMetadata metadata;
  final List<VocabularyItem> items;
}
