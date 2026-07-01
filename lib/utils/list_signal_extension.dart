import 'package:signals_flutter/signals_flutter.dart';

/// Extension on ListSignal to safely handle the lifecycle of nested Signals.
extension DisposableSignalList<T> on ListSignal<Signal<T>> {
  /// Disposes all internal signals and clears the list to prevent memory leaks.
  void clearAndDispose() {
    for (final signal in this) {
      signal.dispose();
    }
    clear();
  }

  /// Removes an item at [index] and explicitly disposes it.
  void removeAndDisposeAt(int index) {
    if (index < 0 || index >= length) return;

    // Remove reference from list first, then dispose the isolated object
    final removedSignal = removeAt(index);
    removedSignal.dispose();
  }
}
