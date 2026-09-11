class Chapter {
  const Chapter({
    required this.id,
    required this.bookId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.order,
  });
  final String id;
  final String bookId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int order;
}
