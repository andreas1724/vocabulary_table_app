import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';
import 'package:vocabulary_table_app/utils/list_signal_extension.dart';

class VocabularyController {
  VocabularyController({required List<VocabularyItem> vocabularyItems})
    : _vocabularyItems = listSignal(
        vocabularyItems.map((item) => signal(item)).toList(),
      );

  final ListSignal<Signal<VocabularyItem>> _vocabularyItems;
  final selectedCell = signal<(int, int)?>(null);

  late final vocabularyItems = _vocabularyItems.readonly();

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
    ({int rowIndex, int colIndex}) location,
    String updateText,
  ) {
    if (location.rowIndex < 0 || location.rowIndex >= _vocabularyItems.length) {
      return;
    }
    if (location.colIndex < 0 || location.colIndex > 2) {
      return;
    }

    final vocabularyItem = _vocabularyItems[location.rowIndex].peek();
    final updatedItem = switch (location.colIndex) {
      0 => vocabularyItem.copyWith(termA: updateText),
      1 => vocabularyItem.copyWith(termB: updateText),
      2 => vocabularyItem.copyWith(comment: updateText),
      _ => throw RangeError('${location.colIndex} out of range (0..2)'),
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
      final item = _vocabularyItems.value.removeAt(oldIndex);
      _vocabularyItems.value.insert(newIndex, item);
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
