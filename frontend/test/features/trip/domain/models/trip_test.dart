import 'package:context_app/features/trip/domain/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';

Trip _makeTrip({
  String id = 't1',
  String name = 'Test Trip',
  DateTime? startDate,
  DateTime? endDate,
  String? coverImageUrl,
  String? description,
  DateTime? createdAt,
}) {
  return Trip(
    id: id,
    name: name,
    startDate: startDate,
    endDate: endDate,
    coverImageUrl: coverImageUrl,
    description: description,
    createdAt: createdAt ?? DateTime(2026, 4, 17),
  );
}

void main() {
  group('Trip JSON round-trip', () {
    test('preserves all fields when optional fields are present', () {
      final original = _makeTrip(
        id: 'full',
        name: '2026 Japan Trip',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 10),
        coverImageUrl: 'https://example.com/cover.jpg',
        description: 'Cherry blossom season',
        createdAt: DateTime(2026, 4, 17, 10, 30),
      );

      final restored = Trip.fromJson(original.toJson());

      expect(restored, equals(original));
    });

    test('preserves all fields when optional fields are null', () {
      final original = _makeTrip(id: 'min', name: 'Weekend Trip');

      final restored = Trip.fromJson(original.toJson());

      expect(restored, equals(original));
      expect(restored.startDate, isNull);
      expect(restored.endDate, isNull);
      expect(restored.coverImageUrl, isNull);
      expect(restored.description, isNull);
    });
  });

  group('Trip.copyWith', () {
    test('updates only the provided fields and keeps id/createdAt', () {
      final original = _makeTrip(
        id: 'keep',
        name: 'Old Name',
        startDate: DateTime(2026, 5, 1),
      );

      final updated = original.copyWith(
        name: 'New Name',
        endDate: DateTime(2026, 5, 10),
      );

      expect(updated.id, 'keep');
      expect(updated.createdAt, original.createdAt);
      expect(updated.name, 'New Name');
      expect(updated.startDate, DateTime(2026, 5, 1));
      expect(updated.endDate, DateTime(2026, 5, 10));
    });
  });
}
