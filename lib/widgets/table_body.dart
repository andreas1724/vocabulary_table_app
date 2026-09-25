import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/widgets/row_index_scope.dart';
import 'package:vocabulary_table_app/widgets/table_row_without_top_border.dart';

class TableBody extends StatefulWidget {
  const TableBody({
    super.key,
    required this.tableWidth,
    required this.isMultiTouch,
    required this.activeChapterId,
  });

  final double tableWidth;
  final ReadonlySignal<bool> isMultiTouch;
  final ReadonlySignal<String?> activeChapterId;

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
        final allItems = _vocabularyController.vocabularyItems.value;
        final chapterId = widget.activeChapterId.value;

        // 1. Reactive list filtering based on the currently selected chapter
        final chapterItems = chapterId != null
            ? allItems.where((item) => item.chapterId == chapterId).toList()
            : allItems;

        final isMultiTouch = widget.isMultiTouch.value;
        final dynamicPhysics = isMultiTouch
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics();

        return CustomScrollView(
          // Removed `key: ValueKey(appMode)` to preserve scroll offsetkey
          physics: dynamicPhysics,
          // optional: scrollCacheExtent: const ScrollCacheExtent.pixels(2500),
          slivers: [
            SliverReorderableList(
              itemCount: chapterItems.length,
              proxyDecorator: _proxyDecorator,
              onReorderStart: (index) => _draggedItemIndex.value = index,
              onReorderEnd: (index) => _draggedItemIndex.value = null,
              onReorderItem: (oldUiIndex, newUiIndex) {
                // 2. Safe index mapping from the filtered UI list back to the global state list
                if (oldUiIndex == newUiIndex) return;

                final draggedItem = chapterItems[oldUiIndex];
                final globalOldIndex = allItems.indexWhere((i) => i.id == draggedItem.id);

                int globalNewIndex;
                if (newUiIndex >= chapterItems.length) {
                  // Moved to the very end of the current chapter
                  final lastItem = chapterItems.last;
                  globalNewIndex = allItems.indexWhere((i) => i.id == lastItem.id) + 1;
                } else {
                  // Find the global index of the item that currently occupies the target position
                  final targetItem = chapterItems[newUiIndex];
                  globalNewIndex = allItems.indexWhere((i) => i.id == targetItem.id);
                }

                _vocabularyController.reorderItem(globalOldIndex, globalNewIndex);
              },
              itemBuilder: (context, index) {
                final vocabularyItem = chapterItems[index];
                final globalIndex = allItems.indexWhere((i) => i.id == vocabularyItem.id);

                return _DraggableRowWrapper(
                  key: ValueKey(vocabularyItem.id),
                  uiIndex: index,
                  globalIndex: globalIndex,
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
                clipBehavior: .none,
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
    required this.uiIndex,
    required this.globalIndex,
    required this.tableWidth,
    required this.draggedItemIndex,
  });

  final int uiIndex;
  final int globalIndex;
  final double tableWidth;
  final ReadonlySignal<int?> draggedItemIndex;

  @override
  Widget build(BuildContext context) {
    final tableLayoutController = GetIt.I<TableLayoutController>();

    return Stack(
      clipBehavior: .none,
      children: [
        RowIndexScope(
          uiIndex: uiIndex,
          globalIndex: globalIndex,
          child: TableRowWithoutTopBorder(tableWidth: tableWidth),
        ),
        // FIX: Positioned must strictly wrap the SignalBuilder to be visible to the Stack.
        Positioned(
          // Using .peek() here is safe as the border width doesn't dynamically animate 
          // while this specific row is standing still. It saves a reactive dependency[cite: 13].
          top: -tableLayoutController.borderWidth.peek(),
          left: 0,
          right: 0,
          height: tableLayoutController.borderWidth.peek(),
          child: SignalBuilder(
            builder: (context) {
              if (draggedItemIndex.value == null) {
                return const SizedBox.shrink();
              }

              return ColoredBox(
                color: Theme.of(context).colorScheme.outlineVariant,
              );
            },
          ),
        ),
      ],
    );
  }
}