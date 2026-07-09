import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Custom drag listener that allows configuring the long-press delay.
class CustomDelayedDragStartListener extends ReorderableDragStartListener {
  const CustomDelayedDragStartListener({
    super.key,
    required super.child,
    required super.index,
    super.enabled,
    this.delay = const Duration(milliseconds: 500),
  });

  final Duration delay;

  @override
  MultiDragGestureRecognizer createRecognizer() {
    // A new recognizer instance is required here anyway;
    // passing the dynamic 'delay' property has zero performance penalty.
    return DelayedMultiDragGestureRecognizer(delay: delay);
  }
}
