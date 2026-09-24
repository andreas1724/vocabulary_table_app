import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vocabulary_table_app/data/controllers/chapter_controller.dart';
import 'package:vocabulary_table_app/data/controllers/vocab_repository.dart';
import 'package:vocabulary_table_app/models/chapter.dart';

// --- Mocks ---
class MockVocabRepository extends Mock implements VocabRepository {}

class FakeChapter extends Fake implements Chapter {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeChapter());
  });

  group('ChapterController Tests', () {
    late MockVocabRepository mockRepository;
    late ChapterController controller;
    late StreamController<List<Chapter>> streamController;
    const bookId = 'test-book';

    setUp(() {
      mockRepository = MockVocabRepository();
      
      // Use a broadcast stream to precisely control the mock DB emissions.
      streamController = StreamController<List<Chapter>>.broadcast();

      final now = DateTime.now().toUtc();
      final initialChapters = [
        Chapter(
          id: 'c1',
          bookId: bookId,
          name: 'Chapter 1',
          order: 0,
          createdAt: now,
          updatedAt: now,
        ),
        Chapter(
          id: 'c2',
          bookId: bookId,
          name: 'Chapter 2',
          order: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      when(() => mockRepository.watchChaptersForBook(bookId))
          .thenAnswer((_) => streamController.stream);
      when(() => mockRepository.addChapterLocally(any()))
          .thenAnswer((_) async {});
      when(() => mockRepository.updateChapterLocally(any()))
          .thenAnswer((_) async {});
      when(() => mockRepository.deleteChapterLocally(any()))
          .thenAnswer((_) async {});
      when(() => mockRepository.updateChaptersLocally(any()))
          .thenAnswer((_) async {});

      controller = ChapterController(
        repository: mockRepository,
        bookId: bookId,
      );

      // Seed initial stream data
      streamController.add(initialChapters);
    });

    tearDown(() {
      controller.dispose();
      streamController.close();
    });

    test('initializes correctly and consumes stream data', () async {
      // Yield to event loop to allow stream signal initialization
      await Future.delayed(Duration.zero);
      
      expect(controller.chapters.value.length, 2);
      expect(controller.chapters.value.first.name, 'Chapter 1');
    });

    test('addChapter applies synchronous optimistic update and calls DB', () async {
      await Future.delayed(Duration.zero); 

      final newChapter = Chapter(
        id: 'c3',
        bookId: bookId,
        name: 'New Chapter',
        order: 99, // Will be overridden by controller logic
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      // Execute without awaiting to intercept the synchronous optimistic state
      final future = controller.addChapter(newChapter);

      // Verify optimistic UI update occurred immediately
      expect(controller.chapters.value.length, 3);
      expect(controller.chapters.value.last.name, 'New Chapter');
      expect(controller.chapters.value.last.order, 2); // Dynamically set to items.length

      await future;

      final captured = verify(
        () => mockRepository.addChapterLocally(captureAny()),
      ).captured;
      final savedChapter = captured.first as Chapter;
      expect(savedChapter.id, 'c3');
      expect(savedChapter.order, 2);
    });

    test('updateChapter applies optimistic update securely', () async {
      await Future.delayed(Duration.zero);

      final updatePayload = Chapter(
        id: 'c1',
        bookId: 'malicious-book-id', // Should be forced back to actual bookId
        name: 'Updated Title',
        order: 0,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      final future = controller.updateChapter(updatePayload);

      // Verify optimistic update
      expect(controller.chapters.value.first.name, 'Updated Title');

      await future;

      final captured = verify(
        () => mockRepository.updateChapterLocally(captureAny()),
      ).captured;
      
      final savedChapter = captured.first as Chapter;
      // Validates structural integrity enforcement in the controller
      expect(savedChapter.bookId, bookId);
    });

    test('deleteChapter applies optimistic deletion', () async {
      await Future.delayed(Duration.zero);

      final chapterToDelete = controller.chapters.value.first;

      final future = controller.deleteChapter(chapterToDelete);

      // Verify synchronous optimistic deletion
      expect(controller.chapters.value.length, 1);
      expect(controller.chapters.value.first.id, 'c2');

      await future;

      verify(
        () => mockRepository.deleteChapterLocally(chapterToDelete),
      ).called(1);
    });

    test('reorderChapter applies optimistic sorting and triggers batch update', () async {
      await Future.delayed(Duration.zero);

      // Move index 0 to index 1
      final future = controller.reorderChapter(0, 1);

      // Verify optimistic UI sorting and auto-reindexing
      final items = controller.chapters.value;
      expect(items.first.id, 'c2');
      expect(items.first.order, 0);
      
      expect(items.last.id, 'c1');
      expect(items.last.order, 1);

      await future;

      final captured = verify(
        () => mockRepository.updateChaptersLocally(captureAny()),
      ).captured;
      
      final batchedItems = captured.first as List<Chapter>;
      expect(batchedItems.length, 2);
    });

    test('reorderChapter ignores invalid bounds', () async {
      await Future.delayed(Duration.zero);

      await controller.reorderChapter(-1, 0);
      await controller.reorderChapter(0, 99);
      await controller.reorderChapter(0, 0); // Same index

      // State should remain unchanged
      expect(controller.chapters.value.first.id, 'c1');
      verifyNever(() => mockRepository.updateChaptersLocally(any()));
    });
  });
}