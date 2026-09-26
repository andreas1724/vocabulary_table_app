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
const _dragHandleSize = 17.0;

/// Must be wrapped in RowIndexScope (InheritedWidget)
class EditableItemCell extends StatefulWidget {
  const EditableItemCell({super.key, required this.colIndex});

  final int colIndex;

  @override
  State<EditableItemCell> createState() => _EditableItemCellState();
}

class _EditableItemCellState extends State<EditableItemCell> {
  late final VocabularyController _vocabularyController;
  late final FocusNode _editableTextFocus;
  late final FocusNode _plainTextFocus;
  late final TextEditingController _textController;

  late ({int globalIndex, int uiIndex}) _row;

  // Returns a positional record (int, int) to strictly match the selectedCell signal type
  ({int rowIndex, int colIndex}) get _currentLocation =>
      (rowIndex: _row.globalIndex, colIndex: widget.colIndex);

  @override
  void initState() {
    super.initState();
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
    _row = RowIndexScope.of(context);
  }

  void _onPlainTextFocusChanged() {
    if (_plainTextFocus.hasFocus) {
      _startEditing();
    }
  }

  void _onEditableTextFocusChanged() {
    if (!_editableTextFocus.hasFocus) {
      _saveChanges();
    }
  }

  void _saveChanges() {
    final location = _currentLocation;
    final textToSave = _textController.text;

    // Decouple the state mutation from the current synchronous frame to prevent
    // "setState called during build" exceptions when focus is lost.
    Future.microtask(() {
      _vocabularyController.updateVocabularyAtLocation((
        rowIndex: location.rowIndex,
        colIndex: location.colIndex,
      ), textToSave);

      if (_vocabularyController.selectedCell.peek() == location) {
        _vocabularyController.selectedCell.value = null;
      }
    });
  }

  void _startEditing() {
    final currentText = _vocabularyController.vocabularyItems
        .peek()[_row.globalIndex]
        .tableColumns[widget.colIndex];

    Future.microtask(() {
      if (!mounted) return;

      _textController.text = currentText;
      _textController.selection = TextSelection.collapsed(
        offset: _textController.text.length,
      );

      _vocabularyController.selectedCell.value = _currentLocation;
      _editableTextFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _editableTextFocus.removeListener(_onEditableTextFocusChanged);
    _plainTextFocus.removeListener(_onPlainTextFocusChanged);

    final location = _currentLocation;
    final textToSave = _textController.text;

    // Rely on our own reactive state rather than the detached focus tree
    final wasEditing = _vocabularyController.selectedCell.peek() == location;

    if (wasEditing) {
      // Defer the signal mutation to the next microtask to safely bypass the locked widget tree
      Future.microtask(() {
        _vocabularyController.updateVocabularyAtLocation((
          rowIndex: location.rowIndex,
          colIndex: location.colIndex,
        ), textToSave);

        if (_vocabularyController.selectedCell.peek() == location) {
          _vocabularyController.selectedCell.value = null;
        }
      });
    }

    _editableTextFocus.dispose();
    _plainTextFocus.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tableLayoutController = GetIt.I<TableLayoutController>();

    return SignalBuilder(
      builder: (context) {
        final appMode = tableLayoutController.appMode.value;
        final isSelected =
            _vocabularyController.selectedCell.value == _currentLocation;

        final focusOrder = tableLayoutController.focusOrder(
          _row.globalIndex,
          widget.colIndex,
        );

        return FocusTraversalOrder(
          order: NumericFocusOrder(focusOrder),
          child: isSelected && appMode == .edit
              ? _EditableTextCell(
                  focusNode: _editableTextFocus,
                  textController: _textController,
                )
              : Material(
                  child: InkWell(
                    mouseCursor: SystemMouseCursors.basic,
                    focusNode: _plainTextFocus,
                    onTap: () {
                      if (!_plainTextFocus.hasFocus &&
                          !_editableTextFocus.hasFocus) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      }
                    },
                    onDoubleTap: appMode == .edit ? _startEditing : null,
                    child: _PlainTextCell(colIndex: widget.colIndex),
                  ),
                ),
        );
      },
    );
  }
}

class _EditableTextCell extends StatelessWidget {
  const _EditableTextCell({
    required this.focusNode,
    required this.textController,
  });

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
            child: NotificationListener<KeepAliveNotification>(
              // crucial: prevent TextField's underlying EditableText's AutomaticKeepAliveClientMixin
              onNotification: (_) => true,
              child: TextField(
                focusNode: focusNode,
                controller: textController,
                // empty braces to override (event) => unfocus()
                onTapOutside: (event) {},
                onSubmitted: (_) => focusNode.unfocus(),
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
          ),
        );
      },
    );
  }
}

class _PlainTextCell extends StatelessWidget {
  const _PlainTextCell({required this.colIndex});

  final int colIndex;

  @override
  Widget build(BuildContext context) {
    final tableLayoutController = GetIt.I<TableLayoutController>();
    final vocabularyController = GetIt.I<VocabularyController>();
    final row = RowIndexScope.of(context);

    return SignalBuilder(
      builder: (context) {
        final itemSignal =
            vocabularyController.vocabularyItems.value[row.globalIndex];
        final text = itemSignal.tableColumns[colIndex];

        final scale = tableLayoutController.scale.value;
        final appMode = tableLayoutController.appMode.value;
        final showComment = tableLayoutController.showComment.value;
        final isDragMode = appMode == .drag;
        final showHandle =
            isDragMode &&
            ((showComment && colIndex == 2) || (!showComment && colIndex == 1));

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
                _ResponsiveDragHandle(scale: scale),
            ],
          ),
        );
      },
    );
  }
}

class _ResponsiveDragHandle extends StatelessWidget {
  const _ResponsiveDragHandle({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final dragHandleColor = Theme.of(context).colorScheme.secondary;

    final isTouchPlatform =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;

    final row = RowIndexScope.of(context);

    return ReorderableDragStartListener(
      index: row.uiIndex,
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.only(left: isTouchPlatform ? 32.0 : scale * 4.0),
        child: Center(
          child: Icon(
            Icons.drag_handle,
            size: _dragHandleSize * scale,
            color: dragHandleColor,
          ),
        ),
      ),
    );
  }
}

extension on VocabularyItem {
  // Generates exactly the 3 string columns needed for your UI table
  List<String> get tableColumns => [termA, termB, comment];
}
