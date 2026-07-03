import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';
import 'package:vocabulary_table_app/widgets/vocabulary_table_app.dart';

void main(List<String> args) {
  SignalsObserver.instance = null;
  
  WidgetsFlutterBinding.ensureInitialized();
  
  setUpDependencies();

  runApp(
    const MaterialApp(
      home: VocabularyTableApp(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

void setUpDependencies() {
  GetIt.I.registerLazySingleton(
    () => VocabularyController(vocabularyItems: _vocabularies),
  );
}

final _vocabularies = [
  VocabularyItem(termA: 'Apple', termB: 'Apfel', comment: 'lecker'),
  VocabularyItem(termA: 'House', termB: 'Haus'),
  VocabularyItem(termA: 'Car', termB: 'Auto', comment: 'schnell'),
  VocabularyItem(termA: 'Tree', termB: 'Baum'),
  VocabularyItem(
    termA: 'This is probably a multiline text.',
    termB: 'Dies ist wahrscheinlich ein mehrzeiliger Text.',
  ),
  VocabularyItem(termA: 'Apple2', termB: 'Apfel2'),
  VocabularyItem(termA: 'House2', termB: 'Haus2', comment: 'gemütlich'),
  VocabularyItem(termA: 'Car2', termB: 'Auto2', comment: 'kaputt'),
  VocabularyItem(termA: 'Tree2', termB: 'Baum2', comment: 'groß'),
];
