import 'package:get_it/get_it.dart';

import 'package:vocabulary_table_app/data/services/local_storage_service.dart';
import 'package:vocabulary_table_app/data/services/csv_parser_service.dart';
import 'package:vocabulary_table_app/data/services/sembast_local_storage_service.dart';
import 'package:vocabulary_table_app/data/controllers/books_controller.dart';
import 'package:vocabulary_table_app/data/controllers/vocab_repository.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Services
  getIt.registerLazySingleton<CsvParserService>(() => CsvParserService());

  getIt.registerLazySingleton<LocalStorageService>(
    () => SembastLocalStorageService(),
  );

  // State Management (Signals)
  getIt.registerLazySingleton<VocabRepository>(() => VocabRepository(getIt()));
  getIt.registerLazySingleton<BooksController>(() => BooksController(getIt()));
}
