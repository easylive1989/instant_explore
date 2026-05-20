import 'package:context_app/features/analytics/domain/models/abandon_reason.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AbandonReason', () {
    group('wireName', () {
      test('should map each reason to its snake_case wire id', () {
        expect(AbandonReason.userStop.wireName, 'user_stop');
        expect(AbandonReason.switched.wireName, 'switched');
        expect(AbandonReason.backgrounded.wireName, 'backgrounded');
        expect(AbandonReason.killed.wireName, 'killed');
        expect(AbandonReason.routeChange.wireName, 'route_change');
      });

      test('should cover every enum value (exhaustive)', () {
        for (final reason in AbandonReason.values) {
          expect(
            reason.wireName,
            isNotEmpty,
            reason: 'No wireName mapping for $reason',
          );
        }
      });
    });
  });
}
