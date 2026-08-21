import 'package:vocabulary_table_app/data/services/csv_parser_service.dart';
import 'package:vocabulary_table_app/data/services/local_storage_service.dart';
import 'package:vocabulary_table_app/models/book.dart';

// ignore_for_file: prefer_initializing_formals

/// Controller responsible for managing vocabulary state and operations
class VocabRepository {
  VocabRepository({
    required CsvParserService parserService,
    required LocalStorageService storageService,
  }) : _parserService = parserService,
       _storageService = storageService;

  final CsvParserService _parserService;
  final LocalStorageService _storageService;

  /// Parses CSV data and returns it without retaining any state.
  Future<ParsedCsvResult> parseCsv(
    String csvContent, {
    String? defaultChapter,
  }) async {
    // Simulate slight delay if needed for future Drive API integration
    return _parserService.parseCsv(
      csvContent,
      defaultChapter: defaultChapter ?? 'Unknown Chapter',
    );
  }

  /// Saves the complete book (metadata and items) to the local database.
  Future<void> saveBookLocally(Book book) async {
    await _storageService.saveBook(book);
  }

  /// Retrieves a complete book from the local database by ID.
  Future<Book?> getBookLocally(String id) async {
    return _storageService.getBookContent(id);
  }
}
