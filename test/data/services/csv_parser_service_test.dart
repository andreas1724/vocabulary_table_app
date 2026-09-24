import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_table_app/data/services/csv_parser_service.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

void main() {
  group('CsvParserService Tests', () {
    late CsvParserService parserService;

    setUp(() {
      parserService = CsvParserService();
    });

    test('parses a standard CSV row correctly and assigns scoped orders', () {
      const csv = '''
Learning
English;German;Comment
Chapter 1
house;Haus;Noun
Chapter 2
dog;Hund;Noun
cat;Katze;Noun
''';
      final result = parserService.parseCsv(csv);

      expect(result.vocabularyItems.length, 3);
      expect(result.title, 'Learning');
      expect(result.languageA, 'English');
      expect(result.languageB, 'German');
      expect(result.commentHeader, 'Comment');

      final house = result.vocabularyItems[0];
      expect(house.termA, 'house');
      expect(house.termB, 'Haus');
      expect(house.comment, 'Noun');
      expect(house.chapterId, 'Chapter 1');
      // Verify that the first item in Chapter 1 starts at order 0
      expect(house.order, 0); 

      final dog = result.vocabularyItems[1];
      expect(dog.termA, 'dog');
      expect(dog.chapterId, 'Chapter 2');
      // Verify that the order resets to 0 for a new chapter
      expect(dog.order, 0); 

      final cat = result.vocabularyItems[2];
      expect(cat.termA, 'cat');
      expect(cat.chapterId, 'Chapter 2');
      // Verify that the order increments correctly within the same chapter
      expect(cat.order, 1); 
    });

    test(
      'inherits chapter and correctly increments order across empty chapter columns',
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
        
        expect(result.vocabularyItems[0].chapterId, 'Chapter 1: Intro');
        expect(result.vocabularyItems[0].order, 0);
        
        expect(result.vocabularyItems[1].chapterId, 'Chapter 1: Intro');
        expect(result.vocabularyItems[1].order, 1);
        
        expect(result.vocabularyItems[2].chapterId, 'Chapter 1: Intro');
        expect(result.vocabularyItems[2].order, 2);
        
        expect(result.vocabularyItems[3].chapterId, 'Chapter 2: Deep Dive');
        expect(result.vocabularyItems[3].order, 0);
        
        expect(result.vocabularyItems[4].chapterId, 'Chapter 2: Deep Dive');
        expect(result.vocabularyItems[4].order, 1);
      },
    );

    test('handles empty lines and missing first chapter name gracefully', () {
      const csv = '''
Learning

English;German;Comment

house;Haus;
      
dog;Hund
''';
      final result = parserService.parseCsv(csv);

      expect(result.vocabularyItems.length, 2);
      expect(result.vocabularyItems[0].termA, 'house');
      expect(result.vocabularyItems[0].order, 0);
      
      expect(result.vocabularyItems[1].termA, 'dog');
      expect(result.vocabularyItems[1].chapterId, ''); // Inherits from 'house'
      expect(result.vocabularyItems[1].order, 1);
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
      expect(result.vocabularyItems[0].chapterId, 'Chapter 1');
      expect(result.vocabularyItems[0].order, 0);

      expect(result.vocabularyItems[1].termA, 'quote "inside"');
      expect(result.vocabularyItems[1].termB, 'Zitat "drinnen"');
      expect(result.vocabularyItems[1].comment, '');
      expect(result.vocabularyItems[1].chapterId, 'Chapter 1');
      expect(result.vocabularyItems[1].order, 1);
    });

    test(
      'generateCsv creates CSV with inherited chapters (empty when same)',
      () {
        final now = DateTime.now().toUtc();
        
        // Use explicit instantiation to guarantee structural integrity for the encoder
        final vocabularyItems = [
          VocabularyItem(
            id: 'v1',
            bookId: 'test',
            termA: 'house',
            termB: 'Haus',
            comment: 'Noun',
            chapterId: 'Chapter 1',
            order: 0,
            createdAt: now,
            updatedAt: now,
          ),
          VocabularyItem(
            id: 'v2',
            bookId: 'test',
            termA: 'dog',
            termB: 'Hund',
            comment: 'Noun',
            chapterId: 'Chapter 1',
            order: 1,
            createdAt: now,
            updatedAt: now,
          ),
          VocabularyItem(
            id: 'v3',
            bookId: 'test',
            termA: 'run',
            termB: 'rennen',
            comment: 'Verb',
            chapterId: 'Chapter 2',
            order: 0,
            createdAt: now,
            updatedAt: now,
          ),
          VocabularyItem(
            id: 'v4',
            bookId: 'test',
            termA: 'walk',
            termB: 'gehen',
            comment: 'Verb',
            chapterId: 'Chapter 2',
            order: 1,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final csv = parserService.generateCsv(
          vocabularyItems: vocabularyItems,
          title: 'Learning',
          languageA: 'English',
          languageB: 'German',
          commentHeader: 'Comment',
        );

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