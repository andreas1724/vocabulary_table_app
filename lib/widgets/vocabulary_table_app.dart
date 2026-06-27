import 'package:flutter/material.dart';
import 'package:vocabulary_table_app/controller/app_mode_controller.dart';
import 'package:vocabulary_table_app/controller/orientation_controller.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/widgets/table_scope.dart';
import 'package:vocabulary_table_app/widgets/vocabulary_table_scaffold.dart';

class VocabularyTableApp extends StatefulWidget {
  const VocabularyTableApp({super.key});

  @override
  State<VocabularyTableApp> createState() => _VocabularyTableAppState();
}

class _VocabularyTableAppState extends State<VocabularyTableApp> {
  late final OrientationController _orientationController;
  late final AppModeController _appModeController;
  late final TableLayoutController _tableLayoutController;

  @override
  void initState() {
    super.initState();
    _orientationController = OrientationController();
    _orientationController.init();
    _tableLayoutController = TableLayoutController();
    _appModeController = AppModeController();
  }

  @override
  void dispose() {
    _orientationController.dispose();
    _tableLayoutController.dispose();
    _appModeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TableScope(
      orientationController: _orientationController,
      tableLayoutController: _tableLayoutController,
      appModeController: _appModeController,
      child: VocabularyTableScaffold(),
    );
  }
}