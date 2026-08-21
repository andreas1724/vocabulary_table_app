/*
import 'package:flutter_test/flutter_test.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/data/controllers/vocab_repository.dart';
import 'package:vocabulary_table_app/data/services/csv_parser_service.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

void main() {
  group('VocabRepository Tests', () {
    late VocabRepository repository;
    late CsvParserService parserService;

    setUp(() {
      parserService = CsvParserService();
      repository = VocabRepository(parserService);
    });

    test('initial state is AsyncData with empty list', () {
      expect(repository.vocabularyItems.value.isLoading, false);
      expect(repository.vocabularyItems.value.hasError, false);
      expect(repository.vocabularyItems.value.value, isEmpty);
    });

    test(
      'loadFromCsvString parses valid CSV and updates state to AsyncData',
      () async {
        const csv = 'English;German;Comment;Chapter\nhouse;Haus;;Chapter 1';

        // Initially, we can wait for the future
        await repository.loadFromCsvString(csv);

        expect(repository.vocabularyItems.value.isLoading, false);
        expect(repository.vocabularyItems.value.hasError, false);
        expect(repository.vocabularyItems.value.value, isNotNull);
        expect(repository.vocabularyItems.value.value!.length, 1);
        expect(repository.vocabularyItems.value.value!.first.termA, 'house');
      },
    );

    test(
      'addVocabulary only works if current state is successful AsyncData',
      () async {
        // 1. Force an error state to verify it DOES NOT add
        // To do this, we can clear the state to empty and then manually inject an error,
        // or just mock an error. We'll simply set it to an error state directly.
        repository.vocabularyItems.value = AsyncState.error(
          'Forced error',
          StackTrace.empty,
        );

        repository.addVocabularyItem(
          VocabularyItem(
            termA: 'cat',
            termB: 'Katze',
            comment: '',
            chapter: 'Chapter 1',
          ),
        );

        // State should still be error, not data
        expect(repository.vocabularyItems.value.hasError, true);
        expect(repository.vocabularyItems.value.value, isNull);

        // 2. Now load successfully and verify it DOES add
        await repository.loadFromCsvString(
          'English;German;Comment;Chapter\ndog;Hund;;Chapter 1',
        );

        expect(repository.vocabularyItems.value.value!.length, 1);

        repository.addVocabularyItem(
          VocabularyItem(
            termA: 'cat',
            termB: 'Katze',
            comment: '',
            chapter: 'Chapter 1',
          ),
        );

        expect(repository.vocabularyItems.value.value!.length, 2);
        expect(repository.vocabularyItems.value.value!.last.termA, 'cat');
      },
    );

    test(
      'chapters computed signal returns unique chapters in insertion order',
      () async {
        const csv = '''
English;German;Comment;Chapter
apple;Apfel;;Vehicle
banana;Banane;;Fruit
car;Auto;;Vehicle
dog;Hund;;Animal
''';
        await repository.loadFromCsvString(csv);

        expect(repository.chapters.value, ['Vehicle', 'Fruit', 'Animal']);
      },
    );
  });
}
*/
