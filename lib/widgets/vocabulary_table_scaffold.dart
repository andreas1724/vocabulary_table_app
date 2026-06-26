import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/widgets/table_scope.dart';
import 'package:vocabulary_table_app/widgets/universal_toolbar.dart';

class VocabularyTableScaffold extends StatelessWidget {
  const VocabularyTableScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final orientationController = TableScope.of(context).orientationController;

    return Scaffold(
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final isLandscape = orientationController.isLandscape.value;

            return Flex(
              direction: isLandscape ? .horizontal : .vertical,
              children: [
                UniversalToolbar(isVertical: isLandscape),
                const Expanded(child: _TableContent()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TableContent extends StatelessWidget {
  const _TableContent();

  @override
  Widget build(BuildContext context) {
    final appModeController = TableScope.of(context).appModeController;

    return SignalBuilder(
      builder: (context) {
        final appMode = appModeController.appMode.value;
        final isCommentVisible = appModeController.isCommentVisible.value;
        return Center(
          child: Text(
            'Mode: ${appMode.name.toUpperCase()} | Comments: $isCommentVisible',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        );
      },
    );
  }
}