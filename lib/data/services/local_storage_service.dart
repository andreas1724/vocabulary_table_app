import 'package:vocabulary_table_app/data/models/book.dart';

abstract class LocalStorageService {
  /// Returns a list of all cached books (metadata only)
  Future<List<BookMetadata>> getAllBooks();

  /// Returns the full book content (including CSV string) by its ID
  Future<Book?> getBookContent(String id);

  /// Saves or updates a book in the local cache
  Future<void> saveBook(Book book);

  /// Deletes a book from the local cache
  Future<void> deleteBook(String id);
}
