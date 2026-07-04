import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Custom ScrollPhysics that dynamically disables scrolling
/// when multiple pointers are active, without requiring a widget rebuild.
class MultiTouchBlockerScrollPhysics extends ScrollPhysics {
  const MultiTouchBlockerScrollPhysics({
    required this.activePointers,
    super.parent,
  });

  final Signal<int> activePointers;

  @override
  MultiTouchBlockerScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return MultiTouchBlockerScrollPhysics(
      activePointers: activePointers,
      parent: buildParent(ancestor),
    );
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    // Read the signal synchronously without subscribing.
    // If more than one finger is on the screen, block the scroll interaction.
    if (activePointers.peek() > 1) {
      return false;
    }
    return super.shouldAcceptUserOffset(position);
  }
}
