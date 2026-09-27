import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/data/controllers/chapter_controller.dart';
import 'package:vocabulary_table_app/data/controllers/vocab_repository.dart';
import 'package:vocabulary_table_app/data/core/di/service_locator.dart';
import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/models/chapter.dart';
import 'package:vocabulary_table_app/raw_csv_string.dart';
import 'package:vocabulary_table_app/widgets/vocabulary_table_app.dart';

/* 
rm /Users/user/Library/Containers/com.example.vocabularyTableApp/Data/Documents/vocabularies_local.db
*/

void main() async {
  // Always invoke this first before utilizing framework features
  WidgetsFlutterBinding.ensureInitialized();

  SignalsObserver.instance = null;

  await setUpDependencies();

  runApp(
    MaterialApp(
      home: const VocabularyTableApp(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orangeAccent,
          brightness: Brightness.light,
        ),
      ),
      debugShowCheckedModeBanner: false,
    ),
  );
}

Future<void> setUpDependencies() async {
  await setupDependencies();

  final repository = GetIt.I<VocabRepository>();
  const dummyBookId = 'test-csv-book-id';

  Book? activeBook = await repository.getBookLocally(dummyBookId);

  // If the book does not exist or was corrupted (empty items), purge and re-seed
  if (activeBook == null || activeBook.items.isEmpty) {
    if (activeBook != null) {
      debugPrint('Found empty book shell. Purging existing records...');
      await repository.deleteBook(dummyBookId, hardDelete: true);
    }

    final parsedResult = await repository.parseCsv(rawCsvString);

    activeBook = Book(
      metadata: BookMetadata.create(
        id: dummyBookId, // Consider using a UUID package instead of hardcoding in production
        title: parsedResult.title,
        languageA: parsedResult.languageA,
        languageB: parsedResult.languageB,
        commentHeader: parsedResult.commentHeader,
      ),
      items: parsedResult.vocabularyItems,
    );

    await repository.saveBookLocally(activeBook);
    debugPrint('CSV parsed and securely saved to Sembast.');

    final uniqueChapterNames = parsedResult.vocabularyItems
        .map((item) => item.chapterId)
        .toSet()
        .toList();

    // Parallelize database inserts to avoid N+1 I/O blocking
    final chapterFutures = <Future<void>>[];

    for (var i = 0; i < uniqueChapterNames.length; i++) {
      final name = uniqueChapterNames[i];
      final chapter = Chapter.create(
        id: name,
        bookId: dummyBookId,
        name: name,
        order: i,
      );
      chapterFutures.add(repository.addChapterLocally(chapter));
    }

    // Await all inserts concurrently
    await Future.wait(chapterFutures);
  } else {
    debugPrint(
      'Loaded existing book from Sembast with ${activeBook.items.length} items.',
    );
  }

  // At this point, activeBook is guaranteed to be non-null and seeded.
  GetIt.I.registerLazySingleton<VocabularyController>(
    () => VocabularyController(repository: repository, book: activeBook!),
  );

  GetIt.I.registerLazySingleton<ChapterController>(
    () => ChapterController(
      repository: repository,
      bookId: activeBook!.metadata.id,
    ),
  );
}
