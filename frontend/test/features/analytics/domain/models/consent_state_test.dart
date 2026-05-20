import 'package:context_app/features/analytics/domain/models/consent_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsentState', () {
    group('defaultOn', () {
      test('should opt the user in by default', () {
        final state = ConsentState.defaultOn();

        expect(state.enabled, isTrue);
      });

      test('should stamp updatedAt with a current timestamp', () {
        final before = DateTime.now();
        final state = ConsentState.defaultOn();
        final after = DateTime.now();

        expect(
          state.updatedAt.isBefore(before.subtract(const Duration(seconds: 1))),
          isFalse,
        );
        expect(
          state.updatedAt.isAfter(after.add(const Duration(seconds: 1))),
          isFalse,
        );
      });
    });

    group('copyWith', () {
      test('should override only the fields supplied', () {
        final original = ConsentState(
          enabled: true,
          updatedAt: DateTime.utc(2026, 1, 1),
        );

        final flipped = original.copyWith(enabled: false);

        expect(flipped.enabled, isFalse);
        expect(flipped.updatedAt, original.updatedAt);
      });
    });

    group('equality', () {
      test('should treat states with identical fields as equal', () {
        final timestamp = DateTime.utc(2026, 1, 1);
        final a = ConsentState(enabled: true, updatedAt: timestamp);
        final b = ConsentState(enabled: true, updatedAt: timestamp);

        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('should treat differing enabled flags as not equal', () {
        final timestamp = DateTime.utc(2026, 1, 1);
        final a = ConsentState(enabled: true, updatedAt: timestamp);
        final b = ConsentState(enabled: false, updatedAt: timestamp);

        expect(a, isNot(equals(b)));
      });
    });

    group('toJson', () {
      test('should serialise enabled and updatedAt with snake_case keys', () {
        final state = ConsentState(
          enabled: false,
          updatedAt: DateTime.utc(2026, 1, 1, 12, 30),
        );

        final json = state.toJson();

        expect(json, {
          'enabled': false,
          'updated_at': '2026-01-01T12:30:00.000Z',
        });
      });
    });
  });
}
