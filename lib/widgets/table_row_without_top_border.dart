import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';
import 'package:vocabulary_table_app/widgets/vocabulary_table_cell.dart';

const _heightFactor = 1.2;
const _letterSpacing = 0.0;

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

        final w1 = tableWidth * tableLayoutController.col1Ratio.value;
        final w2 = tableWidth * tableLayoutController.col2Ratio.value;
        final w3 = tableWidth * tableLayoutController.col3Ratio.value;

        return Table(
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
                _EditableItemCell(
                  rowIndex: rowIndex,
                  colIndex: 0,
                  draggable: false,
                ),
                _EditableItemCell(
                  rowIndex: rowIndex,
                  colIndex: 1,
                  draggable: !showComment,
                ),
                if (showComment)
                  _EditableItemCell(
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

class _EditableItemCell extends StatefulWidget {
  const _EditableItemCell({
    required this.rowIndex,
    required this.colIndex,
    required this.draggable,
  });

  final int colIndex;
  final int rowIndex;
  final bool draggable;

  @override
  State<_EditableItemCell> createState() => _EditableItemCellState();
}

class _EditableItemCellState extends State<_EditableItemCell> {
  late final VocabularyController _vocabularyController;
  late final FocusNode _editableTextFocus;
  late final FocusNode _plainTextFocus;

  String _previousText = '';

  // Getters to always use the most current widget.rowIndex
  (int, int) get _currentLocation => (widget.rowIndex, widget.colIndex);
  
  String get _currentCacheKey {
    final item = _vocabularyController.vocabularyItems.peek()[widget.rowIndex].peek();
    return '${item.id}_${widget.colIndex}';
  }

  @override
  void initState() {
    super.initState();
    _vocabularyController = GetIt.I<VocabularyController>();

    _plainTextFocus = FocusNode()..addListener(_plainTextFocusChanged);

    _editableTextFocus = FocusNode(
      onKeyEvent: (node, event) {
        if (event.logicalKey == .escape) {
          final cachedController = _vocabularyController.getControllerFor(
            _currentCacheKey,
            _previousText,
          );
          cachedController.text = _previousText;

          _vocabularyController.updateVocabularyAtIndexColumn(
            widget.rowIndex,
            widget.colIndex,
            _previousText,
          );
          _editableTextFocus.unfocus();
          return .handled;
        }
        return .ignored;
      },
    )..addListener(_editableTextFocusChanged);
  }

  void _plainTextFocusChanged() {
    if (_plainTextFocus.hasFocus) {
      _startEditing();
    }
  }

  void _editableTextFocusChanged() {
    if (!_editableTextFocus.hasFocus) {
      debugPrint('edit finished');

      final cachedController = _vocabularyController.getControllerFor(
        _currentCacheKey,
        _previousText,
      );

      _vocabularyController.updateVocabularyAtIndexColumn(
        widget.rowIndex,
        widget.colIndex,
        cachedController.text,
      );

      if (_vocabularyController.selectedCell.peek() == _currentLocation) {
        _vocabularyController.selectedCell.value = null;
      }
    }
  }

  void _startEditing() {
    _previousText = _vocabularyController.vocabularyItems[widget.rowIndex]
        .peek()
        .at(widget.colIndex);

    final cachedController = _vocabularyController.getControllerFor(
      _currentCacheKey,
      _previousText,
    );
    cachedController.text = _previousText;

    _vocabularyController.selectedCell.value = _currentLocation;

    _editableTextFocus.unfocus();
    _editableTextFocus.requestFocus();
  }

  @override
  void dispose() {
    _editableTextFocus.removeListener(_editableTextFocusChanged);
    _plainTextFocus.removeListener(_plainTextFocusChanged);
    _editableTextFocus.dispose();
    _plainTextFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tableLayoutController = GetIt.I<TableLayoutController>();

    return SignalBuilder(
      builder: (context) {
        final item = _vocabularyController.vocabularyItems.value[widget.rowIndex];
        final text = item.value.at(widget.colIndex);
        final itemId = item.value.id;
        
        // Evaluate selection state directly during build to guarantee fresh row indices
        final isSelected = _vocabularyController.selectedCell.value == _currentLocation;
        final appMode = tableLayoutController.appMode.value;

        if (isSelected && appMode == .edit) {
          return _EditableTextCell(
            itemId: itemId,
            initialText: text,
            rowIndex: widget.rowIndex,
            colIndex: widget.colIndex,
            draggable: widget.draggable,
            focusNode: _editableTextFocus,
          );
        } else {
          return InkWell(
            focusNode: _plainTextFocus,
            onTap: () {
              if (!_plainTextFocus.hasFocus && !_editableTextFocus.hasFocus) {
                FocusManager.instance.primaryFocus?.unfocus();
              }
            },
            onDoubleTap: _startEditing,
            child: _PlainTextCell(
              text: text,
              rowIndex: widget.rowIndex,
              draggable: widget.draggable,
            ),
          );
        }
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

  final int rowIndex;
  final bool draggable;
  final String text;

  @override
  Widget build(BuildContext context) {
    final controller = GetIt.I<TableLayoutController>();
    return SignalBuilder(
      builder: (context) {
        final isDragMode = controller.appMode.value == AppMode.drag;
        final scale = controller.scale.value;
        return VocabularyTableCell(
          rowIndex: rowIndex,
          draggable: draggable,
          child: Text(
            text,
            maxLines: isDragMode ? 3 : null,
            style: TextStyle(
              fontSize: TableLayoutController.fontSize * scale,
              height: _heightFactor,
              letterSpacing: _letterSpacing,
            ),
          ),
        );
      },
    );
  }
}

class _EditableTextCell extends StatelessWidget {
  const _EditableTextCell({
    required this.itemId,
    required this.initialText,
    required this.rowIndex,
    required this.colIndex,
    required this.draggable,
    required this.focusNode,
  });

  final String itemId;
  final String initialText;
  final int rowIndex;
  final int colIndex;
  final bool draggable;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final vocabularyController = GetIt.I<VocabularyController>();
    final tableLayoutController = GetIt.I<TableLayoutController>();

    // Globally unique key per exact field
    final cacheKey = '${itemId}_$colIndex';
    final textController = vocabularyController.getControllerFor(
      cacheKey,
      initialText,
    );

    return SignalBuilder(
      builder: (context) {
        final scale = tableLayoutController.scale.value;
        final fontSize = TableLayoutController.fontSize * scale;
        final singleLineHeight = fontSize * _heightFactor;

        return VocabularyTableCell(
          rowIndex: rowIndex,
          draggable: draggable,
          child: Padding(
            padding: EdgeInsets.only(bottom: singleLineHeight * 0.5),
            child: TextField(
              focusNode: focusNode,
              controller: textController,
              minLines: 2,
              maxLines: null,
              selectAllOnFocus: true,
              style: TextStyle(
                fontSize: fontSize,
                height: _heightFactor,
                letterSpacing: _letterSpacing,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                isDense: true,
              ),
            ),
          ),
        );
      },
    );
  }
}
