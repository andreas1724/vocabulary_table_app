import 'package:flutter_test/flutter_test.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/data/controllers/vocab_repository.dart';
import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

class MockVocabRepository extends Mock implements VocabRepository {}

class FakeBook extends Fake implements Book {}
class FakeVocabularyItem extends Fake implements VocabularyItem {}

void main() {
  // Register the fallback value once before all tests run
  setUpAll(() {
    registerFallbackValue(FakeBook());
    registerFallbackValue(FakeVocabularyItem());
  });

  group('VocabularyController Tests', () {
    late MockVocabRepository mockRepository;
    late VocabularyController controller;
    late Book initialBook;

    setUp(() {
      mockRepository = MockVocabRepository();

      initialBook = Book(
        metadata: BookMetadata(
          id: 'test-id',
          title: 'My Test Book',
          modifiedTime: DateTime(2026, 1, 1),
        ),
        items: [
          VocabularyItem(bookId: "test-id", termA: 'dog', termB: 'Hund', chapter: 'Animals'),
          VocabularyItem(bookId: "test-id", termA: 'cat', termB: 'Katze', chapter: 'Animals'),
        ],
      );

      when(() => mockRepository.watchVocabulariesForBook('test-id'))
          .thenAnswer((_) => Stream.value(initialBook.items));
      when(() => mockRepository.updateVocabularyLocally(any()))
          .thenAnswer((_) async {});

      controller = VocabularyController(
        repository: mockRepository,
        book: initialBook,
      );
    });

    test('initializes correctly with provided book data', () {
      expect(controller.vocabularyItems.value.length, 2);
      expect(controller.chapters.value, ['Animals']);
    });

    test('updateVocabularyAtLocation updates specific cell immutably', () async {
      registerFallbackValue(VocabularyItem(bookId: "test", chapter: "test", termA: "", termB: ""));
      
      await controller.updateVocabularyAtLocation(
        (rowIndex: 0, column: ColumnName.termB),
        'Hündchen',
      );

      final captured = verify(() => mockRepository.updateVocabularyLocally(captureAny())).captured;
      final updatedItem = captured.first as VocabularyItem;
      expect(updatedItem.termA, 'dog'); // unchanged
      expect(updatedItem.termB, 'Hündchen'); // changed
    });
  });
}