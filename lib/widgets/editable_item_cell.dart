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

  int _globalIndex = -1;
  int _uiIndex = -1;

  // Returns a positional record (int, int) to strictly match the selectedCell signal type
  (int rowIndex, int colIndex) get _currentLocation =>
      (_globalIndex, widget.colIndex);

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
    final scope = RowIndexScope.of(context);
    _globalIndex = scope.globalIndex;
    _uiIndex = scope.uiIndex;
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
        rowIndex: location.$1,
        colIndex: location.$2,
      ), textToSave);

      if (_vocabularyController.selectedCell.peek() == location) {
        _vocabularyController.selectedCell.value = null;
      }
    });
  }

  void _startEditing() {
    final currentText = _vocabularyController.vocabularyItems
        .peek()[_globalIndex]
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
          rowIndex: location.$1,
          colIndex: location.$2,
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
          _globalIndex,
          widget.colIndex,
        );

        return FocusTraversalOrder(
          order: NumericFocusOrder(focusOrder),
          child: isSelected && appMode == .edit
              ? _EditableTextCell(
                  globalIndex: _globalIndex,
                  colIndex: widget.colIndex,
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
                    child: _PlainTextCell(
                      colIndex: widget.colIndex,
                      globalIndex: _globalIndex,
                      uiIndex: _uiIndex,
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _EditableTextCell extends StatelessWidget {
  const _EditableTextCell({
    required this.globalIndex,
    required this.colIndex,
    required this.focusNode,
    required this.textController,
  });

  final int globalIndex;
  final int colIndex;
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
  const _PlainTextCell({
    required this.colIndex,
    required this.globalIndex,
    required this.uiIndex,
  });

  final int globalIndex;
  final int uiIndex;
  final int colIndex;

  @override
  Widget build(BuildContext context) {
    final tableLayoutController = GetIt.I<TableLayoutController>();
    final vocabularyController = GetIt.I<VocabularyController>();

    return SignalBuilder(
      builder: (context) {
        final itemSignal =
            vocabularyController.vocabularyItems.value[globalIndex];
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
                _ResponsiveDragHandle(scale: scale, uiIndex: uiIndex),
            ],
          ),
        );
      },
    );
  }
}

class _ResponsiveDragHandle extends StatelessWidget {
  const _ResponsiveDragHandle({required this.scale, required this.uiIndex});

  final double scale;
  final int uiIndex;

  @override
  Widget build(BuildContext context) {
    const dragHandleSize = 17.0;
    final dragHandleColor = Theme.of(context).colorScheme.secondary;

    final isMobile =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;

    return ReorderableDragStartListener(
      index: uiIndex,
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

extension on VocabularyItem {
  // Generates exactly the 3 string columns needed for your UI table
  List<String> get tableColumns => [termA, termB, comment];
}
