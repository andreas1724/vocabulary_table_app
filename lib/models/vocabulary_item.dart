import 'package:uuid/uuid.dart';

enum ColumnName { termA, termB, comment, chapter, id }

const _uuid = Uuid();

class VocabularyItem {
  VocabularyItem({
    String? id,
    required this.termA,
    required this.termB,
    this.comment = '',
    this.chapter = '',
  }) : id = id ?? _uuid.v4();

  final String id;
  final String termA;
  final String termB;
  final String comment;
  final String chapter;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'termA': termA,
      'termB': termB,
      'comment': comment,
      'chapter': chapter,
    };
  }

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id'] as String,
      termA: json['termA'] as String,
      termB: json['termB'] as String,
      comment: json['comment'] as String,
      chapter: json['chapter'] as String,
    );
  }

  VocabularyItem copyWith({
    String? termA,
    String? termB,
    String? comment,
    String? chapter,
    String? id,
  }) => VocabularyItem(
    termA: termA ?? this.termA,
    termB: termB ?? this.termB,
    comment: comment ?? this.comment,
    chapter: chapter ?? this.chapter,
    id: id ?? this.id,
  );

  String operator [](ColumnName column) => switch (column) {
    .termA => termA,
    .termB => termB,
    .comment => comment,
    .chapter => chapter,
    .id => id,
  };

  @override
  String toString() {
    return 'VocabularyItem(termA: $termA, termB: $termB, comment: $comment, chapter: $chapter, id: $id)';
  }
}
