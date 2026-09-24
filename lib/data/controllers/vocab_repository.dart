// ignore_for_file: prefer_initializing_formals

import 'package:vocabulary_table_app/data/services/csv_parser_service.dart';
import 'package:vocabulary_table_app/data/services/local_storage_service.dart';
import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/models/chapter.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

/// Controller responsible for managing vocabulary and chapter state operations.
class VocabRepository {
  VocabRepository({
    required CsvParserService parserService,
    required LocalStorageService storageService,
  })  : _parserService = parserService,
        _storageService = storageService;

  final CsvParserService _parserService;
  final LocalStorageService _storageService;

  // --- CSV ---

  /// Parses CSV data and returns it without retaining any state.
  Future<ParsedCsvResult> parseCsv(
    String csvContent, {
    String? defaultChapter,
  }) async {
    return _parserService.parseCsv(csvContent);
  }

  // --- Books ---

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

  // --- Chapters ---

  /// Streams the chapters for a given book from local storage.
  Stream<List<Chapter>> watchChaptersForBook(String bookId) {
    return _storageService.watchChaptersForBook(bookId);
  }

  /// Adds a new chapter locally.
  Future<void> addChapterLocally(Chapter chapter) async {
    await _storageService.addChapter(chapter);
  }

  /// Updates an existing chapter locally.
  Future<void> updateChapterLocally(Chapter chapter) async {
    await _storageService.updateChapter(chapter);
  }

  /// Deletes a chapter locally, triggering a cascade soft-delete for its vocabularies.
  Future<void> deleteChapterLocally(Chapter chapter) async {
    await _storageService.deleteChapter(chapter);
  }

  /// Updates multiple chapters locally in a single batch transaction.
  Future<void> updateChaptersLocally(List<Chapter> chapters) async {
    await _storageService.updateChapters(chapters);
  }

  // --- Vocabularies ---

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

  /// Updates multiple vocabulary items locally in a single batch transaction.
  Future<void> updateVocabulariesLocally(List<VocabularyItem> items) async {
    await _storageService.updateVocabularies(items);
  }
}