import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';

/// Size for the drag area between columns.
const _dragHandleWidth = 48.0;

class HeaderRow extends StatefulWidget {
  const HeaderRow({super.key, required this.controller});

  final TableLayoutController controller;

  @override
  State<HeaderRow> createState() => _HeaderRowState();
}

class _HeaderRowState extends State<HeaderRow> {
  final _containerKey = GlobalKey();

  // Cache the RenderBox to avoid tree-walking during 60fps drag updates
  RenderBox? _cachedRenderBox;

  void _cacheRenderBox(_) {
    final context = _containerKey.currentContext;
    if (context != null) {
      _cachedRenderBox = context.findRenderObject() as RenderBox?;
    }
  }

  double? _getLocalX(Offset globalPosition) {
    if (_cachedRenderBox == null || !_cachedRenderBox!.attached) return null;
    return _cachedRenderBox!.globalToLocal(globalPosition).dx;
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final tableWidth = widget.controller.tableWidth.value;
        final borderColor = widget.controller.borderColor.value;
        final borderWidth = widget.controller.borderWidth.value;

        final r1 = widget.controller.col1Ratio.value;
        final r2 = widget.controller.col2Ratio.value;
        final r3 = widget.controller.col3Ratio.value;
        final showComment = widget.controller.showComment.value;

        final w1 = tableWidth * r1;
        final w2 = tableWidth * r2;
        final w3 = tableWidth * r3;

        final scale = widget.controller.scale.value;

        return Stack(
          key: _containerKey,
          children: [
            Table(
              border: TableBorder.all(color: borderColor, width: borderWidth),
              columnWidths: {
                0: FixedColumnWidth(w1),
                1: FixedColumnWidth(w2),
                if (showComment) 2: FixedColumnWidth(w3),
              },
              children: [
                TableRow(
                  children: ['English', 'German', if (showComment) 'Comment']
                      .map(
                        (text) => ClipRect(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize:
                                    TableLayoutController.fontSize * scale,
                                fontWeight: .bold,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),

            // Handle 1
            _DragHandle(
              leftPosition: w1,
              onDragStart: _cacheRenderBox, // Cache when dragging begins
              onDragUpdate: (globalPosition) {
                if (tableWidth <= 0) return;
                final localX = _getLocalX(globalPosition);
                if (localX != null) {
                  widget.controller.updateFirstHandle(localX / tableWidth);
                }
              },
            ),

            // Handle 2
            if (showComment)
              _DragHandle(
                leftPosition: w1 + w2,
                onDragStart: _cacheRenderBox,
                onDragUpdate: (globalPosition) {
                  if (tableWidth <= 0) return;
                  final localX = _getLocalX(globalPosition);
                  if (localX != null) {
                    widget.controller.updateSecondHandle(localX / tableWidth);
                  }
                },
              ),
          ],
        );
      },
    );
  }
}

class _DragHandle extends StatefulWidget {
  const _DragHandle({
    required this.leftPosition,
    required this.onDragStart,
    required this.onDragUpdate,
  });

  final double leftPosition;
  final void Function(DragDownDetails) onDragStart;
  final void Function(Offset) onDragUpdate;

  @override
  State<_DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<_DragHandle> {
  // Track drag state to provide visual feedback on touch devices
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.leftPosition - _dragHandleWidth / 2,
      top: 0,
      bottom: 0,
      width: _dragHandleWidth,
      child: GestureDetector(
        behavior: .opaque,
        onHorizontalDragDown: (details) {
          setState(() => _isDragging = true);
          widget.onDragStart(details);
        },
        onHorizontalDragUpdate: (details) =>
            widget.onDragUpdate(details.globalPosition),
        onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
        onHorizontalDragCancel: () => setState(() => _isDragging = false),
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          // Visual indicator replacing the transparent container
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              // Increase width slightly while dragging for tactile feedback
              width: _isDragging ? 4.0 : 2.0,
              // Highlight with primary color when active
              color: _isDragging
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.0),
            ),
          ),
        ),
      ),
    );
  }
}
