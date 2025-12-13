import 'package:flutter_test/flutter_test.dart';
import 'package:context_app/features/passport/models/passport_entry.dart';
import 'package:context_app/features/player/models/narration_style.dart';

void main() {
  group('PassportEntry', () {
    final testDate = DateTime.parse('2023-10-27T10:00:00Z');
    final entry = PassportEntry(
      id: 'test-id',
      userId: 'user-123',
      placeId: 'place-123',
      placeName: 'Test Place',
      placeAddress: '123 Test St',
      placeImageUrl: 'http://example.com/image.jpg',
      narrationText: 'This is a test narration.',
      narrationStyle: NarrationStyle.brief,
      createdAt: testDate,
    );

    final json = {
      'id': 'test-id',
      'user_id': 'user-123',
      'place_id': 'place-123',
      'place_name': 'Test Place',
      'place_address': '123 Test St',
      'place_image_url': 'http://example.com/image.jpg',
      'narration_text': 'This is a test narration.',
      'narration_style': 'brief',
      'created_at': '2023-10-27T10:00:00.000Z',
    };

    test('fromJson creates correct PassportEntry', () {
      final result = PassportEntry.fromJson(json);

      expect(result.id, entry.id);
      expect(result.userId, entry.userId);
      expect(result.placeId, entry.placeId);
      expect(result.placeName, entry.placeName);
      expect(result.placeAddress, entry.placeAddress);
      expect(result.placeImageUrl, entry.placeImageUrl);
      expect(result.narrationText, entry.narrationText);
      expect(result.narrationStyle, entry.narrationStyle);
      expect(result.createdAt, entry.createdAt);
    });

    test('toJson returns correct Map', () {
      final result = entry.toJson();
      expect(result, json);
    });

    test('fromJson handles deep_dive style correctly', () {
      final deepDiveJson = {...json, 'narration_style': 'deepDive'};
      final result = PassportEntry.fromJson(deepDiveJson);
      expect(result.narrationStyle, NarrationStyle.deepDive);
    });

    test('fromJson defaults to brief on unknown style', () {
      final unknownJson = {...json, 'narration_style': 'unknown'};
      final result = PassportEntry.fromJson(unknownJson);
      expect(result.narrationStyle, NarrationStyle.brief);
    });
  });
}