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
Learning
English;German;Comment
Chapter 1
house;Haus;Noun
Chapter 2
dog;Hund;Noun
''';
      final result = parserService.parseCsv(csv);

      expect(result.vocabularyItems.length, 2);
      expect(result.title, 'Learning');
      expect(result.languageA, 'English');
      expect(result.languageB, 'German');
      expect(result.commentHeader, 'Comment');

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
Learning
English;German;Comment
Chapter 1: Intro
nice;schön;Adj.
bright;hell;Adj;
house;Haus;;
Chapter 2: Deep Dive
question;Frage;;Chapter 2: Deep Dive
hello;Hallo
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

    test('handles empty lines and missing first chapter name', () {
      const csv = '''
Learning

English;German;Comment

house;Haus;
      
dog;Hund
''';
      final result = parserService.parseCsv(csv);

      expect(result.vocabularyItems.length, 2);
      expect(result.vocabularyItems[0].termA, 'house');
      expect(result.vocabularyItems[1].termA, 'dog');
      expect(
        result.vocabularyItems[1].chapter,
        '',
      ); // Inherits from 'house'
    });

    test('handles complex fields with quotes and semicolons correctly', () {
      const csv = '''
Learning
English;German
Chapter 1
"hello; hi";"Hallo; Moin";"A common greeting; used every day"
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
          VocabularyItem.create(bookId: "test", 
            termA: 'house',
            termB: 'Haus',
            comment: 'Noun',
            chapter: 'Chapter 1',
          ),
          VocabularyItem.create(bookId: "test", 
            termA: 'dog',
            termB: 'Hund',
            comment: 'Noun',
            chapter: 'Chapter 1',
          ),
          VocabularyItem.create(bookId: "test", 
            termA: 'run',
            termB: 'rennen',
            comment: 'Verb',
            chapter: 'Chapter 2',
          ),
          VocabularyItem.create(bookId: "test", 
            termA: 'walk',
            termB: 'gehen',
            comment: 'Verb',
            chapter: 'Chapter 2',
          ),
        ];

        final csv = parserService.generateCsv(
          vocabularyItems: vocabularyItems,
          title: 'Learning',
          languageA: 'English',
          languageB: 'German',
          commentHeader: 'Comment'
        );

        // Expected format:
        // Learning
        // English;German;Comment
        // Chapter 1
        // house;Haus;Noun
        // dog;Hund;Noun
        // Chapter 2
        // run;rennen;Verb
        // walk;gehen;Verb

        final lines = csv.split('\r\n');
        expect(lines[0], 'Learning');
        expect(lines[1], 'English;German;Comment');
        expect(lines[2], 'Chapter 1');
        expect(lines[3], 'house;Haus;Noun');
        expect(lines[4], 'dog;Hund;Noun');
        expect(lines[5], 'Chapter 2');
        expect(lines[6], 'run;rennen;Verb');
        expect(lines[7], 'walk;gehen;Verb');
      },
    );
  });
}
