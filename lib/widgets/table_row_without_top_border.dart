import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/widgets/editable_item_cell.dart';

class TableRowWithoutTopBorder extends StatelessWidget {
  const TableRowWithoutTopBorder({
    super.key,
    required this.rowIndex,
    required this.tableWidth,
  });

  final int rowIndex;
  final double tableWidth;

  @override
  Widget build(BuildContext context) {
    final tableLayoutController = GetIt.I<TableLayoutController>();

    return SignalBuilder(
      builder: (context) {
        final borderWidth = tableLayoutController.borderWidth.value;
        final borderColor = tableLayoutController.borderColor.value;
        final showComment = tableLayoutController.showComment.value;

        // Read appMode to trigger rebuild on mode change
        final appMode = tableLayoutController.appMode.value;

        final w1 = tableWidth * tableLayoutController.col1Ratio.value;
        final w2 = tableWidth * tableLayoutController.col2Ratio.value;
        final w3 = tableWidth * tableLayoutController.col3Ratio.value;

        return Table(
          key: ValueKey(appMode),
          columnWidths: {
            0: FixedColumnWidth(w1),
            1: FixedColumnWidth(w2),
            if (showComment) 2: FixedColumnWidth(w3),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
          border: TableBorder(
            left: BorderSide(color: borderColor, width: borderWidth),
            right: BorderSide(color: borderColor, width: borderWidth),
            bottom: BorderSide(color: borderColor, width: borderWidth),
            verticalInside: BorderSide(color: borderColor, width: borderWidth),
          ),
          children: [
            TableRow(
              children: [
                EditableItemCell(
                  rowIndex: rowIndex,
                  colIndex: 0,
                  draggable: false,
                ),
                EditableItemCell(
                  rowIndex: rowIndex,
                  colIndex: 1,
                  draggable: !showComment,
                ),
                if (showComment)
                  EditableItemCell(
                    rowIndex: rowIndex,
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