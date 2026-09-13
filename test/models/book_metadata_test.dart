import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_table_app/models/book.dart';

void main() {
  group('BookMetadata Model Tests', () {
    test('create() generates unique UUID and strictly UTC timestamps', () {
      final metadata = BookMetadata.create(
        title: 'Korean Basics',
        languageA: 'German',
        languageB: 'Korean',
        commentHeader: 'Notes',
      );

      // Verify UUID assignment
      expect(metadata.id, isNotEmpty);
      expect(metadata.id.length, 36);

      // Verify initialization fields
      expect(metadata.title, 'Korean Basics');
      expect(metadata.languageA, 'German');
      expect(metadata.languageB, 'Korean');

      // Ensure all dates strictly enforce UTC timezone
      expect(metadata.createdAt.isUtc, isTrue);
      expect(metadata.updatedAt.isUtc, isTrue);
      expect(metadata.cleanedAt.isUtc, isTrue);
      expect(metadata.deletedAt, isNull);
    });

    test('copyWith() applies partial updates without mutating other fields', () {
      final initial = BookMetadata.create(
        title: 'Old Title',
        languageA: 'EN',
        languageB: 'ES',
        commentHeader: '',
      );

      final updated = initial.copyWith(
        title: 'New Title',
      );

      expect(updated.title, 'New Title');
      expect(updated.id, initial.id);
      expect(updated.languageA, initial.languageA);
      expect(updated.createdAt, initial.createdAt);
    });

    test('toJson() and fromJson() execute a lossless roundtrip for sync', () {
      final original = BookMetadata.create(
        title: 'Sync Test',
        languageA: 'A',
        languageB: 'B',
        commentHeader: 'Header',
      );

      final jsonMap = original.toJson();
      
      // Validate correct stringification of dates
      expect(jsonMap['createdAt'], isA<String>());
      expect((jsonMap['createdAt'] as String).endsWith('Z'), isTrue);

      final reconstructed = BookMetadata.fromJson(jsonMap);

      expect(reconstructed.id, original.id);
      expect(reconstructed.title, original.title);
      expect(reconstructed.createdAt, original.createdAt);
      expect(reconstructed.deletedAt, isNull);
    });
  });
}