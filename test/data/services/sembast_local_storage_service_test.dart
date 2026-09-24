import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/data/services/sembast_local_storage_service.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

void main() {
  group('SembastLocalStorageService Tests', () {
    late SembastLocalStorageService storageService;

    setUp(() async {
      // Use the in-memory factory for fast, isolated, and flake-free unit tests.
      final factory = newDatabaseFactoryMemory();
      storageService = SembastLocalStorageService(
        factoryOverride: factory,
        dbPathOverride: 'test.db',
      );
    });

    test('initially returns an empty list of books', () async {
      final books = await storageService.loadBooks();
      expect(books, isEmpty);
    });

    test('saves a book and retrieves its metadata', () async {
      final now = DateTime.now().toUtc();
      final book = Book(
        metadata: BookMetadata(
          id: 'file_123',
          title: 'English Vocabs',
          languageA: 'LanguageA',
          languageB: 'LanguageB',
          commentHeader: 'Comment',
          createdAt: now,
          updatedAt: now,
          cleanedAt: now,
        ),
        items: [
          VocabularyItem.create(
            bookId: 'file_123',
            chapterId: 'chapter 1',
            termA: 'house',
            termB: 'Haus',
          ),
        ],
      );

      await storageService.saveBook(book);

      final books = await storageService.loadBooks();
      expect(books.length, 1);
      expect(books.first.id, 'file_123');
      expect(books.first.title, 'English Vocabs');
      expect(books.first.languageA, 'LanguageA');
      expect(books.first.languageB, 'LanguageB');
      expect(books.first.updatedAt.toIso8601String(), now.toIso8601String());
    });

    test('retrieves the full book content by ID', () async {
      final book = Book(
        metadata: BookMetadata.create(
          id: 'file_999',
          title: 'Spanish Vocabs',
          languageA: 'LanguageA',
          languageB: 'LanguageB',
          commentHeader: 'Comment',
        ),
        items: [
          VocabularyItem.create(
            bookId: "file_999",
            chapterId: 'chapter 1',
            termA: 'hola',
            termB: 'hallo',
          ),
        ],
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
      final metadata = BookMetadata.create(
        id: 'file_update',
        title: 'Old Title',
        languageA: 'LanguageA',
        languageB: 'LanguageB',
        commentHeader: 'Comment',
      );

      await storageService.saveBook(
        Book(
          metadata: metadata,
          items: [
            VocabularyItem.create(
              bookId: "file_update",
              chapterId: 'chapter 1',
              termA: 'old',
              termB: 'content',
            ),
          ],
        ),
      );

      final updatedMetadata = BookMetadata.create(
        id: 'file_update', // Same ID triggers upsert/update
        title: 'New Title',
        languageA: 'LanguageA',
        languageB: 'LanguageB',
        commentHeader: 'Comment',
      );
      
      await storageService.saveBook(
        Book(
          metadata: updatedMetadata,
          items: [
            VocabularyItem.create(
              bookId: "file_update",
              chapterId: 'chapter 1',
              termA: 'new',
              termB: 'content',
            ),
          ],
        ),
      );

      final books = await storageService.loadBooks();
      expect(books.length, 1);
      expect(books.first.title, 'New Title');

      final content = await storageService.getBookContent('file_update');
      expect(content!.items.first.termA, 'new');
    });

    test('deletes a book', () async {
      final book = Book(
        metadata: BookMetadata.create(
          id: 'delete_me',
          title: 'To be deleted',
          languageA: 'LanguageA',
          languageB: 'LanguageB',
          commentHeader: 'Comment',
        ),
        items: [],
      );

      await storageService.saveBook(book);
      expect((await storageService.loadBooks()).length, 1);

      await storageService.deleteBook('delete_me');

      expect((await storageService.loadBooks()).length, 0);
      expect(await storageService.getBookContent('delete_me'), isNull);
    });

    test(
      'adds, updates, and deletes an individual vocabulary item and updates book updatedAt',
      () async {
        final initialTime = DateTime(2025, 1, 1).toUtc();
        const bookId = 'vocab_crud_test';

        await storageService.saveBook(
          Book(
            metadata: BookMetadata(
              id: bookId,
              title: 'Test Book',
              languageA: 'EN',
              languageB: 'DE',
              commentHeader: '',
              createdAt: initialTime,
              updatedAt: initialTime,
              cleanedAt: initialTime,
            ),
            items: [],
          ),
        );

        final now = DateTime.now().toUtc();
        final newItem = VocabularyItem(
          id: 'item_1',
          bookId: bookId,
          termA: 'cat',
          termB: 'Katze',
          chapterId: 'Animals',
          createdAt: now,
          updatedAt: now,
        );

        // Delay slightly to ensure time difference is measurable for the book metadata
        await Future.delayed(const Duration(milliseconds: 10));
        await storageService.addVocabulary(newItem);

        var retrievedBook = await storageService.getBookContent(bookId);
        expect(retrievedBook!.items.length, 1);
        expect(retrievedBook.items.first.termA, 'cat');
        expect(
          retrievedBook.metadata.updatedAt.isAfter(initialTime),
          isTrue,
          reason: 'Adding a vocabulary should update the book updatedAt',
        );

        final timeAfterAdd = retrievedBook.metadata.updatedAt;
        await Future.delayed(const Duration(milliseconds: 10));

        final updatedItem = newItem.copyWith(
          termB: 'Kater',
          updatedAt: DateTime.now().toUtc(),
        );
        await storageService.updateVocabulary(updatedItem);

        retrievedBook = await storageService.getBookContent(bookId);
        expect(retrievedBook!.items.first.termB, 'Kater');
        expect(
          retrievedBook.metadata.updatedAt.isAfter(timeAfterAdd),
          isTrue,
          reason: 'Updating a vocabulary should update the book updatedAt',
        );

        final timeAfterUpdate = retrievedBook.metadata.updatedAt;
        await Future.delayed(const Duration(milliseconds: 10));

        await storageService.deleteVocabulary(updatedItem);

        retrievedBook = await storageService.getBookContent(bookId);
        expect(retrievedBook!.items, isEmpty);
        expect(
          retrievedBook.metadata.updatedAt.isAfter(timeAfterUpdate),
          isTrue,
          reason: 'Deleting a vocabulary should update the book updatedAt',
        );
      },
    );

    test(
      'updateVocabularies performs batch update and updates book updatedAt',
      () async {
        final initialTime = DateTime(2025, 1, 1).toUtc();
        const bookId = 'batch_test';

        final itemTime = DateTime.now().toUtc();

        await storageService.saveBook(
          Book(
            metadata: BookMetadata(
              id: bookId,
              title: 'Batch Book',
              languageA: 'EN',
              languageB: 'DE',
              commentHeader: '',
              createdAt: initialTime,
              updatedAt: initialTime,
              cleanedAt: initialTime,
            ),
            items: [
              VocabularyItem(
                id: 'v1',
                bookId: bookId,
                termA: 'apple',
                termB: 'Apfel',
                chapterId: 'Fruits',
                createdAt: itemTime,
                updatedAt: itemTime,
              ),
              VocabularyItem(
                id: 'v2',
                bookId: bookId,
                termA: 'banana',
                termB: 'Banane',
                chapterId: 'Fruits',
                createdAt: itemTime,
                updatedAt: itemTime,
              ),
            ],
          ),
        );

        await Future.delayed(const Duration(milliseconds: 10));

        final retrievedBook = await storageService.getBookContent(bookId);
        final updateTime = DateTime.now().toUtc();
        
        final itemsToUpdate = [
          retrievedBook!.items[0].copyWith(
            termB: 'Apfel (grün)', 
            updatedAt: updateTime,
          ),
          retrievedBook.items[1].copyWith(
            termB: 'Banane (gelb)', 
            updatedAt: updateTime,
          ),
        ];

        await storageService.updateVocabularies(itemsToUpdate);

        final updatedBook = await storageService.getBookContent(bookId);
        expect(updatedBook!.items[0].termB, 'Apfel (grün)');
        expect(updatedBook.items[1].termB, 'Banane (gelb)');
        expect(
          updatedBook.metadata.updatedAt.isAfter(initialTime),
          isTrue,
          reason: 'Batch update should update the book updatedAt',
        );
      },
    );

    test(
      'watchVocabulariesForBook emits updates when vocabularies change',
      () async {
        const bookId = 'stream_test';

        await storageService.saveBook(
          Book(
            metadata: BookMetadata.create(
              id: bookId,
              title: 'Stream Book',
              languageA: 'EN',
              languageB: 'DE',
              commentHeader: '',
            ),
            items: [],
          ),
        );

        final stream = storageService.watchVocabulariesForBook(bookId);

        // Assign the Future to a variable WITHOUT awaiting it yet to properly register 
        // the stream listener before firing database mutations.
        final streamExpectation = expectLater(
          stream,
          emitsInOrder([
            [], 
            [isA<VocabularyItem>().having((i) => i.termA, 'termA', 'dog')], 
            [isA<VocabularyItem>().having((i) => i.termA, 'termA', 'hound')], 
            [], 
          ]),
        );

        await Future.delayed(const Duration(milliseconds: 10));

        final now = DateTime.now().toUtc();
        final item = VocabularyItem(
          id: 's1',
          bookId: bookId,
          termA: 'dog',
          termB: 'Hund',
          chapterId: 'Animals',
          createdAt: now,
          updatedAt: now,
        );

        await storageService.addVocabulary(item);
        await Future.delayed(const Duration(milliseconds: 10));

        final updatedItem = item.copyWith(
          termA: 'hound',
          updatedAt: DateTime.now().toUtc(),
        );
        await storageService.updateVocabulary(updatedItem);
        await Future.delayed(const Duration(milliseconds: 10));

        await storageService.deleteVocabulary(updatedItem);

        // Await the expectation at the very end to verify all snapshot events were emitted.
        await streamExpectation;
      },
    );
  });
}