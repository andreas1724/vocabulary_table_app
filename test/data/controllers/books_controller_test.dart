import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:vocabulary_table_app/data/controllers/books_controller.dart';
import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/data/services/local_storage_service.dart';

// --- Mocks ---

class MockLocalStorageService extends Mock implements LocalStorageService {}

class FakeBook extends Fake implements Book {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBook());
  });

  group('BooksController Tests', () {
    late BooksController controller;
    late MockLocalStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockLocalStorageService();
      controller = BooksController(storageService: mockStorageService);
    });

    test('initial state is AsyncData with empty list', () {
      expect(controller.books.value.isLoading, false);
      expect(controller.books.value.hasError, false);
      expect(controller.books.value.requireValue, isEmpty);
    });

    test('loadBooks retrieves books from storage', () async {
      final now = DateTime.now().toUtc();
      final loadedBooks = [
        BookMetadata(
          id: '1',
          title: 'Test Book',
          languageA: 'LanguageA',
          languageB: 'LanguageB',
          commentHeader: 'Comment',
          createdAt: now,
          updatedAt: now,
          cleanedAt: now, // Required for sync tombstone logic
        ),
      ];

      when(() => mockStorageService.loadBooks())
          .thenAnswer((_) async => loadedBooks);

      // Trigger load
      final future = controller.loadBooks();

      // Verify synchronous loading state
      expect(controller.books.value.isLoading, true);

      await future;

      // Verify resolved state
      expect(controller.books.value.requireValue.length, 1);
      expect(controller.books.value.requireValue.first.title, 'Test Book');
      verify(() => mockStorageService.loadBooks()).called(1);
    });

    test('saveBook applies optimistic update, sorts correctly, and calls storage', () async {
      final olderTime = DateTime(2025, 1, 1).toUtc();
      final newerTime = DateTime(2026, 1, 1).toUtc();

      // Setup initial state with one old book
      controller.books.value = AsyncState.data([
        BookMetadata(
          id: 'old_book',
          title: 'Old Vocabs',
          languageA: 'EN',
          languageB: 'DE',
          commentHeader: '',
          createdAt: olderTime,
          updatedAt: olderTime,
          cleanedAt: olderTime,
        ),
      ]);

      when(() => mockStorageService.saveBook(any()))
          .thenAnswer((_) async {}); // Simulate successful DB write

      final newBook = Book(
        metadata: BookMetadata(
          id: 'new_book',
          title: 'New Vocabs',
          languageA: 'EN',
          languageB: 'DE',
          commentHeader: '',
          createdAt: newerTime,
          updatedAt: newerTime,
          cleanedAt: newerTime,
        ),
        items: [],
      );

      // Execute save action without awaiting to check optimistic state
      final saveFuture = controller.saveBook(newBook);

      // Verify synchronous optimistic UI update
      final currentState = controller.books.value.requireValue;
      expect(currentState.length, 2);
      
      // Verify correct descending sorting based on updatedAt
      expect(currentState.first.id, 'new_book');
      expect(currentState.last.id, 'old_book');

      await saveFuture;
      verify(() => mockStorageService.saveBook(any())).called(1);
    });

    test('saveBook rolls back state on storage error', () async {
      final now = DateTime.now().toUtc();
      final initialState = [
        BookMetadata(
          id: 'existing',
          title: 'Safe Book',
          languageA: 'EN',
          languageB: 'DE',
          commentHeader: '',
          createdAt: now,
          updatedAt: now,
          cleanedAt: now,
        ),
      ];

      controller.books.value = AsyncState.data(initialState);

      // Force database to throw an error
      when(() => mockStorageService.saveBook(any()))
          .thenThrow(Exception('Database locked'));

      final failedBook = Book(
        metadata: BookMetadata(
          id: 'fail_book',
          title: 'Will Fail',
          languageA: 'EN',
          languageB: 'DE',
          commentHeader: '',
          createdAt: now,
          updatedAt: now,
          cleanedAt: now,
        ),
        items: [],
      );

      await controller.saveBook(failedBook);

      // Verify rollback to initial state
      final currentState = controller.books.value.requireValue;
      expect(currentState.length, 1);
      expect(currentState.first.id, 'existing');
    });

    test('deleteBook applies optimistic deletion and calls storage', () async {
      final now = DateTime.now().toUtc();
      controller.books.value = AsyncState.data([
        BookMetadata(
          id: 'del',
          title: 'Delete Me',
          languageA: 'EN',
          languageB: 'DE',
          commentHeader: '',
          createdAt: now,
          updatedAt: now,
          cleanedAt: now,
        ),
      ]);

      when(() => mockStorageService.deleteBook(any()))
          .thenAnswer((_) async {});

      final deleteFuture = controller.deleteBook('del');

      // Verify synchronous optimistic deletion
      expect(controller.books.value.requireValue, isEmpty);

      await deleteFuture;
      verify(() => mockStorageService.deleteBook('del')).called(1);
    });
  });
}