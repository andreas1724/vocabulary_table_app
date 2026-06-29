import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

class VocabularyController {
  VocabularyController({required List<VocabularyItem> vocabularyItems})
    : _vocabularyItems = listSignal(vocabularyItems);

  final ListSignal<VocabularyItem> _vocabularyItems;

  late final vocabularyItems = _vocabularyItems.readonly();

  /// oldIndex refers to the item's original position before removal.
  /// newIndex points to the exact target position in the cleaned list after removal.
  void reorderItem(int oldIndex, int newIndex) {
    batch(() {
      final item = _vocabularyItems.value.removeAt(oldIndex);
      _vocabularyItems.value.insert(newIndex, item);
    });
  }

  void dispose() {
    _vocabularyItems.dispose();
  }
}
