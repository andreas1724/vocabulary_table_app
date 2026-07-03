import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/widgets/header_row.dart';
import 'package:vocabulary_table_app/widgets/table_body.dart';

class VocabularyTable extends StatelessWidget {
  const VocabularyTable({super.key});

  @override
  Widget build(BuildContext context) {
    // Resolve dependencies within the build context.
    // This allows the widget to have a const constructor.
    final vocabularyController = GetIt.I<VocabularyController>();
    final tableLayoutController = GetIt.I<TableLayoutController>();

    return GestureDetector(
      behavior: .opaque,
      onScaleStart: (details) => tableLayoutController.scaleStart(),
      onScaleUpdate: (details) =>
          tableLayoutController.scaleUpdate(details.scale),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth;
          return Column(
            children: [
              HeaderRow(
                controller: tableLayoutController,
                tableWidth: tableWidth,
              ),
              Expanded(
                child: TableBody(
                  vocabularyController: vocabularyController,
                  tableLayoutController: tableLayoutController,
                  tableWidth: tableWidth,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}