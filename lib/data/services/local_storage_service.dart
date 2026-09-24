import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/models/chapter.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

/// Abstract contract for local data persistence.
///
/// Implementing classes must ensure that operations are atomic, handle soft
/// deletions properly, and maintain timestamp integrity for cloud synchronization.
abstract interface class LocalStorageService {
  /// Fetches a list of all non-deleted books.
  ///
  /// The results should be sorted descending by their [updatedAt] timestamp,
  /// ensuring the most recently modified books appear first.
  Future<List<BookMetadata>> loadBooks();

  /// Fetches a fully assembled [Book] including all its active chapters
  /// and vocabulary items.
  ///
  /// Returns `null` if the book metadata does not exist. Items are expected
  /// to be sorted contextually (chapter order -> item order).
  Future<Book?> getBookContent(String id);

  /// Performs a bulk upsert of a complete [Book].
  ///
  /// This method computes a diff against the existing database. Items not present
  /// in the provided [book] are soft-deleted. The `updatedAt` timestamps of the
  /// incoming items must be trusted and preserved to ensure Last-Write-Wins (LWW)
  /// conflict resolution during external syncs.
  Future<void> saveBook(Book book);

  /// Emits a stream of all non-deleted chapters for a given [bookId].
  ///
  /// The emitted lists must be strictly pre-sorted by their `order` property.
  Stream<List<Chapter>> watchChaptersForBook(String bookId);

  /// Emits a stream of all non-deleted vocabulary items for a given [bookId].
  ///
  /// The emitted lists are intentionally unsorted to allow reactive UI
  /// controllers to handle the complex, multi-level sorting logic in memory.
  Stream<List<VocabularyItem>> watchVocabulariesForBook(String bookId);

  /// Persists a new book metadata record.
  ///
  /// Throws a [StateError] if a book with the given ID already exists.
  Future<void> addBook(BookMetadata metadata);

  /// Persists a new chapter.
  ///
  /// Throws a [StateError] if a chapter with the given ID already exists.
  /// Automatically updates the parent book's `updatedAt` timestamp.
  Future<void> addChapter(Chapter chapter);

  /// Persists a new vocabulary item.
  ///
  /// Throws a [StateError] if an item with the given ID already exists.
  /// Automatically updates the parent book's `updatedAt` timestamp.
  Future<void> addVocabulary(VocabularyItem item);

  /// Modifies an existing book's metadata.
  ///
  /// Throws a [StateError] if the book does not exist.
  Future<void> updateBook(BookMetadata metadata);

  /// Modifies an existing chapter.
  ///
  /// Throws a [StateError] if the chapter does not exist.
  /// Automatically updates the parent book's `updatedAt` timestamp.
  Future<void> updateChapter(Chapter chapter);

  /// Performs a highly optimized batch update on multiple chapters.
  Future<void> updateChapters(List<Chapter> chapters);

  /// Modifies a single vocabulary item.
  ///
  /// Throws a [StateError] if the item does not exist.
  /// Automatically updates the parent book's `updatedAt` timestamp.
  Future<void> updateVocabulary(VocabularyItem item);

  /// Modifies multiple vocabulary items in a single atomic transaction.
  ///
  /// Skips processing if the list is empty. Automatically extracts unique
  /// book IDs and bumps their `updatedAt` timestamps.
  Future<void> updateVocabularies(List<VocabularyItem> items);

  /// Deletes a book and cascades the deletion to all associated chapters
  /// and vocabulary items.
  ///
  /// If [hardDelete] is true, records are physically purged from the database.
  /// If false, records receive a `deletedAt` tombstone timestamp.
  Future<void> deleteBook(String id, {bool hardDelete = false});

  /// Soft-deletes a chapter and cascades the soft-deletion to all its
  /// contained vocabulary items.
  ///
  /// Throws a [StateError] if the chapter does not exist.
  Future<void> deleteChapter(Chapter chapter);

  /// Deletes a single vocabulary item.
  ///
  /// If [hardDelete] is true, the record is physically purged.
  /// If false, the record receives a `deletedAt` tombstone timestamp.
  /// Throws a [StateError] if the item does not exist.
  Future<void> deleteVocabulary(VocabularyItem item, {bool hardDelete = false});

  /// Safely releases database resources and terminates active connections.
  Future<void> close();
}
