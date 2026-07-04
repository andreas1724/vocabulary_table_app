import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/widgets/table_row_without_top_border.dart';
import 'package:vocabulary_table_app/widgets/row_index_scope.dart';

class TableBody extends StatefulWidget {
  const TableBody({
    super.key,
    required this.tableWidth,
    required this.isMultiTouch, 
  });

  final double tableWidth;
  final ReadonlySignal<bool> isMultiTouch; 

  @override
  State<TableBody> createState() => _TableBodyState();
}

class _TableBodyState extends State<TableBody> {
  late final _tableLayoutController = GetIt.I<TableLayoutController>();

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final mode = _tableLayoutController.appMode.value;
        
        // Non-view modes don't require text selection logic
        if (mode != AppMode.view) {
          return _TableListView(
            tableWidth: widget.tableWidth,
            isMultiTouch: widget.isMultiTouch,
          );
        }

        return SelectionArea(
          child: SignalBuilder(
            builder: (context) {
              final isMultiTouch = widget.isMultiTouch.value;

              // THE FIX: Use SelectionContainer.disabled to safely unregister the 
              // scrollable hierarchy from the SelectionArea during active multi-touch gestures.
              if (isMultiTouch) {
                return SelectionContainer.disabled(
                  child: _TableListView(
                    tableWidth: widget.tableWidth,
                    isMultiTouch: widget.isMultiTouch,
                  ),
                );
              }

              return _TableListView(
                tableWidth: widget.tableWidth,
                isMultiTouch: widget.isMultiTouch,
              );
            },
          ),
        );
      },
    );
  }
}

/// Extracted private widget class for high-performance rendering and clear structure
class _TableListView extends StatefulWidget {
  const _TableListView({
    super.key,
    required this.tableWidth,
    required this.isMultiTouch,
  });

  final double tableWidth;
  final ReadonlySignal<bool> isMultiTouch;

  @override
  State<_TableListView> createState() => _TableListViewState();
}

class _TableListViewState extends State<_TableListView> {
  late final _vocabularyController = GetIt.I<VocabularyController>();
  late final _tableLayoutController = GetIt.I<TableLayoutController>();
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final vocabularyItems = _vocabularyController.vocabularyItems.value;
        final borderWidth = _tableLayoutController.borderWidth.value;
        final borderColor = _tableLayoutController.borderColor.value;
        
        final isMultiTouch = widget.isMultiTouch.value;
        final dynamicPhysics = isMultiTouch 
            ? const NeverScrollableScrollPhysics() 
            : const AlwaysScrollableScrollPhysics();

        return ReorderableListView.builder(
          physics: dynamicPhysics,
          buildDefaultDragHandles: false,
          itemCount: vocabularyItems.length,
          onReorderStart: (index) => setState(() => _isDragging = true),
          onReorderEnd: (index) => setState(() => _isDragging = false),
          onReorderItem: (int oldIndex, int newIndex) =>
              _vocabularyController.reorderItem(oldIndex, newIndex),
          proxyDecorator: _proxyDecorator,
          itemBuilder: (context, index) {
            final vocabularyItem = vocabularyItems[index];
            final id = vocabularyItem.peek().id;

            return Stack(
              key: ValueKey(id),
              clipBehavior: Clip.none,
              children: [
                RowIndexScope(
                  rowIndex: index,
                  child: SignalBuilder(
                    builder: (context) {
                      final item = vocabularyItem.value;
                      return TableRowWithoutTopBorder(
                        vocabularyItem: item,
                        tableWidth: widget.tableWidth,
                      );
                    },
                  ),
                ),
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

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    const elevation = 6.0;

    return SignalBuilder(
      builder: (context) {
        final scale = _tableLayoutController.scale.value;
        final borderWidth = _tableLayoutController.borderWidth.value;
        final borderColor = _tableLayoutController.borderColor.value;

        return Material(
          elevation: elevation * scale,
          color: Colors.blue[50],
          child: Stack(
            clipBehavior: Clip.none,
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