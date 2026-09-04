// ignore_for_file: prefer_initializing_formals

import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/data/controllers/vocab_repository.dart';
import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

class VocabularyController {
  VocabularyController({
    required VocabRepository repository,
    required Book book,
  })  : _repository = repository,
        bookId = book.metadata.id {
    // Initialize the stream signal from the repository
    _vocabularyItemsStream = streamSignal(
      () => _repository.watchVocabulariesForBook(bookId),
      options: AsyncSignalOptions(initialValue: book.items),
    );
  }

  final VocabRepository _repository;
  final String bookId;

  late final StreamSignal<List<VocabularyItem>> _vocabularyItemsStream;
  
  // Expose the list of vocabulary items reactively
  // streamSignal.value will contain the AsyncState
  late final vocabularyItems = computed<List<VocabularyItem>>(() {
    final state = _vocabularyItemsStream.value;
    return state.value ?? [];
  });

  final selectedCell = signal<(int rowIndex, ColumnName)?>(null);

  final languageA = signal<String>('Language A');
  final languageB = signal<String>('Language B');

  late final chapters = computed(() {
    final temp = <String>{};
    return vocabularyItems.value
        .map((item) => item.chapter)
        .where((chapter) => temp.add(chapter))
        .toList();
  });

  Future<void> addVocabulary(VocabularyItem item) async {
    final items = vocabularyItems.value;
    final newOrder = items.length;
    // Ensure the new item is associated with this book and order is at the end
    final itemToSave = item.copyWith(bookId: bookId, order: newOrder);
    await _repository.addVocabularyLocally(itemToSave);
  }

  Future<void> removeVocabularyAt(int index) async {
    final items = vocabularyItems.value;
    if (index < 0 || index >= items.length) return;
    
    final itemToDelete = items[index];
    await _repository.deleteVocabularyLocally(itemToDelete);
  }

  Future<void> updateVocabularyAt(int index, VocabularyItem item) async {
    final items = vocabularyItems.value;
    if (index < 0 || index >= items.length) return;
    
    // Ensure the item ID matches the existing one at the index
    final existingItem = items[index];
    final itemToUpdate = item.copyWith(id: existingItem.id, bookId: bookId);
    
    await _repository.updateVocabularyLocally(itemToUpdate);
  }

  Future<void> updateVocabularyAtLocation(
    ({int rowIndex, ColumnName column}) location,
    String updateText,
  ) async {
    final items = vocabularyItems.value;
    if (location.rowIndex < 0 || location.rowIndex >= items.length) {
      return;
    }

    final vocabularyItem = items[location.rowIndex];
    final updatedItem = switch (location.column) {
      .termA => vocabularyItem.copyWith(termA: updateText),
      .termB => vocabularyItem.copyWith(termB: updateText),
      .comment => vocabularyItem.copyWith(comment: updateText),
      .chapter => vocabularyItem.copyWith(chapter: updateText),
      .id => vocabularyItem.copyWith(id: updateText) // Should not really edit ID but keeping parity
    };
    
    await _repository.updateVocabularyLocally(updatedItem);
  }

  /// oldIndex refers to the item's original position before removal.
  /// newIndex points to the exact target position in the cleaned list after removal.
  Future<void> reorderItem(int oldIndex, int newIndex) async {
    final items = List<VocabularyItem>.from(vocabularyItems.value);
    
    if (oldIndex == newIndex) return;

    if (oldIndex < 0 ||
        oldIndex >= items.length ||
        newIndex < 0 ||
        newIndex > items.length) {
      return;
    }
    
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    final updatedItems = <VocabularyItem>[];
    for (var i = 0; i < items.length; i++) {
      if (items[i].order != i) {
        items[i] = items[i].copyWith(order: i);
        updatedItems.add(items[i]);
      }
    }

    if (updatedItems.isNotEmpty) {
      await _repository.updateVocabulariesLocally(updatedItems);
    }
  }

  void dispose() {
    _vocabularyItemsStream.dispose();
  }
}
