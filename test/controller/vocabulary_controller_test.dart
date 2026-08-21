import 'package:flutter_test/flutter_test.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/data/controllers/vocab_repository.dart';
import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

class MockVocabRepository extends Mock implements VocabRepository {}

class FakeBook extends Fake implements Book {}

void main() {
  // Register the fallback value once before all tests run
  setUpAll(() {
    registerFallbackValue(FakeBook());
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
          VocabularyItem(termA: 'dog', termB: 'Hund', chapter: 'Animals'),
          VocabularyItem(termA: 'cat', termB: 'Katze', chapter: 'Animals'),
        ],
      );

      controller = VocabularyController(
        repository: mockRepository,
        book: initialBook,
      );
    });

    test('initializes correctly with provided book data', () {
      expect(controller.vocabularyItems.length, 2);
      expect(controller.chapters.value, ['Animals']);
    });

    test('saveBook calls repository and updates modifiedTime', () async {
      // Arrange
      when(() => mockRepository.saveBookLocally(any())).thenAnswer((_) async {});

      final initialTime = initialBook.metadata.modifiedTime;

      // Act
      await controller.saveBook();

      // Assert
      final captured = verify(() => mockRepository.saveBookLocally(captureAny())).captured;
      final savedBook = captured.first as Book;

      expect(savedBook.items.length, 2);
      expect(savedBook.metadata.id, 'test-id');
      expect(savedBook.metadata.modifiedTime.isAfter(initialTime), true);
    });
    
    test('updateVocabularyAtLocation updates specific cell immutably', () {
      controller.updateVocabularyAtLocation(
        (rowIndex: 0, column: ColumnName.termB), 
        'Hündchen',
      );
      
      expect(controller.vocabularyItems[0].value.termA, 'dog'); // unchanged
      expect(controller.vocabularyItems[0].value.termB, 'Hündchen'); // changed
    });
  });
}