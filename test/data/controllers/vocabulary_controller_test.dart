import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/data/controllers/vocab_repository.dart';
import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

class MockVocabRepository extends Mock implements VocabRepository {}

class FakeBook extends Fake implements Book {}

class FakeVocabularyItem extends Fake implements VocabularyItem {}

void main() {
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
        metadata: BookMetadata.create(
          id: 'test-id',
          title: 'My Test Book',
          languageA: 'LanguageA',
          languageB: 'LanguageB',
          commentHeader: 'Comment',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        items: [
          VocabularyItem.create(
            id: 'item-1',
            bookId: 'test-id',
            termA: 'dog',
            termB: 'Hund',
            chapterId: 'Animals',
            order: 0,
          ),
          VocabularyItem.create(
            id: 'item-2',
            bookId: 'test-id',
            termA: 'cat',
            termB: 'Katze',
            chapterId: 'Animals',
            order: 1,
          ),
        ],
      );

      // Stub all necessary stream and async repository interactions
      when(() => mockRepository.watchVocabulariesForBook(any()))
          .thenAnswer((_) => Stream.value(initialBook.items));
      when(() => mockRepository.updateVocabularyLocally(any()))
          .thenAnswer((_) async {});
      when(() => mockRepository.addVocabularyLocally(any()))
          .thenAnswer((_) async {});
      when(() => mockRepository.deleteVocabularyLocally(any()))
          .thenAnswer((_) async {});
      when(() => mockRepository.updateVocabulariesLocally(any()))
          .thenAnswer((_) async {});

      controller = VocabularyController(
        repository: mockRepository,
        book: initialBook,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('initializes correctly and exposes computed signals', () {
      expect(controller.vocabularyItems.value.length, 2);
      expect(controller.chapters.value, ['Animals']);
      expect(controller.title.value, 'My Test Book');
      expect(controller.languageA.value, 'LanguageA');
    });

    test('addVocabulary updates optimistically and calls repository', () async {
      final newItem = VocabularyItem.create(
        id: 'item-3',
        bookId: 'test-id',
        termA: 'bird',
        termB: 'Vogel',
        chapterId: 'New Chapter',
      );

      await controller.addVocabulary(newItem);

      // Verify synchronous optimistic UI state
      expect(controller.vocabularyItems.value.length, 3);
      expect(controller.vocabularyItems.value.last.termA, 'bird');
      expect(controller.chapters.value, contains('New Chapter'));

      // Verify repository interaction
      final captured = verify(
        () => mockRepository.addVocabularyLocally(captureAny()),
      ).captured;
      final savedItem = captured.first as VocabularyItem;
      expect(savedItem.order, 2); // Validates correct dynamic ordering
    });

    test('removeVocabularyAt applies optimistic delete and calls repository', () async {
      final itemToDelete = controller.vocabularyItems.value.first;

      await controller.removeVocabularyAt(0);

      // Verify synchronous optimistic UI state
      expect(controller.vocabularyItems.value.length, 1);
      expect(controller.vocabularyItems.value.first.termA, 'cat');

      verify(
        () => mockRepository.deleteVocabularyLocally(itemToDelete),
      ).called(1);
    });

    test('removeVocabularyAt ignores invalid indices safely', () async {
      await controller.removeVocabularyAt(-1);
      await controller.removeVocabularyAt(99);

      expect(controller.vocabularyItems.value.length, 2);
      verifyNever(() => mockRepository.deleteVocabularyLocally(any()));
    });

    test('updateVocabularyAt updates correct item', () async {
      final itemToUpdate = VocabularyItem.create(
        id: 'new-id-ignored', // Controller must enforce existing ID
        bookId: 'wrong-book', // Controller must enforce existing bookId
        chapterId: 'wrong-chapter', // Required field added
        termA: 'doggy',
        termB: 'Hündchen',
      );

      await controller.updateVocabularyAt(0, itemToUpdate);

      expect(controller.vocabularyItems.value.first.termA, 'doggy');

      final captured = verify(
        () => mockRepository.updateVocabularyLocally(captureAny()),
      ).captured;
      
      final updatedItem = captured.first as VocabularyItem;
      // Validates structural integrity enforcement in the controller
      expect(updatedItem.id, 'item-1'); 
      expect(updatedItem.bookId, 'test-id');
    });

    test('updateVocabularyAtLocation updates specific cell immutably', () async {
      await controller.updateVocabularyAtLocation(
        (rowIndex: 0, colIndex: 1),
        'Hündchen',
      );

      final captured = verify(
        () => mockRepository.updateVocabularyLocally(captureAny()),
      ).captured;
      final updatedItem = captured.first as VocabularyItem;
      
      expect(updatedItem.termA, 'dog');
      expect(updatedItem.termB, 'Hündchen');
    });

    test('updateVocabularyAtLocation rejects ID modification via cell editing', () async {
      await controller.updateVocabularyAtLocation(
        (rowIndex: 0, colIndex: 99), // Invalid/ID column
        'hacked-id',
      );

      // The controller should gracefully abort
      verifyNever(() => mockRepository.updateVocabularyLocally(any()));
    });

    test('reorderItem applies optimistic sorting and batch updates DB', () async {
      // Reorder index 0 (dog) to index 1 (after cat)
      await controller.reorderItem(0, 1);

      final items = controller.vocabularyItems.value;
      
      // Verify optimistic UI sorting
      expect(items.first.termA, 'cat');
      expect(items.last.termA, 'dog');
      
      // Verify local order field regeneration
      expect(items.first.order, 0);
      expect(items.last.order, 1);

      // Verify repository batch interaction
      final captured = verify(
        () => mockRepository.updateVocabulariesLocally(captureAny()),
      ).captured;
      
      final batchedItems = captured.first as List<VocabularyItem>;
      expect(batchedItems.length, 2);
    });
  });
}