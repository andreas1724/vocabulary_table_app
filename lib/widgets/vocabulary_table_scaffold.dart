import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/orientation_controller.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';
import 'package:vocabulary_table_app/widgets/header_row.dart';
import 'package:vocabulary_table_app/widgets/universal_toolbar.dart';

class VocabularyTableScaffold extends StatelessWidget {
  const VocabularyTableScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final orientationController = GetIt.I<OrientationController>();
    final tableLayoutController = GetIt.I<TableLayoutController>();

    return Scaffold(
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final isLandscape = orientationController.isLandscape.value;

            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: Flex(
                direction: isLandscape ? .horizontal : .vertical,
                children: [
                  UniversalToolbar(isVertical: isLandscape),
                  Expanded(
                    child: Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return HeaderRow(
                              controller: tableLayoutController,
                              tableWidth: constraints.maxWidth,
                            );
                          },
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
