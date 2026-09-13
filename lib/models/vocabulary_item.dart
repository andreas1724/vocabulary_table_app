import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class VocabularyItem {
  const VocabularyItem({
    required this.id,
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
      chapterId: json['chapterId'] as String? ?? '',
      termA: json['termA'] as String? ?? '',
      termB: json['termB'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
      deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
      // Safely parse order, handling potential double values from JSON
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  factory VocabularyItem.create({
    String? id,
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
  final String chapterId;
  final String termA;
  final String termB;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int order;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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

  VocabularyItem copyWith({
    String? id,
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
    chapterId: chapterId ?? this.chapterId,
    termA: termA ?? this.termA,
    termB: termB ?? this.termB,
    comment: comment ?? this.comment,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    order: order ?? this.order,
  );

  @override
  String toString() {
    return 'VocabularyItem(termA: $termA, termB: $termB, comment: $comment, id: $id, chapterId: $chapterId, order: $order)';
  }
}
