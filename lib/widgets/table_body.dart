import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';

class TableBody extends StatefulWidget {
  const TableBody({
    super.key,
    required this.vocabularyController,
    required this.tableLayoutController,
    required this.tableWidth,
  });

  final VocabularyController vocabularyController;
  final TableLayoutController tableLayoutController;
  final double tableWidth;

  @override
  State<TableBody> createState() => _TableBodyState();
}

class _TableBodyState extends State<TableBody> {
  bool _isDragging = false;

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
    return SignalBuilder(
      builder: (context) {
        final vocabularyItems =
            widget.vocabularyController.vocabularyItems.value;
        final borderWidth = widget.tableLayoutController.borderWidth.value;
        final borderColor = widget.tableLayoutController.borderColor.value;

        return ReorderableListView.builder(
          buildDefaultDragHandles: false,
          itemCount: vocabularyItems.length,
          onReorderStart: (index) => setState(() => _isDragging = true),
          onReorderEnd: (index) => setState(() => _isDragging = false),
          onReorderItem: (int oldIndex, int newIndex) =>
              widget.vocabularyController.reorderItem(oldIndex, newIndex),
          proxyDecorator: _proxyDecorator,

          itemBuilder: (context, index) {
            final vocabularyItem = vocabularyItems[index];

            return Stack(
              key: ValueKey(vocabularyItem.id),

              // Allows drawing the top line outside the box
              clipBehavior: .none,
              children: [
                // 1. The actual row as an optimized single-row table
                _TableRowWithoutTopBorder(
                  vocabularyItem,
                  index,
                  widget.tableWidth,
                ),
                // 2. The "border-collapse" line, which lies exactly on the bottom border
                // of the previous row or closes the gap below.
                if (_isDragging)
                  Positioned(
                    top: -borderWidth,
                    left: 0,
                    right: 0,
                    height: borderWidth,
                    child: Container(color: borderColor),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
  final tableLayoutController = GetIt.I<TableLayoutController>();

  return SignalBuilder(
    builder: (context) {
      final scale = tableLayoutController.scale.value;
      final borderWidth = tableLayoutController.borderWidth.value;
      final borderColor = tableLayoutController.borderColor.value;
      return Material(
        elevation: 6 * scale,
        color: Colors.blue[50],
        child: Stack(
          clipBehavior: .none,
          children: [
            child,
            Positioned(
              top: -borderWidth,
              left: 0,
              right: 0,
              height: borderWidth,
              child: Container(color: borderColor),
            ),
          ],
        ),
      );
    },
  );
}

class _TableRowWithoutTopBorder extends StatelessWidget {
  _TableRowWithoutTopBorder(this.vocabularyItem, this.index, this.tableWidth);
  final VocabularyItem vocabularyItem;
  final int index;
  final double tableWidth;
  final tableLayoutController = GetIt.I<TableLayoutController>();

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final borderWidth = tableLayoutController.borderWidth.value;
        final borderColor = tableLayoutController.borderColor.value;
        final showComment = tableLayoutController.showComment.value;

        final w1 = tableWidth * tableLayoutController.col1Ratio.value;
        final w2 = tableWidth * tableLayoutController.col2Ratio.value;
        final w3 = tableWidth * tableLayoutController.col3Ratio.value;

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
                _VocabularyTableCell(text: vocabularyItem.termA),
                _VocabularyTableCell(
                  text: vocabularyItem.termB,
                  index: showComment ? null : index,
                ),
                if (showComment)
                  _VocabularyTableCell(
                    text: vocabularyItem.comment,
                    index: index,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Only cells, who could have a drag handle, should have an index.
class _VocabularyTableCell extends StatelessWidget {
  _VocabularyTableCell({required this.text, this.index});

  final tableLayoutController = GetIt.I<TableLayoutController>();
  final String text;
  final int? index;

  @override
  Widget build(BuildContext context) {
    const padding = 6.0;
    const dragHandleSize = 18.0;
    final dragHandleColor = Colors.grey[700];

    return SignalBuilder(
      builder: (context) {
        final scale = tableLayoutController.scale.value;
        final isDragMode = tableLayoutController.appMode.value == .drag;
        return Padding(
          padding: EdgeInsets.all(scale * padding),
          child: Row(
            crossAxisAlignment: .start,
            children: [
              Expanded(
                child: SelectableText(
                  text,
                  minLines: 1,
                  maxLines: isDragMode ? 3 : null,
                  style: TextStyle(
                    fontSize: TableLayoutController.fontSize * scale,
                  ),
                ),
              ),
              if (isDragMode && index != null)
                ReorderableDragStartListener(
                  index: index!,
                  child: Center(
                    child: Icon(
                      Icons.drag_handle,
                      size: dragHandleSize * scale,
                      color: dragHandleColor,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
