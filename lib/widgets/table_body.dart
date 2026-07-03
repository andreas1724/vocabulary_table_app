import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/widgets/table_row_without_top_border.dart';

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

  // Track active pointers to resolve gesture collisions.
  final _activePointers = signal(0);

  @override
  void initState() {
    super.initState();
    GetIt.I.pushNewScope(scopeName: 'InsideTableScope');

    GetIt.I.registerSingleton(widget.vocabularyController);

    GetIt.I.registerSingleton(widget.tableLayoutController);
  }

  @override
  void dispose() {
    _activePointers.dispose();
    GetIt.I.popScope();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Wrap the widget tree with a Listener to count screen touches.
    return Listener(
      onPointerDown: (_) => _activePointers.value++,
      // Clamp prevents the count from becoming negative if an event is dropped.
      onPointerUp: (_) =>
          _activePointers.value = (_activePointers.value - 1).clamp(0, 10),
      onPointerCancel: (_) =>
          _activePointers.value = (_activePointers.value - 1).clamp(0, 10),
      child: SignalBuilder(
        builder: (context) {
          final vocabularyItems =
              widget.vocabularyController.vocabularyItems.value;
          final borderWidth = widget.tableLayoutController.borderWidth.value;
          final borderColor = widget.tableLayoutController.borderColor.value;

          final pointers = _activePointers.value;

          return ReorderableListView.builder(
            // 2. Kill list scrolling dynamically if multiple fingers are on screen.
            // This hands control back to the outer GestureDetector's onScaleUpdate.
            physics: pointers > 1
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: vocabularyItems.length,
            onReorderStart: (index) => setState(() => _isDragging = true),
            onReorderEnd: (index) => setState(() => _isDragging = false),
            onReorderItem: (int oldIndex, int newIndex) =>
                widget.vocabularyController.reorderItem(oldIndex, newIndex),
            proxyDecorator: _proxyDecorator,

            itemBuilder: (context, index) {
              final vocabularyItem = vocabularyItems[index];
              final id = vocabularyItem.peek().id;

              return Stack(
                key: ValueKey(id),

                // Allows drawing the top line outside the box
                clipBehavior: .none,
                children: [
                  // 1. The actual row as an optimized single-row table
                  SignalBuilder(
                    builder: (context) {
                      final item = vocabularyItem.value;
                      return TableRowWithoutTopBorder(
                        vocabularyItem: item,
                        index: index,
                        tableWidth: widget.tableWidth,
                        controller: widget.tableLayoutController,
                      );
                    },
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
      ),
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return SignalBuilder(
      builder: (context) {
        final scale = widget.tableLayoutController.scale.value;
        final borderWidth = widget.tableLayoutController.borderWidth.value;
        final borderColor = widget.tableLayoutController.borderColor.value;
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
}
