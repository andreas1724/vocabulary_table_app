import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_table_app/controller/table_layout_controller.dart';

void main() {
  group('TableLayoutController Tests', () {
    late TableLayoutController controller;

    setUp(() {
      controller = TableLayoutController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Next mode cycles correctly', () {
      expect(controller.appMode.peek(), AppMode.edit);
      controller.nextMode();
      expect(controller.appMode.peek(), AppMode.play);
      controller.nextMode();
      expect(controller.appMode.peek(), AppMode.drag);
      controller.nextMode();
      expect(controller.appMode.peek(), AppMode.edit); // Wraps around
    });

    test('Scale updates within bounds', () {
      controller.scaleStart();
      controller.scaleUpdate(3.0); // Attempt max scale bypass
      expect(controller.scale.peek(), TableLayoutController.maxScale);

      controller.scaleStart();
      controller.scaleUpdate(0.1); // Attempt min scale bypass
      expect(controller.scale.peek(), TableLayoutController.minScale);
    });

    test('Toggle comment recalculates ratios safely', () {
      controller.setRatios(col1Ratio: 0.3, col2Ratio: 0.3); // from extension
      controller.toggleComment(); // Hide comment
      
      expect(controller.showComment.peek(), false);
      expect(controller.col3Ratio.peek(), 0.0);
      
      // Ratios should scale up to fill the 1.0 space (0.3 + 0.3 = 0.6)
      // New ratios should be 0.5 and 0.5
      expect(controller.col1Ratio.peek(), closeTo(0.5, 0.01));
      expect(controller.col2Ratio.peek(), closeTo(0.5, 0.01));
    });
  });
}