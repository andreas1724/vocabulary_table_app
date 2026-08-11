class BookMetadata {
  final String id; // Represents the Google Drive File ID or a local UUID
  final String title;
  final DateTime modifiedTime;

  BookMetadata({
    required this.id,
    required this.title,
    required this.modifiedTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'modifiedTime': modifiedTime.toIso8601String(),
    };
  }

  factory BookMetadata.fromJson(Map<String, dynamic> json) {
    return BookMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      modifiedTime: DateTime.parse(json['modifiedTime'] as String),
    );
  }
}

class Book {
  final BookMetadata metadata;
  final String csvContent;

  Book({required this.metadata, required this.csvContent});
}
