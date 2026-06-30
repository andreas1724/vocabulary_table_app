import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';

/// Size for the drag area between columns.
const _dragHandleWidthMobile = 48.0;
const _dragHandleWidthDesktop = 24.0;

class HeaderRow extends StatefulWidget {
  const HeaderRow({
    super.key,
    required this.controller,
    required this.tableWidth,
  });

  final TableLayoutController controller;
  final double tableWidth;

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
        final tableWidth = widget.tableWidth;
        final borderWidth = widget.controller.borderWidth.value;
        final borderColor = widget.controller.borderColor.value;
        final showComment = widget.controller.showComment.value;

        final w1 = tableWidth * widget.controller.col1Ratio.value;
        final w2 = tableWidth * widget.controller.col2Ratio.value;
        final w3 = tableWidth * widget.controller.col3Ratio.value;

        final scale = widget.controller.scale.value;

        return Stack(
          key: _containerKey,
          children: [
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Table(
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 8 * scale,
                              ),
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
              scale: scale,
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
                scale: scale,
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
    required this.scale,
  });

  final double leftPosition;
  final double scale;
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
    final isMobile =
        (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);
    return Positioned(
      left: isMobile
          ? widget.leftPosition - _dragHandleWidthMobile / 2
          : widget.leftPosition - widget.scale * _dragHandleWidthDesktop / 2,
      top: 0,
      bottom: 0,
      width: isMobile
          ? _dragHandleWidthMobile
          : widget.scale * _dragHandleWidthDesktop,
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
