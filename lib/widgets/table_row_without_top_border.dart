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
                _DynamicCell(
                  itemId: vocabularyItem.id,
                  text: vocabularyItem.termA,
                  rowIndex: index,
                  colIndex: 0,
                  draggable: false,
                ),
                _DynamicCell(
                  itemId: vocabularyItem.id,
                  text: vocabularyItem.termB,
                  rowIndex: index,
                  colIndex: 1,
                  draggable: !showComment,
                ),
                if (showComment)
                  _DynamicCell(
                    itemId: vocabularyItem.id,
                    text: vocabularyItem.comment,
                    rowIndex: index,
                    colIndex: 2,
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

class _DynamicCell extends StatelessWidget {
  const _DynamicCell({
    required this.itemId,
    required this.text,
    required this.rowIndex,
    required this.colIndex,
    required this.draggable,
  });

  final String itemId;
  final String text;
  final int rowIndex;
  final int colIndex;
  final bool draggable;

  @override
  Widget build(BuildContext context) {
    final controller = GetIt.I<TableLayoutController>();

    // Isolated reactivity: Only the specific cell redraws on mode changes
    return SignalBuilder(
      builder: (context) {
        return switch (controller.appMode.value) {
          .view => _SelectableTextCell(
              text: text,
              rowIndex: rowIndex,
              draggable: draggable,
            ),
          // .edit => _EditableTextCell(
          //     itemId: itemId,
          //     initialText: text,
          //     colIndex: colIndex,
          //     draggable: draggable,
          //   ),
          _ => _PlainTextCell(
              text: text,
              rowIndex: rowIndex,
              draggable: draggable,
            ),
        };
      },
    );
  }
}

class _SelectableTextCell extends StatelessWidget {
  const _SelectableTextCell({
    required this.text,
    required this.rowIndex,
    required this.draggable,
  });
  final bool draggable;
  final int rowIndex;
  final String text;

  @override
  Widget build(BuildContext context) {
    final controller = GetIt.I<TableLayoutController>();
    return SignalBuilder(
      builder: (context) {
        final isDragMode = controller.appMode.value == .drag;
        final scale = controller.scale.value;
        return VocabularyTableCell(
          index: rowIndex,
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

class _PlainTextCell extends StatelessWidget {
  const _PlainTextCell({
    required this.text,
    required this.rowIndex,
    required this.draggable,
  });
  final bool draggable;
  final int rowIndex;
  final String text;

  @override
  Widget build(BuildContext context) {
    final controller = GetIt.I<TableLayoutController>();
    return SignalBuilder(
      builder: (context) {
        final isDragMode = controller.appMode.value == .drag;
        final scale = controller.scale.value;
        return VocabularyTableCell(
          index: rowIndex,
          draggable: draggable,
          child: Text(
            text,
            maxLines: isDragMode ? 3 : null,
            style: TextStyle(fontSize: TableLayoutController.fontSize * scale),
          ),
        );
      },
    );
  }
}
