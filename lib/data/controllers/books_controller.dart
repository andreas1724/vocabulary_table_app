// ignore_for_file: prefer_initializing_formals

import 'package:signals_flutter/signals_flutter.dart';

import 'package:vocabulary_table_app/data/services/local_storage_service.dart';
import 'package:vocabulary_table_app/models/book.dart';

/// Controller responsible for managing local books list and persistence.
class BooksController {
  BooksController({required LocalStorageService storageService})
      : _storageService = storageService;

  final LocalStorageService _storageService;

  // --- State (Signals) ---

  /// Holds the state of the locally available vocabulary books (metadata only).
  final books = asyncSignal<List<BookMetadata>>(AsyncState.data([]));

  // --- Actions / Methods ---

  /// Loads all book metadata from local storage.
  Future<void> loadBooks() async {
    books.value = AsyncState.loading();
    try {
      final loadedBooks = await _storageService.loadBooks();
      books.value = AsyncState.data(loadedBooks);
    } catch (e, st) {
      books.value = AsyncState.error(e, st);
    }
  }

  /// Saves a book to local storage using optimistic UI updates and graceful rollback.
  Future<void> saveBook(Book book) async {
    // Read state without subscribing to mutations[cite: 6]
    final currentState = books.peek(); 
    List<BookMetadata>? rollbackState;

    if (currentState is AsyncData<List<BookMetadata>>) {
      rollbackState = currentState.requireValue;
      
      // Use Dart 3 list comprehensions to efficiently replace the existing item
      final updatedList = [
        for (final b in rollbackState)
          if (b.id != book.metadata.id) b,
      ];
      
      updatedList.add(book.metadata);

      // Enforce consistent descending sorting based on updatedAt to match Sembast
      updatedList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      // Apply optimistic update for zero-latency UI feedback
      books.value = AsyncState.data(updatedList);
    }

    try {
      await _storageService.saveBook(book);
    } catch (e) {
      // Graceful rollback: Revert to previous state instead of destroying the list UI
      if (rollbackState != null) {
        books.value = AsyncState.data(rollbackState);
      }
      // Note: Trigger a separate SignalEffect here to show a SnackBar error to the user
    }
  }

  /// Deletes a book with optimistic updates and graceful rollback.
  Future<void> deleteBook(String id) async {
    final currentState = books.peek();
    List<BookMetadata>? rollbackState;

    if (currentState is AsyncData<List<BookMetadata>>) {
      rollbackState = currentState.requireValue;
      
      // Apply optimistic deletion efficiently
      final updatedList = [
        for (final b in rollbackState)
          if (b.id != id) b,
      ];
      
      books.value = AsyncState.data(updatedList);
    }

    try {
      await _storageService.deleteBook(id);
    } catch (e) {
      // Revert optimistic deletion on database failure
      if (rollbackState != null) {
        books.value = AsyncState.data(rollbackState);
      }
    }
  }
}