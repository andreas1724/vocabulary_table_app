import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_core.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/widgets/header_row.dart';

class VocabularyTable extends StatefulWidget {
  const VocabularyTable({
    super.key,
    required this.vocabularyController,
    required this.tableLayoutController,
  });

  final VocabularyController vocabularyController;
  final TableLayoutController tableLayoutController;

  @override
  State<VocabularyTable> createState() => _VocabularyTableState();
}

class _VocabularyTableState extends State<VocabularyTable> {
  @override
  void initState() {
    super.initState();
    GetIt.I.pushNewScope(scopeName: 'InsideTableScope');

    GetIt.I.registerSingleton(widget.vocabularyController);

    GetIt.I.registerSingleton(widget.tableLayoutController);
  }

  @override
  void dispose() {
    GetIt.I.popScope();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            widget.tableLayoutController.tableWidth.value = constraints.maxWidth;
            return HeaderRow(controller: widget.tableLayoutController);
          },
        ),
        Expanded(
          child: ReorderableListView.builder(
            itemBuilder: (context, index) {
              final item = widget.vocabularyController.vocabularyItems.value[index];
              return Text(key: ValueKey(item.id), item.termA);
            },
            onReorderItem: widget.vocabularyController.reorderItem,
            itemCount: widget.vocabularyController.vocabularyItems.length,
          ),
        ),
      ],
    );
  }
}
