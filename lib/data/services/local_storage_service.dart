import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

abstract class LocalStorageService {
  /// Returns a list of all cached books (metadata only)
  Future<List<BookMetadata>> getAllBooks();

  /// Returns the full book content (including CSV string) by its ID
  Future<Book?> getBookContent(String id);

  /// Saves or updates a book in the local cache
  Future<void> saveBook(Book book);

  /// Deletes a book from the local cache
  Future<void> deleteBook(String id);

  /// Streams the vocabulary items for a given book
  Stream<List<VocabularyItem>> watchVocabulariesForBook(String bookId);

  /// Adds a new vocabulary item to the store and updates the book's modified time
  Future<void> addVocabulary(VocabularyItem item);

  /// Updates an existing vocabulary item in the store and updates the book's modified time
  Future<void> updateVocabulary(VocabularyItem item);

  /// Deletes a vocabulary item from the store and updates the book's modified time
  Future<void> deleteVocabulary(VocabularyItem item);

  /// Updates multiple vocabulary items in the store and updates the book's modified time
  Future<void> updateVocabularies(List<VocabularyItem> items);
}
