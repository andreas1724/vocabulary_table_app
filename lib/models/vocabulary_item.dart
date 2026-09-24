import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class VocabularyItem {
  const VocabularyItem({
    required this.id,
    required this.bookId, // Added for NoSQL denormalization
    required this.chapterId,
    required this.termA,
    required this.termB,
    this.comment = '',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.order = 0,
  });

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toUtc();

    return VocabularyItem(
      id: json['id'] as String? ?? '',
      bookId: json['bookId'] as String? ?? '',
      chapterId: json['chapterId'] as String? ?? '',
      termA: json['termA'] as String? ?? '',
      termB: json['termB'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
      deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  factory VocabularyItem.create({
    String? id,
    required String bookId,
    required String chapterId,
    required String termA,
    required String termB,
    String comment = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int order = 0,
  }) {
    final now = DateTime.now().toUtc();

    return VocabularyItem(
      id: id ?? _uuid.v4(),
      bookId: bookId,
      chapterId: chapterId,
      termA: termA,
      termB: termB,
      comment: comment,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      deletedAt: deletedAt,
      order: order,
    );
  }

  final String id;
  final String bookId;
  final String chapterId;
  final String termA;
  final String termB;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int order;

  VocabularyItem copyWith({
    String? id,
    String? bookId,
    String? chapterId,
    String? termA,
    String? termB,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? order,
  }) => VocabularyItem(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    chapterId: chapterId ?? this.chapterId,
    termA: termA ?? this.termA,
    termB: termB ?? this.termB,
    comment: comment ?? this.comment,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    order: order ?? this.order,
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'chapterId': chapterId,
      'termA': termA,
      'termB': termB,
      'comment': comment,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'deletedAt': deletedAt?.toUtc().toIso8601String(),
      'order': order,
    };
  }

  @override
  String toString() {
    return 'VocabularyItem(id: $id, bookId: $bookId, chapterId: $chapterId, termA: $termA, termB: $termB, order: $order)';
  }
}