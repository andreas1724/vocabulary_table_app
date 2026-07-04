import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/widgets/header_row.dart';
import 'package:vocabulary_table_app/widgets/table_body.dart';

class VocabularyTable extends StatefulWidget {
  const VocabularyTable({super.key});

  @override
  State<VocabularyTable> createState() => _VocabularyTableState();
}

class _VocabularyTableState extends State<VocabularyTable> {
  late final _tableLayoutController = GetIt.I<TableLayoutController>();

  final _activePointerIds = <int>{};
  bool _isPanZooming = false;
  
  late final _activePointers = signal<int>(0);
  
  // Memoized derived state: Only notifies listeners when the boolean result changes.
  late final _isMultiTouch = computed(() => _activePointers.value > 1);

  @override
  void dispose() {
    _activePointers.dispose();
    _isMultiTouch.dispose();
    super.dispose();
  }

void _handlePointerEvent(PointerEvent event, {required bool isAdding}) {
    // Optional, aber sicherer: Wir filtern explizit nach Touch-Events, 
    // damit z.B. Maus-Klicks nicht als "Finger" gezählt werden.
    if (event.kind != PointerDeviceKind.touch) return;

    if (isAdding) {
      _activePointerIds.add(event.pointer);
    } else {
      _activePointerIds.remove(event.pointer);
    }
    
    // Einfache, strikte Zuweisung. Kein PanZoom-Fake mehr.
    _activePointers.value = _activePointerIds.length;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) => _handlePointerEvent(e, isAdding: true),
      onPointerUp: (e) => _handlePointerEvent(e, isAdding: false),
      onPointerCancel: (e) => _handlePointerEvent(e, isAdding: false),
      
      onPointerSignal: (event) => _handlePointerSignal(event, _tableLayoutController.scale),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (details) => _tableLayoutController.scaleStart(),
        onScaleUpdate: (details) => _tableLayoutController.scaleUpdate(details.scale),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth = constraints.maxWidth;
            return Column(
              children: [
                HeaderRow(tableWidth: tableWidth),
                Expanded(
                  child: TableBody(
                    tableWidth: tableWidth,
                    // Pass the computed boolean signal instead of the raw integer count
                    isMultiTouch: _isMultiTouch,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handlePointerSignal(PointerSignalEvent event, Signal<double> scale) {
    if (event is PointerScaleEvent) {
      final current = scale.peek();
      scale.value = (current * event.scale).clamp(0.5, 4.0);
    }
  }
}