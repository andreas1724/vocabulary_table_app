import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/models/vocabulary_item.dart';
import 'package:vocabulary_table_app/widgets/vocabulary_table_cell.dart';

const _heightFactor = 1.2;
const _letterSpacing = 0.0;

class EditableItemCell extends StatefulWidget {
  const EditableItemCell({super.key, 
    required this.rowIndex,
    required this.colIndex,
    required this.draggable,
  });

  final int colIndex;
  final int rowIndex;
  final bool draggable;

  @override
  State<EditableItemCell> createState() => _EditableItemCellState();
}

class _EditableItemCellState extends State<EditableItemCell> {
  late final VocabularyController _vocabularyController;
  late final FocusNode _editableTextFocus;
  late final FocusNode _plainTextFocus;
  
  // Create the controller locally to bind it strictly to the Widget lifecycle.
  late final TextEditingController _textController;

  (int, int) get _currentLocation => (widget.rowIndex, widget.colIndex);

  String get _currentText => _vocabularyController.vocabularyItems
      .peek()[widget.rowIndex]
      .peek()
      .at(widget.colIndex);

  @override
  void initState() {
    super.initState();
    _vocabularyController = GetIt.I<VocabularyController>();
    _textController = TextEditingController();

    _plainTextFocus = FocusNode()..addListener(_plainTextFocusChanged);

    _editableTextFocus = FocusNode(
      onKeyEvent: (node, event) {
        if (event.logicalKey == .escape) {
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
      // Save changes immediately back to the model upon losing focus.
      _vocabularyController.updateVocabularyAtLocation(
        (rowIndex: widget.rowIndex, colIndex: widget.colIndex),
        _textController.text,
      );

      if (_vocabularyController.selectedCell.peek() == _currentLocation) {
        _vocabularyController.selectedCell.value = null;
      }
    }
  }

  void _startEditing() {
    // Populate UI controller with fresh state before granting focus.
    _textController.text = _currentText;
    _vocabularyController.selectedCell.value = _currentLocation;
    _editableTextFocus.requestFocus();
  }

  @override
  void dispose() {
    _editableTextFocus.removeListener(_editableTextFocusChanged);
    _plainTextFocus.removeListener(_plainTextFocusChanged);
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
            .peek()[widget.rowIndex];
        final text = itemSignal.value.at(widget.colIndex);

        final isSelected =
            _vocabularyController.selectedCell.value == _currentLocation;
        final appMode = tableLayoutController.appMode.value;

        if (isSelected && appMode == .edit) {
          return _EditableTextCell(
            rowIndex: widget.rowIndex,
            draggable: widget.draggable,
            focusNode: _editableTextFocus,
            textController: _textController, // Pass the managed instance down
          );
        } else {
          return InkWell(
            mouseCursor: SystemMouseCursors.basic,
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

class _EditableTextCell extends StatelessWidget {
  const _EditableTextCell({
    required this.rowIndex,
    required this.draggable,
    required this.focusNode,
    required this.textController,
  });

  final int rowIndex;
  final bool draggable;
  final FocusNode focusNode;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    final tableLayoutController = GetIt.I<TableLayoutController>();

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
    final tableLayoutController = GetIt.I<TableLayoutController>();
    return SignalBuilder(
      builder: (context) {
        final isDragMode = tableLayoutController.appMode.value == AppMode.drag;
        final scale = tableLayoutController.scale.value;
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