import 'package:signals_flutter/signals_flutter.dart';

import 'package:vocabulary_table_app/data/models/book.dart';
import 'package:vocabulary_table_app/data/services/local_storage_service.dart';

/// Controller responsible for managing local books list and persistence
class BooksController {
  BooksController(this._storageService);

  final LocalStorageService _storageService;

  // --- State (Signals) ---

  /// Holds the state of the locally available vocabulary books (metadata only)
  final books = asyncSignal<List<BookMetadata>>(AsyncState.data([]));

  // --- Actions / Methods ---

  /// Loads all book metadata from local storage
  Future<void> loadBooks() async {
    books.value = AsyncState.loading();
    try {
      final loadedBooks = await _storageService.getAllBooks();
      books.value = AsyncState.data(loadedBooks);
    } catch (e, st) {
      books.value = AsyncState.error(e, st);
    }
  }

  /// Saves a book to local storage and updates the signal
  Future<void> saveBook(Book book) async {
    try {
      await _storageService.saveBook(book);

      final state = books.value;
      if (state is AsyncData<List<BookMetadata>>) {
        final currentBooks = state.requireValue;
        final index = currentBooks.indexWhere((b) => b.id == book.metadata.id);

        final updatedList = List<BookMetadata>.from(currentBooks);
        if (index != -1) {
          // Update existing book
          updatedList[index] = book.metadata;
        } else {
          // Add new book
          updatedList.add(book.metadata);
        }
        books.value = AsyncState.data(updatedList);
      } else {
        // If we are in an error/loading state, just reload everything
        await loadBooks();
      }
    } catch (e, st) {
      books.value = AsyncState.error(e, st);
    }
  }

  /// Deletes a book from local storage and updates the signal
  Future<void> deleteBook(String id) async {
    try {
      await _storageService.deleteBook(id);

      final state = books.value;
      if (state is AsyncData<List<BookMetadata>>) {
        final currentBooks = state.requireValue;
        final updatedList = currentBooks.where((b) => b.id != id).toList();
        books.value = AsyncState.data(updatedList);
      } else {
        await loadBooks();
      }
    } catch (e, st) {
      books.value = AsyncState.error(e, st);
    }
  }
}
