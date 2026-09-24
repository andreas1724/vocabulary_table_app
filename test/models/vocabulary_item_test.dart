import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

void main() {
  group('VocabularyItem Model Tests', () {
    test('create() generates unique UUID and proper UTC timestamps', () {
      final item = VocabularyItem.create(
        bookId: 'book_uuid_123',
        chapterId: 'chapter_uuid_123',
        termA: 'Violine',
        termB: '바이올린',
        comment: 'Nomen',
      );

      // Verify UUID generation format
      expect(item.id, isNotEmpty);
      expect(item.id.length, 36);

      // Verify relationship and assignments
      expect(item.bookId, 'book_uuid_123');
      expect(item.chapterId, 'chapter_uuid_123');
      expect(item.termA, 'Violine');
      expect(item.termB, '바이올린');
      expect(item.comment, 'Nomen');

      // Ensure creation time is strictly UTC
      expect(item.createdAt.isUtc, isTrue);
      expect(item.updatedAt.isUtc, isTrue);
      expect(item.deletedAt, isNull);
    });

    test('copyWith() updates fields while keeping immutable data intact', () {
      final initialItem = VocabularyItem.create(
        bookId: 'book_uuid_123',
        chapterId: 'chapter_1',
        termA: 'Apfel',
        termB: 'Apple',
      );

      final newTimestamp = DateTime.now().toUtc();
      final updatedItem = initialItem.copyWith(
        termB: '사과',
        updatedAt: newTimestamp,
      );

      // Verify targeted changes
      expect(updatedItem.termB, '사과');
      expect(updatedItem.updatedAt, newTimestamp);

      // Verify immutability of other fields
      expect(updatedItem.id, initialItem.id);
      expect(updatedItem.bookId, initialItem.bookId);
      expect(updatedItem.chapterId, initialItem.chapterId);
      expect(updatedItem.termA, initialItem.termA);
      expect(updatedItem.createdAt, initialItem.createdAt);
    });

    test(
      'toJson() and fromJson() perform a lossless roundtrip for Drive Sync',
      () {
        final originalItem = VocabularyItem.create(
          bookId: 'book_uuid_456',
          chapterId: 'chapter_456',
          termA: 'Orchester',
          termB: '오케스트라',
          order: 5,
        );

        final Map<String, dynamic> jsonMap = originalItem.toJson();

        // Verify JSON structure contains newly added timestamps
        expect(jsonMap.containsKey('createdAt'), isTrue);
        expect(jsonMap.containsKey('updatedAt'), isTrue);
        expect(jsonMap['chapterId'], 'chapter_456');
        expect(jsonMap['bookId'], 'book_uuid_456');

        final reconstructedItem = VocabularyItem.fromJson(jsonMap);

        // Ensure the reconstructed object matches exactly
        expect(reconstructedItem.id, originalItem.id);
        expect(reconstructedItem.bookId, originalItem.bookId);
        expect(reconstructedItem.chapterId, originalItem.chapterId);
        expect(reconstructedItem.termA, originalItem.termA);
        expect(reconstructedItem.termB, originalItem.termB);
        expect(reconstructedItem.order, originalItem.order);

        // Verify timestamps maintain precise sync data after roundtrip
        expect(reconstructedItem.createdAt, originalItem.createdAt);
        expect(reconstructedItem.updatedAt, originalItem.updatedAt);
      },
    );
  });
}
