class VocabEntity {
  final String termA;
  final String termB;
  final String comment;
  final String chapter;

  VocabEntity({
    required this.termA,
    required this.termB,
    required this.comment,
    required this.chapter,
  });

  @override
  String toString() {
    return 'Vocabulary(termA: $termA, termB: $termB, comment: $comment, chapter: $chapter)';
  }
}

class ParsedCsvResult {
  final List<VocabEntity> vocabEntities;
  final String languageA;
  final String languageB;

  ParsedCsvResult({
    required this.vocabEntities,
    required this.languageA,
    required this.languageB,
  });
}
