import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

void main() {
  group('VocabularyItem Tests', () {
    test('CopyWith updates fields correctly', () {
      final item = VocabularyItem(termA: 'Hello', termB: 'Hallo');
      final updated = item.copyWith(termA: 'Hi');
      
      expect(updated.id, item.id); // ID must remain the same
      expect(updated.termA, 'Hi');
      expect(updated.termB, 'Hallo');
    });

    test('Operator [] accesses correct columns', () {
      final item = VocabularyItem(termA: 'A', termB: 'B', comment: 'C');
      expect(item[ColumnName.termA], 'A');
      expect(item[ColumnName.termB], 'B');
      expect(item[ColumnName.comment], 'C');
    });
  });
}