import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
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
  });
  final VocabularyItem vocabularyItem;
  final int index;
  final double tableWidth;

  @override
  Widget build(BuildContext context) {
    final controller = GetIt.I<TableLayoutController>();

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
                _SelectableTextCell(
                  text: vocabularyItem.termA,
                  index: index,
                  draggable: false,
                ),
                _SelectableTextCell(
                  index: index,
                  text: vocabularyItem.termB,
                  draggable: !showComment,
                ),
                if (showComment)
                  _SelectableTextCell(
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

class _SelectableTextCell extends StatelessWidget {
  const _SelectableTextCell({
    required this.text,
    required this.index,
    required this.draggable,
  });
  final bool draggable;
  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final controller = GetIt.I<TableLayoutController>();
    return SignalBuilder(
      builder: (context) {
        final isDragMode = controller.appMode.value == .drag;
        final scale = controller.scale.value;
        return VocabularyTableCell(
          index: index,
          draggable: draggable,
          child: SelectableText(
            text,
            minLines: 1,
            maxLines: isDragMode ? 3 : null,
            style: TextStyle(fontSize: TableLayoutController.fontSize * scale),
          ),
        );
      },
    );
  }
}
