class Vocabulary {
  final String termA;
  final String termB;
  final String comment;
  final String chapter;

  Vocabulary({
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
  final List<Vocabulary> vocabularies;
  final String languageA;
  final String languageB;

  ParsedCsvResult({
    required this.vocabularies,
    required this.languageA,
    required this.languageB,
  });
}
