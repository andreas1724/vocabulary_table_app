import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:vocabulary_table_app/data/models/book.dart';
import 'package:vocabulary_table_app/data/services/sembast_local_storage_service.dart';

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
        csvContent: 'English;German\nhouse;Haus',
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
        csvContent: 'Spanish;German\nhola;hallo',
      );

      await storageService.saveBook(book);

      final retrievedBook = await storageService.getBookContent('file_999');

      expect(retrievedBook, isNotNull);
      expect(retrievedBook!.metadata.title, 'Spanish Vocabs');
      expect(retrievedBook.csvContent, 'Spanish;German\nhola;hallo');
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
        Book(metadata: metadata, csvContent: 'old content'),
      );

      // Update the book
      final updatedMetadata = BookMetadata(
        id: 'file_update', // Same ID!
        title: 'New Title',
        modifiedTime: DateTime.now(),
      );
      await storageService.saveBook(
        Book(metadata: updatedMetadata, csvContent: 'new content'),
      );

      // Verify updates
      final books = await storageService.getAllBooks();
      expect(books.length, 1); // Should still be only 1 book
      expect(books.first.title, 'New Title');

      final content = await storageService.getBookContent('file_update');
      expect(content!.csvContent, 'new content');
    });

    test('deletes a book', () async {
      final book = Book(
        metadata: BookMetadata(
          id: 'delete_me',
          title: 'To be deleted',
          modifiedTime: DateTime.now(),
        ),
        csvContent: 'content',
      );

      await storageService.saveBook(book);
      expect((await storageService.getAllBooks()).length, 1);

      await storageService.deleteBook('delete_me');

      expect((await storageService.getAllBooks()).length, 0);
      expect(await storageService.getBookContent('delete_me'), isNull);
    });
  });
}
