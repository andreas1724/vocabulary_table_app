import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Chapter {
  const Chapter({
    required this.id,
    required this.bookId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.order,
  });

  factory Chapter.create({
    String? id,
    required String bookId,
    required String name,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int order = 0,
  }) {
    final now = DateTime.now().toUtc();

    return Chapter(
      id: id ?? _uuid.v4(),
      bookId: bookId,
      name: name,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      deletedAt: deletedAt,
      order: order,
    );
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toUtc();

    return Chapter(
      id: json['id'] as String? ?? '',
      bookId: json['bookId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
      deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String bookId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int order;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'name': name,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'deletedAt': deletedAt?.toUtc().toIso8601String(),
      'order': order,
    };
  }

  Chapter copyWith({
    String? id,
    String? bookId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? order,
  }) {
    return Chapter(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      order: order ?? this.order,
    );
  }
}
