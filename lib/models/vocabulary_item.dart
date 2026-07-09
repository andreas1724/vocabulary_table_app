import 'package:uuid/uuid.dart';

enum ColumnName { termA, termB, comment }

const _uuid = Uuid();

class VocabularyItem {
  VocabularyItem({
    String? id,
    required this.termA,
    required this.termB,
    this.comment = '',
  }) : id = id ?? _uuid.v4();

  final String id;
  final String termA;
  final String termB;
  final String comment;
}

extension VocabularyItemX on VocabularyItem {
  VocabularyItem copyWith({String? termA, String? termB, String? comment}) =>
      VocabularyItem(
        id: id,
        termA: termA ?? this.termA,
        termB: termB ?? this.termB,
        comment: comment ?? this.comment,
      );

  String operator [](ColumnName column) => switch (column) {
    .termA => termA,
    .termB => termB,
    .comment => comment,
  };
}
