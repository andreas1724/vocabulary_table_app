import 'package:flutter_test/flutter_test.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/data/controllers/vocabulary_controller.dart';
import 'package:vocabulary_table_app/data/models/vocab_entity.dart';
import 'package:vocabulary_table_app/data/services/csv_parser_service.dart';

void main() {
  group('VocabularyController Tests', () {
    late VocabularyController controller;
    late CsvParserService parserService;

    setUp(() {
      parserService = CsvParserService();
      controller = VocabularyController(parserService);
    });

    test('initial state is AsyncData with empty list', () {
      expect(controller.vocabEntities.value.isLoading, false);
      expect(controller.vocabEntities.value.hasError, false);
      expect(controller.vocabEntities.value.value, isEmpty);
    });

    test(
      'loadFromCsvString parses valid CSV and updates state to AsyncData',
      () async {
        const csv = 'English;German;Comment;Chapter\nhouse;Haus;;Chapter 1';

        // Initially, we can wait for the future
        await controller.loadFromCsvString(csv);

        expect(controller.vocabEntities.value.isLoading, false);
        expect(controller.vocabEntities.value.hasError, false);
        expect(controller.vocabEntities.value.value, isNotNull);
        expect(controller.vocabEntities.value.value!.length, 1);
        expect(controller.vocabEntities.value.value!.first.termA, 'house');
      },
    );

    test(
      'addVocabulary only works if current state is successful AsyncData',
      () async {
        // 1. Force an error state to verify it DOES NOT add
        // To do this, we can clear the state to empty and then manually inject an error,
        // or just mock an error. We'll simply set it to an error state directly.
        controller.vocabEntities.value = AsyncState.error(
          'Forced error',
          StackTrace.empty,
        );

        controller.addVocabEntity(
          VocabEntity(
            termA: 'cat',
            termB: 'Katze',
            comment: '',
            chapter: 'Chapter 1',
          ),
        );

        // State should still be error, not data
        expect(controller.vocabEntities.value.hasError, true);
        expect(controller.vocabEntities.value.value, isNull);

        // 2. Now load successfully and verify it DOES add
        await controller.loadFromCsvString(
          'English;German;Comment;Chapter\ndog;Hund;;Chapter 1',
        );

        expect(controller.vocabEntities.value.value!.length, 1);

        controller.addVocabEntity(
          VocabEntity(
            termA: 'cat',
            termB: 'Katze',
            comment: '',
            chapter: 'Chapter 1',
          ),
        );

        expect(controller.vocabEntities.value.value!.length, 2);
        expect(controller.vocabEntities.value.value!.last.termA, 'cat');
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
        await controller.loadFromCsvString(csv);

        expect(controller.chapters.value, ['Vehicle', 'Fruit', 'Animal']);
      },
    );
  });
}
