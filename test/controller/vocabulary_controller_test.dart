import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

void main() {
  group('VocabularyController Tests', () {
    late VocabularyController controller;

    setUp(() {
      controller = VocabularyController(
        vocabularyItems: [
          VocabularyItem(id: '1', termA: 'One', termB: 'Eins'),
          VocabularyItem(id: '2', termA: 'Two', termB: 'Zwei'),
        ],
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('Reorder item updates list securely', () {
      controller.reorderItem(0, 1);
      final items = controller.vocabularyItems.peek();
      
      expect(items[0].peek().id, '2');
      expect(items[1].peek().id, '1');
    });

    test('Update vocabulary at location modifies correct signal', () {
      controller.updateVocabularyAtLocation(
        (rowIndex: 0, column: ColumnName.termA),
        'Uno',
      );
      
      final updatedItem = controller.vocabularyItems.peek()[0].peek();
      expect(updatedItem.termA, 'Uno');
      expect(updatedItem.termB, 'Eins'); // Unchanged
    });
  });
}