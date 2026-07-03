import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';

/// Content of the cell with optional drag handle
class VocabularyTableCell extends StatelessWidget {
  const VocabularyTableCell({
    super.key,
    required this.text,
    required this.index,
    required this.controller,
    this.draggable = false,
  });

  final TableLayoutController controller;
  final String text;
  final int index;
  final bool draggable;

  @override
  Widget build(BuildContext context) {
    const padding = 6.0;

    return SignalBuilder(
      builder: (context) {
        final scale = controller.scale.value;
        final isDragMode = controller.appMode.value == .drag;
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Padding(
            padding: EdgeInsets.all(scale * padding),
            child: SignalBuilder(
              builder: (context) {
                return Row(
                  crossAxisAlignment: .start,
                  children: [
                    Expanded(
                      child: SelectableText(
                        text,
                        minLines: 1,
                        maxLines: isDragMode ? 3 : null,
                        style: TextStyle(
                          fontSize: TableLayoutController.fontSize * scale,
                        ),
                      ),
                    ),
                    if (isDragMode && draggable)
                      _ResponsiveDragHandle(index: index, scale: scale),
                  ],
                );
              }
            ),
          ),
        );
      },
    );
  }
}

class _ResponsiveDragHandle extends StatelessWidget {
  const _ResponsiveDragHandle({required this.index, required this.scale});

  final int index;
  final double scale;

  @override
  Widget build(BuildContext context) {
    const dragHandleSize = 18.0;
    final dragHandleColor = Colors.grey[700];

    final isMobile =
        (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

    return ReorderableDragStartListener(
      index: index,
      child: Container(
        color: Colors.transparent,
        // Apply responsive padding for the hit area.
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