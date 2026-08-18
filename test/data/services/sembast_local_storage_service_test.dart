import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:vocabulary_table_app/data/models/book.dart';
import 'package:vocabulary_table_app/data/services/sembast_local_storage_service.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

void main() {
  group('SembastLocalStorageService Tests', () {
    late SembastLocalStorageService storageService;

    setUp(() async {
      // Use the in-memory factory for fast and isolated unit tests
      final factory = newDatabaseFactoryMemory();
      storageService = SembastLocalStorageService(
        factoryOverride: factory,
        dbPathOverride: 'test.db',
      );
    });

    test('initially returns an empty list of books', () async {
      final books = await storageService.getAllBooks();
      expect(books, isEmpty);
    });

    test('saves a book and retrieves its metadata', () async {
      final now = DateTime.now();
      final book = Book(
        metadata: BookMetadata(
          id: 'file_123',
          title: 'English Vocabs',
          modifiedTime: now,
        ),
        items: [VocabularyItem(termA: 'house', termB: 'Haus')],
      );

      await storageService.saveBook(book);

      final books = await storageService.getAllBooks();
      expect(books.length, 1);
      expect(books.first.id, 'file_123');
      expect(books.first.title, 'English Vocabs');
      expect(books.first.modifiedTime.toIso8601String(), now.toIso8601String());
    });

    test('retrieves the full book content by ID', () async {
      final book = Book(
        metadata: BookMetadata(
          id: 'file_999',
          title: 'Spanish Vocabs',
          modifiedTime: DateTime.now(),
        ),
        items: [VocabularyItem(termA: 'hola', termB: 'hallo')],
      );

      await storageService.saveBook(book);

      final retrievedBook = await storageService.getBookContent('file_999');

      expect(retrievedBook, isNotNull);
      expect(retrievedBook!.metadata.title, 'Spanish Vocabs');
      expect(retrievedBook.items, isNotEmpty);
      expect(retrievedBook.items.first.termA, 'hola');
    });

    test(
      'returns null when requesting content for non-existent book',
      () async {
        final retrievedBook = await storageService.getBookContent(
          'does_not_exist',
        );
        expect(retrievedBook, isNull);
      },
    );

    test('updates an existing book', () async {
      final metadata = BookMetadata(
        id: 'file_update',
        title: 'Old Title',
        modifiedTime: DateTime.now(),
      );

      await storageService.saveBook(
        Book(
          metadata: metadata,
          items: [VocabularyItem(termA: 'old', termB: 'content')],
        ),
      );

      // Update the book
      final updatedMetadata = BookMetadata(
        id: 'file_update', // Same ID!
        title: 'New Title',
        modifiedTime: DateTime.now(),
      );
      await storageService.saveBook(
        Book(
          metadata: updatedMetadata,
          items: [VocabularyItem(termA: 'new', termB: 'content')],
        ),
      );

      // Verify updates
      final books = await storageService.getAllBooks();
      expect(books.length, 1); // Should still be only 1 book
      expect(books.first.title, 'New Title');

      final content = await storageService.getBookContent('file_update');
      expect(content!.items.first.termA, 'new');
    });

    test('deletes a book', () async {
      final book = Book(
        metadata: BookMetadata(
          id: 'delete_me',
          title: 'To be deleted',
          modifiedTime: DateTime.now(),
        ),
        items: [],
      );

      await storageService.saveBook(book);
      expect((await storageService.getAllBooks()).length, 1);

      await storageService.deleteBook('delete_me');

      expect((await storageService.getAllBooks()).length, 0);
      expect(await storageService.getBookContent('delete_me'), isNull);
    });
  });
}
