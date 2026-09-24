import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/data/services/local_storage_service.dart';
import 'package:vocabulary_table_app/models/chapter.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

class SembastLocalStorageService implements LocalStorageService {
  /// Optional parameters are used for injecting an in-memory database during testing.
  SembastLocalStorageService({this.factoryOverride, this.dbPathOverride});

  final DatabaseFactory? factoryOverride;
  final String? dbPathOverride;

  Future<Database>? _dbFuture;

  Future<Database> get _db {
    _dbFuture ??= _initDb().catchError((Object error, StackTrace stackTrace) {
      // Reset the future so subsequent calls can retry instead of permanently failing
      _dbFuture = null;
      return Future<Database>.error(error, stackTrace);
    });
    return _dbFuture!;
  }

  // We use three stores to keep things fast:
  // One for metadata (list view), one for chapters and one for the vocabulary items.
  final _metadataStore = stringMapStoreFactory.store('metadata');

  final _chapterStore = stringMapStoreFactory.store('chapters');

  // Key is vocabulary item ID.
  final _contentStore = stringMapStoreFactory.store('vocabularies');

  Future<Database> _initDb() async {
    if (factoryOverride != null) {
      // Use the injected factory (e.g., in-memory for testing)
      return await factoryOverride!.openDatabase(dbPathOverride ?? 'test.db');
    }

    if (kIsWeb) {
      // Use IndexedDB on the web
      final factory = databaseFactoryWeb;
      return await factory.openDatabase('vocabularies_web.db');
    } else {
      // Use the local file system on iOS/Android/Mac
      final dir = await getApplicationDocumentsDirectory();
      await dir.create(recursive: true);
      final dbPath = p.join(dir.path, 'vocabularies_local.db');
      final factory = databaseFactoryIo;
      return await factory.openDatabase(dbPath);
    }
  }

  @override
  Future<List<BookMetadata>> loadBooks() async {
    final db = await _db;

    final finder = Finder(
      filter: Filter.isNull('deletedAt'),
      // Sort descending so the most recently updated books appear at the top.
      sortOrders: [SortOrder('updatedAt', false)],
    );

    final records = await _metadataStore.find(db, finder: finder);

    return [
      for (final record in records)
        if (record.value case final Map<String, dynamic> data)
          BookMetadata.fromJson(data),
    ];
  }

  @override
  Future<Book?> getBookContent(String id) async {
    final db = await _db;

    // metaRecord is already of type Map<String, Object?>?
    final metaRecord = await _metadataStore.record(id).get(db);

    if (metaRecord == null) {
      return null;
    }

    // Since we verified it's not null, we can pass it directly.
    final metadata = BookMetadata.fromJson(metaRecord);

    // Enforce soft-deletion check on the metadata level to prevent
    // returning ghost books.
    if (metadata.deletedAt != null) {
      return null;
    }

    // Execute independent database reads concurrently to eliminate I/O latency.
    final results = await Future.wait([
      _chapterStore.find(
        db,
        finder: Finder(
          filter: Filter.and([
            Filter.equals('bookId', id),
            Filter.isNull('deletedAt'),
          ]),
        ),
      ),
      _contentStore.find(
        db,
        finder: Finder(
          filter: Filter.and([
            Filter.equals('bookId', id),
            Filter.isNull('deletedAt'),
          ]),
        ),
      ),
    ]);

    final chapterRecords = results[0];
    final itemRecords = results[1];

    // Optimize map creation: Perform the type cast only once per iteration.
    final chapterOrderMap = <String, int>{
      for (final record in chapterRecords)
        if (record.value case final Map<String, dynamic> data)
          data['id']?.toString() ?? '': (data['order'] as num?)?.toInt() ?? 0,
    };

    final items = [
      for (final record in itemRecords)
        if (record.value case final Map<String, dynamic> data)
          VocabularyItem.fromJson(data),
    ];

    // Fallback constant for orphaned items (items where the chapter was soft-deleted
    // but the cascade delete has not been executed yet).
    const orphanOrderFallback = 999999;

    // Perform the multi-level sort purely in memory.
    items.sort((a, b) {
      final chapterOrderA = chapterOrderMap[a.chapterId] ?? orphanOrderFallback;
      final chapterOrderB = chapterOrderMap[b.chapterId] ?? orphanOrderFallback;

      final chapterComparison = chapterOrderA.compareTo(chapterOrderB);

      if (chapterComparison != 0) {
        return chapterComparison;
      }

      return a.order.compareTo(b.order);
    });

    return Book(metadata: metadata, items: items);
  }

  @override
  Future<void> saveBook(Book book) async {
    final db = await _db;
    final bookId = book.metadata.id;
    final now = DateTime.now().toUtc();

    // Prepare upsert data efficiently.
    final keys = [for (final item in book.items) item.id];

    final values = [
      for (final (index, item) in book.items.indexed)
        item
            .copyWith(
              bookId: bookId,
              order: index,
              // Do not overwrite updatedAt here.
              // We must trust the incoming timestamp to preserve Last-Write-Wins (LWW)
              // conflict resolution for the Google Drive sync.
            )
            .toJson(),
    ];

    final incomingIds = keys.toSet();

    await db.transaction((txn) async {
      // 1. Update book metadata
      await _metadataStore.record(bookId).put(txn, book.metadata.toJson());

      // 2. Fetch existing records to compute the diff for soft-deletion
      final existingRecords = await _contentStore.find(
        txn,
        finder: Finder(filter: Filter.equals('bookId', bookId)),
      );

      final itemsToSoftDelete = <String>[];
      final softDeleteValues = <Map<String, dynamic>>[];

      for (final record in existingRecords) {
        // Rely on the strongly typed StoreRef; no cast needed.
        final id = record.key;

        if (!incomingIds.contains(id)) {
          if (record.value case final Map<String, dynamic> existingData) {
            if (existingData['deletedAt'] == null) {
              itemsToSoftDelete.add(id);

              // Create a mutable copy of the immutable Sembast snapshot to
              // avoid 'Bad state: read only' errors during modification.
              final mutableData = Map<String, dynamic>.from(existingData);

              // For newly generated tombstones, 'now' is the correct LWW timestamp.
              mutableData['deletedAt'] = now.toIso8601String();
              mutableData['updatedAt'] = now.toIso8601String();

              softDeleteValues.add(mutableData);
            }
          }
        }
      }

      // 3. Apply soft deletes
      if (itemsToSoftDelete.isNotEmpty) {
        await _contentStore
            .records(itemsToSoftDelete)
            .put(txn, softDeleteValues);
      }

      // 4. Execute bulk upsert for all incoming entries
      if (keys.isNotEmpty) {
        await _contentStore.records(keys).put(txn, values);
      }
    });
  }

  /// Streams all chapters for a specific book that have not been soft-deleted.
  /// Results are pre-sorted by their 'order' field.
  @override
  Stream<List<Chapter>> watchChaptersForBook(String bookId) async* {
    final db = await _db;

    final finder = Finder(
      filter: Filter.and([
        Filter.equals('bookId', bookId),
        Filter.isNull('deletedAt'), // Enforce soft deletion
      ]),
      sortOrders: [SortOrder('order')],
    );

    yield* _chapterStore.query(finder: finder).onSnapshots(db).map((snapshots) {
      return snapshots.map((snapshot) {
        return Chapter.fromJson(snapshot.value as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Streams all vocabulary items for a specific book that have not been soft-deleted.
  /// We defer sorting here to allow computed signals to handle the complex
  /// chapter-based sorting logic later.
  @override
  Stream<List<VocabularyItem>> watchVocabulariesForBook(String bookId) async* {
    final db = await _db;

    final finder = Finder(
      filter: Filter.and([
        Filter.equals('bookId', bookId), // Enabled via denormalization
        Filter.isNull('deletedAt'), // Enforce soft deletion
      ]),
    );

    yield* _contentStore.query(finder: finder).onSnapshots(db).map((snapshots) {
      return snapshots.map((snapshot) {
        return VocabularyItem.fromJson(snapshot.value as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> _updateBookModifiedTime(
    Transaction txn,
    String bookId, [
    DateTime? updatedAt,
  ]) async {
    final updateTime = (updatedAt ?? DateTime.now()).toUtc().toIso8601String();

    await _metadataStore.record(bookId).update(txn, {'updatedAt': updateTime});
  }

  /// Adds a new book (metadata only) strictly.
  /// Throws a StateError if a book with the same ID already exists to prevent data loss.
  @override
  Future<void> addBook(BookMetadata metadata) async {
    final db = await _db;

    await db.transaction((txn) async {
      final insertedKey = await _metadataStore
          .record(metadata.id)
          .add(txn, metadata.toJson());

      if (insertedKey == null) {
        throw StateError('BookMetadata with ID ${metadata.id} already exists.');
      }
    });
  }

  /// Adds a new chapter strictly.
  /// Throws a StateError if the chapter already exists.
  @override
  Future<void> addChapter(Chapter chapter) async {
    final db = await _db;

    await db.transaction((txn) async {
      final insertedKey = await _chapterStore
          .record(chapter.id)
          .add(txn, chapter.toJson());

      if (insertedKey == null) {
        throw StateError('Chapter with ID ${chapter.id} already exists.');
      }

      // Synchronize the book's modified time to trigger cloud sync events for structural changes.
      await _updateBookModifiedTime(txn, chapter.bookId, chapter.updatedAt);
    });
  }

  /// Adds a new vocabulary item strictly.
  /// Throws a StateError if the item already exists to prevent accidental overwrites.
  @override
  Future<void> addVocabulary(VocabularyItem item) async {
    final db = await _db;

    await db.transaction((txn) async {
      final insertedKey = await _contentStore
          .record(item.id)
          .add(txn, item.toJson());

      if (insertedKey == null) {
        throw StateError('VocabularyItem with ID ${item.id} already exists.');
      }

      await _updateBookModifiedTime(txn, item.bookId);
    });
  }

  /// Updates the metadata of an existing book.
  /// Throws a StateError if the book does not exist to prevent ghost records.
  @override
  Future<void> updateBook(BookMetadata metadata) async {
    final db = await _db;

    await db.transaction((txn) async {
      // Always bump the updatedAt timestamp to trigger cloud sync.
      final updatedMetadata = metadata.copyWith(
        updatedAt: DateTime.now().toUtc(),
      );

      final updatedKey = await _metadataStore
          .record(metadata.id)
          .update(txn, updatedMetadata.toJson());

      if (updatedKey == null) {
        throw StateError(
          'Cannot update: Book with ID ${metadata.id} not found.',
        );
      }
    });
  }

  /// Updates an existing chapter strictly.
  /// Throws a StateError if the chapter does not exist, preventing zombie records.
  @override
  Future<void> updateChapter(Chapter chapter) async {
    final db = await _db;

    await db.transaction((txn) async {
      final updatedKey = await _chapterStore
          .record(chapter.id)
          .update(txn, chapter.toJson());

      if (updatedKey == null) {
        throw StateError(
          'Cannot update: Chapter with ID ${chapter.id} not found.',
        );
      }

      await _updateBookModifiedTime(txn, chapter.bookId, chapter.updatedAt);
    });
  }

  /// Performs a highly optimized batch update on multiple chapters.
  @override
  Future<void> updateChapters(List<Chapter> chapters) async {
    if (chapters.isEmpty) return;

    final db = await _db;

    final keys = [for (final chapter in chapters) chapter.id];
    final values = [for (final chapter in chapters) chapter.toJson()];
    final uniqueBookIds = {for (final chapter in chapters) chapter.bookId};

    await db.transaction((txn) async {
      await _chapterStore.records(keys).update(txn, values);

      // Iterate through the unique set to update all affected books' sync timestamps.
      for (final bookId in uniqueBookIds) {
        await _updateBookModifiedTime(txn, bookId);
      }
    });
  }

  /// Updates an existing vocabulary item strictly.
  /// Throws a StateError if the item does not exist, preventing zombie records
  /// during background syncs or multi-tab cross-talk.
  @override
  Future<void> updateVocabulary(VocabularyItem item) async {
    final db = await _db;

    await db.transaction((txn) async {
      final updatedKey = await _contentStore
          .record(item.id)
          .update(txn, item.toJson());

      if (updatedKey == null) {
        throw StateError(
          'Cannot update: VocabularyItem with ID ${item.id} not found.',
        );
      }

      await _updateBookModifiedTime(txn, item.bookId, item.updatedAt);
    });
  }

  /// Performs a highly optimized batch update on multiple vocabulary items.
  @override
  Future<void> updateVocabularies(List<VocabularyItem> items) async {
    if (items.isEmpty) return;

    final db = await _db;

    final keys = [for (final item in items) item.id];
    final values = [for (final item in items) item.toJson()];

    // Extract a set of unique book IDs to safely handle cross-book batch updates.
    final uniqueBookIds = {for (final item in items) item.bookId};

    await db.transaction((txn) async {
      await _contentStore.records(keys).update(txn, values);

      // Iterate through the unique set to update all affected books.
      for (final bookId in uniqueBookIds) {
        await _updateBookModifiedTime(txn, bookId);
      }
    });
  }

  /// Deletes a book and all its hierarchical children (chapters, vocabularies).
  @override
  Future<void> deleteBook(String id, {bool hardDelete = false}) async {
    final db = await _db;

    // A single finder targeting all child entities across different stores.
    final childFinder = Finder(filter: Filter.equals('bookId', id));

    await db.transaction((txn) async {
      if (hardDelete) {
        // TODO(Sync): Google Drive Implementation
        // Before purging the metadata locally, ensure we push a "cleaned" tombstone
        // to Google Drive utilizing the existing `cleanedAt` field. Otherwise,
        // offline devices will re-upload this book during their next sync.

        await _metadataStore.record(id).delete(txn);

        // Purge all relational dependencies to prevent orphaned records.
        await _chapterStore.delete(txn, finder: childFinder);
        await _contentStore.delete(txn, finder: childFinder);
      } else {
        final now = DateTime.now().toUtc().toIso8601String();
        final updatePayload = {'deletedAt': now, 'updatedAt': now};

        // 1. Soft delete the book metadata.
        final updatedKey = await _metadataStore
            .record(id)
            .update(txn, updatePayload);
        if (updatedKey == null) {
          throw StateError('Cannot soft-delete: Book with ID $id not found.');
        }

        // 2. Highly optimized batch soft deletes using Sembast finders.
        await _chapterStore.update(txn, updatePayload, finder: childFinder);
        await _contentStore.update(txn, updatePayload, finder: childFinder);
      }
    });
  }

  /// Soft-deletes a chapter and cascades the soft-deletion to all its vocabulary items.
  @override
  Future<void> deleteChapter(Chapter chapter) async {
    final db = await _db;

    final childFinder = Finder(filter: Filter.equals('chapterId', chapter.id));

    await db.transaction((txn) async {
      final now = DateTime.now().toUtc().toIso8601String();
      final updatePayload = {'deletedAt': now, 'updatedAt': now};

      // 1. Soft-delete the chapter itself
      final updatedKey = await _chapterStore
          .record(chapter.id)
          .update(txn, updatePayload);
      if (updatedKey == null) {
        throw StateError(
          'Cannot delete: Chapter with ID ${chapter.id} not found.',
        );
      }

      // 2. Cascade soft-delete to all vocabulary items within this chapter
      await _contentStore.update(txn, updatePayload, finder: childFinder);

      // 3. Update the book's timestamp to reflect the deletion
      await _updateBookModifiedTime(txn, chapter.bookId);
    });
  }

  @override
  Future<void> deleteVocabulary(
    VocabularyItem item, {
    bool hardDelete = false,
  }) async {
    final db = await _db;

    await db.transaction((txn) async {
      if (hardDelete) {
        // Physical deletion: Removes the record permanently.
        await _contentStore.record(item.id).delete(txn);
      } else {
        // Soft deletion: Generates a tombstone for sync resolution.
        final now = DateTime.now().toUtc().toIso8601String();
        final updatedKey = await _contentStore.record(item.id).update(txn, {
          'deletedAt': now,
          'updatedAt': now,
        });

        if (updatedKey == null) {
          throw StateError(
            'Cannot delete: VocabularyItem with ID ${item.id} not found.',
          );
        }
      }

      // Always bump the book's modified time to trigger sync events.
      await _updateBookModifiedTime(txn, item.bookId);
    });
  }

  @override
  Future<void> close() async {
    if (_dbFuture != null) {
      try {
        final db = await _dbFuture;
        await db?.close();
      } catch (_) {
        // Ignore initialization errors during shutdown
      } finally {
        _dbFuture = null;
      }
    }
  }
}
