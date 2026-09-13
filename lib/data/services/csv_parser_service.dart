import 'package:csv/csv.dart';

import 'package:vocabulary_table_app/models/vocabulary_item.dart';

class ParsedCsvResult {
  ParsedCsvResult({
    required this.vocabularyItems,
    required this.title,
    required this.languageA,
    required this.languageB,
    required this.commentHeader,
  });

  final List<VocabularyItem> vocabularyItems;
  final String title;
  final String languageA;
  final String languageB;
  final String commentHeader;
}

class CsvParserService {
  // Use the Csv codec with semicolon as delimiter
  // A field with semicolon has to be quoted with " (RFC 4180)
  // dynamicTyping: false -> ensure numbers like "1" are parsed as strings (default)
  // skipEmptyLines: true -> every row has at least one item (default)
  CsvParserService({this.fieldDelimiter = ';'})
    : _converter = Csv(fieldDelimiter: fieldDelimiter);

  final String fieldDelimiter;
  final Csv _converter;

  /// Parses the CSV string based on the format:
  /// LanguageA;LanguageB;Comment
  ParsedCsvResult parseCsv(String csvContent) {
    final rows = _converter.decode(csvContent);

    final vocabularyItems = <VocabularyItem>[];
    String currentChapter = '';
    String title = '';
    String languageA = '';
    String languageB = '';
    String commentHeader = '';

    // Get metadata from first two rows
    if (rows.isNotEmpty) {
      final titleRow = rows[0];
      title = titleRow[0].toString().trim();
    }

    if (rows.length > 1) {
      final headerRow = rows[1];
      languageA = headerRow[0].toString().trim();
      if (headerRow.length > 1) {
        languageB = headerRow[1].toString().trim();
      }
      if (headerRow.length > 2) {
        commentHeader = headerRow[2].toString().trim();
      }
    }

    // Vocabulary data starts at 3rd row
    for (var i = 2; i < rows.length; i++) {
      final row = rows[i];

      // Rows containing only one value -> chapter name. If skipped, the name remains.
      if (row.length == 1) {
        currentChapter = row[0].toString().trim();
        continue;
      }

      final termA = row[0].toString().trim();
      final termB = row[1].toString().trim();
      final comment = row.length > 2 ? row[2].toString().trim() : '';

      vocabularyItems.add(
        VocabularyItem.create(
          bookId:
              'pending', // Pending, will be correctly set by the caller/save operation
          termA: termA,
          termB: termB,
          comment: comment,
          chapterId: currentChapter,
          order: vocabularyItems.length,
        ),
      );
    }

    return ParsedCsvResult(
      vocabularyItems: vocabularyItems,
      title: title,
      languageA: languageA,
      languageB: languageB,
      commentHeader: commentHeader,
    );
  }

  /// Generates a CSV string from a list of vocabularies.
  /// To keep the CSV clean and easy to edit manually, it only writes
  /// the chapter name if it differs from the previous row's chapter.
  String generateCsv({
    required List<VocabularyItem> vocabularyItems,
    required String title,
    required String languageA,
    required String languageB,
    required String commentHeader,
  }) {
    final rows = <List<String>>[];
    rows.add([title]);

    // Add row with dynamic header names
    rows.add([languageA, languageB, commentHeader]);

    String lastChapter = '';

    for (final vocabulary in vocabularyItems) {
      if (vocabulary.chapterId != lastChapter) {
        rows.add([vocabulary.chapterId.trim()]);
        lastChapter = vocabulary.chapterId;
      }
      rows.add([
        vocabulary.termA.trim(),
        vocabulary.termB.trim(),
        vocabulary.comment.trim(),
      ]);
    }

    // We use lineDelimiter: '\r\n' for better compatibility with Excel/Drive (default)
    // and fieldDelimiter: ';' as per project requirements.
    return _converter.encode(rows);
  }
}
