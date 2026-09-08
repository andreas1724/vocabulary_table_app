import 'package:vocabulary_table_app/data/services/csv_parser_service.dart';
import 'package:vocabulary_table_app/data/services/local_storage_service.dart';
import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

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

  /// Deletes a complete book from the local database by ID.
  Future<void> deleteBookLocally(String id) async {
    await _storageService.deleteBook(id);
  }

  /// Streams the vocabulary items for a given book from local storage.
  Stream<List<VocabularyItem>> watchVocabulariesForBook(String bookId) {
    return _storageService.watchVocabulariesForBook(bookId);
  }

  /// Adds a new vocabulary item locally.
  Future<void> addVocabularyLocally(VocabularyItem item) async {
    await _storageService.addVocabulary(item);
  }

  /// Updates an existing vocabulary item locally.
  Future<void> updateVocabularyLocally(VocabularyItem item) async {
    await _storageService.updateVocabulary(item);
  }

  /// Deletes a vocabulary item locally.
  Future<void> deleteVocabularyLocally(VocabularyItem item) async {
    await _storageService.deleteVocabulary(item);
  }

  /// Updates multiple vocabulary items locally.
  Future<void> updateVocabulariesLocally(List<VocabularyItem> items) async {
    await _storageService.updateVocabularies(items);
  }
}
