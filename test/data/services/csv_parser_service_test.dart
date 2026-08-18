import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_table_app/data/services/csv_parser_service.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

void main() {
  group('CsvParserService Tests', () {
    late CsvParserService parserService;

    setUp(() {
      parserService = CsvParserService();
    });

    test('parses a standard CSV row correctly', () {
      const csv = '''
English;German;Comment;Chapter
house;Haus;Noun;Chapter 1
dog;Hund;Noun;Chapter 2
''';
      final result = parserService.parseCsv(csv);

      expect(result.vocabularyItems.length, 2);
      expect(result.languageA, 'English');
      expect(result.languageB, 'German');

      expect(result.vocabularyItems[0].termA, 'house');
      expect(result.vocabularyItems[0].termB, 'Haus');
      expect(result.vocabularyItems[0].comment, 'Noun');
      expect(result.vocabularyItems[0].chapter, 'Chapter 1');

      expect(result.vocabularyItems[1].termA, 'dog');
      expect(result.vocabularyItems[1].chapter, 'Chapter 2');
    });

    test(
      'inherits chapter from the previous row when chapter column is empty',
      () {
        const csv = '''
English;German;Comment;Chapter
nice;schön;Adj.;Chapter 1: Intro
bright;hell;Adj;
house;Haus;;
question;Frage;;Chapter 2: Deep Dive
hello;Hallo;;
''';
        final result = parserService.parseCsv(csv);

        expect(result.vocabularyItems.length, 5);
        expect(result.vocabularyItems[0].chapter, 'Chapter 1: Intro');
        expect(result.vocabularyItems[1].chapter, 'Chapter 1: Intro');
        expect(result.vocabularyItems[2].chapter, 'Chapter 1: Intro');
        expect(result.vocabularyItems[3].chapter, 'Chapter 2: Deep Dive');
        expect(result.vocabularyItems[4].chapter, 'Chapter 2: Deep Dive');
      },
    );

    test('handles empty lines and invalid rows gracefully', () {
      const csv = '''
English;German;Comment;Chapter

invalid_line_without_semicolons
house;Haus;;Chapter 1
      
dog;Hund
''';
      final result = parserService.parseCsv(csv);

      expect(result.vocabularyItems.length, 2);
      expect(result.vocabularyItems[0].termA, 'house');
      expect(result.vocabularyItems[1].termA, 'dog');
      expect(
        result.vocabularyItems[1].chapter,
        'Chapter 1',
      ); // Inherits from 'house'
    });

    test('handles complex fields with quotes and semicolons correctly', () {
      const csv = '''
English;German;Comment;Chapter
"hello; hi";"Hallo; Moin";"A common greeting; used every day";Chapter 1
"quote ""inside""";"Zitat ""drinnen""";;
''';
      final result = parserService.parseCsv(csv);

      expect(result.vocabularyItems.length, 2);

      expect(result.vocabularyItems[0].termA, 'hello; hi');
      expect(result.vocabularyItems[0].termB, 'Hallo; Moin');
      expect(
        result.vocabularyItems[0].comment,
        'A common greeting; used every day',
      );
      expect(result.vocabularyItems[0].chapter, 'Chapter 1');

      expect(result.vocabularyItems[1].termA, 'quote "inside"');
      expect(result.vocabularyItems[1].termB, 'Zitat "drinnen"');
      expect(result.vocabularyItems[1].comment, '');
      expect(result.vocabularyItems[1].chapter, 'Chapter 1');
    });

    test(
      'generateCsv creates CSV with inherited chapters (empty when same)',
      () {
        final vocabularyItems = [
          VocabularyItem(
            termA: 'house',
            termB: 'Haus',
            comment: 'Noun',
            chapter: 'Chapter 1',
          ),
          VocabularyItem(
            termA: 'dog',
            termB: 'Hund',
            comment: 'Noun',
            chapter: 'Chapter 1',
          ),
          VocabularyItem(
            termA: 'run',
            termB: 'rennen',
            comment: 'Verb',
            chapter: 'Chapter 2',
          ),
          VocabularyItem(
            termA: 'walk',
            termB: 'gehen',
            comment: 'Verb',
            chapter: 'Chapter 2',
          ),
        ];

        final csv = parserService.generateCsv(
          vocabEntities: vocabularyItems,
          languageA: 'English',
          languageB: 'German',
        );

        // Expected format:
        // English;German;Comment;Chapter
        // house;Haus;Noun;Chapter 1
        // dog;Hund;Noun;
        // run;rennen;Verb;Chapter 2
        // walk;gehen;Verb;

        final lines = csv.split('\r\n');
        expect(lines[0], 'English;German;Comment;Chapter');
        expect(lines[1], 'house;Haus;Noun;Chapter 1');
        expect(lines[2], 'dog;Hund;Noun;');
        expect(lines[3], 'run;rennen;Verb;Chapter 2');
        expect(lines[4], 'walk;gehen;Verb;');
      },
    );
  });
}
