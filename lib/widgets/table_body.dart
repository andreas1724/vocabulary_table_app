import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/utils/custom_delayed_drag_start_listener.dart';
import 'package:vocabulary_table_app/widgets/row_index_scope.dart';
import 'package:vocabulary_table_app/widgets/table_row_without_top_border.dart';

/// Extracted private widget class for high-performance rendering and clear structure
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
        final appMode = _tableLayoutController.appMode.value;
        final isMultiTouch = widget.isMultiTouch.value;

        final dynamicPhysics = isMultiTouch
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics();

        return CustomScrollView(
          key: ValueKey(appMode),
          physics: dynamicPhysics,
          slivers: [
            SliverReorderableList(
              itemCount: vocabularyItems.length,
              onReorderItem: _vocabularyController.reorderItem,
              onReorderStart: (index) => _draggedItemIndex.value = index,
              onReorderEnd: (index) => _draggedItemIndex.value = null,
              proxyDecorator: _proxyDecorator,
              itemBuilder: (context, index) {
                final vocabularyItem = vocabularyItems[index];
                final id = vocabularyItem.peek().id;

                return _DraggableRowWrapper(
                  key: ValueKey(id),
                  index: index,
                  tableWidth: widget.tableWidth,
                  draggedItemIndex: _draggedItemIndex,
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

    return SignalBuilder(
      builder: (context) {
        final scale = _tableLayoutController.scale.value;
        final borderWidth = _tableLayoutController.borderWidth.value;
        final borderColor = Theme.of(context).colorScheme.outlineVariant;
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, animatedChild) {
            // Interpolate elevation smoothly during the pickup animation
            final currentElevation = targetElevation * scale * animation.value;
            return Material(
              elevation: currentElevation,
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
    // ignore: unused_element_parameter
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
        RowIndexScope(
          rowIndex: index,
          child: TableRowWithoutTopBorder(tableWidth: tableWidth),
        ),
        SignalBuilder(
          builder: (context) {
            // If NO item is being dragged, hide all top borders to prevent overlaps.
            // If ANY item is dragged, show top borders on all items to ensure the
            // empty gap in the ReorderableListView maintains a top border.
            if (draggedItemIndex.value == null) {
              return const SizedBox.shrink();
            }

            final borderWidth = tableLayoutController.borderWidth.value;
            final borderColor = Theme.of(context).colorScheme.outlineVariant;

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
