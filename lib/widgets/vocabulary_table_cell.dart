import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/widgets/row_index_scope.dart';

class VocabularyTableCell extends StatefulWidget {
  const VocabularyTableCell({
    super.key,
    required this.draggable,
    required this.child,
  });

  final bool draggable;
  final Widget child;

  @override
  State<VocabularyTableCell> createState() => _VocabularyTableCellState();
}

class _VocabularyTableCellState extends State<VocabularyTableCell> {
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
                Expanded(child: widget.child),
                if (isDragMode && widget.draggable)
                  _ResponsiveDragHandle(
                    scale: scale,
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
  });

  final double scale;

  @override
  Widget build(BuildContext context) {
    const dragHandleSize = 18.0;
    final dragHandleColor = Colors.grey[700];

    final isMobile = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;

    // Fetch the index directly from the nearest RowIndexScope
    final rowIndex = RowIndexScope.of(context);

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