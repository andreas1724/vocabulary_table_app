// import 'package:flutter/foundation.dart';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';
// import 'package:sembast/sembast_io.dart';
// import 'package:sembast_web/sembast_web.dart';

// import 'package:vocabulary_table_app/data/services/local_storage_service.dart';
// import 'package:vocabulary_table_app/models/book.dart';
// import 'package:vocabulary_table_app/models/chapter.dart';
// import 'package:vocabulary_table_app/models/vocabulary_item.dart';

// class SembastLocalStorageServiceX implements LocalStorageService {
//   // Constructor placed strictly at the top.
//   SembastLocalStorageServiceX({this.factoryOverride, this.dbPathOverride});

//   final DatabaseFactory? factoryOverride;
//   final String? dbPathOverride;

//   Future<Database>? _dbFuture;

//   final _metadataStore = stringMapStoreFactory.store('metadata');
//   final _chapterStore = stringMapStoreFactory.store('chapters');
//   final _contentStore = stringMapStoreFactory.store('vocabularies');

//   Future<Database> get _db {
//     _dbFuture ??= _initDb().catchError((Object error, StackTrace stackTrace) {
//       // Reset the future so subsequent calls can retry instead of permanently failing.
//       _dbFuture = null;
//       return Future<Database>.error(error, stackTrace);
//     });
//     return _dbFuture!;
//   }

//   Future<Database> _initDb() async {
//     if (factoryOverride != null) {
//       // Use the injected factory (e.g., in-memory for testing).
//       return await factoryOverride!.openDatabase(dbPathOverride ?? 'test.db');
//     }

//     if (kIsWeb) {
//       final factory = databaseFactoryWeb;
//       return await factory.openDatabase('vocabularies_web.db');
//     } else {
//       final dir = await getApplicationDocumentsDirectory();
//       await dir.create(recursive: true);
//       final dbPath = p.join(dir.path, 'vocabularies_local.db');
//       final factory = databaseFactoryIo;
//       return await factory.openDatabase(dbPath);
//     }
//   }

//   @override
//   Stream<List<Chapter>> watchChaptersForBook(String bookId) async* {
//     final db = await _db;

//     final finder = Finder(
//       filter: Filter.and([
//         Filter.equals('bookId', bookId),
//         Filter.isNull('deletedAt'),
//       ]),
//       // Native sorting is fine here as it's a single collection.
//       sortOrders: [SortOrder('order')],
//     );

//     yield* _chapterStore.query(finder: finder).onSnapshots(db).map((snapshots) {
//       return snapshots.map((snapshot) {
//         return Chapter.fromJson(snapshot.value);
//       }).toList();
//     });
//   }

//   @override
//   Stream<List<VocabularyItem>> watchVocabulariesForBook(String bookId) async* {
//     final db = await _db;

//     final finder = Finder(
//       filter: Filter.and([
//         Filter.equals('bookId', bookId),
//         Filter.isNull('deletedAt'),
//       ]),
//       // Omit DB sorting. Complex multi-level sorting will be handled by the UI/Controllers.
//     );

//     yield* _contentStore.query(finder: finder).onSnapshots(db).map((snapshots) {
//       return snapshots.map((snapshot) {
//         return VocabularyItem.fromJson(snapshot.value);
//       }).toList();
//     });
//   }

//   @override
//   Future<Book?> getBookContent(String id) async {
//     final db = await _db;

//     final metaRecord = await _metadataStore.record(id).get(db);
//     if (metaRecord == null) {
//       return null;
//     }

//     // Execute independent database reads concurrently to eliminate I/O latency.
//     final results = await Future.wait([
//       _chapterStore.find(
//         db,
//         finder: Finder(
//           filter: Filter.and([
//             Filter.equals('bookId', id),
//             Filter.isNull('deletedAt'),
//           ]),
//         ),
//       ),
//       _contentStore.find(
//         db,
//         finder: Finder(
//           filter: Filter.and([
//             Filter.equals('bookId', id),
//             Filter.isNull('deletedAt'),
//           ]),
//         ),
//       ),
//     ]);

//     final chapterRecords = results[0];
//     final itemRecords = results[1];

//     // Build the O(1) lookup map safely, guarding against corrupt DB entries.
//     final chapterOrderMap = <String, int>{
//       for (final record in chapterRecords)
//         if (record.value case final Map<String, dynamic> data)
//           data['id']?.toString() ?? '': (data['order'] as num?)?.toInt() ?? 0,
//     };

//     // Utilize list comprehension for reduced iterable allocation overhead in Dart 3.
//     final items = [
//       for (final record in itemRecords)
//         if (record.value case final Map<String, dynamic> data)
//           VocabularyItem.fromJson(data)
//     ];

//     // Fallback constant for orphaned items (chapter soft-deleted, but cascade pending).
//     const orphanOrderFallback = 999999;

//     // Perform the multi-level sort purely in memory.
//     items.sort((a, b) {
//       final chapterOrderA = chapterOrderMap[a.chapterId] ?? orphanOrderFallback;
//       final chapterOrderB = chapterOrderMap[b.chapterId] ?? orphanOrderFallback;

//       final chapterComparison = chapterOrderA.compareTo(chapterOrderB);

//       if (chapterComparison != 0) {
//         return chapterComparison;
//       }

//       return a.order.compareTo(b.order);
//     });

//     return Book(
//       metadata: BookMetadata.fromJson(metaRecord as Map<String, dynamic>),
//       items: items,
//     );
//   }

//   @override
//   Future<void> close() async {
//     if (_dbFuture != null) {
//       try {
//         final db = await _dbFuture;
//         await db?.close();
//       } catch (_) {
//         // Suppress shutdown errors.
//       } finally {
//         _dbFuture = null;
//       }
//     }
//   }
// }
