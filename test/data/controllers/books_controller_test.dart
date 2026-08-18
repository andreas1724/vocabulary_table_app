import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:vocabulary_table_app/data/controllers/books_controller.dart';
import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/data/services/sembast_local_storage_service.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

void main() {
  group('BooksController Tests', () {
    late BooksController controller;
    late SembastLocalStorageService storageService;

    setUp(() async {
      final factory = newDatabaseFactoryMemory();
      storageService = SembastLocalStorageService(
        factoryOverride: factory,
        dbPathOverride: 'test.db',
      );

      controller = BooksController(storageService);
    });

    test('initial state is AsyncData with empty list', () {
      expect(controller.books.value.isLoading, false);
      expect(controller.books.value.hasError, false);
      expect(controller.books.value.value, isEmpty);
    });

    test('loadBooks retrieves books from storage', () async {
      await storageService.saveBook(
        Book(
          metadata: BookMetadata(
            id: '1',
            title: 'Test Book',
            modifiedTime: DateTime.now(),
          ),
          items: [VocabularyItem(termA: 'a', termB: 'b')],
        ),
      );

      await controller.loadBooks();

      expect(controller.books.value.requireValue.length, 1);
      expect(controller.books.value.requireValue.first.title, 'Test Book');
    });

    test('saveBook adds a new book to the signal and storage', () async {
      final book = Book(
        metadata: BookMetadata(
          id: 'new_book',
          title: 'My Vocabs',
          modifiedTime: DateTime.now(),
        ),
        items: [VocabularyItem(termA: 'x', termB: 'y')],
      );

      await controller.saveBook(book);

      expect(controller.books.value.requireValue.length, 1);
      expect(controller.books.value.requireValue.first.id, 'new_book');

      // Verify it was actually saved to the underlying storage
      final booksInStorage = await storageService.getAllBooks();
      expect(booksInStorage.length, 1);
    });

    test(
      'saveBook updates an existing book in the signal without duplication',
      () async {
        const id = 'existing_book';
        final initialBook = Book(
          metadata: BookMetadata(
            id: id,
            title: 'Old Title',
            modifiedTime: DateTime.now(),
          ),
          items: [],
        );

        await controller.saveBook(initialBook);
        expect(controller.books.value.requireValue.length, 1);
        expect(controller.books.value.requireValue.first.title, 'Old Title');

        final updatedBook = Book(
          metadata: BookMetadata(
            id: id,
            title: 'New Title',
            modifiedTime: DateTime.now(),
          ),
          items: [VocabularyItem(termA: 'x', termB: 'y', comment: 'z')],
        );

        await controller.saveBook(updatedBook);

        expect(controller.books.value.requireValue.length, 1);
        expect(controller.books.value.requireValue.first.title, 'New Title');
      },
    );

    test('deleteBook removes book from signal and storage', () async {
      final book = Book(
        metadata: BookMetadata(
          id: 'del',
          title: 'Delete Me',
          modifiedTime: DateTime.now(),
        ),
        items: [],
      );

      await controller.saveBook(book);
      expect(controller.books.value.requireValue.length, 1);

      await controller.deleteBook('del');

      expect(controller.books.value.requireValue.length, 0);

      // Verify storage
      final booksInStorage = await storageService.getAllBooks();
      expect(booksInStorage.length, 0);
    });
  });
}
