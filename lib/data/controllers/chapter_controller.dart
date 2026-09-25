// ignore_for_file: prefer_initializing_formals

import 'package:signals_flutter/signals_flutter.dart';

import 'package:vocabulary_table_app/data/controllers/vocab_repository.dart';
import 'package:vocabulary_table_app/models/chapter.dart';

class ChapterController {
  ChapterController({
    required VocabRepository repository,
    required this.bookId,
  }) : _repository = repository {
    _chaptersStream = streamSignal(
      () => _repository.watchChaptersForBook(bookId),
      options: const AsyncSignalOptions(initialValue: []),
    );

    // Reverts optimistic state once the DB stream emits the real data
    effect(() {
      final state = _chaptersStream.value;
      if (state.hasValue && _optimisticChapters.peek() != null) {
        Future.microtask(() => _optimisticChapters.value = null);
      }
    });
  }

  final VocabRepository _repository;
  final String bookId;

  // --- State (Signals) ---

  final Signal<List<Chapter>?> _optimisticChapters = signal(null);

  late final StreamSignal<List<Chapter>> _chaptersStream;

  late final chapters = computed<List<Chapter>>(() {
    final optimistic = _optimisticChapters.value;
    if (optimistic != null) {
      return optimistic;
    }

    return _chaptersStream.value.value ?? [];
  });

  // --- Actions ---

  Future<void> addChapter(Chapter chapter) async {
    final current = chapters.peek().toList();
    final newOrder = current.length;
    
    final chapterToSave = chapter.copyWith(bookId: bookId, order: newOrder);
    
    // Apply optimistic update
    _optimisticChapters.value = [...current, chapterToSave];
    
    await _repository.addChapterLocally(chapterToSave);
  }

  Future<void> updateChapter(Chapter chapter) async {
    final current = chapters.peek().toList();
    final index = current.indexWhere((c) => c.id == chapter.id);
    if (index == -1) return;

    final existing = current[index];
    final updatedChapter = chapter.copyWith(
      id: existing.id, 
      bookId: bookId,
    );

    // Apply optimistic update
    current[index] = updatedChapter;
    _optimisticChapters.value = current;

    await _repository.updateChapterLocally(updatedChapter);
  }

  Future<void> deleteChapter(Chapter chapter) async {
    final current = chapters.peek().toList();
    
    // Optimistically remove the chapter
    current.removeWhere((c) => c.id == chapter.id);
    _optimisticChapters.value = current;

    // The repository method handles the cascade soft-deletion of associated vocabularies.
    await _repository.deleteChapterLocally(chapter);
  }

  Future<void> reorderChapter(int oldIndex, int newIndex) async {
    final currentItems = chapters.peek().toList();

    if (oldIndex == newIndex || 
        oldIndex < 0 || 
        oldIndex >= currentItems.length || 
        newIndex < 0 || 
        newIndex > currentItems.length) {
      return;
    }

    final item = currentItems.removeAt(oldIndex);
    currentItems.insert(newIndex, item);

    final updatedItems = <Chapter>[];
    
    for (final (index, currentChapter) in currentItems.indexed) {
      if (currentChapter.order != index) {
        final updated = currentChapter.copyWith(order: index);
        currentItems[index] = updated; 
        updatedItems.add(updated);
      }
    }

    // Set optimistic state for smooth Drag & Drop UI
    _optimisticChapters.value = currentItems;

    if (updatedItems.isNotEmpty) {
      // NOTE: Ensure your VocabRepository and LocalStorageService have a 
      // batch update method for chapters (e.g., `updateChaptersLocally`) 
      // similar to `updateVocabulariesLocally` to handle this efficiently.
      await _repository.updateChaptersLocally(updatedItems);
    }
  }

  void dispose() {
    _chaptersStream.dispose();
  }
}