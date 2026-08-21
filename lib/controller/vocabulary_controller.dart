// ignore_for_file: prefer_initializing_formals

import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/data/controllers/vocab_repository.dart';
import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';
import 'package:vocabulary_table_app/utils/list_signal_extension.dart';

class VocabularyController {
  VocabularyController({
    required VocabRepository repository,
    required Book book,
  })  : _repository = repository,
        _metadata = book.metadata,
        _vocabularyItems = listSignal(
          book.items.map((item) => signal(item)).toList(),
        );

  final VocabRepository _repository;
  BookMetadata _metadata;

  final ListSignal<Signal<VocabularyItem>> _vocabularyItems;
  final selectedCell = signal<(int rowIndex, ColumnName)?>(null);

  final languageA = signal<String>('Language A');
  final languageB = signal<String>('Language B');

  late final vocabularyItems = _vocabularyItems.readonly();

  late final chapters = computed(() {
    final temp = <String>{};
    return _vocabularyItems
        .map((signalItem) => signalItem.value.chapter)
        .where((chapter) => temp.add(chapter))
        .toList();
  });

  /// Saves the current state of the vocabulary list to the local database.
  Future<void> saveBook() async {
    // Update the modified time to now
    _metadata = BookMetadata(
      id: _metadata.id,
      title: _metadata.title,
      modifiedTime: DateTime.now(),
    );

    // Extract raw VocabularyItem values from the signals
    final itemsToSave = _vocabularyItems.map((s) => s.peek()).toList();

    final updatedBook = Book(
      metadata: _metadata,
      items: itemsToSave,
    );

    await _repository.saveBookLocally(updatedBook);
  }

  void addVocabulary(VocabularyItem item) {
    _vocabularyItems.add(signal(item));
  }

  void removeVocabularyAt(int index) {
    if (index < 0 || index >= _vocabularyItems.length) return;
    final removedSignal = _vocabularyItems.removeAt(index);
    removedSignal.dispose();
  }

  void updateVocabularyAt(int index, VocabularyItem item) {
    if (index < 0 || index >= _vocabularyItems.length) return;
    _vocabularyItems[index].value = item;
  }

  void updateVocabularyAtLocation(
    ({int rowIndex, ColumnName column}) location,
    String updateText,
  ) {
    if (location.rowIndex < 0 || location.rowIndex >= _vocabularyItems.length) {
      return;
    }

    final vocabularyItem = _vocabularyItems[location.rowIndex].peek();
    final updatedItem = switch (location.column) {
      .termA => vocabularyItem.copyWith(termA: updateText),
      .termB => vocabularyItem.copyWith(termB: updateText),
      .comment => vocabularyItem.copyWith(comment: updateText),
      .chapter => vocabularyItem.copyWith(chapter: updateText),
      .id => vocabularyItem.copyWith(id: updateText)
    };
    updateVocabularyAt(location.rowIndex, updatedItem);
  }

  /// oldIndex refers to the item's original position before removal.
  /// newIndex points to the exact target position in the cleaned list after removal.
  void reorderItem(int oldIndex, int newIndex) {
    // Prevent unnecessary operations if the position hasn't changed
    if (oldIndex == newIndex) return;

    // Strict bounds checking to prevent RangeError during dynamic list operations
    if (oldIndex < 0 ||
        oldIndex >= _vocabularyItems.length ||
        newIndex < 0 ||
        newIndex > _vocabularyItems.length) {
      return;
    }
    batch(() {
      final item = _vocabularyItems.removeAt(oldIndex);
      _vocabularyItems.insert(newIndex, item);
    });
  }

  void clear() {
    _vocabularyItems.clearAndDispose();
  }

  void dispose() {
    _vocabularyItems.clear();
    _vocabularyItems.dispose();
  }
}
