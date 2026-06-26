import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/widgets/vocabulary_table_app.dart';

void main(List<String> args) {
  SignalsObserver.instance = null;
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const MaterialApp(
      home: VocabularyTableApp(),
      debugShowCheckedModeBanner: false,
    ),
  );
}