import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

import 'package:vocabulary_table_app/data/models/book.dart';
import 'package:vocabulary_table_app/data/services/local_storage_service.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

class SembastLocalStorageService implements LocalStorageService {
  /// Optional parameters are used for injecting an in-memory database during testing.
  SembastLocalStorageService({this.factoryOverride, this.dbPathOverride});

  final DatabaseFactory? factoryOverride;
  final String? dbPathOverride;

  Future<Database>? _dbFuture;

  Future<Database> get _db {
    _dbFuture ??= _initDb();
    return _dbFuture!;
  }

  // We use two stores to keep things fast:
  // One for metadata (list view) and one for the vocabulary items.
  final _metadataStore = stringMapStoreFactory.store('metadata');
  final _contentStore = StoreRef<String, List<dynamic>>('vocab_content');

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
    final contentRecord = await _contentStore.record(id).get(db);

    if (metaRecord == null || contentRecord == null) {
      return null;
    }

    final items = contentRecord
        .map(
          (json) =>
              VocabularyItem.fromJson(Map<String, dynamic>.from(json as Map)),
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

      final itemsJson = book.items.map((item) => item.toJson()).toList();
      await _contentStore.record(id).put(txn, itemsJson);
    });
  }

  @override
  Future<void> deleteBook(String id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await _metadataStore.record(id).delete(txn);
      await _contentStore.record(id).delete(txn);
    });
  }
}
