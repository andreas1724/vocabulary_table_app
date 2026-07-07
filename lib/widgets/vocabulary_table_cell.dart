import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';

class VocabularyTableCell extends StatelessWidget {
  const VocabularyTableCell({
    super.key,
    required this.rowIndex,
    required this.draggable,
    required this.child,
  });

  final bool draggable;
  final int rowIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = GetIt.I<TableLayoutController>();
    const padding = 6.0;

    return SignalBuilder(
      builder: (context) {
        final scale = controller.scale.value;
        final isDragMode = controller.appMode.value == AppMode.drag;
        
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Padding(
            padding: EdgeInsets.all(scale * padding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: child),
                if (isDragMode && draggable)
                  _ResponsiveDragHandle(
                    scale: scale,
                    rowIndex: rowIndex,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResponsiveDragHandle extends StatelessWidget {
  const _ResponsiveDragHandle({
    required this.scale,
    required this.rowIndex,
  });

  final double scale;
  final int rowIndex;

  @override
  Widget build(BuildContext context) {
    const dragHandleSize = 18.0;
    final dragHandleColor = Colors.grey[700];

    final isMobile = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;

    return ReorderableDragStartListener(
      index: rowIndex,
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