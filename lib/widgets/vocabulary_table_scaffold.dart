import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/orientation_controller.dart';
import 'package:vocabulary_table_app/widgets/universal_toolbar.dart';

class VocabularyTableScaffold extends StatefulWidget {
  const VocabularyTableScaffold({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<VocabularyTableScaffold> createState() =>
      _VocabularyTableScaffoldState();
}

class _VocabularyTableScaffoldState extends State<VocabularyTableScaffold> {
  // Defer the GetIt resolution with 'late' so it resolves only when accessed.
  // This gives the app time to properly register dependencies beforehand.
  late final _orientationController = GetIt.I<OrientationController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final isLandscape = _orientationController.isLandscape.value;

            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: Flex(
                direction: isLandscape ? .horizontal : .vertical,
                children: [
                  UniversalToolbar(isVertical: isLandscape),
                  Expanded(child: widget.child),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}