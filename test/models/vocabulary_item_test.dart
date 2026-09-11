import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

void main() {
  group('VocabularyItem Tests', () {
    test('CopyWith updates fields correctly', () {
      final item = VocabularyItem.create(bookId: "test", chapter: 'chapter 1', termA: 'Hello', termB: 'Hallo');
      final updated = item.copyWith(termA: 'Hi');
      
      expect(updated.id, item.id); // ID must remain the same
      expect(updated.termA, 'Hi');
      expect(updated.termB, 'Hallo');
    });
  });
}