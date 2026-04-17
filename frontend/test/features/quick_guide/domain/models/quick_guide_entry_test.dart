import 'dart:typed_data';

import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final imageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
  const description = 'This is a beautiful temple.';
  const language = Language('zh-TW');

  group('QuickGuideEntry.create', () {
    test('creates entry with correct data', () {
      final entry = QuickGuideEntry.create(
        id: 'test-id',
        imageBytes: imageBytes,
        aiDescription: description,
        language: language,
      );

      expect(entry.id, 'test-id');
      expect(entry.imageBytes, imageBytes);
      expect(entry.aiDescription, description);
      expect(entry.language, language);
      expect(
        entry.createdAt.difference(DateTime.now()).abs(),
        lessThan(const Duration(seconds: 5)),
      );
    });

    test('preserves distinct IDs passed by caller', () {
      final entry1 = QuickGuideEntry.create(
        id: 'id-1',
        imageBytes: imageBytes,
        aiDescription: description,
        language: language,
      );
      final entry2 = QuickGuideEntry.create(
        id: 'id-2',
        imageBytes: imageBytes,
        aiDescription: description,
        language: language,
      );

      expect(entry1.id, equals('id-1'));
      expect(entry2.id, equals('id-2'));
      expect(entry1.id, isNot(equals(entry2.id)));
    });
  });

  group('QuickGuideEntry JSON round-trip', () {
    test('toJson/fromJson preserves all fields', () {
      final original = QuickGuideEntry.create(
        id: 'round-trip-id',
        imageBytes: imageBytes,
        aiDescription: description,
        language: language,
      );

      final restored = QuickGuideEntry.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.imageBytes, original.imageBytes);
      expect(restored.aiDescription, original.aiDescription);
      expect(restored.language.code, original.language.code);
      expect(
        restored.createdAt.toIso8601String(),
        original.createdAt.toIso8601String(),
      );
    });

    test('fromJson defaults language to zh-TW when absent', () {
      final original = QuickGuideEntry.create(
        id: 'lang-test-id',
        imageBytes: imageBytes,
        aiDescription: description,
        language: language,
      );
      final json = original.toJson()..remove('language');

      final restored = QuickGuideEntry.fromJson(json);

      expect(restored.language.code, 'zh-TW');
    });

    test('create defaults tripId to null when omitted', () {
      final entry = QuickGuideEntry.create(
        id: 'no-trip-id',
        imageBytes: imageBytes,
        aiDescription: description,
        language: language,
      );

      expect(entry.tripId, isNull);
    });

    test('create attaches tripId when provided', () {
      final entry = QuickGuideEntry.create(
        id: 'with-trip-id',
        imageBytes: imageBytes,
        aiDescription: description,
        language: language,
        tripId: 'trip-42',
      );

      expect(entry.tripId, 'trip-42');
    });

    test('copyWithTripId returns a copy with updated tripId', () {
      final original = QuickGuideEntry.create(
        id: 'copy-id',
        imageBytes: imageBytes,
        aiDescription: description,
        language: language,
        tripId: 'trip-a',
      );

      final moved = original.copyWithTripId('trip-b');
      final cleared = original.copyWithTripId(null);

      expect(moved.tripId, 'trip-b');
      expect(moved.id, original.id);
      expect(cleared.tripId, isNull);
    });

    test('fromJson treats missing trip_id as null (backward compat)', () {
      final entry = QuickGuideEntry.create(
        id: 'legacy-id',
        imageBytes: imageBytes,
        aiDescription: description,
        language: language,
        tripId: 'will-be-removed',
      );
      final legacyJson = entry.toJson()..remove('trip_id');

      final restored = QuickGuideEntry.fromJson(legacyJson);

      expect(restored.tripId, isNull);
    });

    test('toJson stores imageBytes as base64 string', () {
      final entry = QuickGuideEntry.create(
        id: 'base64-test-id',
        imageBytes: imageBytes,
        aiDescription: description,
        language: language,
      );
      final json = entry.toJson();

      expect(json['image_base64'], isA<String>());
      expect((json['image_base64'] as String).isNotEmpty, isTrue);
    });
  });
}
