// ignore_for_file: prefer_initializing_formals

import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/data/controllers/vocab_repository.dart';
import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

class VocabularyController {
  VocabularyController({
    required VocabRepository repository,
    required Book book,
  })  : _repository = repository,
        bookId = book.metadata.id,
        metadata = signal<BookMetadata>(book.metadata) {
    // Initialize the stream signal from the repository
    _vocabularyItemsStream = streamSignal(
      () => _repository.watchVocabulariesForBook(bookId),
      options: AsyncSignalOptions(initialValue: book.items),
    );

    // Watch for updates from the database. When the real data catches up with our
    // optimistic update, we clear the optimistic state to resume reacting to DB changes.
    effect(() {
      final state = _vocabularyItemsStream.value;
      if (state.hasValue && _optimisticItems.peek() != null) {
        // Run asynchronously (microtask) to ensure UI immediately switches back to DB stream
        // without flickering when DB resolves.
        Future.microtask(() => _optimisticItems.value = null);
      }
    });
  }

  final VocabRepository _repository;
  final String bookId;

  // --- State (Signals) ---

  final Signal<BookMetadata> metadata;
  
  // Placed variables after constructor to strictly follow sort_constructors_first
  final Signal<(int rowIndex, int colIndex)?> selectedCell = signal(null);
  
  // Holds synchronous updates to bridge the DB writing gap
  final Signal<List<VocabularyItem>?> _optimisticItems = signal(null);

  late final StreamSignal<List<VocabularyItem>> _vocabularyItemsStream;

  late final languageA = computed(() => metadata.value.languageA);
  late final languageB = computed(() => metadata.value.languageB);
  late final commentHeader = computed(() => metadata.value.commentHeader);
  late final title = computed(() => metadata.value.title);

  // Expose the list of vocabulary items reactively
  // Shows optimistic update if present, otherwise reads from stream
  late final vocabularyItems = computed<List<VocabularyItem>>(() {
    final optimistic = _optimisticItems.value;
    if (optimistic != null) {
      return optimistic;
    }

    return _vocabularyItemsStream.value.value ?? [];
  });

  // Optimized chapter extraction using Dart 3 Set conversion
  late final chapters = computed(() {
    return vocabularyItems.value.map((item) => item.chapterId).toSet().toList();
  });

  // --- Actions ---

  Future<void> addVocabulary(VocabularyItem item) async {
    // Read state without subscribing via peek()
    final items = vocabularyItems.peek().toList();
    final newOrder = items.length;
    
    final itemToSave = item.copyWith(bookId: bookId, order: newOrder);
    
    // Apply optimistic update for instantaneous UI feedback
    _optimisticItems.value = [...items, itemToSave];
    
    await _repository.addVocabularyLocally(itemToSave);
  }

  Future<void> removeVocabularyAt(int index) async {
    final items = vocabularyItems.peek().toList();
    if (index < 0 || index >= items.length) return;

    final itemToDelete = items.removeAt(index);
    
    // Apply optimistic update
    _optimisticItems.value = items;
    
    await _repository.deleteVocabularyLocally(itemToDelete);
  }

  Future<void> updateVocabularyAt(int index, VocabularyItem item) async {
    final items = vocabularyItems.peek().toList();
    if (index < 0 || index >= items.length) return;

    final existingItem = items[index];
    final itemToUpdate = item.copyWith(id: existingItem.id, bookId: bookId);

    // Apply optimistic update
    items[index] = itemToUpdate;
    _optimisticItems.value = items;

    await _repository.updateVocabularyLocally(itemToUpdate);
  }

  Future<void> updateVocabularyAtLocation(
    ({int rowIndex, int colIndex}) location,
    String updateText,
  ) async {
    final items = vocabularyItems.peek().toList();
    if (location.rowIndex < 0 || location.rowIndex >= items.length) {
      return;
    }

    final vocabularyItem = items[location.rowIndex];
    
    final updatedItem = switch (location.colIndex) {
      0 => vocabularyItem.copyWith(termA: updateText),
      1 => vocabularyItem.copyWith(termB: updateText),
      2 => vocabularyItem.copyWith(comment: updateText),
      3 => vocabularyItem.copyWith(chapterId: updateText),
      // Crucial security fix: Never manipulate the ID via UI cell editing.
      _ => null, 
    };

    if (updatedItem == null || updatedItem == vocabularyItem) return;

    // Apply optimistic update
    items[location.rowIndex] = updatedItem;
    _optimisticItems.value = items;

    await _repository.updateVocabularyLocally(updatedItem);
  }

  /// oldIndex refers to the item's original position before removal.
  /// newIndex points to the exact target position in the cleaned list after removal.
  Future<void> reorderItem(int oldIndex, int newIndex) async {
    final items = vocabularyItems.peek().toList();

    if (oldIndex == newIndex) return;

    if (oldIndex < 0 ||
        oldIndex >= items.length ||
        newIndex < 0 ||
        newIndex > items.length) {
      return;
    }

    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    final updatedItems = <VocabularyItem>[];
    
    // Use Dart 3 indexed iteration for cleaner access
    for (final (index, currentItem) in items.indexed) {
      if (currentItem.order != index) {
        final updated = currentItem.copyWith(order: index);
        items[index] = updated; // Keep the optimistic list in perfect sync
        updatedItems.add(updated);
      }
    }

    // Set optimistic state so the UI animation is perfectly smooth
    _optimisticItems.value = items;

    if (updatedItems.isNotEmpty) {
      await _repository.updateVocabulariesLocally(updatedItems);
    }
  }

  void dispose() {
    _vocabularyItemsStream.dispose();
  }
}