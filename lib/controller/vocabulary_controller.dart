import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';
import 'package:vocabulary_table_app/utils/list_signal_extension.dart';

class VocabularyController {
  VocabularyController({required List<VocabularyItem> vocabularyItems})
    : _vocabularyItems = listSignal(
        vocabularyItems.map((item) => signal(item)).toList(),
      );

  final ListSignal<Signal<VocabularyItem>> _vocabularyItems;

  late final vocabularyItems = _vocabularyItems.readonly();

  void addVocabulary(VocabularyItem item) {
    _vocabularyItems.add(signal(item));
  }

  void removeVocabularyAt(int index) {
    if (index < 0 || index >= _vocabularyItems.length) return;

    // 1. Remove reference to trigger ListSignal updates
    final removedSignal = _vocabularyItems.removeAt(index);
    
    // 2. Explicitly dispose the inner signal to prevent memory leaks
    removedSignal.dispose();
  }

  void updateVocabularyAt(int index, VocabularyItem item) {
    if (index < 0 || index >= _vocabularyItems.length) return;

    // Mutate inner value. Does not trigger a list rebuild, 
    // only rebuilds the specific widget reading this signal.
    _vocabularyItems[index].value = item;
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
