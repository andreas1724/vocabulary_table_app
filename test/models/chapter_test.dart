import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_table_app/models/chapter.dart';

void main() {
  group('Chapter Model Tests', () {
    test('create() establishes correct hierarchy and defaults', () {
      const parentBookId = 'book_uuid_999';
      final chapter = Chapter.create(
        bookId: parentBookId,
        name: 'Lesson 1: Greetings',
        order: 10,
      );

      // Validate relationship linkage
      expect(chapter.bookId, parentBookId);
      expect(chapter.name, 'Lesson 1: Greetings');
      expect(chapter.order, 10);
      
      // Validate timestamps
      expect(chapter.createdAt.isUtc, isTrue);
      expect(chapter.deletedAt, isNull);
    });

    test('toJson() properly omits or nullifies deletedAt when active', () {
      final chapter = Chapter.create(
        bookId: 'book_uuid_888',
        name: 'Lesson 2',
      );

      final jsonMap = chapter.toJson();

      // Ensure deletedAt is either null or completely absent
      // Note: adjust this expectation based on whether you used ?? '' or let it be null
      expect(
        jsonMap['deletedAt'] == null || jsonMap['deletedAt'] == '', 
        isTrue,
      );
      expect(jsonMap['bookId'], 'book_uuid_888');
    });

    test('fromJson() gracefully handles missing fields and defaults', () {
      // Simulate an incomplete JSON payload from a legacy or partial sync
      final Map<String, dynamic> partialJson = {
        'id': 'legacy_chapter_1',
        'bookId': 'book_1',
        'name': 'Legacy Chapter',
        // Missing createdAt, updatedAt, order, and deletedAt
      };

      final reconstructed = Chapter.fromJson(partialJson);

      expect(reconstructed.id, 'legacy_chapter_1');
      expect(reconstructed.name, 'Legacy Chapter');
      expect(reconstructed.order, 0); // Must fallback to 0
      
      // Timestamps must fallback to current UTC time
      expect(reconstructed.createdAt.isUtc, isTrue);
      expect(reconstructed.deletedAt, isNull);
    });
  });
}