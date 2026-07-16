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

class _EditableItemCellState extends State<EditableItemCell>
    with AutomaticKeepAliveClientMixin {
  late final VocabularyController _vocabularyController;
  late final FocusNode _editableTextFocus;
  late final FocusNode _plainTextFocus;
  late final TextEditingController _textController;
  int _rowIndex = -1;

  // Stores the cleanup function for the signal effect
  EffectCleanup? _syncEffectCleanup;

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
  bool get wantKeepAlive => _editableTextFocus.hasFocus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newIndex = RowIndexScope.of(context);
    if (newIndex != _rowIndex) {
      _rowIndex = newIndex;
      _setupSyncEffect();
    }
  }

  @override
  void didUpdateWidget(EditableItemCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.column != widget.column) {
      if (_editableTextFocus.hasFocus) {
        _vocabularyController.selectedCell.value = _currentLocation;
        _setupSyncEffect();
      }
    }
  }

  void _setupSyncEffect() {
    // Clean up previous subscription before creating a new one
    _syncEffectCleanup?.call();

    _syncEffectCleanup = effect(() {
      final currentText =
          _vocabularyController.vocabularyItems[_rowIndex].value[widget.column];

      if (_textController.text != currentText) {
        _textController.text = currentText;
      }
    });
  }

  void _onPlainTextFocusChanged() {
    if (_plainTextFocus.hasFocus) {
      _startEditing();
    }
  }

  void _onEditableTextFocusChanged() {
    updateKeepAlive();
    if (!_editableTextFocus.hasFocus) {
      // Save changes immediately back to the model upon losing focus.
      _vocabularyController.updateVocabularyAtLocation((
        rowIndex: _rowIndex,
        column: widget.column,
      ), _textController.text);

      if (_vocabularyController.selectedCell.peek() == _currentLocation) {
        _vocabularyController.selectedCell.value = null;
      }
    }
  }

  void _startEditing() {
    _textController.selection = TextSelection.collapsed(
      offset: _textController.text.length,
    );
    _vocabularyController.selectedCell.value = _currentLocation;
    _editableTextFocus.requestFocus();
  }

  @override
  void dispose() {
    _syncEffectCleanup?.call();

    // Safety check: ensure selectedCell is cleared if widget is disposed while focused
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
    // required in this Mixin
    super.build(context);
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
            focusNode: _editableTextFocus,
            textController: _textController, // Pass the managed instance down
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
              child: _PlainTextCell(text: text, rowIndex: _rowIndex),
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
    required this.focusNode,
    required this.textController,
  });

  final int rowIndex;
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

        return Padding(
          padding: EdgeInsets.only(bottom: singleLineHeight * 0.5),
          child: Padding(
            padding: EdgeInsets.all(_padding * scale),
            child: TextField(
              focusNode: focusNode,
              controller: textController,
              // empty braces to override (event) => unfocus()
              onTapOutside: (event) {},
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
  const _PlainTextCell({required this.text, required this.rowIndex});

  final int rowIndex;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tableLayoutController = GetIt.I<TableLayoutController>();
    return SignalBuilder(
      builder: (context) {
        final scale = tableLayoutController.scale.value;
        final appMode = tableLayoutController.appMode.value;
        return Padding(
          padding: EdgeInsets.all(_padding * scale),
          child: Text(
            text,
            maxLines: appMode == .drag ? 3 : null,
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
