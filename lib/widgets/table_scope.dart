import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:vocabulary_table_app/controller/orientation_controller.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';

class TableScope extends StatefulWidget {
  const TableScope({super.key, required this.child});

  final Widget child;

  @override
  State<TableScope> createState() => _TableScopeState();
}

class _TableScopeState extends State<TableScope> {
  @override
  void initState() {
    super.initState();

    GetIt.I.pushNewScope(scopeName: 'TableScope');

    GetIt.I.registerLazySingleton<OrientationController>(
      () => OrientationController()..init(),
      dispose: (controller) => controller.dispose(),
    );

    GetIt.I.registerLazySingleton<TableLayoutController>(
      () => TableLayoutController(borderColor: Theme.of(context).colorScheme.outlineVariant),
      dispose: (controller) => controller.dispose,
    );
  }

  @override
  void dispose() {
    GetIt.I.popScope();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
