import 'package:csv/csv.dart';

import 'package:vocabulary_table_app/data/models/vocab_entity.dart';

class CsvParserService {
  /// Parses the CSV string based on the format:
  /// LanguageA;LanguageB;Comment;Chapter
  /// Empty chapter cells inherit the chapter from the previous row.
  ParsedCsvResult parseCsv(
    String csvContent, {
    String defaultChapter = 'Unknown Chapter',
  }) {
    // 2. Let the csv package do the heavy lifting
    // Use the Csv codec with semicolon as delimiter
    // dynamicTyping: false -> ensure numbers like "1" are parsed as strings
    final converter = Csv(fieldDelimiter: ';', dynamicTyping: false);
    final rows = converter.decode(csvContent);

    final vocabEntities = <VocabEntity>[];
    String currentChapter = defaultChapter;
    String languageA = 'Language A';
    String languageB = 'Language B';

    if (rows.isEmpty) {
      return ParsedCsvResult(
        vocabEntities: vocabEntities,
        languageA: languageA,
        languageB: languageB,
      );
    }

    // Parse header row
    final headerRow = rows[0];
    if (headerRow.isNotEmpty) {
      languageA = headerRow[0].toString().trim();
      if (headerRow.length > 1) {
        languageB = headerRow[1].toString().trim();
      }
    }

    // Start at index 1 to skip the header row
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];

      // Skip rows that are completely empty or have no semicolon
      if (row.isEmpty || row.length < 2) continue;

      final termA = row[0].toString().trim();
      final termB = row[1].toString().trim();

      // If both language columns are empty, it's not a valid vocabulary item
      if (termA.isEmpty && termB.isEmpty) continue;

      final comment = row.length > 2 ? row[2].toString().trim() : '';
      final chapterColumn = row.length > 3 ? row[3].toString().trim() : '';

      // State update: If a new chapter is defined, remember it
      if (chapterColumn.isNotEmpty) {
        currentChapter = chapterColumn;
      }

      vocabEntities.add(
        VocabEntity(
          termA: termA,
          termB: termB,
          comment: comment,
          chapter: currentChapter,
        ),
      );
    }

    return ParsedCsvResult(
      vocabEntities: vocabEntities,
      languageA: languageA,
      languageB: languageB,
    );
  }

  /// Generates a CSV string from a list of vocabularies.
  /// To keep the CSV clean and easy to edit manually, it only writes
  /// the chapter name if it differs from the previous row's chapter.
  String generateCsv({
    required List<VocabEntity> vocabEntities,
    required String languageA,
    required String languageB,
  }) {
    final rows = <List<dynamic>>[];

    // Add header row with dynamic language names
    rows.add([languageA, languageB, 'Comment', 'Chapter']);

    String lastChapter = '';

    for (final vocab in vocabEntities) {
      final String chapterToWrite;
      if (vocab.chapter != lastChapter) {
        chapterToWrite = vocab.chapter;
        lastChapter = vocab.chapter;
      } else {
        chapterToWrite = '';
      }

      rows.add([vocab.termA, vocab.termB, vocab.comment, chapterToWrite]);
    }

    // We use lineDelimiter: '\r\n' for better compatibility with Excel/Drive
    // and fieldDelimiter: ';' as per project requirements.
    return Csv(fieldDelimiter: ';', lineDelimiter: '\r\n').encode(rows);
  }
}
