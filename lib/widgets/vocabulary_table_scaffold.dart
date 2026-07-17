import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/orientation_controller.dart';
import 'package:vocabulary_table_app/widgets/universal_toolbar.dart';

class VocabularyTableScaffold extends StatefulWidget {
  const VocabularyTableScaffold({super.key, required this.child});

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
    const padding = 4.0;
    return Scaffold(
      body: GestureDetector(
        behavior: .opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: SignalBuilder(
            builder: (context) {
              final isLandscape = _orientationController.isLandscape.value;

              return Padding(
                padding: const EdgeInsets.all(padding),
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: Flex(
                    direction: isLandscape ? .horizontal : .vertical,
                    children: [
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(1),
                        child: UniversalToolbar(isVertical: isLandscape),
                      ),
                      Expanded(
                        child: FocusTraversalOrder(
                          order: const NumericFocusOrder(2),
                          child: widget.child,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
