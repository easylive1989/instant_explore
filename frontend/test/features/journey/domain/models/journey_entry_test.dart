import 'package:flutter_test/flutter_test.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';

void main() {
  group('PassportEntry', () {
    final testDate = DateTime.parse('2023-10-27T10:00:00Z');
    final entry = JourneyEntry(
      id: 'test-id',
      userId: 'user-123',
      placeId: 'place-123',
      placeName: 'Test Place',
      placeAddress: '123 Test St',
      placeImageUrl: 'http://example.com/image.jpg',
      narrationText: 'This is a test narration.',
      narrationAspect: NarrationAspect.historicalBackground,
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
      'narration_style': 'historical_background',
      'created_at': '2023-10-27T10:00:00.000Z',
    };

    test('fromJson creates correct PassportEntry', () {
      final result = JourneyEntry.fromJson(json);

      expect(result.id, entry.id);
      expect(result.userId, entry.userId);
      expect(result.placeId, entry.placeId);
      expect(result.placeName, entry.placeName);
      expect(result.placeAddress, entry.placeAddress);
      expect(result.placeImageUrl, entry.placeImageUrl);
      expect(result.narrationText, entry.narrationText);
      expect(result.narrationAspect, entry.narrationAspect);
      expect(result.createdAt, entry.createdAt);
    });

    test('toJson returns correct Map', () {
      final result = entry.toJson();
      expect(result, json);
    });

    test('fromJson handles architecture aspect correctly', () {
      final architectureJson = {...json, 'narration_style': 'architecture'};
      final result = JourneyEntry.fromJson(architectureJson);
      expect(result.narrationAspect, NarrationAspect.architecture);
    });

    test('fromJson defaults to historicalBackground on unknown aspect', () {
      final unknownJson = {...json, 'narration_style': 'unknown'};
      final result = JourneyEntry.fromJson(unknownJson);
      expect(result.narrationAspect, NarrationAspect.historicalBackground);
    });
  });
}
