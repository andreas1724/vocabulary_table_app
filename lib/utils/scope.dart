import 'package:flutter/material.dart';

class Scope<T> extends InheritedWidget {
  const Scope({super.key, required this.value, required super.child});

  final T value;

  // Optional retrieval: returns T or null if the Scope is not found
  static T? maybeOf<T>(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<Scope<T>>();
    return widget?.value;
  }

  static T of<T>(BuildContext context) {
    final result = maybeOf<T>(context);
    if (result == null) {
      throw StateError(
        'No Scope<$T> found in context. Ensure that the widget tree contains a Scope<$T> above this context.',
      );
    }
    return result;
  }

  @override
  bool updateShouldNotify(Scope<T> oldWidget) => value != oldWidget.value;
}
