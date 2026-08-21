import 'package:get_it/get_it.dart';

import 'package:vocabulary_table_app/data/services/local_storage_service.dart';
import 'package:vocabulary_table_app/data/services/csv_parser_service.dart';
import 'package:vocabulary_table_app/data/services/sembast_local_storage_service.dart';
import 'package:vocabulary_table_app/data/controllers/books_controller.dart';
import 'package:vocabulary_table_app/data/controllers/vocab_repository.dart';

Future<void> setupDependencies() async {
  // Services
  GetIt.I.registerLazySingleton<CsvParserService>(() => CsvParserService());

  GetIt.I.registerLazySingleton<LocalStorageService>(
    () => SembastLocalStorageService(),
  );

  // State Management (Signals)
  GetIt.I.registerLazySingleton<VocabRepository>(
    () => VocabRepository(
      parserService: GetIt.I<CsvParserService>(),
      storageService: GetIt.I<LocalStorageService>(),
    ),
  );
  
  GetIt.I.registerLazySingleton<BooksController>(() => BooksController(GetIt.I()));
}
