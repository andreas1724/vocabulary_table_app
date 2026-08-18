class VocabEntity {
  VocabEntity({
    required this.termA,
    required this.termB,
    required this.comment,
    required this.chapter,
  });

  final String termA;
  final String termB;
  final String comment;
  final String chapter;

  @override
  String toString() {
    return 'Vocabulary(termA: $termA, termB: $termB, comment: $comment, chapter: $chapter)';
  }
}
