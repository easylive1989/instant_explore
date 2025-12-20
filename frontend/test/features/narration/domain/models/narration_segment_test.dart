import 'package:context_app/features/narration/domain/models/narration_segment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NarrationSegment', () {
    group('containsPosition', () {
      test('should return true for positions within range', () {
        const segment = NarrationSegment(
          text: 'Test',
          startPosition: 10,
          endPosition: 20,
        );

        expect(segment.containsPosition(10), true);
        expect(segment.containsPosition(15), true);
        expect(segment.containsPosition(19), true);
      });

      test('should return false for positions outside range', () {
        const segment = NarrationSegment(
          text: 'Test',
          startPosition: 10,
          endPosition: 20,
        );

        expect(segment.containsPosition(9), false);
        expect(segment.containsPosition(20), false); // endPosition 不含
        expect(segment.containsPosition(25), false);
      });

      test('should handle edge case at boundaries', () {
        const segment = NarrationSegment(
          text: 'A',
          startPosition: 0,
          endPosition: 1,
        );

        expect(segment.containsPosition(-1), false);
        expect(segment.containsPosition(0), true);
        expect(segment.containsPosition(1), false);
      });
    });
  });
}
