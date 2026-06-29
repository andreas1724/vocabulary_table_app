import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/orientation_controller.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';
import 'package:vocabulary_table_app/widgets/universal_toolbar.dart';
import 'package:vocabulary_table_app/widgets/vocabulary_table.dart';

class VocabularyTableScaffold extends StatefulWidget {
  const VocabularyTableScaffold({super.key});

  @override
  State<VocabularyTableScaffold> createState() =>
      _VocabularyTableScaffoldState();
}

class _VocabularyTableScaffoldState extends State<VocabularyTableScaffold> {
  final _vocabularyController = VocabularyController(
    vocabularyItems: _vocabularies,
  );

  @override
  void dispose() {
    _vocabularyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientationController = GetIt.I<OrientationController>();
    final tableLayoutController = GetIt.I<TableLayoutController>();

    return Scaffold(
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final isLandscape = orientationController.isLandscape.value;

            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: Flex(
                direction: isLandscape ? .horizontal : .vertical,
                children: [
                  UniversalToolbar(isVertical: isLandscape),
                  Expanded(
                    child: VocabularyTable(
                      vocabularyController: _vocabularyController,
                      tableLayoutController: tableLayoutController,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
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
