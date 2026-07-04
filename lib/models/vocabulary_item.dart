import 'package:uuid/uuid.dart';

class VocabularyItem {
  VocabularyItem({
    String? id,
    required this.termA,
    required this.termB,
    this.comment = '',
  }) : id = id ?? const Uuid().v4();

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
}
