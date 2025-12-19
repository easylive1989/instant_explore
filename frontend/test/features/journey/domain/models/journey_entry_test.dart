import 'package:flutter_test/flutter_test.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/core/domain/models/language.dart';

void main() {
  group('JourneyEntry', () {
    final testDate = DateTime.parse('2023-10-27T10:00:00Z');
    const testPlace = SavedPlace(
      id: 'place-123',
      name: 'Test Place',
      address: '123 Test St',
      imageUrl: 'http://example.com/image.jpg',
    );
    final testContent = NarrationContent.fromText('This is a test narration.');
    final testLanguage = Language.fromString('zh-TW');

    final entry = JourneyEntry(
      id: 'test-id',
      userId: 'user-123',
      place: testPlace,
      narrationContent: testContent,
      createdAt: testDate,
      language: testLanguage,
    );

    final json = {
      'id': 'test-id',
      'user_id': 'user-123',
      'place': {
        'id': 'place-123',
        'name': 'Test Place',
        'address': '123 Test St',
        'image_url': 'http://example.com/image.jpg',
      },
      'narration_content': testContent.toJson(),
      'created_at': '2023-10-27T10:00:00.000Z',
      'language': 'zh-TW',
    };

    test('fromJson creates correct JourneyEntry', () {
      final result = JourneyEntry.fromJson(json);

      expect(result.id, entry.id);
      expect(result.userId, entry.userId);
      expect(result.place.id, entry.place.id);
      expect(result.place.name, entry.place.name);
      expect(result.place.address, entry.place.address);
      expect(result.place.imageUrl, entry.place.imageUrl);
      expect(result.narrationContent.text, entry.narrationContent.text);
      expect(result.language.code, entry.language.code);
      expect(result.createdAt, entry.createdAt);
    });

    test('toJson returns correct Map', () {
      final result = entry.toJson();
      expect(result['id'], json['id']);
      expect(result['user_id'], json['user_id']);
      expect(result['place'], json['place']);
      expect(result['language'], json['language']);
      expect(result['created_at'], json['created_at']);
    });

    test('fromJson handles place without imageUrl', () {
      final jsonWithoutImage = {
        ...json,
        'place': {
          'id': 'place-123',
          'name': 'Test Place',
          'address': '123 Test St',
        },
      };
      final result = JourneyEntry.fromJson(jsonWithoutImage);
      expect(result.place.imageUrl, isNull);
    });
  });
}
