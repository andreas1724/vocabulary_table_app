import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/widgets/table_row_without_top_border.dart';

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
  @override
  Widget build(BuildContext context) {
    return _TableListView(
      tableWidth: widget.tableWidth,
      isMultiTouch: widget.isMultiTouch,
    );
  }
}

/// Extracted private widget class for high-performance rendering and clear structure
class _TableListView extends StatefulWidget {
  const _TableListView({required this.tableWidth, required this.isMultiTouch});

  final double tableWidth;
  final ReadonlySignal<bool> isMultiTouch;

  @override
  State<_TableListView> createState() => _TableListViewState();
}

class _TableListViewState extends State<_TableListView> {
  late final _vocabularyController = GetIt.I<VocabularyController>();
  late final _tableLayoutController = GetIt.I<TableLayoutController>();

  final _draggedItemIndex = signal<int?>(null);

  @override
  void dispose() {
    _draggedItemIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final vocabularyItems = _vocabularyController.vocabularyItems.value;
        final isMultiTouch = widget.isMultiTouch.value;

        final dynamicPhysics = isMultiTouch
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics();

        return CustomScrollView(
          physics: dynamicPhysics,
          slivers: [
            SliverReorderableList(
              itemCount: vocabularyItems.length,
              // O(1) index resolution during dynamic list updates
              findChildIndexCallback: (Key key) {
                if (key is! ValueKey<String>) return null;

                final index = vocabularyItems.indexWhere(
                  (item) => item.peek().id == key.value,
                );
                return index >= 0 ? index : null;
              },
              onReorderItem: (oldIndex, newIndex) =>
                  _vocabularyController.reorderItem,
              onReorderStart: (index) => _draggedItemIndex.value = index,
              onReorderEnd: (index) => _draggedItemIndex.value = null,
              proxyDecorator: _proxyDecorator,
              itemBuilder: (context, index) {
                final vocabularyItem = vocabularyItems[index];
                final id = vocabularyItem.peek().id;

                // Explicit DragStartListener is required when building custom sliver lists
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(id),
                  index: index,
                  child: _DraggableRowWrapper(
                    index: index,
                    tableWidth: widget.tableWidth,
                    draggedItemIndex: _draggedItemIndex,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    const targetElevation = 6.0;

    return AnimatedBuilder(
      animation: animation,
      child:
          child, // Pass child here to avoid rebuilding the dragged row on every frame
      builder: (context, animatedChild) {
        return SignalBuilder(
          builder: (context) {
            final scale = _tableLayoutController.scale.value;
            final borderWidth = _tableLayoutController.borderWidth.value;
            final borderColor = _tableLayoutController.borderColor.value;

            // Interpolate elevation smoothly during the pickup animation
            final currentElevation = targetElevation * scale * animation.value;

            return Material(
              elevation: currentElevation,
              color: Colors.blue[50],
              shadowColor: Colors.black45,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  animatedChild!,
                  Positioned(
                    top: -borderWidth,
                    left: 0,
                    right: 0,
                    height: borderWidth,
                    child: ColoredBox(color: borderColor),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DraggableRowWrapper extends StatelessWidget {
  const _DraggableRowWrapper({
    super.key,
    required this.index,
    required this.tableWidth,
    required this.draggedItemIndex,
  });

  final int index;
  final double tableWidth;
  final ReadonlySignal<int?> draggedItemIndex;

  @override
  Widget build(BuildContext context) {
    final tableLayoutController = GetIt.I<TableLayoutController>();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        TableRowWithoutTopBorder(rowIndex: index, tableWidth: tableWidth),
        SignalBuilder(
          builder: (context) {

            // If NO item is being dragged, hide all top borders to prevent overlaps.
            // If ANY item is dragged, show top borders on all items to ensure the
            // empty gap in the ReorderableListView maintains a top border.
            if (draggedItemIndex.value == null) {
              return const SizedBox.shrink();
            }

            final borderWidth = tableLayoutController.borderWidth.value;
            final borderColor = tableLayoutController.borderColor.value;

            return Positioned(
              top: -borderWidth,
              left: 0,
              right: 0,
              height: borderWidth,
              child: ColoredBox(color: borderColor),
            );
          },
        ),
      ],
    );
  }
}
