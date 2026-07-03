import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/widgets/table_row_without_top_border.dart';

class TableBody extends StatefulWidget {
  const TableBody({super.key, required this.tableWidth});

  final double tableWidth;

  @override
  State<TableBody> createState() => _TableBodyState();
}

class _TableBodyState extends State<TableBody> {
  late final _vocabularyController = GetIt.I<VocabularyController>();
  late final _tableLayoutController = GetIt.I<TableLayoutController>();
  bool _isDragging = false;

  final _activePointers = signal(0);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _activePointers.value++,
      onPointerUp: (_) =>
          _activePointers.value = (_activePointers.value - 1).clamp(0, 10),
      onPointerCancel: (_) =>
          _activePointers.value = (_activePointers.value - 1).clamp(0, 10),
      child: SignalBuilder(
        builder: (context) {
          // Explicitly read the signal to register this builder as a dependency.
          // This forces the ReorderableListView to recalculate child extents on mode switch.
          final _ = _tableLayoutController.appMode.value;

          final vocabularyItems = _vocabularyController.vocabularyItems.value;
          final borderWidth = _tableLayoutController.borderWidth.value;
          final borderColor = _tableLayoutController.borderColor.value;

          final pointers = _activePointers.value;

          return ReorderableListView.builder(
            physics: pointers > 1
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
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
                clipBehavior: .none,
                children: [
                  SignalBuilder(
                    builder: (context) {
                      final item = vocabularyItem.value;
                      return TableRowWithoutTopBorder(
                        vocabularyItem: item,
                        index: index,
                        tableWidth: widget.tableWidth,
                      );
                    },
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
      ),
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
