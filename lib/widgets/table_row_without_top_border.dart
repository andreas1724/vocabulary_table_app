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
    super.key, // Best Practice: Forward key to super
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
  late final Computed<bool> _isSelected;
  late final (int, int) _cellLocation;

  // No local TextEditingController here anymore to avoid state duplication!
  late String _previousText;
  late final String _cacheKey;

  @override
  void initState() {
    super.initState();
    _cellLocation = (widget.rowIndex, widget.colIndex);
    _vocabularyController = GetIt.I<VocabularyController>();

    // FIX: Initialize _previousText BEFORE it is used for any operations
    final currentItem = _vocabularyController.vocabularyItems
        .peek()[widget.rowIndex]
        .peek();

    _previousText = currentItem.at(widget.colIndex);

    // Globally unique key matching the one in _EditableTextCell
    _cacheKey = '${currentItem.id}_${widget.colIndex}';

    _isSelected = computed(
      () => _vocabularyController.selectedCell.value == _cellLocation,
    );

    _plainTextFocus = FocusNode()..addListener(_plainTextFocusChanged);

    _editableTextFocus = FocusNode(
      onKeyEvent: (node, event) {
        if (event.logicalKey == .escape) {
          // Revert text using the centrally cached controller
          final cachedController = _vocabularyController.getControllerFor(
            _cacheKey,
            _previousText,
          );
          cachedController.text = _previousText;

          _vocabularyController.updateVocabularyAtIndexColumn(
            _cellLocation.$1,
            _cellLocation.$2,
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
        _cacheKey,
        _previousText,
      );

      _vocabularyController.updateVocabularyAtIndexColumn(
        _cellLocation.$1,
        _cellLocation.$2,
        cachedController.text,
      );

      if (_vocabularyController.selectedCell.peek() == _cellLocation) {
        _vocabularyController.selectedCell.value = null;
      }
    }
  }

  void _startEditing() {
    _previousText = _vocabularyController.vocabularyItems[_cellLocation.$1]
        .peek()
        .at(_cellLocation.$2);

    // Update the centrally cached controller to reflect the current signal state
    final cachedController = _vocabularyController.getControllerFor(
      _cacheKey,
      _previousText,
    );
    cachedController.text = _previousText;

    _vocabularyController.selectedCell.value = _cellLocation;

    _editableTextFocus.unfocus();
    _editableTextFocus.requestFocus();
  }

  @override
  void dispose() {
    _isSelected.dispose();
    _editableTextFocus.removeListener(_editableTextFocusChanged);
    _plainTextFocus.removeListener(_plainTextFocusChanged);
    _editableTextFocus.dispose();
    _plainTextFocus.dispose();
    // Removed local text controller disposal since it's now fully managed by VocabularyController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tableLayoutController = GetIt.I<TableLayoutController>();

    return SignalBuilder(
      builder: (context) {
        final item =
            _vocabularyController.vocabularyItems.value[widget.rowIndex];
        final text = item.value.at(widget.colIndex);
        final itemId = item.value.id;
        final isSelected = _isSelected.value;
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
        return VocabularyTableCell(
          rowIndex: rowIndex,
          draggable: draggable,
          child: TextField(
            focusNode: focusNode,
            controller: textController,
            maxLines: null,
            style: TextStyle(
              fontSize: TableLayoutController.fontSize * scale,
              height: _heightFactor,
              letterSpacing: _letterSpacing,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
            ),
            onChanged: (value) {
              vocabularyController.updateVocabularyAtIndexColumn(
                rowIndex,
                colIndex,
                value,
              );
            },
          ),
        );
      },
    );
  }
}
