import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/data/services/local_storage_service.dart';
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

  // We use two stores to keep things fast:
  // One for metadata (list view) and one for the vocabulary items.
  final _metadataStore = stringMapStoreFactory.store('metadata');

  // Refactored: _contentStore now stores individual vocabulary items
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
  Future<List<BookMetadata>> getAllBooks() async {
    final db = await _db;
    final records = await _metadataStore.find(db);
    return records
        .map((record) => BookMetadata.fromJson(record.value))
        .toList();
  }

  @override
  Future<Book?> getBookContent(String id) async {
    final db = await _db;
    final metaRecord = await _metadataStore.record(id).get(db);

    if (metaRecord == null) {
      return null;
    }

    // Find all vocabulary items for this book
    final finder = Finder(
      filter: Filter.equals('bookId', id),
      sortOrders: [SortOrder('order')],
    );
    final itemRecords = await _contentStore.find(db, finder: finder);

    final items = itemRecords
        .map(
          (record) =>
              VocabularyItem.fromJson(Map<String, dynamic>.from(record.value)),
        )
        .toList();

    return Book(
      metadata: BookMetadata.fromJson(
        Map<String, dynamic>.from(metaRecord as Map),
      ),
      items: items,
    );
  }

  @override
  Future<void> saveBook(Book book) async {
    final id = book.metadata.id;

    final db = await _db;
    await db.transaction((txn) async {
      // Save metadata
      await _metadataStore.record(id).put(txn, book.metadata.toJson());

      // Delete all existing vocabulary items for this book
      final finder = Finder(filter: Filter.equals('bookId', id));
      await _contentStore.delete(txn, finder: finder);

      // Save new vocabulary items individually
      for (var i = 0; i < book.items.length; i++) {
        final item = book.items[i];
        // Ensure the bookId is matching the book's metadata id and order is set
        final itemToSave = item.copyWith(bookId: id, order: i);
        await _contentStore.record(itemToSave.id).put(txn, itemToSave.toJson());
      }
    });
  }

  @override
  Future<void> deleteBook(String id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await _metadataStore.record(id).delete(txn);

      // Delete all vocabulary items for this book
      final finder = Finder(filter: Filter.equals('bookId', id));
      await _contentStore.delete(txn, finder: finder);
    });
  }

  @override
  Stream<List<VocabularyItem>> watchVocabulariesForBook(String bookId) async* {
    final db = await _db;
    final finder = Finder(
      filter: Filter.equals('bookId', bookId),
      sortOrders: [SortOrder('order')],
    );
    final query = _contentStore.query(finder: finder);

    yield* query.onSnapshots(db).map((snapshots) {
      return snapshots
          .map(
            (snapshot) => VocabularyItem.fromJson(
              Map<String, dynamic>.from(snapshot.value),
            ),
          )
          .toList();
    });
  }

  Future<void> _updateBookModifiedTime(Transaction txn, String bookId) async {
    final metaRecord = await _metadataStore.record(bookId).get(txn);
    if (metaRecord != null) {
      final meta = BookMetadata.fromJson(
        Map<String, dynamic>.from(metaRecord as Map),
      );
      final updatedMeta = meta.copyWith(modifiedTime: DateTime.now());
      await _metadataStore.record(bookId).put(txn, updatedMeta.toJson());
    }
  }

  @override
  Future<void> addVocabulary(VocabularyItem item) async {
    final db = await _db;
    await db.transaction((txn) async {
      await _contentStore.record(item.id).put(txn, item.toJson());
      await _updateBookModifiedTime(txn, item.bookId);
    });
  }

  @override
  Future<void> updateVocabulary(VocabularyItem item) async {
    final db = await _db;
    await db.transaction((txn) async {
      await _contentStore.record(item.id).put(txn, item.toJson());
      await _updateBookModifiedTime(txn, item.bookId);
    });
  }

  @override
  Future<void> deleteVocabulary(VocabularyItem item) async {
    final db = await _db;
    await db.transaction((txn) async {
      await _contentStore.record(item.id).delete(txn);
      await _updateBookModifiedTime(txn, item.bookId);
    });
  }

  @override
  Future<void> updateVocabularies(List<VocabularyItem> items) async {
    if (items.isEmpty) return;
    final db = await _db;
    await db.transaction((txn) async {
      for (final item in items) {
        await _contentStore.record(item.id).put(txn, item.toJson());
      }
      await _updateBookModifiedTime(txn, items.first.bookId);
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
