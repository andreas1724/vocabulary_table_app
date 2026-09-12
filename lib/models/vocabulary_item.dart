import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class VocabularyItem {
  const VocabularyItem({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.termA,
    required this.termB,
    this.comment = '',
    this.order = 0,
  });

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id'] as String? ?? '',
      bookId: json['bookId'] as String? ?? '',
      chapter: json['chapter'] as String? ?? '',
      termA: json['termA'] as String? ?? '',
      termB: json['termB'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      // Safely parse order, handling potential double values from JSON
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  factory VocabularyItem.create({
    required String bookId,
    required String chapter,
    required String termA,
    required String termB,
    String comment = '',
    int order = 0,
  }) {
    return VocabularyItem(
      id: _uuid.v4(),
      bookId: bookId,
      chapter: chapter,
      termA: termA,
      termB: termB,
      comment: comment,
      order: order,
    );
  }

  final String id;
  final String bookId;
  final String termA;
  final String termB;
  final String comment;
  final String chapter;
  final int order;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'termA': termA,
      'termB': termB,
      'comment': comment,
      'chapter': chapter,
      'order': order,
    };
  }

  VocabularyItem copyWith({
    String? termA,
    String? termB,
    String? comment,
    String? chapter,
    String? id,
    String? bookId,
    int? order,
  }) => VocabularyItem(
    termA: termA ?? this.termA,
    termB: termB ?? this.termB,
    comment: comment ?? this.comment,
    chapter: chapter ?? this.chapter,
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    order: order ?? this.order,
  );

  @override
  String toString() {
    return 'VocabularyItem(bookId: $bookId, termA: $termA, termB: $termB, comment: $comment, chapter: $chapter, id: $id, order: $order)';
  }
}
