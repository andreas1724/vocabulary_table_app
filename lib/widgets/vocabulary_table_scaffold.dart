import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/widgets/header_row.dart';
import 'package:vocabulary_table_app/widgets/table_scope.dart';
import 'package:vocabulary_table_app/widgets/universal_toolbar.dart';

class VocabularyTableScaffold extends StatelessWidget {
  VocabularyTableScaffold({super.key});
  final _tableLayoutController = TableLayoutController();

  @override
  Widget build(BuildContext context) {
    final orientationController = TableScope.of(context).orientationController;

    return Scaffold(
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final isLandscape = orientationController.isLandscape.value;

            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: Flex(
                direction: isLandscape ? .horizontal : .vertical,
                crossAxisAlignment: isLandscape ? .start : .center,
                mainAxisAlignment: isLandscape ? .center : .start,
                children: [
                  UniversalToolbar(isVertical: isLandscape),
                  Expanded(
                    child: Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return HeaderRow(
                              controller: _tableLayoutController,
                              tableWidth: constraints.maxWidth,
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
