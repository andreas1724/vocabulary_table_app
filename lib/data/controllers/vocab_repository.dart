import 'package:signals_flutter/signals_flutter.dart';

import 'package:vocabulary_table_app/data/services/csv_parser_service.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

/// Controller responsible for managing vocabulary state and operations
class VocabRepository {
  VocabRepository(this._parserService);

  final CsvParserService _parserService;

  // --- State (Signals) ---

  /// Holds the state of our vocabularies (loading, error, or data)
  final vocabularyItems = asyncSignal<List<VocabularyItem>>(
    AsyncState.data([]),
  );

  /// Holds the name of Language A (extracted from CSV header)
  final languageA = signal<String>('Language A');

  /// Holds the name of Language B (extracted from CSV header)
  final languageB = signal<String>('Language B');

  // --- Computed Values ---

  /// Returns a list of all unique chapters available in the vocabulary list,
  /// preserving the order in which they appear in the CSV.
  late final chapters = computed(() {
    final state = vocabularyItems.value;
    if (state is! AsyncData<List<VocabularyItem>>) return <String>[];

    final temp = <String>{};
    return state.value.map((v) => v.chapter).where((v) => temp.add(v)).toList();
  });

  // --- Actions / Methods ---

  /// Loads vocabularies from a CSV string
  Future<void> loadFromCsvString(
    String csvContent, {
    String? defaultChapter,
  }) async {
    vocabularyItems.value = AsyncState.loading();

    try {
      // Simulate slight delay if needed, or just parse directly.
      // Parsing is synchronous, but we make the method async for future Drive API integration
      final parsedResult = _parserService.parseCsv(
        csvContent,
        defaultChapter: defaultChapter ?? 'Unknown Chapter',
      );

      languageA.value = parsedResult.languageA;
      languageB.value = parsedResult.languageB;
      vocabularyItems.value = AsyncState.data(parsedResult.vocabularyItems);
    } catch (e, st) {
      vocabularyItems.value = AsyncState.error(e, st);
    }
  }

  /// Adds a single new vocabulary item
  void addVocabularyItem(VocabularyItem vocabularyItem) {
    final currentState = vocabularyItems.value;

    // Only allow adding if we currently have successfully loaded data
    if (currentState is AsyncData<List<VocabularyItem>>) {
      final updatedList = List<VocabularyItem>.from(currentState.value)
        ..add(vocabularyItem);
      vocabularyItems.value = AsyncState.data(updatedList);
    } else {
      // Depending on app requirements, you might want to throw an exception here
      // throw StateError('Cannot add vocabulary while data is loading or in error state.');
    }
  }

  /// Clears all data
  void clear() {
    vocabularyItems.value = AsyncState.data([]);
  }
}
