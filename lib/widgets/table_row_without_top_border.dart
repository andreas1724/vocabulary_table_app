import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';
import 'package:vocabulary_table_app/widgets/vocabulary_table_cell.dart';

class TableRowWithoutTopBorder extends StatelessWidget {
  const TableRowWithoutTopBorder({
    super.key,
    required this.vocabularyItem,
    required this.index,
    required this.tableWidth,
    required this.controller,
  });
  final VocabularyItem vocabularyItem;
  final int index;
  final double tableWidth;
  final TableLayoutController controller;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final borderWidth = controller.borderWidth.value;
        final borderColor = controller.borderColor.value;
        final showComment = controller.showComment.value;

        final w1 = tableWidth * controller.col1Ratio.value;
        final w2 = tableWidth * controller.col2Ratio.value;
        final w3 = tableWidth * controller.col3Ratio.value;

        return Table(
          columnWidths: {
            0: FixedColumnWidth(w1),
            1: FixedColumnWidth(w2),
            if (showComment) 2: FixedColumnWidth(w3),
          },
          defaultVerticalAlignment: .intrinsicHeight,
          border: TableBorder(
            left: BorderSide(color: borderColor, width: borderWidth),
            right: BorderSide(color: borderColor, width: borderWidth),
            bottom: BorderSide(color: borderColor, width: borderWidth),
            verticalInside: BorderSide(color: borderColor, width: borderWidth),
          ),
          children: [
            TableRow(
              children: [
                VocabularyTableCell(
                  controller: controller,
                  text: vocabularyItem.termA,
                  index: index,
                ),
                VocabularyTableCell(
                  controller: controller,
                  text: vocabularyItem.termB,
                  index: index,
                  draggable: showComment ? false : true,
                ),
                if (showComment)
                  VocabularyTableCell(
                    controller: controller,
                    text: vocabularyItem.comment,
                    index: index,
                    draggable: true,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
