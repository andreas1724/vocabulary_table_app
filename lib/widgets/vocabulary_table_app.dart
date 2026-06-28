import 'package:flutter/material.dart';
import 'package:vocabulary_table_app/widgets/table_scope.dart';
import 'package:vocabulary_table_app/widgets/vocabulary_table_scaffold.dart';

class VocabularyTableApp extends StatelessWidget {
  const VocabularyTableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return TableScope(child: VocabularyTableScaffold());
  }
}
