import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

enum AppMode { view, drag, edit, play }

extension AppModeX on AppMode {
  String get title => switch (this) {
    .view => 'View',
    .drag => 'Drag',
    .edit => 'Edit',
    .play => 'Play (TTS)',
  };

  IconData get icon => switch (this) {
    .view => Icons.visibility,
    .drag => Icons.drag_handle,
    .edit => Icons.edit,
    .play => Icons.play_arrow,
  };
}

class AppModeController {
  final appMode = signal<AppMode>(.view);

  void dispose() {
    appMode.dispose();
  }
}