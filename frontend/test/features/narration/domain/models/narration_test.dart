import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/narration/domain/models/narration.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Narration', () {
    // Helper function to create a test place
    Place createTestPlace() {
      return Place(
        id: 'test-place-id',
        name: 'Test Place',
        formattedAddress: 'Test Address',
        location: PlaceLocation(latitude: 25.0330, longitude: 121.5654),
        types: const ['tourist_attraction'],
        photos: const [],
        category: PlaceCategory.historicalCultural,
      );
    }

    // Helper function to create test content
    NarrationContent createTestContent() {
      return NarrationContent.fromText('第一句。第二句。第三句。');
    }

    group('constructor', () {
      test('should create narration with all required fields', () {
        final place = createTestPlace();
        final content = createTestContent();

        final narration = Narration(
          id: 'test-id',
          place: place,
          aspect: NarrationAspect.historicalBackground,
          content: content,
        );

        expect(narration.id, 'test-id');
        expect(narration.place, place);
        expect(narration.aspect, NarrationAspect.historicalBackground);
        expect(narration.content, content);
      });
    });

    group('copyWith', () {
      test('should copy with updated id', () {
        final narration = Narration(
          id: 'test-id',
          place: createTestPlace(),
          aspect: NarrationAspect.historicalBackground,
          content: createTestContent(),
        );

        final updated = narration.copyWith(id: 'new-id');

        expect(updated.id, 'new-id');
        expect(updated.place, narration.place);
        expect(updated.aspect, narration.aspect);
        expect(updated.content, narration.content);
      });

      test('should copy with updated place', () {
        final narration = Narration(
          id: 'test-id',
          place: createTestPlace(),
          aspect: NarrationAspect.historicalBackground,
          content: createTestContent(),
        );

        final newPlace = Place(
          id: 'new-place-id',
          name: 'New Place',
          formattedAddress: 'New Address',
          location: PlaceLocation(latitude: 25.0330, longitude: 121.5654),
          types: const ['tourist_attraction'],
          photos: const [],
          category: PlaceCategory.historicalCultural,
        );
        final updated = narration.copyWith(place: newPlace);

        expect(updated.place, newPlace);
        expect(updated.id, narration.id);
        expect(updated.aspect, narration.aspect);
        expect(updated.content, narration.content);
      });

      test('should copy with updated aspect', () {
        final narration = Narration(
          id: 'test-id',
          place: createTestPlace(),
          aspect: NarrationAspect.historicalBackground,
          content: createTestContent(),
        );

        final updated = narration.copyWith(aspect: NarrationAspect.architecture);

        expect(updated.aspect, NarrationAspect.architecture);
        expect(updated.id, narration.id);
        expect(updated.place, narration.place);
        expect(updated.content, narration.content);
      });

      test('should copy with updated content', () {
        final narration = Narration(
          id: 'test-id',
          place: createTestPlace(),
          aspect: NarrationAspect.historicalBackground,
          content: createTestContent(),
        );

        final newContent = NarrationContent.fromText('新的內容。');
        final updated = narration.copyWith(content: newContent);

        expect(updated.content, newContent);
        expect(updated.id, narration.id);
        expect(updated.place, narration.place);
        expect(updated.aspect, narration.aspect);
      });

      test('should preserve all fields when none specified', () {
        final narration = Narration(
          id: 'test-id',
          place: createTestPlace(),
          aspect: NarrationAspect.historicalBackground,
          content: createTestContent(),
        );

        final updated = narration.copyWith();

        expect(updated.id, narration.id);
        expect(updated.place, narration.place);
        expect(updated.aspect, narration.aspect);
        expect(updated.content, narration.content);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final place = createTestPlace();
        final content = createTestContent();

        final narration1 = Narration(
          id: 'test-id',
          place: place,
          aspect: NarrationAspect.historicalBackground,
          content: content,
        );

        final narration2 = Narration(
          id: 'test-id',
          place: place,
          aspect: NarrationAspect.historicalBackground,
          content: content,
        );

        expect(narration1, equals(narration2));
        expect(narration1.hashCode, equals(narration2.hashCode));
      });

      test('should not be equal when id differs', () {
        final place = createTestPlace();
        final content = createTestContent();

        final narration1 = Narration(
          id: 'test-id-1',
          place: place,
          aspect: NarrationAspect.historicalBackground,
          content: content,
        );

        final narration2 = Narration(
          id: 'test-id-2',
          place: place,
          aspect: NarrationAspect.historicalBackground,
          content: content,
        );

        expect(narration1, isNot(equals(narration2)));
      });

      test('should not be equal when aspect differs', () {
        final place = createTestPlace();
        final content = createTestContent();

        final narration1 = Narration(
          id: 'test-id',
          place: place,
          aspect: NarrationAspect.historicalBackground,
          content: content,
        );

        final narration2 = Narration(
          id: 'test-id',
          place: place,
          aspect: NarrationAspect.architecture,
          content: content,
        );

        expect(narration1, isNot(equals(narration2)));
      });

      test('should not be equal when content differs', () {
        final place = createTestPlace();

        final narration1 = Narration(
          id: 'test-id',
          place: place,
          aspect: NarrationAspect.historicalBackground,
          content: createTestContent(),
        );

        final narration2 = Narration(
          id: 'test-id',
          place: place,
          aspect: NarrationAspect.historicalBackground,
          content: NarrationContent.fromText('不同的內容。'),
        );

        expect(narration1, isNot(equals(narration2)));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final place = createTestPlace();
        final narration = Narration(
          id: 'test-id',
          place: place,
          aspect: NarrationAspect.historicalBackground,
          content: createTestContent(),
        );

        final stringRep = narration.toString();

        expect(stringRep, contains('test-id'));
        expect(stringRep, contains('Test Place'));
        expect(stringRep, contains('historicalBackground'));
      });
    });
  });
}
