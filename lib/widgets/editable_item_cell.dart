import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';
import 'package:vocabulary_table_app/widgets/row_index_scope.dart';

const _heightFactor = 1.2;
const _letterSpacing = 0.0;
const _padding = 6.0;

class EditableItemCell extends StatefulWidget {
  const EditableItemCell({super.key, required this.column});

  final ColumnName column;

  @override
  State<EditableItemCell> createState() => _EditableItemCellState();
}

class _EditableItemCellState extends State<EditableItemCell> {
  late final VocabularyController _vocabularyController;
  late final FocusNode _editableTextFocus;
  late final FocusNode _plainTextFocus;
  late final TextEditingController _textController;
  int _rowIndex = -1;

  (int, ColumnName) get _currentLocation => (_rowIndex, widget.column);

  @override
  void initState() {
    _vocabularyController = GetIt.I<VocabularyController>();
    _textController = TextEditingController();

    _plainTextFocus = FocusNode()..addListener(_onPlainTextFocusChanged);

    _editableTextFocus = FocusNode(
      onKeyEvent: (node, event) {
        if (event.logicalKey == .escape) {
          _editableTextFocus.unfocus();
          return .handled;
        }
        return .ignored;
      },
    )..addListener(_onEditableTextFocusChanged);

    // do not call before all late variables are initialized!
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rowIndex = RowIndexScope.of(context);
  }

  void _onPlainTextFocusChanged() {
    if (_plainTextFocus.hasFocus) {
      _startEditing();
    }
  }

  void _onEditableTextFocusChanged() {
    if (!_editableTextFocus.hasFocus) {
      if (_vocabularyController.selectedCell.peek() == _currentLocation) {
        _vocabularyController.selectedCell.value = null;
      }
    }
  }

  void _startEditing() {
    final currentText = _vocabularyController.vocabularyItems
        .peek()[_rowIndex]
        .peek()[widget.column];

    _textController.text = currentText;
    _textController.selection = TextSelection.collapsed(
      offset: _textController.text.length,
    );

    _vocabularyController.selectedCell.value = _currentLocation;
    _editableTextFocus.requestFocus();
  }

  @override
  void dispose() {
    // Safety check: ensure selectedCell is cleared if widget is disposed while selected
    if (_vocabularyController.selectedCell.peek() == _currentLocation) {
      _vocabularyController.selectedCell.value = null;
    }

    _editableTextFocus.removeListener(_onEditableTextFocusChanged);
    _plainTextFocus.removeListener(_onPlainTextFocusChanged);
    _editableTextFocus.dispose();
    _plainTextFocus.dispose();

    // Crucial: dispose UI element locally.
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tableLayoutController = GetIt.I<TableLayoutController>();

    return SignalBuilder(
      builder: (context) {
        final itemSignal = _vocabularyController.vocabularyItems
            .peek()[_rowIndex];
        final text = itemSignal.value[widget.column];

        final isSelected =
            _vocabularyController.selectedCell.value == _currentLocation;
        final appMode = tableLayoutController.appMode.value;

        if (isSelected && appMode == .edit) {
          return _EditableTextCell(
            rowIndex: _rowIndex,
            column: widget.column,
            focusNode: _editableTextFocus,
            textController: _textController,
          );
        } else {
          return Material(
            child: InkWell(
              mouseCursor: SystemMouseCursors.basic,
              focusNode: _plainTextFocus,
              onTap: () {
                if (!_plainTextFocus.hasFocus && !_editableTextFocus.hasFocus) {
                  FocusManager.instance.primaryFocus?.unfocus();
                }
              },
              onDoubleTap: appMode == .edit ? _startEditing : null,
              child: _PlainTextCell(
                text: text,
                column: widget.column,
                rowIndex: _rowIndex,
              ),
            ),
          );
        }
      },
    );
  }
}

class _EditableTextCell extends StatelessWidget {
  const _EditableTextCell({
    required this.rowIndex,
    required this.column,
    required this.focusNode,
    required this.textController,
  });

  final int rowIndex;
  final ColumnName column;
  final FocusNode focusNode;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    final tableLayoutController = GetIt.I<TableLayoutController>();
    final vocabularyController = GetIt.I<VocabularyController>();

    return SignalBuilder(
      builder: (context) {
        final scale = tableLayoutController.scale.value;
        final fontSize = TableLayoutController.fontSize * scale;
        final singleLineHeight = fontSize * _heightFactor;

        return Padding(
          padding: EdgeInsets.only(bottom: singleLineHeight * 0.5),
          child: Padding(
            padding: EdgeInsets.all(_padding * scale),
            child: TextField(
              focusNode: focusNode,
              controller: textController,
              // empty braces to override (event) => unfocus()
              onTapOutside: (event) {},
              onChanged: (value) =>
                  vocabularyController.updateVocabularyAtLocation((
                    rowIndex: rowIndex,
                    column: column,
                  ), value),
              minLines: 2,
              maxLines: null,
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

class _PlainTextCell extends StatelessWidget {
  const _PlainTextCell({
    required this.text,
    required this.column,
    required this.rowIndex,
  });

  final int rowIndex;
  final ColumnName column;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tableLayoutController = GetIt.I<TableLayoutController>();
    return SignalBuilder(
      builder: (context) {
        final scale = tableLayoutController.scale.value;
        final appMode = tableLayoutController.appMode.value;
        final showComment = tableLayoutController.showComment.value;
        final isDragMode = appMode == .drag;
        final showHandle =
            isDragMode &&
            ((showComment && column == .comment) ||
                (!showComment && column == .termB));

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: .start,
            children: [
              Expanded(
                child: Text(
                  text,
                  maxLines: appMode == .drag ? 3 : null,
                  style: TextStyle(
                    fontSize: TableLayoutController.fontSize * scale,
                    height: _heightFactor,
                    letterSpacing: _letterSpacing,
                  ),
                ),
              ),
              if (showHandle)
                _ResponsiveDragHandle(scale: scale, rowIndex: rowIndex),
            ],
          ),
        );
      },
    );
  }
}

class _ResponsiveDragHandle extends StatelessWidget {
  const _ResponsiveDragHandle({required this.scale, required this.rowIndex});

  final double scale;
  final int rowIndex;

  @override
  Widget build(BuildContext context) {
    const dragHandleSize = 17.0;
    final dragHandleColor = Theme.of(context).colorScheme.secondary;

    final isMobile =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;

    return ReorderableDragStartListener(
      index: rowIndex,
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.only(left: isMobile ? 32.0 : scale * 4.0),
        child: Center(
          child: Icon(
            Icons.drag_handle,
            size: dragHandleSize * scale,
            color: dragHandleColor,
          ),
        ),
      ),
    );
  }
}
